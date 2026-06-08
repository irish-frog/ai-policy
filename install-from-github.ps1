param(
    [string]$RepositoryZipUrl,

    [string]$Repository = 'irish-frog/ai-policy',

    [string]$Branch = 'main',

    [string]$ProgramDataPath = 'C:\ProgramData\AI Warning'
)

$ErrorActionPreference = 'Stop'

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script from an elevated PowerShell prompt or as an admin deployment task.'
}

if ([string]::IsNullOrWhiteSpace($RepositoryZipUrl)) {
    if ([string]::IsNullOrWhiteSpace($Repository)) {
        throw 'Provide either -RepositoryZipUrl or -Repository, for example -Repository "irish-frog/ai-policy".'
    }
    $RepositoryZipUrl = "https://github.com/$Repository/archive/refs/heads/$Branch.zip"
}

$WorkingPath = Join-Path $ProgramDataPath 'github-install'
$SourcePath = Join-Path $ProgramDataPath 'source'
$ZipPath = Join-Path $WorkingPath 'ai-warning.zip'
$ExtractPath = Join-Path $WorkingPath 'package'

New-Item -ItemType Directory -Force -Path $ProgramDataPath, $WorkingPath | Out-Null
Remove-Item -Path $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path $SourcePath -Recurse -Force -ErrorAction SilentlyContinue

Invoke-WebRequest -Uri $RepositoryZipUrl -OutFile $ZipPath
Expand-Archive -Path $ZipPath -DestinationPath $ExtractPath -Force

$InstallCmd = Get-ChildItem -Path $ExtractPath -Recurse -Filter 'install.cmd' | Select-Object -First 1
if (-not $InstallCmd) {
    throw 'Downloaded package did not contain install.cmd.'
}

$PackageRoot = Split-Path -Parent $InstallCmd.FullName
Copy-Item -Path $PackageRoot -Destination $SourcePath -Recurse -Force

& (Join-Path $SourcePath 'install.cmd')
exit $LASTEXITCODE
