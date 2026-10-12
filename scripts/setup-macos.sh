#!/usr/bin/env bash
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo 'Execute este script no MacBook.' >&2; exit 1; }
task_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$task_root"
command -v brew >/dev/null || { echo 'Instale o Homebrew conforme docs/MACBOOK.md.' >&2; exit 1; }
xcodebuild -version >/dev/null || { echo 'Instale e abra o Xcode completo antes de continuar.' >&2; exit 1; }
if [[ "$(sysctl -in sysctl.proc_translated 2>/dev/null || true)" == 1 ]]; then
  echo 'Abra um Terminal nativo, fora do Rosetta, e execute novamente.' >&2; exit 1
fi
brew install python cmake ninja pkg-config llvm nasm yasm autoconf automake libtool cocoapods
mkdir -p .tools/downloads
python3 scripts/bootstrap-source.py
python3 -m venv .tools/python
.tools/python/bin/python -m pip install 'pillow==12.3.0'
export CARGO_HOME="$task_root/.tools/cargo" RUSTUP_HOME="$task_root/.tools/rustup"
mac_rust="$(python3 -c 'import json; print(json.load(open("config/source-lock.json"))["rust_macos"])')"
if [[ ! -x "$CARGO_HOME/bin/rustup" ]]; then
  curl --fail --location --proto '=https' --tlsv1.2 https://sh.rustup.rs -o .tools/downloads/rustup-init.sh
  sh .tools/downloads/rustup-init.sh -y --no-modify-path --profile minimal --default-toolchain "$mac_rust"
fi
export PATH="$CARGO_HOME/bin:$PATH"
rustup toolchain install "$mac_rust" --profile minimal --component rustfmt
flutter_version="$(python3 -c 'import json; print(json.load(open("config/source-lock.json"))["flutter"])')"
if [[ ! -d .tools/flutter/.git ]]; then
  git clone --depth 1 --branch "$flutter_version" https://github.com/flutter/flutter.git .tools/flutter
fi
[[ "$(git -C .tools/flutter describe --tags --exact-match HEAD)" == "$flutter_version" ]] || { echo 'Private Flutter SDK version mismatch' >&2; exit 1; }
vcpkg_commit="$(python3 -c 'import json; print(json.load(open("config/source-lock.json"))["vcpkg_commit"])')"
if [[ ! -d .tools/vcpkg/.git ]]; then
  git clone https://github.com/microsoft/vcpkg.git .tools/vcpkg
  git -C .tools/vcpkg checkout "$vcpkg_commit"
fi
[[ "$(git -C .tools/vcpkg rev-parse HEAD)" == "$vcpkg_commit" ]] || { echo 'Private vcpkg version mismatch' >&2; exit 1; }
source scripts/env-macos.sh
python3 scripts/prepare.py
python3 scripts/prepare-sodium.py
python3 scripts/export-icons.py
python3 scripts/prepare-macos-tools.py
"$VCPKG_ROOT/bootstrap-vcpkg.sh" -disableMetrics
"$VCPKG_ROOT/vcpkg" install --x-manifest-root="$task_root/config/macos-vcpkg" --x-install-root="$VCPKG_ROOT/installed" --triplet "$VCPKG_DEFAULT_TRIPLET" --host-triplet "$VCPKG_DEFAULT_HOST_TRIPLET"
cargo install cargo-expand --version "$(python3 -c 'import json; print(json.load(open("config/source-lock.json"))["cargo_expand"])')" --locked
cargo install flutter_rust_bridge_codegen --version "$(python3 -c 'import json; print(json.load(open("config/source-lock.json"))["bridge_codegen"])')" --features uuid --locked
flutter config --enable-macos-desktop --no-analytics
flutter precache --macos
cp config/flutter-pubspec.lock upstream/flutter/pubspec.lock
(cd upstream/flutter && flutter pub get)
export RUST_LOG=info
(cd upstream && flutter_rust_bridge_codegen --rust-input src/flutter_ffi.rs --dart-output flutter/lib/generated_bridge.dart --c-output flutter/macos/Runner/bridge_generated.h --llvm-path "$LLVM_ROOT")
echo 'Preparação concluída. Execute: bash scripts/build-macos.sh both'
