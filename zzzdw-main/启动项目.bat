@echo off
setlocal
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

REM [1] 检查 MySQL 的 food_db 库
set "MYSQL=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
echo [1/5] 检查数据库 food_db ...
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

REM [2] 前端依赖
echo [2/5] 检查前端依赖 node_modules ...
if not exist "%~dp0food-login-vue\node_modules" (
    echo       首次运行，执行 npm install（可能需要几分钟）...
    pushd "%~dp0food-login-vue"
    call npm install
    popd
) else (
    echo       已存在，跳过
)

REM [3] 启动 Spring Boot 后端（新窗口，端口 8081，数据走 MySQL food_db）
echo [3/5] 启动 Spring Boot 后端  端口 8081 ...
pushd "%~dp0springBootTest"
start "美食-后端8081" cmd /k "set SERVER__PORT= && set SERVER_PORT= && mvnw.cmd spring-boot:run -Dspring-boot.run.jvmArguments=-Dfile.encoding=UTF-8 -Dspring-boot.run.arguments=--server.port=8081"
popd

REM [4] 启动 Vue 前端（新窗口，端口 5173，/api 代理到 8081）
echo [4/5] 启动 Vue 前端  端口 5173 ...
pushd "%~dp0food-login-vue"
start "美食-前端5173" cmd /k "npx vite"
popd

echo.
echo ==========================================
echo   全部启动完成！
echo   前端页面:     http://localhost:5173
echo   后台管理:     http://localhost:5173/admin  (admin / admin123)
echo   Spring Boot:  http://localhost:8081
echo   数据库:       MySQL food_db (localhost:3306)
echo   旧 Express(3000) 已废弃，不再启动
echo   关闭项目请双击  停止项目.bat
echo ==========================================
pause
