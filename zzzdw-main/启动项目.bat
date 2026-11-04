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
"%MYSQL%" -uroot -p123456 -e "USE food_db; SELECT 1 FROM tag LIMIT 1;" >nul 2>nul
if errorlevel 1 (
    echo       应用升级脚本 sql\upgrade_v2.sql（tag 表等）...
    "%MYSQL%" -uroot -p123456 --default-character-set=utf8mb4 < "%~dp0springBootTest\sql\upgrade_v2.sql" 2>nul
    echo       升级完成
) else (
    echo       表结构已是最新，跳过升级
)

REM [1.6] 默认账号：food_db.sql 只有表结构没有数据，空库不补账号就登录不了后台（幂等，不覆盖已改密码）
echo [1.6] 检查默认账号 admin/admin123 、 test/123456 ...
"%MYSQL%" -uroot -p123456 --default-character-set=utf8mb4 food_db < "%~dp0springBootTest\sql\seed_users.sql" >nul 2>nul
if errorlevel 1 ( echo       [警告] 默认账号写入失败，请检查 MySQL 是否启动 ) else ( echo       默认账号就绪 )

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
echo [3/6] 启动 Spring Boot 后端  端口 8081 ...
pushd "%~dp0springBootTest"
start "美食-后端8081" cmd /k "set SERVER__PORT= && set SERVER_PORT= && set JAVA_HOME= && %~dp0apache-maven-3.9.9\bin\mvn.cmd -Dmaven.repo.local=D:\workSpace\m2-repository -o spring-boot:run -Dspring-boot.run.jvmArguments=-Dfile.encoding=UTF-8 -Dspring-boot.run.arguments=--server.port=8081"
popd

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
echo [6/6] 等待后端 8081 端口就绪（最多 600 秒，若在补下载 Maven 依赖会较慢）...
set "API_OK=0"
for /l %%i in (1,1,600) do (
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
    echo   [警告] 后端 8081 在 600 秒内未就绪！请看 "美食-后端8081" 窗口里的红色报错并截图反馈
)
echo   数据库:       MySQL food_db ^(localhost:3306^)
echo   关闭项目请双击  停止项目.bat
echo ==========================================
echo.
echo 提示：本窗口可以关掉，但"前端/后端"两个子窗口要一直开着。
pause
