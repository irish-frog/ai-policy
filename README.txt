AI Warning Banner

This package deploys a browser policy extension that shows a warning banner on approved AI websites.

Current setup:
  - Chrome and Edge use the self-hosted update policy:
    gghjldfblicajaepdoijgiijknkmoakn;https://it-inyanga.co.za/ai-warning/update.xml

  - Firefox uses the original local XPI policy:
    ai-warning@example.com

Deploy from GitHub

Run this from an Administrator Command Prompt:

  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "iwr -Uri 'https://raw.githubusercontent.com/irish-frog/ai-policy/main/install-from-github.ps1' -OutFile '%TEMP%\install-from-github.ps1'; & '%TEMP%\install-from-github.ps1' -Repository 'irish-frog/ai-policy' -Branch 'main'"

Deploy from Local Folder

Run this from an Administrator Command Prompt:

  cd /d "C:\Users\gavin\Downloads\AI-Warning-Debug-Package\AI-Warning-Debug-Package"
  install.cmd

Uninstall

Run this from an Administrator Command Prompt:

  cd /d "C:\Users\gavin\Downloads\AI-Warning-Debug-Package\AI-Warning-Debug-Package"
  uninstall.cmd

Check Policies

Chrome:

  reg query "HKLM\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist"

Edge:

  reg query "HKLM\SOFTWARE\Policies\Microsoft\Edge\ExtensionInstallForcelist"

Firefox:

  reg query "HKLM\SOFTWARE\Policies\Mozilla\Firefox" /v ExtensionSettings

Logs

Install log:

  C:\ProgramData\AI Warning\install.log

Uninstall log:

  C:\ProgramData\AI Warning\uninstall.log

Notes

  - Run install and uninstall as administrator.
  - Fully close and reopen browsers after installing.
  - The installer writes policy only. It does not track URLs, store browsing data, or send data externally.
  - Chrome and Edge read the policy from HKLM.
  - Firefox reads the policy from HKLM and may also use its distribution policies file.
