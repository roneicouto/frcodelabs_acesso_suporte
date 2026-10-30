# Runs the real portable updater with harmless executables in an isolated folder.
param([string]$DartExecutable = '', [switch]$CompiledLauncher)
$ErrorActionPreference = 'Stop'
if (-not $DartExecutable) {
    $DartExecutable = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\.tools\flutter\bin\cache\dart-sdk\bin\dart.exe'))
    if (-not (Test-Path -LiteralPath $DartExecutable)) { $DartExecutable = (Get-Command dart -ErrorAction Stop).Source }
}
$dartLauncher = Join-Path $PSScriptRoot 'launch-updater.dart'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('FRCodeLabs-updater-test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$fixture = Join-Path $testRoot 'fixture.exe'
Add-Type -OutputAssembly $fixture -OutputType ConsoleApplication -TypeDefinition @'
using System;
using System.IO;
using System.Threading;
public class Fixture {
    public static void Main(string[] args) {
        File.WriteAllText(Environment.GetCommandLineArgs()[0] + ".started", string.Join("|", args));
        if (args.Length > 0 && args[0] == "wait") Thread.Sleep(30000);
    }
}
'@
$helper = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\cf_update_windows.ps1'))
foreach ($profile in @('qs', 'full', 'corrupt')) {
    $folder = Join-Path $testRoot "$profile user's files"
    New-Item -ItemType Directory -Path $folder | Out-Null
    $runtime = Join-Path $folder $(if ($profile -eq 'full') { 'FRCodeLabs.exe' } else { 'FRCodeLabsQS.exe' })
    $package = Join-Path $folder 'download.exe'
    $target = Join-Path $folder 'original launcher.exe'
    Copy-Item -LiteralPath $fixture -Destination $runtime
    Copy-Item -LiteralPath $fixture -Destination $package
    Set-Content -LiteralPath $target -Value 'original-version' -Encoding ASCII
    $oldHash = (Get-FileHash -LiteralPath $target).Hash
    $old = Start-Process -FilePath $runtime -ArgumentList 'wait' -WindowStyle Hidden -PassThru
    $planPath = Join-Path $folder 'plan.json'
    $planData = @{
        mode='portable'; profile=$(if ($profile -eq 'full') { 'full' } else { 'qs' }); version='1.0.5'
        package=$package; target=$target; runtime=$runtime; processId=$old.Id
        bytes=(Get-Item -LiteralPath $package).Length
        sha256=$(if ($profile -eq 'corrupt') { '0' * 64 } else { (Get-FileHash -LiteralPath $package).Hash.ToLowerInvariant() })
    }
    $planData | ConvertTo-Json | Set-Content -LiteralPath $planPath -Encoding UTF8
    $launchArguments = @(('"{0}"' -f $helper), ('"{0}"' -f $planPath))
    if (-not $CompiledLauncher) { $launchArguments = @(('"{0}"' -f $dartLauncher)) + $launchArguments }
    $runner = Start-Process -FilePath $DartExecutable -WindowStyle Hidden -PassThru -ArgumentList $launchArguments
    try {
        $deadline = (Get-Date).AddSeconds(15)
        while (-not (Test-Path -LiteralPath "$planPath.ready") -and -not (Test-Path -LiteralPath "$planPath.error")) {
            if ((Get-Date) -gt $deadline) { throw "Helper startup timeout: $folder" }
            Start-Sleep -Milliseconds 100
        }
        if ($profile -eq 'corrupt') {
            if (-not (Test-Path -LiteralPath "$planPath.error") -or
                (Test-Path -LiteralPath "$planPath.ready") -or
                (Get-FileHash -LiteralPath $target).Hash -ne $oldHash) { throw 'Corrupt update was accepted' }
        } else {
            if (Test-Path -LiteralPath "$planPath.error") { throw (Get-Content -LiteralPath "$planPath.error" -Raw) }
            if (-not $runner.WaitForExit(3000) -or $runner.ExitCode -ne 0) { throw 'Dart launcher did not exit cleanly' }
            Set-Content -LiteralPath "$planPath.go" -Value 'confirmed'
            Start-Sleep -Milliseconds 400
            if ((Get-FileHash -LiteralPath $target).Hash -ne $oldHash) { throw 'Replaced before client exited' }
            Stop-Process -Id $old.Id -Force
            $deadline = (Get-Date).AddSeconds(15)
            while (-not (Test-Path -LiteralPath "$planPath.done")) {
                if ((Get-Date) -gt $deadline -or (Test-Path -LiteralPath "$planPath.error")) { throw "Helper apply failed: $folder" }
                Start-Sleep -Milliseconds 100
            }
            if (-not (Test-Path -LiteralPath "$planPath.done")) { throw "Update failed: $folder" }
            if ((Get-FileHash -LiteralPath $target).Hash -ne (Get-FileHash -LiteralPath $package).Hash -or
                (Get-FileHash -LiteralPath "$target.previous").Hash -ne $oldHash) { throw 'Replacement/backup mismatch' }
            $deadline = (Get-Date).AddSeconds(5)
            while (-not (Test-Path -LiteralPath "$target.started")) {
                if ((Get-Date) -gt $deadline) { throw 'Client was not restarted' }
                Start-Sleep -Milliseconds 100
            }
            $argsReceived = [IO.File]::ReadAllText("$target.started")
            if ($profile -eq 'full' -and $argsReceived -ne '--noinstall') { throw 'Full would reopen installer' }
            if ($profile -eq 'qs' -and $argsReceived -ne '') { throw 'QS launch arguments changed' }
        }
        Write-Output "PASS: $profile portable handoff"
    } finally {
        if (-not $old.HasExited) { Stop-Process -Id $old.Id -Force }
        if (-not $runner.HasExited) { Stop-Process -Id $runner.Id -Force }
    }
}
Write-Output "Isolated test evidence: $testRoot"

