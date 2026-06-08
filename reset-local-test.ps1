param(
    [string]$InstallRoot = 'C:\ProgramData\AI Warning',
    [string]$InstallerUrl = 'https://github.com/irish-frog/ai-policy/raw/main/dist/installer/AI-Warning-Policy-Installer.exe'
)

$ErrorActionPreference = 'Stop'

$ResolvedProgramData = [System.IO.Path]::GetFullPath($env:ProgramData)
$ResolvedInstallRoot = [System.IO.Path]::GetFullPath($InstallRoot)
if (-not $ResolvedInstallRoot.StartsWith($ResolvedProgramData, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing to remove path outside ProgramData: $ResolvedInstallRoot"
}

$InstallerPath = Join-Path $env:TEMP 'AI-Warning-Policy-Installer-fresh.exe'
$CacheBustedUrl = "${InstallerUrl}?cachebust=$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"

Write-Host "Stopping browsers..."
Stop-Process -Name firefox,msedge,chrome -Force -ErrorAction SilentlyContinue

Write-Host "Running existing uninstall if present..."
$UninstallCmd = Join-Path $InstallRoot 'source\uninstall.cmd'
if (Test-Path $UninstallCmd) {
    & $UninstallCmd
}

Write-Host "Removing install root: $InstallRoot"
Remove-Item -LiteralPath $InstallRoot -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Downloading latest installer..."
Remove-Item -LiteralPath $InstallerPath -Force -ErrorAction SilentlyContinue
Invoke-WebRequest -Uri $CacheBustedUrl -OutFile $InstallerPath

Write-Host "Downloaded installer:"
Get-Item $InstallerPath | Select-Object FullName, Length, LastWriteTime

Write-Host "Running fresh installer..."
$Process = Start-Process -FilePath $InstallerPath -Wait -PassThru
$ExitCode = $Process.ExitCode
Write-Host "Installer exit code: $ExitCode"

$InstallLog = Join-Path $InstallRoot 'install.log'
if (Test-Path $InstallLog) {
    Write-Host "Install log tail:"
    Get-Content $InstallLog -Tail 120
} else {
    Write-Host "Install log not found at $InstallLog"
}

exit $ExitCode
