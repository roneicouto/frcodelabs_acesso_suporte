param(
    [Alias('Profile')][ValidateSet('full', 'qs', 'both')][string]$BuildProfile = 'both',
    [switch]$SkipBridge,
    [switch]$SkipFlutter
)
. "$PSScriptRoot\env.ps1"
# Windows PowerShell treats native stderr as ErrorRecords, even for compiler warnings.
Set-Location $TaskRoot
function Invoke-BuildStep([string]$Executable, [string[]]$Arguments) {
    $PreviousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $Executable @Arguments
    $StepExitCode = $LASTEXITCODE
    $ErrorActionPreference = $PreviousPreference
    if ($StepExitCode -ne 0) { throw "Build failed: $Executable $Arguments (exit $StepExitCode)" }
}
Invoke-BuildStep 'python' @('scripts/prepare.py')
Invoke-BuildStep 'python' @('scripts/export-icons.py')
$ClientConfig = Get-Content config\client.json -Raw | ConvertFrom-Json
Push-Location upstream
try {
    if (-not $SkipBridge) {
        $env:RUST_LOG = 'info'
        Invoke-BuildStep 'flutter_rust_bridge_codegen' @('--rust-input', 'src/flutter_ffi.rs', '--dart-output', 'flutter/lib/generated_bridge.dart', '--c-output', 'flutter/macos/Runner/bridge_generated.h', '--llvm-path', "$TaskRoot\.tools\llvm")
        Copy-Item -LiteralPath flutter\macos\Runner\bridge_generated.h -Destination flutter\ios\Runner\bridge_generated.h
    }
    $Profiles = if ($BuildProfile -eq 'both') { @('full', 'qs') } else { @($BuildProfile) }
    Invoke-BuildStep 'cargo' @('build', '--locked', '--release', '-p', 'dylib_virtual_display')
    foreach ($CurrentProfile in $Profiles) {
        Invoke-BuildStep 'cargo' @('build', '--locked', '--release', '--lib', '--features', "flutter,cf-$CurrentProfile")
        if (-not $SkipFlutter) {
            Push-Location flutter
            try { Invoke-BuildStep 'flutter' @('build', 'windows', '--release', '--build-name', $ClientConfig.version, '--build-number', '1') }
            finally { Pop-Location }
        }
        $AppName = if ($CurrentProfile -eq 'qs') { $ClientConfig.qs_app_name } else { $ClientConfig.full_app_name }
        $Bundle = Join-Path $TaskRoot "dist\windows\$CurrentProfile"
        New-Item -ItemType Directory -Force $Bundle | Out-Null
        Copy-Item -Path flutter\build\windows\x64\runner\Release\* -Destination $Bundle -Recurse -Force
        Copy-Item -LiteralPath target\release\librustdesk.dll -Destination "$Bundle\librustdesk.dll" -Force
        Copy-Item -LiteralPath target\release\deps\dylib_virtual_display.dll -Destination $Bundle -Force
        Move-Item -LiteralPath "$Bundle\rustdesk.exe" -Destination "$Bundle\$AppName.exe" -Force
        Copy-Item -LiteralPath LICENCE -Destination "$Bundle\LICENCE.txt" -Force
        Copy-Item -LiteralPath "$TaskRoot\docs\NOTICE.txt" -Destination $Bundle -Force
        Invoke-BuildStep 'python' @('libs/portable/generate.py', '-f', $Bundle, '-o', 'libs/portable', '-e', "$Bundle\$AppName.exe", '-l', '6')
        $PackageName = if ($CurrentProfile -eq 'qs') { "$AppName-$($ClientConfig.version).exe" } else { "$AppName-$($ClientConfig.version)-install.exe" }
        Copy-Item -LiteralPath target\release\rustdesk-portable-packer.exe -Destination "$TaskRoot\dist\windows\$PackageName" -Force
        Get-FileHash -LiteralPath "$TaskRoot\dist\windows\$PackageName" -Algorithm SHA256 | Format-List
    }
}
finally { Pop-Location }
