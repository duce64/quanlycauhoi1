@echo off
echo Đang khởi động Flutter Web server...
cd /d "%~dp0build\web"
http-server -p 8080 --host 0.0.0.0
pause
