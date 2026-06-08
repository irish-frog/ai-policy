AI Warning Banner - Policy Deployment Package

Install silently in N-central/SolarWinds:
  install.cmd

Uninstall silently:
  uninstall.cmd

For local troubleshooting, run:
  install-debug.cmd

Logs:
  C:\ProgramData\AI Warning\install.log
  C:\ProgramData\AI Warning\uninstall.log

Installed package copy:
  C:\ProgramData\AI Warning\source

Browser policy setup:
  1. Publish or self-host the Chrome/Edge extension so it has a stable extension ID and update URL.
     - Chrome Web Store update URL:
       https://clients2.google.com/service/update2/crx
     - Microsoft Edge Add-ons update URL:
       https://edge.microsoft.com/extensionwebstorebase/v1/crx
  2. Package/sign the Firefox extension as an XPI and host it at a stable HTTPS URL, such as a GitHub Release asset.
  3. Copy policy-config.example.json to policy-config.json.
  4. Replace the extension IDs and URLs in policy-config.json.
  5. Deploy install.cmd as administrator.

What install.cmd writes:
  - Chrome:
    HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist
  - Edge:
    HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist
  - Firefox:
    C:\Program Files\Mozilla Firefox\distribution\policies.json

GitHub pull-and-install option:
  Host this package in GitHub, then run this from an elevated PowerShell prompt or RMM task:

  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File install-from-github.ps1

  The default repository is:
    irish-frog/ai-policy

  To specify it explicitly:

  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File install-from-github.ps1 -Repository "irish-frog/ai-policy" -Branch "main"

  Or with a direct GitHub ZIP URL:

  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File install-from-github.ps1 -RepositoryZipUrl "https://github.com/irish-frog/ai-policy/archive/refs/heads/main.zip"

For a fully remote bootstrap, host install-from-github.ps1 in a trusted location and call it with the GitHub ZIP URL for this package.

  Example one-liner:

  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/irish-frog/ai-policy/main/install-from-github.ps1' -OutFile \"$env:TEMP\install-from-github.ps1\"; & \"$env:TEMP\install-from-github.ps1\""

Notes:
  - Browsers must be fully closed and reopened after install.
  - Chrome and Edge policy force-install requires a published or self-hosted signed extension. Copying an unpacked extension folder locally is not dependable for enterprise force install.
  - Firefox policy force-install should use a signed XPI hosted at a stable URL.
  - The installer preserves existing Chrome/Edge numbered force-install values and adds the AI warning extension in the next free slot.
  - If Firefox already has policies.json, the installer backs it up once to policies.ai-warning.backup.json and merges the AI warning entry.
