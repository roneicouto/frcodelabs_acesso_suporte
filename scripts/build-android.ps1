param([ValidateSet('full', 'qs', 'both')][string]$BuildProfile = 'both')
. "$PSScriptRoot\env.ps1"
Set-Location $TaskRoot
$env:ANDROID_HOME = Join-Path $env:LOCALAPPDATA 'Android\sdk'
$env:ANDROID_NDK_HOME = Join-Path $env:ANDROID_HOME 'ndk\28.2.13676358'
$env:ANDROID_NDK_ROOT = $env:ANDROID_NDK_HOME
$env:JAVA_HOME = 'C:\Program Files\Android\Android Studio\jbr'
$env:VCPKG_INSTALLED_ROOT = Join-Path $TaskRoot '.tools\android-installed'
# magnum-opus resolves VCPKG_ROOT/installed directly, without the installed-root override.
$AndroidVcpkgRoot = Join-Path $TaskRoot '.tools\android-vcpkg-root'
New-Item -ItemType Directory -Force $AndroidVcpkgRoot | Out-Null
if (-not (Test-Path "$AndroidVcpkgRoot\installed")) {
    New-Item -ItemType Junction -Path "$AndroidVcpkgRoot\installed" -Target $env:VCPKG_INSTALLED_ROOT | Out-Null
}
$env:VCPKG_ROOT = $AndroidVcpkgRoot
$env:OPENSSL_DIR = Join-Path $env:VCPKG_INSTALLED_ROOT 'arm64-android'
$env:OPENSSL_NO_VENDOR = '1'
$env:SODIUM_LIB_DIR_aarch64_linux_android = Join-Path $env:OPENSSL_DIR 'lib'
$env:CMAKE_GENERATOR = 'Ninja'
$env:CARGO_BUILD_JOBS = '4'
$env:CFLAGS = '--target=aarch64-linux-android21'
$env:CXXFLAGS = '--target=aarch64-linux-android21'
$env:PATH = "$env:ANDROID_NDK_HOME\toolchains\llvm\prebuilt\windows-x86_64\bin;$env:JAVA_HOME\bin;$env:PATH"
function Invoke-AndroidStep([string]$Executable, [string[]]$Arguments) {
    $PreviousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $Executable @Arguments
    $StepExitCode = $LASTEXITCODE
    $ErrorActionPreference = $PreviousPreference
    if ($StepExitCode -ne 0) { throw "Android build failed: $Executable $Arguments (exit $StepExitCode)" }
}
Invoke-AndroidStep 'python' @('scripts/prepare.py')
Invoke-AndroidStep 'python' @('scripts/export-icons.py')
Invoke-AndroidStep 'python' @('scripts/android-signing.py')
Invoke-AndroidStep 'python' @('scripts/prepare-sodium.py')
$ClientConfig = Get-Content config\client.json -Raw | ConvertFrom-Json
$Profiles = if ($BuildProfile -eq 'both') { @('full', 'qs') } else { @($BuildProfile) }
foreach ($CurrentProfile in $Profiles) {
    Invoke-AndroidStep 'python' @('scripts/prepare-android.py', $CurrentProfile)
    Push-Location upstream
    try {
        Invoke-AndroidStep 'cargo' @('ndk', '--platform', '21', '--target', 'aarch64-linux-android', 'build', '--locked', '--release', '--lib', '--features', "flutter,cf-$CurrentProfile")
        $NativeFolder = 'flutter\android\app\src\main\jniLibs\arm64-v8a'
        New-Item -ItemType Directory -Force $NativeFolder | Out-Null
        Copy-Item -LiteralPath target\aarch64-linux-android\release\liblibrustdesk.so -Destination "$NativeFolder\librustdesk.so" -Force
        Copy-Item -LiteralPath "$env:ANDROID_NDK_HOME\toolchains\llvm\prebuilt\windows-x86_64\sysroot\usr\lib\aarch64-linux-android\libc++_shared.so" -Destination $NativeFolder -Force
        Push-Location flutter
        try { Invoke-AndroidStep 'flutter' @('build', 'apk', '--release', '--target-platform', 'android-arm64', '--build-name', $ClientConfig.version, '--build-number', '1') }
        finally { Pop-Location }
        $OutputFolder = Join-Path $TaskRoot 'dist\android'
        New-Item -ItemType Directory -Force $OutputFolder | Out-Null
        $AppName = if ($CurrentProfile -eq 'qs') { $ClientConfig.qs_app_name } else { $ClientConfig.full_app_name }
        $Output = Join-Path $OutputFolder "$AppName-$($ClientConfig.version)-arm64.apk"
        Copy-Item -LiteralPath flutter\build\app\outputs\flutter-apk\app-release.apk -Destination $Output -Force
        Invoke-AndroidStep "$env:ANDROID_HOME\build-tools\36.1.0\apksigner.bat" @('verify', '--verbose', $Output)
        Get-FileHash -LiteralPath $Output -Algorithm SHA256 | Format-List
    }
    finally { Pop-Location }
}
