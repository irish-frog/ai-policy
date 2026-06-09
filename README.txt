AI Warning Banner

This deploys a browser extension that shows a warning banner on approved AI websites.

The banner reminds users not to share confidential company information with AI tools.

Current Setup

Chrome and Edge:
  Uses the hosted extension update at:
  https://it-inyanga.co.za/ai-warning/update.xml

Firefox:
  Uses the original local Firefox package method.

Install from GitHub

Run this from an Administrator Command Prompt:

  powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "iwr -Uri 'https://raw.githubusercontent.com/irish-frog/ai-policy/main/install-from-github.ps1' -OutFile '%TEMP%\install-from-github.ps1'; & '%TEMP%\install-from-github.ps1' -Repository 'irish-frog/ai-policy' -Branch 'main'"

Install from Local Folder

Run this from an Administrator Command Prompt:

  cd /d "C:\Users\gavin\Downloads\AI-Warning-Debug-Package\AI-Warning-Debug-Package"
  install.cmd

Uninstall

Run this from an Administrator Command Prompt:

  cd /d "C:\Users\gavin\Downloads\AI-Warning-Debug-Package\AI-Warning-Debug-Package"
  uninstall.cmd

After Install

Fully close and reopen Chrome, Edge, and Firefox.

Logs

Install log:
  C:\ProgramData\AI Warning\install.log

Uninstall log:
  C:\ProgramData\AI Warning\uninstall.log
