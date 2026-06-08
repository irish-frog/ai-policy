param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'policy-config.json')
)

$ErrorActionPreference = 'Stop'
$Base = 'C:\ProgramData\AI Warning'
$Log = Join-Path $Base 'install.log'
function Log($m) { Add-Content -Path $Log -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] $m" }

function ToHashtable($InputObject) {
    if ($null -eq $InputObject) { return $null }
    if ($InputObject -is [System.Collections.IDictionary]) {
        $hash = @{}
        foreach ($key in $InputObject.Keys) { $hash[$key] = ToHashtable $InputObject[$key] }
        return $hash
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
        $items = @()
        foreach ($item in $InputObject) { $items += ,(ToHashtable $item) }
        return $items
    }
    if ($InputObject.PSObject.Properties.Name.Count -gt 0 -and $InputObject -isnot [string]) {
        $hash = @{}
        foreach ($property in $InputObject.PSObject.Properties) { $hash[$property.Name] = ToHashtable $property.Value }
        return $hash
    }
    return $InputObject
}

function ReadConfig {
    $default = @{
        BannerText = 'COMPANY POLICY: DO NOT SHARE CONFIDENTIAL INFORMATION WITH AI TOOLS'
    }

    if (Test-Path $ConfigPath) {
        Log "Loading policy config from $ConfigPath"
        $loaded = ToHashtable (Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json)
        foreach ($key in $loaded.Keys) { $default[$key] = $loaded[$key] }
    } else {
        Log "No policy-config.json found at $ConfigPath; browser force-install policies will use available local defaults"
    }

    return $default
}

function GetFirefoxExtensionId($ExtensionPath) {
    $ManifestPath = Join-Path $ExtensionPath 'manifest.json'
    if (-not (Test-Path $ManifestPath)) { return $null }

    $Manifest = Get-Content -Raw -Path $ManifestPath | ConvertFrom-Json
    return $Manifest.browser_specific_settings.gecko.id
}

function NewLocalFirefoxXpi($ExtensionPath, $OutputPath) {
    if (-not (Test-Path (Join-Path $ExtensionPath 'manifest.json'))) {
        Log 'Firefox XPI build skipped; manifest.json not found'
        return $null
    }

    $TempZip = [System.IO.Path]::ChangeExtension($OutputPath, '.zip')
    Remove-Item -Path $TempZip -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $OutputPath -Force -ErrorAction SilentlyContinue
    Compress-Archive -Path (Join-Path $ExtensionPath '*') -DestinationPath $TempZip -Force
    Move-Item -Path $TempZip -Destination $OutputPath -Force
    Log "Local Firefox XPI created at $OutputPath"
    return $OutputPath
}

function CopyBundledFirefoxXpi($OutputPath) {
    $Candidates = @(
        (Join-Path $PSScriptRoot 'signed\firefox\ai-warning-firefox.xpi'),
        (Join-Path $PSScriptRoot 'dist\firefox\ai-warning-firefox.xpi')
    )

    foreach ($Candidate in $Candidates) {
        if (Test-Path $Candidate) {
            Copy-Item -Path $Candidate -Destination $OutputPath -Force
            Log "Bundled signed Firefox XPI copied from $Candidate to $OutputPath"
            return $OutputPath
        }
    }

    $LatestDistXpi = Get-ChildItem -Path (Join-Path $PSScriptRoot 'dist\firefox') -Filter '*.xpi' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if ($LatestDistXpi) {
        Copy-Item -Path $LatestDistXpi.FullName -Destination $OutputPath -Force
        Log "Bundled signed Firefox XPI copied from $($LatestDistXpi.FullName) to $OutputPath"
        return $OutputPath
    }

    return $null
}

function ConvertPathToFileUrl($Path) {
    return ([System.Uri]$Path).AbsoluteUri
}

function SetBrowserForcelistPolicy($PolicyPath, $ExtensionId, $UpdateUrl, $BrowserName) {
    if ([string]::IsNullOrWhiteSpace($ExtensionId) -or [string]::IsNullOrWhiteSpace($UpdateUrl)) {
        Log "$BrowserName force-install policy skipped; missing extension ID or update URL"
        return
    }

    New-Item -Path $PolicyPath -Force | Out-Null
    $Value = "$ExtensionId;$UpdateUrl"
    $Existing = Get-ItemProperty -Path $PolicyPath
    $PolicyValues = @($Existing.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' })
    $TargetName = ($PolicyValues | Where-Object { $_.Value -like "$ExtensionId;*" } | Select-Object -First 1).Name
    if ([string]::IsNullOrWhiteSpace($TargetName)) {
        $Used = @($PolicyValues | ForEach-Object { [int]$_.Name })
        $Next = 1
        while ($Used -contains $Next) { $Next++ }
        $TargetName = [string]$Next
    }

    New-ItemProperty -Path $PolicyPath -Name $TargetName -Value $Value -PropertyType String -Force | Out-Null
    Log "$BrowserName ExtensionInstallForcelist policy value $TargetName written for $ExtensionId"
}

function SetFirefoxPolicy($ExtensionId, $InstallUrl) {
    if ([string]::IsNullOrWhiteSpace($ExtensionId) -or [string]::IsNullOrWhiteSpace($InstallUrl)) {
        Log 'Firefox force-install policy skipped; missing extension ID or install URL'
        return
    }

    $RegistryPolicyPath = 'HKLM:\SOFTWARE\Policies\Mozilla\Firefox'
    New-Item -Path $RegistryPolicyPath -Force | Out-Null

    $RegistrySettings = @{}
    $ExistingRegistrySettings = (Get-ItemProperty -Path $RegistryPolicyPath -Name 'ExtensionSettings' -ErrorAction SilentlyContinue).ExtensionSettings
    if (-not [string]::IsNullOrWhiteSpace($ExistingRegistrySettings)) {
        try {
            $RegistrySettings = ToHashtable ($ExistingRegistrySettings -join "`n" | ConvertFrom-Json)
        } catch {
            Log 'Existing Firefox registry ExtensionSettings could not be parsed; replacing with AI Warning policy'
            $RegistrySettings = @{}
        }
    }

    $RegistrySettings[$ExtensionId] = @{
        installation_mode = 'force_installed'
        install_url = $InstallUrl
    }

    $RegistryJson = $RegistrySettings | ConvertTo-Json -Depth 20 -Compress
    New-ItemProperty -Path $RegistryPolicyPath -Name 'ExtensionSettings' -Value ([string[]]@($RegistryJson)) -PropertyType MultiString -Force | Out-Null
    Log "Firefox registry ExtensionSettings policy written for $ExtensionId"

    $FirefoxRoots = @(
        'C:\Program Files\Mozilla Firefox',
        'C:\Program Files (x86)\Mozilla Firefox'
    ) | Where-Object { Test-Path (Join-Path $_ 'firefox.exe') }

    if ($FirefoxRoots.Count -eq 0) {
        Log 'Firefox executable not found under Program Files or Program Files (x86); registry policy was still written'
        return
    }

    foreach ($FirefoxRoot in $FirefoxRoots) {
        $FirefoxDist = Join-Path $FirefoxRoot 'distribution'
        New-Item -ItemType Directory -Force -Path $FirefoxDist | Out-Null
        $PolicyPath = Join-Path $FirefoxDist 'policies.json'
        if ((Test-Path $PolicyPath) -and -not (Test-Path (Join-Path $FirefoxDist 'policies.ai-warning.backup.json'))) {
            Copy-Item -Path $PolicyPath -Destination (Join-Path $FirefoxDist 'policies.ai-warning.backup.json') -Force
            Log "Existing Firefox policies.json backed up under $FirefoxDist"
        }

        $Policy = @{ policies = @{} }
        if (Test-Path $PolicyPath) {
            $Policy = ToHashtable (Get-Content -Raw -Path $PolicyPath | ConvertFrom-Json)
            if (-not $Policy.ContainsKey('policies')) { $Policy['policies'] = @{} }
        }
        if (-not $Policy['policies'].ContainsKey('ExtensionSettings')) { $Policy['policies']['ExtensionSettings'] = @{} }

        $Policy['policies']['ExtensionSettings'][$ExtensionId] = @{
            installation_mode = 'force_installed'
            install_url = $InstallUrl
        }

        Set-Content -Path $PolicyPath -Value ($Policy | ConvertTo-Json -Depth 20) -Encoding UTF8
        Log "Firefox policies.json ExtensionSettings policy written for $ExtensionId at $PolicyPath"
    }
}

try {
    New-Item -ItemType Directory -Force -Path $Base | Out-Null
    $Config = ReadConfig

    Log 'Creating extension directories'
    $ChromeExt = Join-Path $Base 'chrome-edge-extension'
    $FirefoxExt = Join-Path $Base 'firefox-extension'
    New-Item -ItemType Directory -Force -Path $ChromeExt, $FirefoxExt | Out-Null

    Log 'Copying extension files'
    Copy-Item -Path (Join-Path $PSScriptRoot 'extension\*') -Destination $ChromeExt -Recurse -Force
    Copy-Item -Path (Join-Path $PSScriptRoot 'firefox\*') -Destination $FirefoxExt -Recurse -Force

    if ([string]::IsNullOrWhiteSpace($Config.FirefoxExtensionId)) {
        $Config.FirefoxExtensionId = GetFirefoxExtensionId $FirefoxExt
        if (-not [string]::IsNullOrWhiteSpace($Config.FirefoxExtensionId)) {
            Log "Firefox extension ID discovered from manifest: $($Config.FirefoxExtensionId)"
        }
    }

    if ([string]::IsNullOrWhiteSpace($Config.FirefoxInstallUrl)) {
        $LocalFirefoxXpi = CopyBundledFirefoxXpi (Join-Path $Base 'ai-warning-firefox.xpi')
        if ([string]::IsNullOrWhiteSpace($LocalFirefoxXpi)) {
            $LocalFirefoxXpi = NewLocalFirefoxXpi $FirefoxExt (Join-Path $Base 'ai-warning-firefox.xpi')
            Log 'Normal Firefox releases require this generated XPI to be signed before permanent policy install succeeds'
        }
        if (-not [string]::IsNullOrWhiteSpace($LocalFirefoxXpi)) {
            $Config.FirefoxInstallUrl = ConvertPathToFileUrl $LocalFirefoxXpi
            Log "Firefox install URL defaulted to local XPI: $($Config.FirefoxInstallUrl)"
        }
    }

    Log 'Writing AI Warning audit/reference policy markers'
    New-Item -Path 'HKLM:\SOFTWARE\Policies\AI Warning' -Force | Out-Null
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\AI Warning' -Name 'InstallPath' -Value $Base -PropertyType String -Force | Out-Null
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\AI Warning' -Name 'BannerText' -Value $Config.BannerText -PropertyType String -Force | Out-Null

    Log 'Chrome, Edge, and Firefox enterprise policy deployment'
    SetBrowserForcelistPolicy 'HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist' $Config.ChromeExtensionId $Config.ChromeUpdateUrl 'Chrome'
    SetBrowserForcelistPolicy 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist' $Config.EdgeExtensionId $Config.EdgeUpdateUrl 'Edge'
    SetFirefoxPolicy $Config.FirefoxExtensionId $Config.FirefoxInstallUrl

    Log 'Install completed. Browsers must be restarted.'
    exit 0
}
catch {
    Log "ERROR: $($_.Exception.Message)"
    Log "STACK: $($_.ScriptStackTrace)"
    exit 1
}
