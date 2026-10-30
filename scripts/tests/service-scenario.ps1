param([string]$Scenario, [string]$Plan, [string]$Helper)
$ErrorActionPreference = 'Stop'
$global:cfServiceTestActions = @{ start=0; resume=0; automatic=0; elevate=0 }
function Save-Actions { $global:cfServiceTestActions | ConvertTo-Json -Compress | Set-Content -LiteralPath "$Plan.actions" -Encoding UTF8 }
Save-Actions
$global:cfServiceTestData = Get-Content -LiteralPath $Plan -Raw -Encoding UTF8 | ConvertFrom-Json
function Get-CimInstance {
    param($ClassName, $Filter, $OperationTimeoutSec)
    if ($Scenario -eq 'missing') { return $null }
    $path = if ($Scenario -eq 'mismatch') { 'C:\Other\FRCodeLabs.exe' } else { $global:cfServiceTestData.exe }
    [pscustomobject]@{ PathName=('"{0}" --service' -f $path); StartMode=$(if ($Scenario -eq 'disabled') { 'Disabled' } else { 'Auto' }) }
}
function Get-Service {
    param($Name, $ErrorAction)
    $global:cfServiceTestInstance = [pscustomobject]@{ Status=$(if ($Scenario -eq 'running') { 'Running' } elseif ($Scenario -eq 'paused') { 'Paused' } else { 'Stopped' }) }
    $global:cfServiceTestInstance | Add-Member ScriptMethod WaitForStatus { param($Status,$Timeout) if ($this.Status -ne $Status) { throw 'Service never reached requested state' } }
    $global:cfServiceTestInstance | Add-Member ScriptMethod Refresh {}
    $global:cfServiceTestInstance
}
function Start-Service {
    param($Name)
    $global:cfServiceTestActions.start++; Save-Actions
    if ($Scenario -eq 'error') { throw 'Simulated service control failure' }
    $global:cfServiceTestInstance.Status = 'Running'
}
function Resume-Service { param($Name) $global:cfServiceTestActions.resume++; Save-Actions; $global:cfServiceTestInstance.Status = 'Running' }
function Set-Service { param($Name,$StartupType) $global:cfServiceTestActions.automatic++; Save-Actions }
function Start-Process {
    param($FilePath,$ArgumentList,$Verb,[switch]$Wait)
    $global:cfServiceTestActions.elevate++; Save-Actions
    @{ state='error'; detail='Simulated denied UAC' } | ConvertTo-Json | Set-Content -LiteralPath "$Plan.result" -Encoding UTF8
}
# All service-control/elevation commands are mocked in this isolated process.
& $Helper -Plan $Plan -Elevated:($Scenario -ne 'error')

