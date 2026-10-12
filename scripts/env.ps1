$ErrorActionPreference = 'Stop'
$TaskRoot = Split-Path $PSScriptRoot -Parent
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
$ClangRoot = python -c "import importlib.util, pathlib; spec = importlib.util.find_spec('clang'); print(pathlib.Path(spec.origin).parent / 'native' if spec else '')"
if ($ClangRoot) { $env:LIBCLANG_PATH = $ClangRoot }
