import fs from 'node:fs'

fs.mkdirSync('.output/server', { recursive: true })

fs.writeFileSync(
  '.output/server/index.mjs',
  `import http from 'node:http'

const host = process.env.HOST || '0.0.0.0'
const port = Number(process.env.PORT || 3000)

const server = http.createServer((request, response) => {
  if (request.url === '/') {
    response.writeHead(200, { 'content-type': 'text/plain' })
    response.end('healthy')
    return
  }

  response.writeHead(404, { 'content-type': 'text/plain' })
  response.end('not found')
})

server.listen(port, host)
`
)