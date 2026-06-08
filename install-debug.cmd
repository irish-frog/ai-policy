@echo off
setlocal
set "BASE=C:\ProgramData\AI Warning"
if not exist "%BASE%" mkdir "%BASE%"
set "LOG=%BASE%\install.log"
echo Running installer. Log: %LOG%
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo.
echo Exit code: %ERRORLEVEL%
echo.
echo Last log output:
type "%LOG%"
echo.
pause
