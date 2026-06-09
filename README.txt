# AI Warning Banner

This package deploys a browser extension that displays a warning banner on approved AI websites.

The banner reminds users not to enter confidential, sensitive, or company information into AI services.

## Installation

1. Close all supported browsers:

```cmd
taskkill /F /IM chrome.exe /IM msedge.exe /IM firefox.exe
```

2. Run the following command from an Administrator Command Prompt:

```cmd
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "iwr -Uri 'https://raw.githubusercontent.com/irish-frog/ai-policy/main/install-from-github.ps1' -OutFile '%TEMP%\install-from-github.ps1'; & '%TEMP%\install-from-github.ps1' -Repository 'irish-frog/ai-policy' -Branch 'main'"
```

## Uninstallation

Run the following command from an Administrator Command Prompt:

```cmd
cd /d "C:\ProgramData\AI Warning"
uninstall.cmd
```

## After Installation

Reopen Chrome, Microsoft Edge, and Firefox.

The warning banner will automatically appear when users visit approved AI websites.
