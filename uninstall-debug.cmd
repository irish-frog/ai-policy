@echo off
setlocal
set "BASE=C:\ProgramData\AI Warning"
if not exist "%BASE%" mkdir "%BASE%"
set "LOG=%BASE%\uninstall.log"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
echo.
echo Exit code: %ERRORLEVEL%
echo.
type "%LOG%"
echo.
pause
