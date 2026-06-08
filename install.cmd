@echo off
setlocal
set "BASE=C:\ProgramData\AI Warning"
if not exist "%BASE%" mkdir "%BASE%"
set "LOG=%BASE%\install.log"
echo ================================================== > "%LOG%"
echo AI Warning install started: %date% %time% >> "%LOG%"
echo Running as: %USERNAME% >> "%LOG%"
echo Script path: %~dp0 >> "%LOG%"

powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0install.ps1"
set "RC=%ERRORLEVEL%"
echo Install finished with exit code %RC%: %date% %time% >> "%LOG%"
exit /b %RC%
