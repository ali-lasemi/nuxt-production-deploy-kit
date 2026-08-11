#!/usr/bin/env node

import fs from 'node:fs'
import path from 'node:path'

const [, , command, ...args] = process.argv

function fail(message) {
  console.error(`ERROR: ${message}`)
  process.exit(1)
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

function appendEvent(file, values) {
  fs.mkdirSync(path.dirname(file), { recursive: true })

  const event = {
    schema_version: 1,
    timestamp: new Date().toISOString(),
    operation: values.operation ?? '',
    result: values.result ?? '',
    application: values.application ?? '',
    release: values.release ?? '',
    previous_release: values.previous_release ?? '',
    slot: values.slot ?? '',
    previous_slot: values.previous_slot ?? '',
    source_commit: values.source_commit ?? 'unknown',
    actor: values.actor ?? 'unknown',
    message: values.message ?? ''
  }

  fs.appendFileSync(file, `${JSON.stringify(event)}\n`, 'utf8')
}

function verifyFile(file) {
  if (!fs.existsSync(file)) {
    fail(`Audit file not found: ${file}`)
  }

  const content = fs.readFileSync(file, 'utf8').trim()

  if (!content) {
    fail(`Audit file is empty: ${file}`)
  }

  const lines = content.split('\n')

  const requiredFields = [
    'schema_version',
    'timestamp',
    'operation',
    'result',
    'application',
    'release',
    'previous_release',
    'slot',
    'previous_slot',
    'source_commit',
    'actor',
    'message'
  ]

  lines.forEach((line, index) => {
    let event

    try {
      event = JSON.parse(line)
    } catch (error) {
      fail(`Invalid JSON on audit line ${index + 1}: ${error.message}`)
    }

    for (const field of requiredFields) {
      if (!(field in event)) {
        fail(`Missing field '${field}' on audit line ${index + 1}`)
      }
    }

    if (event.schema_version !== 1) {
      fail(`Unsupported schema version on audit line ${index + 1}`)
    }
  })

  console.log(`Audit trail verified: ${file}`)
  console.log(`Events: ${lines.length}`)
}

function showEvents(file) {
  if (!fs.existsSync(file)) {
    fail(`Audit file not found: ${file}`)
  }

  const lines = fs.readFileSync(file, 'utf8').trim().split('\n').filter(Boolean)

  for (const line of lines) {
    const event = JSON.parse(line)

    console.log(
      [
        event.timestamp,
        event.operation,
        event.result,
        event.slot || '-',
        event.release || '-',
        event.source_commit || 'unknown',
        event.actor || 'unknown',
        event.message || '-'
      ].join(' | ')
    )
  }
}

if (command === 'append') {
  const [file, ...assignments] = args

  if (!file) {
    fail('Usage: deployment-event.mjs append <file> key=value ...')
  }

  appendEvent(file, parseAssignments(assignments))
  process.exit(0)
}

if (command === 'verify') {
  const [file] = args

  if (!file) {
    fail('Usage: deployment-event.mjs verify <file>')
  }

  verifyFile(file)
  process.exit(0)
}

if (command === 'show') {
  const [file] = args

  if (!file) {
    fail('Usage: deployment-event.mjs show <file>')
  }

  showEvents(file)
  process.exit(0)
}

fail(`Unknown command: ${command ?? ''}`)