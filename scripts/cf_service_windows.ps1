param([Parameter(Mandatory=$true)][string]$Plan, [switch]$Elevated)
$ErrorActionPreference = 'Stop'
$resultFile = "$Plan.result"
function Result([string]$State, [string]$Detail = '') {
    @{ state=$State; detail=$Detail } | ConvertTo-Json -Compress |
        Set-Content -LiteralPath $resultFile -Encoding UTF8
}
try {
    $data = Get-Content -LiteralPath $Plan -Raw -Encoding UTF8 | ConvertFrom-Json
    $name = [string]$data.name
    $exe = [string]$data.exe
    if ($name -notmatch '^[A-Za-z0-9_-]+$' -or
        -not [IO.Path]::IsPathRooted($exe) -or
        [IO.Path]::GetFileNameWithoutExtension($exe) -ne $name -or
        -not (Test-Path -LiteralPath $exe -PathType Leaf)) { throw 'Invalid installed client' }
    $record = Get-CimInstance Win32_Service -Filter "Name = '$name'" -OperationTimeoutSec 10
    if (-not $record) { Result 'missing'; exit 0 }
    $command = [regex]::Match($record.PathName, '^\s*(?:"([^"]+)"|(\S+))\s+--service(?:\s|$)')
    $serviceExe = if ($command.Groups[1].Success) { $command.Groups[1].Value } else { $command.Groups[2].Value }
    if (-not $command.Success -or -not [string]::Equals(
        [IO.Path]::GetFullPath($serviceExe), [IO.Path]::GetFullPath($exe), [StringComparison]::OrdinalIgnoreCase)) {
        Result 'mismatch'; exit 0
    }
    $service = Get-Service -Name $name -ErrorAction Stop
    if ($service.Status -eq 'Running') { Result 'running'; exit 0 }
    try {
        if ($service.Status -eq 'StartPending') {
            $service.WaitForStatus('Running', [TimeSpan]::FromSeconds(20))
        } else {
            if ($service.Status -eq 'StopPending') {
                $service.WaitForStatus('Stopped', [TimeSpan]::FromSeconds(20))
                $service.Refresh()
            }
            if ($record.StartMode -eq 'Disabled') { Set-Service -Name $name -StartupType Automatic }
            if ($service.Status -eq 'Paused') { Resume-Service -Name $name }
            else { Start-Service -Name $name }
            $service.WaitForStatus('Running', [TimeSpan]::FromSeconds(20))
        }
        Result 'started'
    } catch {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $admin = ([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole(
            [Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $Elevated -and -not $admin) {
            # Only retry with UAC after an ordinary service-control attempt fails.
            $arguments = @('-NoProfile', '-NonInteractive', '-WindowStyle', 'Hidden',
                '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath),
                '-Plan', ('"{0}"' -f $Plan), '-Elevated')
            Start-Process -FilePath "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList $arguments -Verb RunAs -Wait | Out-Null
            if (-not (Test-Path -LiteralPath $resultFile)) { Result 'error' 'Elevated helper returned no result' }
        } else { throw }
    }
} catch { Result 'error' $_.Exception.Message; exit 1 }

