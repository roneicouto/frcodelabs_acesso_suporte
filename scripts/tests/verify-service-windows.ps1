$ErrorActionPreference = 'Stop'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('FRCodeLabs-service-test-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot | Out-Null
$exe = Join-Path $testRoot 'FRCodeLabs.exe'
Set-Content -LiteralPath $exe -Value 'Service-control fixture only'
$helper = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\cf_service_windows.ps1'))
$scenarioScript = Join-Path $PSScriptRoot 'service-scenario.ps1'
foreach ($scenario in @('running','stopped','disabled','paused','missing','mismatch','error')) {
    $plan = Join-Path $testRoot "$scenario.json"
    @{ name='FRCodeLabs'; exe=$exe } | ConvertTo-Json | Set-Content -LiteralPath $plan -Encoding UTF8
    & "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $scenarioScript -Scenario $scenario -Plan $plan -Helper $helper
    $result = Get-Content -LiteralPath "$plan.result" -Raw -Encoding UTF8 | ConvertFrom-Json
    $actions = Get-Content -LiteralPath "$plan.actions" -Raw -Encoding UTF8 | ConvertFrom-Json
    $expected = switch ($scenario) { 'running' {'running'} 'missing' {'missing'} 'mismatch' {'mismatch'} 'error' {'error'} default {'started'} }
    if ($result.state -ne $expected) { throw "$scenario returned $($result.state), expected $expected" }
    if ($scenario -in @('running','missing','mismatch') -and ($actions.start -ne 0 -or $actions.elevate -ne 0)) { throw 'Unexpected service change' }
    if ($scenario -in @('stopped','disabled') -and $actions.start -ne 1) { throw 'Stopped service was not started once' }
    if ($scenario -eq 'disabled' -and $actions.automatic -ne 1) { throw 'Disabled service was not enabled' }
    if ($scenario -eq 'paused' -and $actions.resume -ne 1) { throw 'Paused service was not resumed' }
    Write-Output "PASS: $scenario service scenario (mocked SCM; no system service modified)"
}
"Evidence: $testRoot"

