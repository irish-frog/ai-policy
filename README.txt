AI Warning Banner - Policy Deployment Package

Install silently in N-central/SolarWinds:
  install.cmd

Build a Windows installer EXE:
  .\build-installer.ps1

Installer output:
  dist\installer\AI-Warning-Policy-Installer.exe

Run installer silently as administrator:
  AI-Warning-Policy-Installer.exe /Q

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
  Chrome and Edge default:
    The installer includes the it-inyanga self-hosted Chrome/Edge policy by default:
      gghjldfblicajaepdoijgiijknkmoakn;https://it-inyanga.co.za/ai-warning/update.xml

    This means Chrome and Edge can be installed without policy-config.json.

  1. Build browser submission packages:

     .\package-browser-stores.ps1

     Outputs:
       dist\store-submissions\ai-warning-chrome-web-store.zip
       dist\store-submissions\ai-warning-edge-addons.zip
       dist\store-submissions\ai-warning-firefox-unsigned-source.zip

  2. Publish/sign as unlisted or controlled distribution:
     - Chrome: upload ai-warning-chrome-web-store.zip to Chrome Web Store as unlisted.
     - Edge: upload ai-warning-edge-addons.zip to Microsoft Edge Add-ons with controlled visibility.
     - Firefox: use sign-firefox.ps1 for Mozilla unlisted signing.

  3. Chrome/Edge will provide stable extension IDs after publishing.
     - Chrome Web Store update URL:
       https://clients2.google.com/service/update2/crx
     - Microsoft Edge Add-ons update URL:
       https://edge.microsoft.com/extensionwebstorebase/v1/crx

  4. Copy policy-config.example.json to policy-config.json.
  5. Replace the Chrome and Edge extension IDs in policy-config.json.
  6. Put the signed Firefox XPI at:

     signed\firefox\ai-warning-firefox.xpi

  7. Commit and push policy-config.json if you want GitHub installs to include the IDs, or copy policy-config.json to endpoints separately if you do not want config in the repo.
  8. Deploy install.cmd, the GitHub one-liner, or the Windows installer as administrator.

Automatic local Firefox attempt:
  If policy-config.json is missing, install.ps1 first looks for a bundled signed XPI:
    signed\firefox\ai-warning-firefox.xpi

  If that file exists, it copies it to:
    C:\ProgramData\AI Warning\ai-warning-firefox.xpi

  If no bundled signed XPI exists, install.ps1 builds an unsigned fallback:
    C:\ProgramData\AI Warning\ai-warning-firefox.xpi

  It then writes Firefox ExtensionSettings using the extension ID from firefox\manifest.json and a local file:/// install URL.
  Normal Firefox releases require the XPI to be signed before it will permanently install.

Signing Firefox XPI:
  1. Create a Mozilla Add-ons API key:
     https://addons.mozilla.org/developers/addon/api/key/
  2. In elevated PowerShell, set the signing credentials:

     $env:AMO_JWT_ISSUER = "your-api-key"
     $env:AMO_JWT_SECRET = "your-api-secret"

  3. Run:

     .\sign-firefox.ps1

  4. Copy the signed .xpi from dist\firefox to:

     signed\firefox\ai-warning-firefox.xpi

  5. Commit and push signed\firefox\ai-warning-firefox.xpi to GitHub.

  6. Endpoints can keep using the same one-line GitHub installer. They do not need Mozilla credentials, Node.js, or signing tools.

Chrome and Edge unlisted publishing:
  1. Run:

     .\package-browser-stores.ps1

  2. Chrome:
     Upload dist\store-submissions\ai-warning-chrome-web-store.zip to the Chrome Web Store developer dashboard.
     Choose unlisted visibility if you do not want it searchable.
     Put the resulting extension ID in policy-config.json as ChromeExtensionId.

  3. Edge:
     Upload dist\store-submissions\ai-warning-edge-addons.zip to Microsoft Partner Center / Edge Add-ons.
     Choose controlled/private/unlisted-style visibility where available.
     Put the resulting extension ID in policy-config.json as EdgeExtensionId.

  4. Re-run the installer. It writes both force-install policies.

Chrome and Edge self-hosted CRX:
  1. Build a self-signed CRX:

     .\package-chromium-selfhost.ps1

  2. Keep the generated private key safe:

     keys\ai-warning-chromium.pem

     Reuse the same key for every future version. If this key changes, the extension ID changes.

  3. Install or load the CRX once on a test browser and copy the extension ID from:

     edge://extensions
     chrome://extensions

  4. Host the CRX on HTTPS, for example:

     https://yourdomain.com/ai-warning/ai-warning.crx

  5. Generate update.xml:

     .\package-chromium-selfhost.ps1 -ExtensionId "your-extension-id" -CrxUrl "https://yourdomain.com/ai-warning/ai-warning.crx"

  6. Host these files on your website:

     dist\self-hosted\chromium\ai-warning.crx
     dist\self-hosted\chromium\update.xml

  7. Configure policy-config.json:

     ChromeExtensionId = your extension ID
     ChromeUpdateUrl = https://yourdomain.com/ai-warning/update.xml
     EdgeExtensionId = your extension ID
     EdgeUpdateUrl = https://yourdomain.com/ai-warning/update.xml

  Note: the .crx file should be served as application/x-chrome-extension.

Manual local signed-file test:
  After signing, you can also copy the signed XPI directly over:

     C:\ProgramData\AI Warning\ai-warning-firefox.xpi

  Then restart Firefox.

Chrome without Chrome installed:
  The installer can still write Chrome policy to:
    HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist

  Chrome will read that policy later when installed, but it still needs a real Chrome extension ID and update URL in policy-config.json.

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
