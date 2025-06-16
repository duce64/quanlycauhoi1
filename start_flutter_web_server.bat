@echo off
color 0A
title Flutter Web Server

:MENU
cls
echo ========================================
echo     FLUTTER WEB SERVER MANAGER
echo ========================================
echo.
echo [1] Bat dau chay server Flutter Web
echo [2] Thoat
echo.
set /p choice=Nhap lua chon (1-2): 

if "%choice%"=="1" goto START
if "%choice%"=="2" exit
goto MENU

:START
echo.
echo ===============================
echo Dang khoi dong Flutter Web server...
echo ===============================
cd /d "%~dp0build\web"
http-server -p 8080 --host 0.0.0.0
pause
goto MENU
