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
- **5173 被占 / "拒绝连接"**：Vite 默认端口被占会自动换 5174，导致浏览器打 localhost:5173 报"拒绝连接"（这是反复出现的那个问题）。根因有二：① 上次没用 停止项目.bat 干净退出，残留进程占着 5173；② 旧 启动项目.bat 用 `start` 异步启动后**立刻**打印"全部启动完成"，用户火速点开浏览器时 Vite 还没 bind 端口，Chrome 缓存了拒绝连接页。现已修复：bat 启动时先按端口杀掉 8081/5173/5174 残留进程 + 用 `vite --strictPort`（端口被占直接报错不再漂移）+ 等端口真正 LISTENING 后再自动开浏览器。
- **手动排查顺序**：若还打不开，先 `停止项目.bat` 清残留 → 双击 `启动项目.bat` 等它自动开浏览器；还不行就看"美食-前端5173"/"美食-后端8081"两个窗口里的报错。
- **D:\workSpace\springBootTest 是旧版**（桌面曾有 `springBootTest.lnk` 指向它）：只有 Hello World，无数据库/JWT/验证码。除非用户明确要求，**不要启动它**。
- **后端 CaptchaController 会打印验证码答案到日志**（联调用），生产环境应删除。
- 本机杀 Windows 进程（Git Bash 里）：`MSYS2_ARG_CONV_EXCL="*" taskkill /F /PID <pid>`；wmic 被安全策略禁用；cmd.exe 在 WorkBuddy 沙箱里被拦截，bat 只能由用户双击运行。
- **Maven 启动后端**：本机 Maven 发行包在 Git Bash 下直接跑 `./mvnw`（shell 脚本）会报 `找不到或无法加载主类 org.codehaus.plexus.classworlds.launcher.Launcher`（classworlds 加载失败，是 shell 脚本在 Git Bash 下的已知坑）。**正确做法**：用 `mvnw.cmd`（Windows 批处理启动器），或指向缓存里的完整 Maven：`C:\Users\Administrator\.m2\wrapper\dists\apache-maven-3.9.9\*\apache-maven-3.9.9\bin\mvn.cmd`。`启动项目.bat` 用的就是 `mvnw.cmd`，双击即可，不要在 Git Bash 里手敲 `./mvnw`。
- **后端 8081 迟迟起不来 / 启动脚本等待超时（2026-11-04 根治，2026-11-09 复发后又加固）**：根因是 Maven 依赖每次开机都重新下载——① 项目自带的 `apache-maven-3.9.9\boot\` 缺 `plexus-classworlds-2.8.0.jar` 等 89 个文件（只剩 license，表现为 `Error: -classpath requires class path specification`）；② C 盘 `~/.m2/repository` 依赖残缺。**为什么会复发**：仓库忽略 `*.jar`，所以"复制/还原项目目录"会让自带的 Maven 再次变成无 jar 残缺版。**修复（2026-11-09 起脚本已能自愈，不要再手动修）**：`启动项目.bat` 检测到 `boot\*.jar` 缺失会自动从 `%USERPROFILE%\.m2\wrapper\dists` 补齐，并在开窗口前用 `call mvn -v` 自检（失败立即报错退出，不再空等）；依赖仓库固定在 `D:\workSpace\m2-repository`（778MB 完整，settings.xml 已固化 + 阿里云镜像），后端以 `-o -Dmaven.repo.local=...` 离线启动（实测 6 秒起）。若以后**新增依赖**导致离线构建失败：临时去掉 `-o` 跑一次让它下载进 D 盘仓库即可。另注意：批处理里调用另一个 .cmd 必须加 `call`，否则控制权移交、后续代码不执行。

## 数据库

- **位置**：本机 MySQL 8.0 服务，`localhost:3306`，库名 `food_db`，账号 `root / 123456`
  - 连接配置：`springBootTest/src/main/resources/application.properties`（jdbc:mysql://localhost:3306/food_db）
  - 物理文件：`C:\ProgramData\MySQL\MySQL Server 8.0\Data\food_db\*.ibd`
  - 图形化：Navicat 里连 `localhost` 看 `food_db` 库即可（截图里连接名 `user@food_db_test` 只是连接标签，库就是 food_db）
- 表：`user`(id/username/password_hash/role/status/created_at)、`post`、`category`、`tag`、`review`、`favorite`、`food_order`
- **建库脚本（唯一数据源）**：`springBootTest/sql/food_db.sql` —— 现在已是**含全部数据的完整 dump**（Navicat 导出）：表结构 + 默认账号（admin/admin123、test/123456）+ 12 篇演示帖子（含 `district` 商圈、`price` 人均、2 篇 featured）+ 分类 + 标签 + 点评。一条 `mysql ... < food_db.sql` 即可完整还原，无需再跑单独的 seed 脚本。（早期备忘里的 seed_users.sql / seed_demo.sql 已合并进此 dump，磁盘上不再单独存在；启动脚本里对它们的引用会静默失败，不影响运行。）
  - 导入必须带 `--default-character-set=utf8mb4`（中文否则报错）。
- **post 表关键字段**：`id,title,category,category_id,author,emoji,content,rating,review_count,favorite_count,order_count,price,featured,status,district,created_at`。`district`(商圈) 是本次新增字段（后端 Post 实体 + 库表 + 本 dump 均已含）；前端卡片与筛选栏依赖它。
- 想清空演示数据：`DELETE FROM review; DELETE FROM post; DELETE FROM category; DELETE FROM tag;`（然后重导 food_db.sql 恢复）
  - 叶子分类名必须与 `food-login-vue/src/data/categories.js` 的 8 个名字完全一致（面食控/日料局/汉堡炸鸡/轻食沙拉/甜品时间/咖啡馆/烧烤夜宵/火锅江湖），否则图标和色卡会退回默认值。
- user 表**没有 phone 字段**，后端 DTO 也没有，不要在代码里加回手机号。

## 备份与重置

- 本目录的持久备份在 `D:\workSpace\zzzdw-main`（不含 node_modules/dist，可用 `npm install` / `npm run build` 重新生成）。
- 桌面被重置后，把 D 盘备份整个复制回桌面即可恢复（脚本、本备忘都在里面）。

## 维护记录

- 2026-10-10：首次搭建启动环境；曾实现前端图片验证码对接（被系统重置还原，如需重做：改 AuthPanel.vue 加验证码图+输入框、useAuth.js 传 captchaId/captchaCode、vite.config.js 代理改 8081）。当前前端快照为短信验证码版本（sendCode，配套 Express mock :3000）。
- 2026-11-02（上午）：前端首页大改版，6 项需求全部落地：
  1. **统一导航栏**：删掉 `HomeView.vue` 内重复的 `<nav class="navbar">`，统一用 `App.vue` 的全局顶栏（品牌/首页/发现/美食地图/排行榜/我的 + 仅管理员可见的「后台管理」入口，`isAdmin` 控制，非管理员不显示且无权限入口）。
  2. **橙色 Banner 重构**：突出搜索框（更大、居中聚焦），首屏内不再放统计四宫格；统计移到页面底部「平台数据概览」区（移出首屏）。
  3. **顶部筛选栏**：排序（最新/人气/好评）+ 商圈筛选（全部 + 8 个商圈 chips），按 `district` 过滤。
  4. **美食卡片重写**：大图封面（emoji+渐变放大）+ 评分(星+分) + 商圈(📍) + 人均(¥price)。
  5. **hover 动效 + 点赞/收藏反馈**：卡片上浮阴影、封面缩放；收藏星标切换带 toast（已加成功提示）；新增「点赞」前端乐观交互（❤️ + toast + 弹跳动画）。
  6. **更多跳转 + 分页 + 响应式**：列表客户端分页（每页 6 条，页码+上/下页）+「查看更多美食 →」跳 `/discover`；栅格 3/2/1 列、筛选栏换行、Hero 堆叠。
  - 后端配合：给 `Post` 实体与 `post` 表新增 `district`(商圈) 字段（ALERT 加列 + 12 条演示数据回填商圈 + `food_db.sql` 完整 dump 同步）。前端 `postDistrict()` 对缺失 district 有按 id 派生兜底。
  - 验证：生产构建零错误；`/api/posts` 返回 50 条且均含 district；登录 admin 取 token → `/api/me` 200。
- 2026-11-02（中午）：美食帖子由 12 条扩充到 50 条。用 `springBootTest/sql/gen_posts.py` 生成 38 条真实风格中文美食帖（覆盖 8 个叶子分类与 8 个商圈，rating/收藏数/点单数/人均/日期按规律生成），插入 live DB `food_db.post`，并重跑 `mysqldump` 把 `food_db.sql` 同步为含 50 条数据的完整 dump（已验证可重导临时库得到 50 条）。前端 `stats.posts` 由 `posts.length` 驱动，首页「平台数据概览」自动显示 50 篇美食笔记，分页每页 6 条共 9 页。
- 2026-11-04：根治"启动脚本等后端 8081 超时、Maven 反复下载依赖"问题：
  1. 发现项目自带 `apache-maven-3.9.9` 残缺（boot 目录缺 classworlds jar 等 89 个文件），从 `~/.m2/wrapper/dists` 的完整发行版 robocopy 补齐（保留已改的 conf\settings.xml）。
  2. 新建 D 盘持久仓库 `D:\workSpace\m2-repository`（旧 C 盘仓库 758MB robocopy 迁入 + `dependency:go-offline` 预热 + 离线 compile 验证通过）。
  3. `启动项目.bat`（GBK）后端命令改为自带 mvn.cmd + `-Dmaven.repo.local=D:\workSpace\m2-repository -o`；等待 8081 由 120 秒放宽到 600 秒。`food-login-vue\start-dev.js` 同步修改。
  4. 自带 Maven `conf\settings.xml` 与 C 盘 `~/.m2/settings.xml` 均固化 D 盘仓库；conf 里另加阿里云镜像。
  5. 实测：离线 `spring-boot:run` 约 5 秒绑定 8081，`/api/posts` 返回 200。
- 2026-11-09：**同一个坑复发 + 加固**。现象：一键启动卡在"等待后端 8081 就绪"，后端窗口报 `Error: -classpath requires class path specification`，前端 Vite 代理 `/api/chat/unread`、`/api/chat/sessions` 报 ECONNREFUSED 127.0.0.1:8081。根因：项目内 `apache-maven-3.9.9` 又变成 0 个 jar（`boot/` 只剩 .license，`lib/` 23 个文件全是 license）；另外 `D:\workSpace\m2-repository` 也不存在了，脚本又丢了 `-o` 参数，导致依赖被重新下载。修复：
  1. 从 `~/.m2/wrapper/dists/apache-maven-3.9.9/3477a4f1` 补齐 49 个 jar；`D:\workSpace\m2-repository` 由 C 盘 776MB 仓库合并重建为 778MB。
  2. `启动项目.bat` 新增 **Maven 自愈**（缺 jar 自动 xcopy 补齐）+ **多级兜底**（项目内 → 本机 dists → mvnw.cmd → PATH）+ **启动自检**（`call mvn -v` 失败即报错退出），并补回 `-o -Dmaven.repo.local=D:\workSpace\m2-repository`。
  3. `[1.5]~[1.8]` 里对 `upgrade_v2/seed_users/seed_posts_200/upgrade_v3/seed_shop_chat` 的引用改为"文件存在才执行"，不再每次刷假 `[警告] 写入失败`（磁盘上确实只有 `food_db.sql`）。
  4. 等待后端时间 600s→180s，失败时直接列出三种常见原因。
  - 验证：一键启动全流程跑通（自检通过 → 5173 就绪 → 8081 就绪）；离线 `spring-boot:run` 2.9 秒完成、6 秒可访问；`/api/chat/unread`、`/api/chat/sessions`、`/api/friends`、`/api/me` 经代理全部 200。
- 2026-11-27：积分好礼改为**后端为准**（原为纯 localStorage 演示）：
  - 数据库：`user` 新增 `points`（默认 120）；新建 `reward`（10 种好礼目录）与 `user_reward`（兑换记录，含兑换码/分类/说明快照）。迁移脚本 `springBootTest/sql/growth_rewards.sql`；`food_db.sql` 已由 `mysqldump` 重新导出同步。
  - 后端新增 `GrowthController` / `GrowthService`：
    - `GET /api/growth/me`：当前积分 + 已兑好礼
    - `POST /api/growth/points`：行为积分上报（`{delta,reason}`，单次上限 1000）
    - `GET /api/rewards`：可兑换好礼目录
    - `GET /api/rewards/mine`：已兑好礼
    - `POST /api/rewards/exchange`：`{rewardId}`，事务内原子扣积分/扣库存/写兑换记录，积分不足返回 400
  - `UserVO` 增加 `points` 字段；`/api/me` 也返回积分。
  - 前端 `useGrowth.js` 改为先调后端同步积分/目录/已兑好礼；点赞/收藏/评价/发笔记/任务领取都上报 `/api/growth/points`；兑换走 `/api/rewards/exchange`。localStorage 仅作缓存与后端不可用时的兜底，不再作为积分真相源。
  - 验证：后端离线 `mvnw.cmd -o -Dmaven.repo.local=C:/Users/Administrator/.m2/repository compile` 通过；前端 `npm run build` 通过；浏览器实测本地积分 999 被后端 110 覆盖、点击兑换后变 60 且已兑列表新增奖品，数据库 `user.points` 与 `user_reward` 同步落库；测试数据已清理，`test` 账号恢复 120 分。
  - 注意：本机 `D:\workSpace\m2-repository` 再次不完整（缺 Spring Boot parent POM），本次编译临时使用 `C:\Users\Administrator\.m2\repository`；启动脚本若再遇到离线构建失败，按 2026-11-09 的自愈流程补齐 D 盘仓库。
