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

$PreviousNpmLogLevel = $env:npm_config_loglevel
$env:npm_config_loglevel = 'error'

$ToolRoot = Join-Path $PSScriptRoot '.tools\web-ext'
$WebExtCmd = Join-Path $ToolRoot 'node_modules\.bin\web-ext.cmd'

if (-not (Test-Path $WebExtCmd)) {
    New-Item -ItemType Directory -Force -Path $ToolRoot | Out-Null
    npm install --prefix $ToolRoot --no-audit --no-fund --loglevel=error web-ext
    if ($LASTEXITCODE -ne 0) {
        throw "Installing web-ext failed with exit code $LASTEXITCODE"
    }
}

& $WebExtCmd sign `
    --source-dir $SourceDir `
    --artifacts-dir $ArtifactsDir `
    --channel unlisted `
    --api-key $env:AMO_JWT_ISSUER `
    --api-secret $env:AMO_JWT_SECRET

if (-not [string]::IsNullOrWhiteSpace($PreviousNpmLogLevel)) {
    $env:npm_config_loglevel = $PreviousNpmLogLevel
} else {
    Remove-Item Env:\npm_config_loglevel -ErrorAction SilentlyContinue
}

if ($LASTEXITCODE -ne 0) {
    throw "Firefox signing failed with exit code $LASTEXITCODE"
}

Write-Host ''
Write-Host "Signed Firefox XPI output:"
Get-ChildItem -Path $ArtifactsDir -Filter '*.xpi' | Sort-Object LastWriteTime -Descending | Select-Object -First 5 FullName, Length, LastWriteTime
