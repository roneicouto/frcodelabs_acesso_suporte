$ErrorActionPreference = 'Stop'
$TaskRoot = Split-Path $PSScriptRoot -Parent
$NativeVsDevCmd = 'C:\Program Files\Microsoft Visual Studio\18\Community\Common7\Tools\VsDevCmd.bat'
if (Test-Path -LiteralPath $NativeVsDevCmd) {
    # Older pinned Rust tooling cannot discover VS 2026 without its developer environment.
    $NativeEnvCommand = 'call "{0}" -no_logo -arch=amd64 -host_arch=amd64 >nul && set' -f $NativeVsDevCmd
    $NativeEnvLines = & $env:ComSpec /d /c $NativeEnvCommand
    if ($LASTEXITCODE -ne 0) { throw 'Unable to initialize the Visual C++ x64 environment' }
    foreach ($NativeEnvLine in $NativeEnvLines) {
        if ($NativeEnvLine -match '^(PATH|INCLUDE|LIB|LIBPATH|VCINSTALLDIR|VCToolsInstallDir|WindowsSdkDir|WindowsSDKVersion|VSINSTALLDIR|VisualStudioVersion|VSCMD_ARG_TGT_ARCH|VSCMD_ARG_HOST_ARCH)=(.*)$') {
            [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2], 'Process')
        }
    }
}
if (Test-Path -LiteralPath "$TaskRoot\.tools\python-win\python.exe") {
    $env:PATH = "$TaskRoot\.tools\python-win;$env:PATH"
}
$env:CARGO_HOME = Join-Path $TaskRoot '.tools\cargo'
$env:RUSTUP_HOME = Join-Path $TaskRoot '.tools\rustup'
$env:VCPKG_ROOT = Join-Path $TaskRoot '.tools\vcpkg'
$env:VCPKG_DOWNLOADS = Join-Path $TaskRoot '.tools\downloads'
$env:VCPKG_DEFAULT_TRIPLET = 'x64-windows-static'
$env:PATH = "$TaskRoot\.tools\cargo\bin;$TaskRoot\.tools\flutter\bin;$env:PATH"
$CMakeRoots = @(Get-ChildItem -LiteralPath "$TaskRoot\.tools\downloads\tools" -Directory -Filter 'cmake-*' -ErrorAction SilentlyContinue)
$CMakeBin = if ($CMakeRoots.Count) {
    Get-ChildItem -LiteralPath $CMakeRoots[0].FullName -Directory -Recurse -Filter bin | Select-Object -First 1 -ExpandProperty FullName
} else { $null }
if ($CMakeBin) { $env:PATH = "$CMakeBin;$env:PATH" }
if (Test-Path 'C:\Program Files\Microsoft Visual Studio\18\Community') {
    $env:CMAKE_GENERATOR = 'Visual Studio 18 2026'
}
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
$env:RUSTUP_TOOLCHAIN = '1.75.0'

# Localização resiliente de libclang / LLVM
$ClangCandidates = @()
try {
    $PyClang = python -c "import sys, pathlib
candidates = []
try:
    import libclang
    candidates.append(str(pathlib.Path(libclang.__file__).parent))
except Exception:
    pass
try:
    import clang
    candidates.append(str(pathlib.Path(clang.__file__).parent / 'native'))
except Exception:
    pass
for p in sys.path:
    candidates.append(str(pathlib.Path(p) / 'libclang'))
    candidates.append(str(pathlib.Path(p) / 'clang/native'))
for c in candidates:
    p = pathlib.Path(c)
    if (p / 'libclang.dll').is_file():
        print(p)
        break
" 2>$null
    if ($PyClang -and (Test-Path "$PyClang\libclang.dll")) {
        $ClangCandidates += $PyClang
    }
} catch {}

if (Test-Path 'C:\Program Files\LLVM\bin\libclang.dll') {
    $ClangCandidates += 'C:\Program Files\LLVM\bin'
}
if (Test-Path "$TaskRoot\.tools\llvm\bin\libclang.dll") {
    $ClangCandidates += "$TaskRoot\.tools\llvm\bin"
}
if (Test-Path "$TaskRoot\.tools\llvm\libclang.dll") {
    $ClangCandidates += "$TaskRoot\.tools\llvm"
}

if ($ClangCandidates.Count -gt 0) {
    $env:LIBCLANG_PATH = $ClangCandidates[0]
}
