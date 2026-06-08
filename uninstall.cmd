@echo off
setlocal
set "BASE=C:\ProgramData\AI Warning"
if not exist "%BASE%" mkdir "%BASE%"
set "LOG=%BASE%\uninstall.log"
echo AI Warning uninstall started: %date% %time% > "%LOG%"
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" >> "%LOG%" 2>&1
exit /b %ERRORLEVEL%
