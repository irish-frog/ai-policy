param(
    [string]$SourceDir = (Join-Path $PSScriptRoot 'firefox'),
    [string]$ArtifactsDir = (Join-Path $PSScriptRoot 'dist\firefox')
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($env:AMO_JWT_ISSUER) -or [string]::IsNullOrWhiteSpace($env:AMO_JWT_SECRET)) {
    throw 'Set AMO_JWT_ISSUER and AMO_JWT_SECRET first. Create them at https://addons.mozilla.org/developers/addon/api/key/'
}

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    throw 'npm is required. Install Node.js, then rerun this script.'
}

New-Item -ItemType Directory -Force -Path $ArtifactsDir | Out-Null

npx --yes web-ext sign `
    --source-dir $SourceDir `
    --artifacts-dir $ArtifactsDir `
    --channel unlisted `
    --api-key $env:AMO_JWT_ISSUER `
    --api-secret $env:AMO_JWT_SECRET

Write-Host ''
Write-Host "Signed Firefox XPI output:"
Get-ChildItem -Path $ArtifactsDir -Filter '*.xpi' | Sort-Object LastWriteTime -Descending | Select-Object -First 5 FullName, Length, LastWriteTime
