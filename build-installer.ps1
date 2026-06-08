param(
    [string]$OutputDir = (Join-Path $PSScriptRoot 'dist\installer'),
    [string]$InstallerName = 'AI-Warning-Policy-Installer.exe'
)

$ErrorActionPreference = 'Stop'

$Csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path $Csc)) {
    throw 'The .NET Framework C# compiler was not found.'
}

$PackageFiles = @(
    'README.txt',
    'install.cmd',
    'install.ps1',
    'install-debug.cmd',
    'uninstall.cmd',
    'uninstall.ps1',
    'uninstall-debug.cmd',
    'install-from-github.ps1',
    'policy-config.example.json',
    'sign-firefox.ps1'
)

$PackageDirs = @(
    'extension',
    'firefox',
    'signed'
)

$BuildRoot = Join-Path $OutputDir 'build'
$PayloadRoot = Join-Path $BuildRoot 'payload'
$PayloadZip = Join-Path $BuildRoot 'payload.zip'
$SourcePath = Join-Path $BuildRoot 'InstallerBootstrap.cs'
$ManifestPath = Join-Path $BuildRoot 'app.manifest'
$OutputExe = Join-Path $OutputDir $InstallerName

Remove-Item -Path $BuildRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $PayloadRoot, $OutputDir | Out-Null

foreach ($File in $PackageFiles) {
    $Source = Join-Path $PSScriptRoot $File
    if (Test-Path $Source) {
        Copy-Item -Path $Source -Destination $PayloadRoot -Force
    }
}

foreach ($Dir in $PackageDirs) {
    $Source = Join-Path $PSScriptRoot $Dir
    if (Test-Path $Source) {
        Copy-Item -Path $Source -Destination (Join-Path $PayloadRoot $Dir) -Recurse -Force
    }
}

Compress-Archive -Path (Join-Path $PayloadRoot '*') -DestinationPath $PayloadZip -Force

Set-Content -Path $ManifestPath -Encoding UTF8 -Value @'
<?xml version="1.0" encoding="utf-8"?>
<assembly manifestVersion="1.0" xmlns="urn:schemas-microsoft-com:asm.v1">
  <trustInfo xmlns="urn:schemas-microsoft-com:asm.v2">
    <security>
      <requestedPrivileges xmlns="urn:schemas-microsoft-com:asm.v3">
        <requestedExecutionLevel level="requireAdministrator" uiAccess="false" />
      </requestedPrivileges>
    </security>
  </trustInfo>
</assembly>
'@

Set-Content -Path $SourcePath -Encoding UTF8 -Value @'
using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;

class InstallerBootstrap
{
    static int Main(string[] args)
    {
        string work = Path.Combine(Path.GetTempPath(), "AI-Warning-Policy-Installer-" + Guid.NewGuid().ToString("N"));
        try
        {
            Directory.CreateDirectory(work);
            string zipPath = Path.Combine(work, "payload.zip");

            using (Stream input = Assembly.GetExecutingAssembly().GetManifestResourceStream("PayloadZip"))
            {
                if (input == null)
                {
                    Console.Error.WriteLine("Embedded installer payload was not found.");
                    return 2;
                }

                using (FileStream output = File.Create(zipPath))
                {
                    input.CopyTo(output);
                }
            }

            ZipFile.ExtractToDirectory(zipPath, work);

            string installCmd = Path.Combine(work, "install.cmd");
            if (!File.Exists(installCmd))
            {
                Console.Error.WriteLine("install.cmd was not found in the embedded payload.");
                return 3;
            }

            ProcessStartInfo startInfo = new ProcessStartInfo();
            startInfo.FileName = "cmd.exe";
            startInfo.Arguments = "/c \"" + installCmd + "\"";
            startInfo.WorkingDirectory = work;
            startInfo.UseShellExecute = false;

            using (Process process = Process.Start(startInfo))
            {
                process.WaitForExit();
                return process.ExitCode;
            }
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine(ex.ToString());
            return 1;
        }
        finally
        {
            try
            {
                if (Directory.Exists(work))
                {
                    Directory.Delete(work, true);
                }
            }
            catch
            {
            }
        }
    }
}
'@

& $Csc `
    /nologo `
    /target:exe `
    /platform:anycpu `
    /win32manifest:$ManifestPath `
    /resource:$PayloadZip,PayloadZip `
    /reference:System.IO.Compression.dll `
    /reference:System.IO.Compression.FileSystem.dll `
    /out:$OutputExe `
    $SourcePath

if (-not (Test-Path $OutputExe)) {
    throw "Installer was not created at $OutputExe"
}

Write-Host "Created installer: $OutputExe"
