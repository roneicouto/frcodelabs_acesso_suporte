param([string]$Package = '')
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
if (-not $Package) { $Package = Join-Path $root 'dist\windows\FRCodeLabs-Windows-Full-install.exe' }
if (Get-Process -Name RuntimeBroker_rustdesk -ErrorAction SilentlyContinue) {
    throw 'A remote privacy broker is running; defer the interactive installer check.'
}
$cache = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'frcodelabs'
$cachedProcesses = Get-CimInstance Win32_Process -Filter "Name = 'FRCodeLabs.exe'" |
    Where-Object { $_.ExecutablePath -and [IO.Path]::GetFullPath($_.ExecutablePath).StartsWith($cache + '\', [StringComparison]::OrdinalIgnoreCase) }
if ($cachedProcesses) { throw 'Close the portable Full before testing its extraction cache.' }
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('FRCodeLabs-installer-window-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$renamed = Join-Path $testRoot 'FRCodeLabs-Windows-Full-install (2).exe'
Copy-Item -LiteralPath $Package -Destination $renamed
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class InstallerWindowCheck {
    [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr window, uint message, IntPtr wparam, IntPtr lparam);
}
'@
$client = $null
try {
    # The production wrapper uses Windows Known Folders, not environment
    # overrides. It refreshes its normal extraction cache, never Program Files.
    $packer = Start-Process -FilePath $renamed -WindowStyle Hidden -PassThru
    $deadline = (Get-Date).AddSeconds(40)
    while ((Get-Date) -lt $deadline) {
        $child = Get-CimInstance Win32_Process -Filter "Name = 'FRCodeLabs.exe'" |
            Where-Object { $_.ParentProcessId -eq $packer.Id } |
            Select-Object -First 1
        if ($child) {
            $client = Get-Process -Id $child.ProcessId -ErrorAction SilentlyContinue
            if ($client) {
                $client.Refresh()
                if ($client.MainWindowHandle -ne [IntPtr]::Zero) { break }
            }
        }
        Start-Sleep -Milliseconds 200
    }
    if (-not $client -or $client.MainWindowTitle -ne 'FRCodeLabs - Install') {
        $title = if ($client) { $client.MainWindowTitle } else { 'No window' }
        throw "Renamed package did not open the installer: $title"
    }
    $client.MainWindowTitle | Set-Content -LiteralPath (Join-Path $testRoot 'window-title.txt') -Encoding UTF8
    'PASS: Full package named install (2).exe opened FRCodeLabs - Install.'
    'The installation was not accepted; no installed files or services were updated.'
    "Fixture package and window evidence: $testRoot"
} finally {
    if ($client -and -not $client.HasExited) {
        [InstallerWindowCheck]::PostMessage($client.MainWindowHandle, 0x10, [IntPtr]::Zero, [IntPtr]::Zero) | Out-Null
        if (-not $client.WaitForExit(5000)) { Stop-Process -Id $client.Id -Force }
    }
}

