@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
title 美食社区-一键启动
cd /d "%~dp0"

echo ==========================================
echo   美食社区 一键启动（数据统一走 MySQL food_db）
echo ==========================================
echo.

REM [0] 清掉 IDE 注入的端口环境变量，避免覆盖 Spring Boot 端口（关键！）
set "SERVER__PORT="
set "SERVER_PORT="

REM [0.5] 清理上次残留进程：否则 5173 被占时 Vite 会漂到 5174，浏览器打 5173 就是"拒绝连接"
echo [0/6] 清理上次残留的 8081 / 5173 / 5174 端口进程 ...
for %%P in (8081 5173 5174) do (
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr "LISTENING" ^| findstr ":%%P "') do (
        echo       释放端口 %%P  PID=%%a
        taskkill /F /T /PID %%a >nul 2>nul
    )
)

REM [1] 检查 MySQL 的 food_db 库
set "MYSQL=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
echo [1/6] 检查数据库 food_db ...
"%MYSQL%" -uroot -p123456 --default-character-set=utf8mb4 -e "USE food_db; SELECT 1 FROM user LIMIT 1;" >nul 2>nul
if errorlevel 1 (
    echo       food_db 缺表，正在导入 springBootTest\sql\food_db.sql ...
    "%MYSQL%" -uroot -p123456 -e "CREATE DATABASE IF NOT EXISTS food_db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" >nul 2>nul
    "%MYSQL%" -uroot -p123456 --default-character-set=utf8mb4 food_db < "%~dp0springBootTest\sql\food_db.sql" 2>nul
    if errorlevel 1 ( echo       [警告] 导入失败，请确认 MySQL 服务已启动 ) else ( echo       导入完成 )
) else (
    echo       food_db 正常，跳过导入
)

REM [1.5] 应用结构升级脚本（幂等，已应用则无变化）
REM 说明：仓库里只保留了 sql\food_db.sql（含完整结构与示例数据），
REM       以下增量脚本若不存在就跳过，不再刷"[警告] 写入失败"的假错误。
if not exist "%~dp0springBootTest\sql\upgrade_v2.sql" goto :skip_v2
"%MYSQL%" -uroot -p123456 -e "USE food_db; SELECT 1 FROM tag LIMIT 1;" >nul 2>nul
if errorlevel 1 (
    echo       应用升级脚本 sql\upgrade_v2.sql（tag 表等）...
    "%MYSQL%" -uroot -p123456 --default-character-set=utf8mb4 < "%~dp0springBootTest\sql\upgrade_v2.sql" 2>nul
    echo       升级完成
) else (
    echo       表结构已是最新，跳过升级
)
:skip_v2

REM [1.6] 默认账号（若提供 seed_users.sql 才执行；food_db.sql 已自带示例账号）
if not exist "%~dp0springBootTest\sql\seed_users.sql" goto :skip_seed_users
echo [1.6] 检查默认账号 admin/admin123 、 test/123456 ...
"%MYSQL%" -uroot -p123456 --default-character-set=utf8mb4 food_db < "%~dp0springBootTest\sql\seed_users.sql" >nul 2>nul
if errorlevel 1 ( echo       [警告] 默认账号写入失败，请检查 MySQL 是否启动 ) else ( echo       默认账号就绪 )
:skip_seed_users

REM [1.7] 美食数据（若提供 seed_posts_200.sql 才执行）
if not exist "%~dp0springBootTest\sql\seed_posts_200.sql" goto :skip_seed_posts
echo [1.7] 检查美食数据（目标 200 道）...
"%MYSQL%" -uroot -p123456 --default-character-set=utf8mb4 food_db < "%~dp0springBootTest\sql\seed_posts_200.sql" >nul 2>nul
if errorlevel 1 ( echo       [警告] 美食数据写入失败，请检查 MySQL 是否启动 ) else ( echo       美食数据就绪 )
:skip_seed_posts

REM [1.8] 店铺信息 + 群聊（若提供 upgrade_v3.sql / seed_shop_chat.sql 才执行）
if not exist "%~dp0springBootTest\sql\upgrade_v3.sql" goto :skip_shops
echo [1.8] 检查店铺与群聊数据表 ...
"%MYSQL%" -uroot -p123456 --default-character-set=utf8mb4 < "%~dp0springBootTest\sql\upgrade_v3.sql" >nul 2>nul
if exist "%~dp0springBootTest\sql\seed_shop_chat.sql" (
    "%MYSQL%" -uroot -p123456 --default-character-set=utf8mb4 food_db < "%~dp0springBootTest\sql\seed_shop_chat.sql" >nul 2>nul
    if errorlevel 1 ( echo       [警告] 店铺/群聊数据写入失败，请检查 MySQL 是否启动 ) else ( echo       店铺与群聊数据就绪 )
)
:skip_shops

REM [2] 前端依赖
echo [2/6] 检查前端依赖 node_modules ...
if not exist "%~dp0food-login-vue\node_modules" (
    echo       首次运行，执行 npm install（可能需要几分钟）...
    pushd "%~dp0food-login-vue"
    call npm install
    popd
) else (
    echo       已存在，跳过
)

REM [3] 启动 Spring Boot 后端（新窗口，端口 8081，数据走 MySQL food_db）
REM JDK 兜底链：优先项目内 runtime\jdk-21（D盘，重启不丢） -> IDEA 自带 JBR -> C盘 Zulu
echo [3/6] 启动 Spring Boot 后端  端口 8081 ...
set "JDK_HOME="
if exist "%~dp0runtime\jdk-21\bin\javac.exe" set "JDK_HOME=%~dp0runtime\jdk-21"
if not defined JDK_HOME if exist "D:\IntelliJ IDEA 2024.3.2.2\jbr\bin\javac.exe" set "JDK_HOME=D:\IntelliJ IDEA 2024.3.2.2\jbr"
if not defined JDK_HOME if exist "C:\Program Files\Zulu\zulu-21\bin\javac.exe" set "JDK_HOME=C:\Program Files\Zulu\zulu-21"
if not defined JDK_HOME ( echo       [错误] 找不到任何 JDK！请确认 %~dp0runtime\jdk-21 存在 & pause & exit /b 1 )
echo       使用 JDK: %JDK_HOME%

REM [3.1] Maven 自愈 + 兜底
REM 常见坑：apache-maven-3.9.9 目录被拷成"只剩 license 没有 jar"，mvn 会报
REM   Error: -classpath requires class path specification
REM 这里先从本机 wrapper 缓存自动补齐 jar，补不齐再改用其他 Maven。
set "MVN_DIR=%~dp0apache-maven-3.9.9"
if not exist "%MVN_DIR%\boot\*.jar" (
    echo       [修复] 项目内 Maven 缺少 jar，尝试从本机缓存自动补齐 ...
    for /d %%D in ("%USERPROFILE%\.m2\wrapper\dists\apache-maven-3.9.9\*") do (
        if exist "%%D\boot\*.jar" (
            xcopy "%%D\boot" "%MVN_DIR%\boot\" /E /Y /I >nul 2>nul
            xcopy "%%D\lib"  "%MVN_DIR%\lib\"  /E /Y /I >nul 2>nul
            xcopy "%%D\conf" "%MVN_DIR%\conf\" /E /Y /I >nul 2>nul
            echo       已从 %%D 补齐
        )
    )
)

set "MVN_CMD="
if exist "%MVN_DIR%\boot\*.jar" if exist "%MVN_DIR%\bin\mvn.cmd" set "MVN_CMD=%MVN_DIR%\bin\mvn.cmd"
if not defined MVN_CMD (
    for /d %%D in ("%USERPROFILE%\.m2\wrapper\dists\apache-maven-3.9.9\*") do (
        if exist "%%D\boot\*.jar" set "MVN_CMD=%%D\bin\mvn.cmd"
    )
)
if not defined MVN_CMD if exist "%~dp0springBootTest\mvnw.cmd" set "MVN_CMD=%~dp0springBootTest\mvnw.cmd"
if not defined MVN_CMD (
    where mvn >nul 2>nul && set "MVN_CMD=mvn"
)
if not defined MVN_CMD (
    echo       [错误] 找不到可用的 Maven。
    echo              请把完整的 apache-maven-3.9.9（含 boot\plexus-classworlds-*.jar 与 lib\*.jar）放回项目根目录，
    echo              或联网后运行 springBootTest\mvnw.cmd 让它自动下载。
    pause
    exit /b 1
)
echo       使用 Maven: %MVN_CMD%

REM [3.2] 启动前自检：Maven 真能跑起来再开窗口，避免后面空等 10 分钟
REM 注意：调用 .cmd 必须加 call，否则控制权移交、后面的代码不会执行
call "%MVN_CMD%" -v >nul 2>nul
if errorlevel 1 (
    echo       [错误] Maven 无法运行（多为发行包缺 jar）。错误窗口里通常显示：
    echo              Error: -classpath requires class path specification
    echo              请检查 %MVN_DIR%\boot 下是否存在 plexus-classworlds-*.jar
    pause
    exit /b 1
)
echo       Maven 自检通过

REM [3.3] 依赖仓库：优先 D 盘持久仓库 + 离线模式（避免每次开机重下依赖，机房没网也能起）
REM 若以后新增了依赖导致离线构建失败，临时双击命令行去掉 -o 跑一次即可（详见 AI-NOTES.md 已知坑）
set "MVN_REPO=-o -Dmaven.repo.local=D:\workSpace\m2-repository"
if not exist "D:\workSpace\m2-repository" (
    set "MVN_REPO="
    echo       [提示] 未找到 D:\workSpace\m2-repository，本次使用默认仓库（可能较慢）
) else (
    echo       依赖仓库: D:\workSpace\m2-repository（离线模式）
)

pushd "%~dp0springBootTest"
start "美食-后端8081" cmd /k "set SERVER__PORT= && set SERVER_PORT= && set "JAVA_HOME=%JDK_HOME%" && %MVN_CMD% %MVN_REPO% spring-boot:run -Dspring-boot.run.jvmArguments=-Dfile.encoding=UTF-8 -Dspring-boot.run.arguments=--server.port=8081"
popd

REM [3.5] Node 兜底：机房电脑 PATH 可能被重置，把 D 盘 nodejs 目录补进 PATH
set "PATH=D:\Program Files\nodejs;%PATH%"
where node >nul 2>nul || ( echo [警告] 找不到 node，前端可能起不来，请检查 D:\Program Files\nodejs )

REM [4] 启动 Vue 前端（新窗口，端口锁定 5173，/api 代理到 8081）
echo [4/6] 启动 Vue 前端  端口 5173 ...
pushd "%~dp0food-login-vue"
start "美食-前端5173" cmd /k "npx vite --port 5173 --strictPort"
popd

REM [5] 等前端端口真正监听（Vite 冷启动要几秒，之前"启动完就喊完成"导致浏览器报拒绝连接）
echo [5/6] 等待前端 5173 端口就绪（最多 90 秒）...
set "WEB_OK=0"
for /l %%i in (1,1,90) do (
    if "!WEB_OK!"=="0" (
        netstat -ano | findstr "LISTENING" | findstr ":5173 " >nul 2>nul
        if not errorlevel 1 set "WEB_OK=1"
        if "!WEB_OK!"=="0" (
            >nul ping -n 2 127.0.0.1
            set /p "=." <nul
        )
    )
)
echo.

REM [6] 等后端 8081 起来（否则页面能开但登录/帖子接口 500）
echo [6/6] 等待后端 8081 端口就绪（最多 180 秒；首次编译/下载依赖会慢一些）...
set "API_OK=0"
for /l %%i in (1,1,180) do (
    if "!API_OK!"=="0" (
        netstat -ano | findstr "LISTENING" | findstr ":8081 " >nul 2>nul && set "API_OK=1"
        if "!API_OK!"=="0" (
            >nul ping -n 2 127.0.0.1
            set /p "=." <nul
        )
    )
)
echo.

echo ==========================================
if "!WEB_OK!"=="1" (
    echo   前端已就绪，正在打开浏览器 ...
    start "" "http://localhost:5173"
    echo   前端页面:     http://localhost:5173
    echo   后台管理:     http://localhost:5173/admin   ^(admin / admin123^)
) else (
    echo   [警告] 前端 90 秒内没起来！请看 "美食-前端5173" 窗口里的红色报错
)
if "!API_OK!"=="1" (
    echo   后端接口:     http://localhost:8081  已就绪
) else (
    echo   [警告] 后端 8081 在 180 秒内未就绪！请先看 "美食-后端8081" 窗口里的报错，常见原因：
    echo          1^) Maven 报 "-classpath requires class path specification"  ^-^> apache-maven-3.9.9 缺 jar
    echo          2^) 报 "Port 8081 was already in use"                      ^-^> 先双击 停止项目.bat 再启动
    echo          3^) 报 "Access denied for user 'root'"                     ^-^> 检查 MySQL 服务与密码
)
echo   数据库:       MySQL food_db ^(localhost:3306^)
echo   关闭项目请双击  停止项目.bat
echo ==========================================
echo.
echo 提示：本窗口可以关掉，但"前端/后端"两个子窗口要一直开着。
pause
