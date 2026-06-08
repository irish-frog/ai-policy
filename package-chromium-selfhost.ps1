param(
    [string]$BrowserExe,
    [string]$ExtensionDir = (Join-Path $PSScriptRoot 'extension'),
    [string]$OutputDir = (Join-Path $PSScriptRoot 'dist\self-hosted\chromium'),
    [string]$PrivateKeyPath = (Join-Path $PSScriptRoot 'keys\ai-warning-chromium.pem'),
    [string]$ExtensionId,
    [string]$CrxUrl
)

$ErrorActionPreference = 'Stop'

function Find-BrowserPackager {
    $Candidates = @(
        'C:\Program Files\Google\Chrome\Application\chrome.exe',
        'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe',
        'C:\Program Files\Microsoft\Edge\Application\msedge.exe',
        'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
    )

    foreach ($Candidate in $Candidates) {
        if (Test-Path $Candidate) { return $Candidate }
    }

    return $null
}

if ([string]::IsNullOrWhiteSpace($BrowserExe)) {
    $BrowserExe = Find-BrowserPackager
}

if ([string]::IsNullOrWhiteSpace($BrowserExe) -or -not (Test-Path $BrowserExe)) {
    throw 'Chrome or Edge executable was not found. Pass -BrowserExe with the full path to chrome.exe or msedge.exe.'
}

if (-not (Test-Path (Join-Path $ExtensionDir 'manifest.json'))) {
    throw "manifest.json was not found in $ExtensionDir"
}

New-Item -ItemType Directory -Force -Path $OutputDir, (Split-Path -Parent $PrivateKeyPath) | Out-Null

$ExtensionFullPath = [System.IO.Path]::GetFullPath($ExtensionDir)
$PrivateKeyFullPath = [System.IO.Path]::GetFullPath($PrivateKeyPath)
$OutputCrx = Join-Path (Split-Path -Parent $ExtensionFullPath) ((Split-Path -Leaf $ExtensionFullPath) + '.crx')
$OutputPem = Join-Path (Split-Path -Parent $ExtensionFullPath) ((Split-Path -Leaf $ExtensionFullPath) + '.pem')

$PackArgs = @("--pack-extension=$ExtensionFullPath")
if (Test-Path $PrivateKeyFullPath) {
    $PackArgs += "--pack-extension-key=$PrivateKeyFullPath"
}

Write-Host "Packing extension with:"
Write-Host "  $BrowserExe"
Write-Host ''

& $BrowserExe $PackArgs
if ($LASTEXITCODE -ne 0) {
    throw "Browser pack command failed with exit code $LASTEXITCODE"
}

$FinalCrx = Join-Path $OutputDir 'ai-warning.crx'
$FinalPem = Join-Path $OutputDir 'ai-warning.pem'

if (-not (Test-Path $OutputCrx)) {
    throw "Expected CRX was not created at $OutputCrx"
}

Move-Item -Path $OutputCrx -Destination $FinalCrx -Force

if ((Test-Path $OutputPem) -and -not (Test-Path $PrivateKeyFullPath)) {
    Move-Item -Path $OutputPem -Destination $PrivateKeyFullPath -Force
}

if (Test-Path $PrivateKeyFullPath) {
    Copy-Item -Path $PrivateKeyFullPath -Destination $FinalPem -Force
}

Write-Host "Created CRX:"
Get-Item $FinalCrx | Select-Object FullName, Length, LastWriteTime
Write-Host ''
Write-Host "Private key:"
Get-Item $PrivateKeyFullPath | Select-Object FullName, Length, LastWriteTime

if (-not [string]::IsNullOrWhiteSpace($ExtensionId) -and -not [string]::IsNullOrWhiteSpace($CrxUrl)) {
    $ManifestVersion = (Get-Content -Raw -Path (Join-Path $ExtensionDir 'manifest.json') | ConvertFrom-Json).version
    $UpdateXmlPath = Join-Path $OutputDir 'update.xml'
    $UpdateXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<gupdate xmlns="http://www.google.com/update2/response" protocol="2.0">
  <app appid="$ExtensionId">
    <updatecheck codebase="$CrxUrl" version="$ManifestVersion" />
  </app>
</gupdate>
"@
    Set-Content -Path $UpdateXmlPath -Value $UpdateXml -Encoding UTF8
    Write-Host ''
    Write-Host "Created update manifest:"
    Get-Item $UpdateXmlPath | Select-Object FullName, Length, LastWriteTime
} else {
    Write-Host ''
    Write-Host 'Next: install ai-warning.crx once in Edge/Chrome to get the extension ID, then rerun this script with:'
    Write-Host '  -ExtensionId "your-extension-id" -CrxUrl "https://yourdomain.com/ai-warning/ai-warning.crx"'
}
