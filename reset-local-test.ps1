param(
    [string]$InstallRoot = 'C:\ProgramData\AI Warning',
    [string]$InstallerScriptUrl = 'https://raw.githubusercontent.com/irish-frog/ai-policy/main/install-from-github.ps1'
)

$ErrorActionPreference = 'Stop'

$ResolvedProgramData = [System.IO.Path]::GetFullPath($env:ProgramData)
$ResolvedInstallRoot = [System.IO.Path]::GetFullPath($InstallRoot)
if (-not $ResolvedInstallRoot.StartsWith($ResolvedProgramData, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove path outside ProgramData: $ResolvedInstallRoot"
}

$InstallerScriptPath = Join-Path $env:TEMP 'install-from-github-fresh.ps1'
$CacheBustedUrl = "${InstallerScriptUrl}?cachebust=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"

Write-Host "Stopping browsers..."
Stop-Process -Name firefox,msedge,chrome -Force -ErrorAction SilentlyContinue

Write-Host "Running existing uninstall if present..."
$UninstallCmd = Join-Path $InstallRoot 'source\uninstall.cmd'
if (Test-Path $UninstallCmd) {
    & $UninstallCmd
}

Write-Host "Removing install root: $InstallRoot"
Remove-Item -LiteralPath $InstallRoot -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Downloading latest GitHub installer script..."
Remove-Item -LiteralPath $InstallerScriptPath -Force -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri $CacheBustedUrl -OutFile $InstallerScriptPath

Write-Host "Downloaded installer script:"
Get-Item $InstallerScriptPath | Select-Object FullName, Length, LastWriteTime

Write-Host "Running fresh GitHub install..."
& powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File $InstallerScriptPath
$ExitCode = $LASTEXITCODE
Write-Host "Installer exit code: $ExitCode"

$InstallLog = Join-Path $InstallRoot 'install.log'
if (Test-Path $InstallLog) {
    Write-Host "Install log tail:"
    Get-Content $InstallLog -Tail 120
} else {
    Write-Host "Install log not found at $InstallLog"
}

exit $ExitCode
