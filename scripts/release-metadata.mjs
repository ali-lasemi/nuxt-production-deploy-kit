#!/usr/bin/env node

import fs from 'node:fs'
import path from 'node:path'

const [, , command, filePath, ...args] = process.argv

function fail(message) {
  console.error(`ERROR: ${message}`)
  process.exit(1)
}

function readMetadata(target) {
  if (!fs.existsSync(target)) {
    fail(`Metadata file not found: ${target}`)
  }

  try {
    return JSON.parse(fs.readFileSync(target, 'utf8'))
  } catch (error) {
    fail(`Invalid metadata JSON: ${error.message}`)
  }
}

function writeMetadata(target, data) {
  fs.mkdirSync(path.dirname(target), { recursive: true })

  const tempFile = `${target}.tmp`
  fs.writeFileSync(tempFile, `${JSON.stringify(data, null, 2)}\n`, 'utf8')
  fs.renameSync(tempFile, target)
}

function parseAssignments(values) {
  const result = {}

  for (const value of values) {
    const separator = value.indexOf('=')

    if (separator === -1) {
      fail(`Invalid assignment: ${value}`)
    }

    const key = value.slice(0, separator)
    const assignmentValue = value.slice(separator + 1)

    if (!key) {
      fail(`Invalid assignment: ${value}`)
    }

    result[key] = assignmentValue
  }

  return result
}

if (!command || !filePath) {
  fail('Usage: release-metadata.mjs <create|update|verify> <file> [key=value ...]')
}

if (command === 'create') {
  const values = parseAssignments(args)

  const metadata = {
    schema_version: 1,
    release_id: values.release_id ?? '',
    created_at: values.created_at ?? new Date().toISOString(),
    updated_at: new Date().toISOString(),
    application: values.application ?? '',
    source_commit: values.source_commit ?? 'unknown',
    artifact: values.artifact ?? '',
    artifact_sha256: values.artifact_sha256 ?? '',
    deployed_by: values.deployed_by ?? 'unknown',
    previous_release: values.previous_release ?? '',
    status: values.status ?? 'preparing',
    validation: values.validation ?? 'pending',
    rollback: values.rollback ?? 'not_required'
  }

  writeMetadata(filePath, metadata)
  process.exit(0)
}

if (command === 'update') {
  const metadata = readMetadata(filePath)
  const updates = parseAssignments(args)

  Object.assign(metadata, updates)
  metadata.updated_at = new Date().toISOString()

  writeMetadata(filePath, metadata)
  process.exit(0)
}

if (command === 'verify') {
  const metadata = readMetadata(filePath)

  const requiredFields = [
    'schema_version',
    'release_id',
    'created_at',
    'updated_at',
    'application',
    'source_commit',
    'artifact',
    'artifact_sha256',
    'deployed_by',
    'previous_release',
    'status',
    'validation',
    'rollback'
  ]

  for (const field of requiredFields) {
    if (!(field in metadata)) {
      fail(`Missing metadata field: ${field}`)
    }
  }

  if (metadata.schema_version !== 1) {
    fail(`Unsupported schema version: ${metadata.schema_version}`)
  }

  console.log(`Metadata verified: ${filePath}`)
  process.exit(0)
}

fail(`Unknown command: ${command}`)