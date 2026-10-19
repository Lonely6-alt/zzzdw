# AI-NOTES.md（给 AI 看的项目备忘，读完再动手，不要重复踩坑）

> 这台电脑每次开机会重置桌面目录（本文件的桌面副本可能被还原，D 盘副本是主版本）。
> 如果你是开机后的新会话：先读这份备忘，优先双击 `启动项目.bat`，不要手工重复排查。

## 项目结构（本目录 = 项目根）

- `springBootTest\` — Spring Boot 3.4.5 完整后端（Java 17+，本机 JDK 21 可跑）
  - 功能：MyBatis-Plus + MySQL(food_db) + JWT + BCrypt + Hutool 图片验证码
  - 接口：`/api/captcha?id=xx`(PNG)、`/api/register`、`/api/login`、`/api/me`、`/api/posts`
  - 端口：**8081**（dev profile）
- `food-login-vue\` — Vue3 + Vite 前端
  - 端口：**5173**（被占会自动 5174）
  - `server\index.js` — Express 模拟后端（端口 **3000**，JSON 文件存储，有 `/api/captcha/send` 短信码模拟）
  - 前端 vite.config.js 默认代理 `/api` → **3000**（Express）；如要接 Spring Boot 改成 **8081**

## 快速启动（优先用脚本）

根目录下有 GBK 编码的 `启动项目.bat` / `停止项目.bat`，直接双击即可，不要手工重复下面的步骤。

手工启动顺序（脚本已封装）：
1. 清环境变量：`set SERVER__PORT=` 和 `set SERVER_PORT=`（**关键坑**：本机 IDE 会注入 `SERVER__PORT=55712`，Spring Boot 宽松绑定会把它当 server.port 覆盖配置文件，且该端口被 IDE 占用 → 启动必失败。命令行显式传 `--server.port=8081` 也可解决）
2. MySQL 8.0（`C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe`，root/123456）应已开机自启；food_db 库重置后仍在。若缺表则导入：
   `mysql -uroot -p123456 --default-character-set=utf8mb4 food_db < springBootTest\sql\food_db.sql`
   （**必须带 --default-character-set=utf8mb4**，否则中文报 ERROR 1366）
3. 前端若无 node_modules：先 `npm install`（在 food-login-vue 目录）
4. 后端：`springBootTest` 目录 `mvnw.cmd spring-boot:run -Dspring-boot.run.arguments=--server.port=8081`
5. Express 模拟后端（可选）：`food-login-vue` 目录 `node server\index.js`
6. 前端：`food-login-vue` 目录 `npm run dev`

## 已知坑（不要再去排查，直接看答案）

- **SERVER__PORT 环境变量**：见上第 1 条。在 IDE（IntelliJ/WorkBuddy）里启动必踩，独立 cmd 窗口没有此变量。
- **devtools 双进程**：spring-boot:run 带 devtools 会 fork 两个 java 进程（Maven 主进程 + 应用进程），停止时要杀两个；按端口找 PID 再 taskkill /F 最稳。
- **SQL 导入中文报错**：必须 `--default-character-set=utf8mb4`。
- **5173 被占**：vite 会自动换 5174，不是错误。
- **D:\workSpace\springBootTest 是旧版**（桌面曾有 `springBootTest.lnk` 指向它）：只有 Hello World，无数据库/JWT/验证码。除非用户明确要求，**不要启动它**。
- **后端 CaptchaController 会打印验证码答案到日志**（联调用），生产环境应删除。
- 本机杀 Windows 进程（Git Bash 里）：`MSYS2_ARG_CONV_EXCL="*" taskkill /F /PID <pid>`；wmic 被安全策略禁用；cmd.exe 在 WorkBuddy 沙箱里被拦截，bat 只能由用户双击运行。

## 数据库

- 库：`food_db`；表：`user`(id/username/password_hash/created_at)、`post`(帖子，含分类/emoji)
- user 表**没有 phone 字段**，后端 DTO 也没有，不要在代码里加回手机号。

## 备份与重置

- 本目录的持久备份在 `D:\workSpace\zzzdw-main`（不含 node_modules/dist，可用 `npm install` / `npm run build` 重新生成）。
- 桌面被重置后，把 D 盘备份整个复制回桌面即可恢复（脚本、本备忘都在里面）。

## 维护记录

- 2026-10-10：首次搭建启动环境；曾实现前端图片验证码对接（被系统重置还原，如需重做：改 AuthPanel.vue 加验证码图+输入框、useAuth.js 传 captchaId/captchaCode、vite.config.js 代理改 8081）。当前前端快照为短信验证码版本（sendCode，配套 Express mock :3000）。
