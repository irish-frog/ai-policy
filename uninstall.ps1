$ErrorActionPreference = 'Continue'
$Base = 'C:\ProgramData\AI Warning'
$Log = Join-Path $Base 'uninstall.log'
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
    $ConfigPath = Join-Path $PSScriptRoot 'policy-config.json'
    if (Test-Path $ConfigPath) {
        return ToHashtable (Get-Content -Raw -Path $ConfigPath | ConvertFrom-Json)
    }
    return @{}
}

function RemoveBrowserForcelistPolicy($PolicyPath, $ExtensionId, $BrowserName) {
    if ([string]::IsNullOrWhiteSpace($ExtensionId) -or -not (Test-Path $PolicyPath)) { return }

    $Existing = Get-ItemProperty -Path $PolicyPath
    $Existing.PSObject.Properties |
        Where-Object { $_.Name -match '^\d+$' -and $_.Value -like "$ExtensionId;*" } |
        ForEach-Object {
            Remove-ItemProperty -Path $PolicyPath -Name $_.Name -Force -ErrorAction SilentlyContinue
            Log "Removed $BrowserName ExtensionInstallForcelist value $($_.Name)"
        }
}

function RemoveFirefoxPolicy($ExtensionId) {
    if ([string]::IsNullOrWhiteSpace($ExtensionId)) { return }

    $FirefoxPolicy = 'C:\Program Files\Mozilla Firefox\distribution\policies.json'
    if (-not (Test-Path $FirefoxPolicy)) { return }

    $Policy = ToHashtable (Get-Content -Raw -Path $FirefoxPolicy | ConvertFrom-Json)
    if ($Policy.ContainsKey('policies') -and
        $Policy['policies'].ContainsKey('ExtensionSettings') -and
        $Policy['policies']['ExtensionSettings'].ContainsKey($ExtensionId)) {
        $Policy['policies']['ExtensionSettings'].Remove($ExtensionId)
        Set-Content -Path $FirefoxPolicy -Value ($Policy | ConvertTo-Json -Depth 20) -Encoding UTF8
        Log "Removed Firefox ExtensionSettings entry for $ExtensionId"
    }
}

Log 'Removing AI Warning files and policy markers'
$Config = ReadConfig
RemoveBrowserForcelistPolicy 'HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist' $Config.ChromeExtensionId 'Chrome'
RemoveBrowserForcelistPolicy 'HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist' $Config.EdgeExtensionId 'Edge'
RemoveFirefoxPolicy $Config.FirefoxExtensionId

Remove-Item -Path 'HKLM:\SOFTWARE\Policies\AI Warning' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'HKLM:\SOFTWARE\Policies\AI-Warning' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'C:\ProgramData\Google\Chrome\Extensions\aiwarningbanner' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'C:\ProgramData\Microsoft\Edge\Extensions\aiwarningbanner' -Recurse -Force -ErrorAction SilentlyContinue

Remove-Item -Path $Base -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'C:\ProgramData\AI-Warning' -Recurse -Force -ErrorAction SilentlyContinue
exit 0
