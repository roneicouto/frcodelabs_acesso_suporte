. "$PSScriptRoot\env.ps1"
Set-Location $TaskRoot
function Invoke-AndroidSetup([string]$Executable, [string[]]$Arguments) {
    $PreviousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $Executable @Arguments
    $StepExitCode = $LASTEXITCODE
    $ErrorActionPreference = $PreviousPreference
    if ($StepExitCode -ne 0) { throw "Android setup failed: $Executable $Arguments" }
}
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\sdk'
$env:ANDROID_NDK_HOME = Join-Path $env:ANDROID_HOME 'ndk\28.2.13676358'
$env:CMAKE_GENERATOR = 'Ninja'
if (-not (Test-Path "$env:ANDROID_NDK_HOME\build\cmake\android.toolchain.cmake")) {
    throw 'Install Android NDK 28.2.13676358 (r28c) through Android Studio before building.'
}
Invoke-AndroidSetup 'cargo' @('+1.81.0', 'install', 'cargo-ndk', '--version', '3.1.2', '--locked')
Invoke-AndroidSetup 'rustup' @('target', 'add', 'aarch64-linux-android', '--toolchain', '1.75.0')
Invoke-AndroidSetup '.\.tools\vcpkg\vcpkg.exe' @('install', '--triplet', 'arm64-android', "--x-install-root=$TaskRoot\.tools\android-installed", "--x-manifest-root=$TaskRoot\config\android-vcpkg")
Invoke-AndroidSetup 'python' @('scripts/prepare-sodium.py')
