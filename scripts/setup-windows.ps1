. "$PSScriptRoot\env.ps1"
Set-Location $TaskRoot
function Invoke-SetupStep([string]$Executable, [string[]]$Arguments) {
    $PreviousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & $Executable @Arguments
    $StepExitCode = $LASTEXITCODE
    $ErrorActionPreference = $PreviousPreference
    if ($StepExitCode -ne 0) { throw "Setup failed: $Executable $Arguments" }
}
New-Item -ItemType Directory -Force .tools | Out-Null
if (-not (Test-Path upstream\Cargo.toml)) {
    Invoke-SetupStep 'git' @('clone', '--depth', '1', '--branch', '1.5.0', '--recurse-submodules', '--shallow-submodules', 'https://github.com/rustdesk/rustdesk.git', 'upstream')
}
if (-not (Test-Path .tools\cargo\bin\rustup.exe)) {
    Invoke-WebRequest https://win.rustup.rs/x86_64 -OutFile .tools\rustup-init.exe
    Invoke-SetupStep '.\.tools\rustup-init.exe' @('-y', '--no-modify-path', '--default-toolchain', '1.75.0', '--profile', 'minimal')
}
Invoke-SetupStep 'rustup' @('toolchain', 'install', '1.81.0', '--profile', 'minimal')
Invoke-SetupStep 'rustup' @('component', 'add', 'rustfmt', '--toolchain', '1.75.0')
Invoke-SetupStep 'cargo' @('+1.81.0', 'install', 'cargo-expand', '--version', '1.0.95', '--locked')
Invoke-SetupStep 'cargo' @('+1.81.0', 'install', 'flutter_rust_bridge_codegen', '--version', '1.80.1', '--features', 'uuid', '--locked')
if (-not (Test-Path .tools\flutter\.git)) {
    Invoke-SetupStep 'git' @('clone', '--depth', '1', '--branch', '3.24.5', 'https://github.com/flutter/flutter.git', '.tools/flutter')
}
if (-not (Test-Path .tools\vcpkg\.git)) {
    Invoke-SetupStep 'git' @('clone', 'https://github.com/microsoft/vcpkg.git', '.tools/vcpkg')
    Invoke-SetupStep 'git' @('-C', '.tools/vcpkg', 'checkout', '9e593bb18ea69cc5095e012465dcd675a822ed0d')
    Invoke-SetupStep '.\.tools\vcpkg\bootstrap-vcpkg.bat' @('-disableMetrics')
}
Invoke-SetupStep 'python' @('-m', 'pip', 'install', 'pillow==12.3.0', 'libclang==18.1.1', 'brotli==1.2.0')
. "$PSScriptRoot\env.ps1"
New-Item -ItemType Directory -Force .tools\llvm\bin | Out-Null
Copy-Item -LiteralPath "$env:LIBCLANG_PATH\libclang.dll" -Destination .tools\llvm\bin\libclang.dll -Force
Invoke-SetupStep 'python' @('scripts/prepare.py')
Invoke-SetupStep 'python' @('scripts/export-icons.py')
Invoke-SetupStep 'python' @('scripts/prepare-tools.py')
Invoke-SetupStep 'flutter' @('precache', '--windows')
# Match the engine used by RustDesk 1.5.0 on Windows x64.
if (-not (Test-Path .tools\custom-engine.ready)) {
    Invoke-WebRequest https://github.com/rustdesk/engine/releases/download/main/windows-x64-release.zip -OutFile .tools\windows-x64-release.zip
    $SourceLock = Get-Content config\source-lock.json -Raw | ConvertFrom-Json
    if ((Get-FileHash .tools\windows-x64-release.zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $SourceLock.windows_engine_sha256) {
        throw 'The upstream Flutter engine changed. Review it before updating source-lock.json.'
    }
    Expand-Archive -LiteralPath .tools\windows-x64-release.zip -DestinationPath .tools\windows-x64-release -Force
    Copy-Item -Path .tools\windows-x64-release\* -Destination .tools\flutter\bin\cache\artifacts\engine\windows-x64-release -Recurse -Force
    New-Item -ItemType File .tools\custom-engine.ready | Out-Null
}
Invoke-SetupStep '.\.tools\vcpkg\vcpkg.exe' @('install', '--triplet', 'x64-windows-static', "--x-install-root=$env:VCPKG_ROOT\installed", "--x-manifest-root=$TaskRoot\upstream")
Push-Location upstream\flutter
try { Invoke-SetupStep 'flutter' @('pub', 'get') }
finally { Pop-Location }
