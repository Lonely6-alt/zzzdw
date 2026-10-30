// 一键启动开发环境：MySQL(food_db) + Spring Boot 后端(8081) + Vite 前端(5173)
// 数据统一走 MySQL food_db（springBootTest），不再使用 Node JSON 后端
import { spawn } from 'node:child_process'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const SPRING_DIR = path.resolve(__dirname, '../springBootTest')

const children = []

function run(name, command, args, options, color) {
  const child = spawn(command, args, {
    shell: true,
    ...options,
    env: { ...process.env, FORCE_COLOR: '1' },
    stdio: ['ignore', 'pipe', 'pipe']
  })
  const tag = `\x1b[${color}m[${name}]\x1b[0m`
  const pipe = (stream) => {
    stream.setEncoding('utf-8')
    stream.on('data', (data) => {
      data.split(/\r?\n/).filter(Boolean).forEach((line) => console.log(tag, line))
    })
  }
  pipe(child.stdout)
  pipe(child.stderr)
  child.on('exit', (code) => {
    if (code !== null) console.log(tag, `进程退出，退出码 ${code}`)
  })
  children.push(child)
  return child
}

console.log('启动后端 (Spring Boot, http://localhost:8081, 数据库 MySQL food_db) ...')
// Windows 下用 mvnw.cmd；其他平台可改用 ./mvnw
// 命令行显式指定 8081，防止配置文件被意外覆盖导致端口漂移；-Dfile.encoding 修正中文日志乱码
run('server', 'mvnw.cmd',
    ['spring-boot:run', '-DskipTests',
     '-Dspring-boot.run.jvmArguments=-Dfile.encoding=UTF-8',
     '-Dspring-boot.run.arguments=--server.port=8081'],
    { cwd: SPRING_DIR }, '36') // 青色

console.log('启动前端 (Vite,   http://localhost:5173) ...')
run('web', 'npx', ['vite'], {}, '35') // 品红

function shutdown() {
  children.forEach((c) => {
    try { c.kill() } catch { /* ignore */ }
  })
  process.exit(0)
}
process.on('SIGINT', shutdown)
process.on('SIGTERM', shutdown)
