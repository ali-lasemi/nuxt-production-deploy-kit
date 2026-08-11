#!/usr/bin/env node

import fs from 'node:fs'

const [, , auditFile, outputFile] = process.argv

function fail(message) {
  console.error(`ERROR: ${message}`)
  process.exit(1)
}

if (!auditFile) {
  fail('Usage: deployment-metrics.mjs <audit-log> [output-file]')
}

if (!fs.existsSync(auditFile)) {
  fail(`Audit log not found: ${auditFile}`)
}

const content = fs.readFileSync(auditFile, 'utf8').trim()

const events = content
  ? content.split('\n').filter(Boolean).map((line, index) => {
      try {
        return JSON.parse(line)
      } catch (error) {
        fail(`Invalid JSON on audit line ${index + 1}: ${error.message}`)
      }
    })
  : []

const counters = new Map()
const latestSuccess = new Map()
const latestFailure = new Map()

function increment(operation, result) {
  const key = `${operation}\u0000${result}`
  counters.set(key, (counters.get(key) ?? 0) + 1)
}

function timestampSeconds(value) {
  const timestamp = Date.parse(value)

  if (Number.isNaN(timestamp)) {
    return 0
  }

  return Math.floor(timestamp / 1000)
}

for (const event of events) {
  const operation = String(event.operation ?? 'unknown')
  const result = String(event.result ?? 'unknown')

  increment(operation, result)

  if (result === 'success') {
    latestSuccess.set(
      operation,
      Math.max(
        latestSuccess.get(operation) ?? 0,
        timestampSeconds(event.timestamp)
      )
    )
  }

  if (
    result === 'failure' ||
    result === 'failed' ||
    result === 'critical_failure'
  ) {
    latestFailure.set(
      operation,
      Math.max(
        latestFailure.get(operation) ?? 0,
        timestampSeconds(event.timestamp)
      )
    )
  }
}

function escapeLabel(value) {
  return String(value)
    .replace(/\\/g, '\\\\')
    .replace(/"/g, '\\"')
    .replace(/\n/g, '\\n')
}

const lines = []

lines.push('# HELP nuxt_deployment_events_total Total deployment lifecycle events.')
lines.push('# TYPE nuxt_deployment_events_total counter')

for (const [key, count] of [...counters.entries()].sort()) {
  const [operation, result] = key.split('\u0000')

  lines.push(
    `nuxt_deployment_events_total{operation="${escapeLabel(operation)}",result="${escapeLabel(result)}"} ${count}`
  )
}

lines.push('')
lines.push('# HELP nuxt_deployment_last_success_timestamp_seconds Unix timestamp of the most recent successful deployment operation.')
lines.push('# TYPE nuxt_deployment_last_success_timestamp_seconds gauge')

for (const [operation, timestamp] of [...latestSuccess.entries()].sort()) {
  lines.push(
    `nuxt_deployment_last_success_timestamp_seconds{operation="${escapeLabel(operation)}"} ${timestamp}`
  )
}

lines.push('')
lines.push('# HELP nuxt_deployment_last_failure_timestamp_seconds Unix timestamp of the most recent failed deployment operation.')
lines.push('# TYPE nuxt_deployment_last_failure_timestamp_seconds gauge')

for (const [operation, timestamp] of [...latestFailure.entries()].sort()) {
  lines.push(
    `nuxt_deployment_last_failure_timestamp_seconds{operation="${escapeLabel(operation)}"} ${timestamp}`
  )
}

lines.push('')
lines.push('# HELP nuxt_deployment_audit_events Current number of events present in the deployment audit log.')
lines.push('# TYPE nuxt_deployment_audit_events gauge')
lines.push(`nuxt_deployment_audit_events ${events.length}`)
lines.push('')

const output = `${lines.join('\n')}\n`

if (outputFile) {
  const temporaryFile = `${outputFile}.tmp`

  fs.writeFileSync(temporaryFile, output, 'utf8')
  fs.renameSync(temporaryFile, outputFile)

  console.log(`Deployment metrics written: ${outputFile}`)
} else {
  process.stdout.write(output)
}