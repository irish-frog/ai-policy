param(
    [string]$OutputDir = (Join-Path $PSScriptRoot 'dist\installer'),
    [string]$InstallerName = 'AI-Warning-Policy-Installer.exe'
)

$ErrorActionPreference = 'Stop'

$IExpress = Join-Path $env:WINDIR 'System32\iexpress.exe'
if (-not (Test-Path $IExpress)) {
    throw 'iexpress.exe was not found. This build script requires Windows IExpress.'
}

$PackageFiles = @(
    'README.txt',
    'install.cmd',
    'install.ps1',
    'install-debug.cmd',
    'uninstall.cmd',
    'uninstall.ps1',
    'uninstall-debug.cmd',
    'install-from-github.ps1',
    'policy-config.example.json',
    'sign-firefox.ps1'
)

$PackageDirs = @(
    'extension',
    'firefox',
    'signed'
)

$BuildRoot = Join-Path $OutputDir 'build'
$PayloadRoot = Join-Path $BuildRoot 'payload'
$IExpressRoot = Join-Path $BuildRoot 'iexpress'
$SedPath = Join-Path $BuildRoot 'ai-warning-installer.sed'
$OutputExe = Join-Path $OutputDir $InstallerName
$PayloadZip = Join-Path $IExpressRoot 'payload.zip'
$Launcher = Join-Path $IExpressRoot 'run-installer.cmd'

Remove-Item -Path $BuildRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $PayloadRoot, $IExpressRoot, $OutputDir | Out-Null

foreach ($File in $PackageFiles) {
    $Source = Join-Path $PSScriptRoot $File
    if (Test-Path $Source) {
        Copy-Item -Path $Source -Destination $PayloadRoot -Force
    }
}

foreach ($Dir in $PackageDirs) {
    $Source = Join-Path $PSScriptRoot $Dir
    if (Test-Path $Source) {
        Copy-Item -Path $Source -Destination (Join-Path $PayloadRoot $Dir) -Recurse -Force
    }
}

Compress-Archive -Path (Join-Path $PayloadRoot '*') -DestinationPath $PayloadZip -Force

Set-Content -Path $Launcher -Encoding ASCII -Value @'
@echo off
setlocal
set "WORK=%TEMP%\AI-Warning-Policy-Installer-%RANDOM%%RANDOM%"
mkdir "%WORK%" >nul 2>&1
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%~dp0payload.zip' -DestinationPath '%WORK%' -Force"
if errorlevel 1 exit /b %ERRORLEVEL%
call "%WORK%\install.cmd"
set "RC=%ERRORLEVEL%"
exit /b %RC%
'@

$Sed = @"
[Version]
Class=IEXPRESS
SEDVersion=3

[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=1
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=AI Warning policy installer completed.
TargetName=$OutputExe
FriendlyName=AI Warning Policy Installer
AppLaunched=run-installer.cmd
PostInstallCmd=<None>
AdminQuietInstCmd=run-installer.cmd
UserQuietInstCmd=run-installer.cmd
SourceFiles=SourceFiles

[Strings]
InstallProgram=run-installer.cmd
FILE0=run-installer.cmd
FILE1=payload.zip

[SourceFiles]
SourceFiles0=$IExpressRoot

[SourceFiles0]
%FILE0%=
%FILE1%=
"@

Set-Content -Path $SedPath -Value $Sed -Encoding ASCII
& $IExpress /N $SedPath

if (-not (Test-Path $OutputExe)) {
    throw "Installer was not created at $OutputExe"
}

Write-Host "Created installer: $OutputExe"
