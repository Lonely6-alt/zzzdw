@echo off
setlocal
chcp 936 >nul
title 美食社区-一键停止
cd /d "%~dp0"

echo 正在停止项目进程（按端口 8081 / 5173 / 5174）...

for %%P in (8081 5173 5174) do (
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr "LISTENING" ^| findstr ":%%P "') do (
        echo   停止端口 %%P  进程 PID=%%a
        taskkill /F /T /PID %%a >nul 2>nul
    )
)

REM 关掉残留的启动窗口
for %%T in ("美食-后端8081" "美食-前端5173") do (
    taskkill /F /FI "WINDOWTITLE eq %%~T*" >nul 2>nul
)

echo.
echo 已停止。MySQL 服务未动（其他项目也在用）。
echo 说明：旧 Express 后端(3000)已废弃，不再纳入停止范围。
pause
