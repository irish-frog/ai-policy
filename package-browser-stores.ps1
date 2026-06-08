param(
    [string]$OutputDir = (Join-Path $PSScriptRoot 'dist\store-submissions')
)

$ErrorActionPreference = 'Stop'

function New-ZipFromDirectory($SourceDir, $OutputPath) {
    if (-not (Test-Path (Join-Path $SourceDir 'manifest.json'))) {
        throw "manifest.json was not found in $SourceDir"
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $OutputPath) | Out-Null
    Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue
    Compress-Archive -Path (Join-Path $SourceDir '*') -DestinationPath $OutputPath -Force
    Write-Host "Created $OutputPath"
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$ChromiumSource = Join-Path $PSScriptRoot 'extension'
$FirefoxSource = Join-Path $PSScriptRoot 'firefox'

New-ZipFromDirectory $ChromiumSource (Join-Path $OutputDir 'ai-warning-chrome-web-store.zip')
New-ZipFromDirectory $ChromiumSource (Join-Path $OutputDir 'ai-warning-edge-addons.zip')
New-ZipFromDirectory $FirefoxSource (Join-Path $OutputDir 'ai-warning-firefox-unsigned-source.zip')

Write-Host ''
Write-Host 'Next steps:'
Write-Host '  Chrome: upload ai-warning-chrome-web-store.zip as an unlisted Chrome Web Store extension.'
Write-Host '  Edge:   upload ai-warning-edge-addons.zip to Microsoft Edge Add-ons with controlled visibility.'
Write-Host '  Firefox: use sign-firefox.ps1 for Mozilla unlisted signing; do not deploy the unsigned source zip.'
