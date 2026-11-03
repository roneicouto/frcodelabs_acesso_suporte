#!/usr/bin/env bash
set -euo pipefail
[[ "$(uname -s)" == Linux ]] || { echo 'Execute este script em uma distribuição Linux (Debian/Ubuntu/Mint).' >&2; exit 1; }
task_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$task_root"

if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y
  sudo apt-get install -y \
    autoconf \
    autoconf-archive \
    automake \
    build-essential \
    clang \
    cmake \
    curl \
    dpkg-dev \
    g++ \
    gcc \
    git \
    libasound2-dev \
    libayatana-appindicator3-dev \
    libclang-dev \
    libdrm-dev \
    libgbm-dev \
    libglib2.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-dev \
    libgtk-3-dev \
    libpam0g-dev \
    libpipewire-0.3-dev \
    libpulse-dev \
    libssl-dev \
    libsystemd-dev \
    libtool \
    libudev-dev \
    libva-dev \
    libvdpau-dev \
    libwayland-dev \
    libx11-dev \
    libxcb-randr0-dev \
    libxcb-shape0-dev \
    libxcb-xfixes0-dev \
    libxdo-dev \
    libxfixes-dev \
    libxkbcommon-dev \
    libxrandr-dev \
    libxtst-dev \
    llvm-dev \
    nasm \
    ninja-build \
    pkg-config \
    python3 \
    python3-pip \
    python3-venv \
    unzip \
    wayland-protocols \
    wget \
    xz-utils \
    yasm \
    zip
  # Avoid linking system libopus dynamically; magnum-opus uses static opus from vcpkg.
  sudo apt-get remove -y libopus-dev 2>/dev/null || true
fi

mkdir -p .tools/downloads
python3 scripts/bootstrap-source.py
if [[ ! -x .tools/python/bin/python ]]; then
  python3 -m venv .tools/python
fi
.tools/python/bin/python -m pip install --upgrade pip
.tools/python/bin/python -m pip install 'pillow==12.3.0'

export CARGO_HOME="$task_root/.tools/cargo" RUSTUP_HOME="$task_root/.tools/rustup"
linux_rust="$(python3 -c 'import json; print(json.load(open("config/source-lock.json"))["rust"])')"
bridge_rust="$(python3 -c 'import json; print(json.load(open("config/source-lock.json"))["rust_macos"])')"
if [[ ! -x "$CARGO_HOME/bin/rustup" ]]; then
  curl --fail --location --proto '=https' --tlsv1.2 https://sh.rustup.rs -o .tools/downloads/rustup-init.sh
  sh .tools/downloads/rustup-init.sh -y --no-modify-path --profile minimal --default-toolchain "$linux_rust"
fi
export PATH="$CARGO_HOME/bin:$PATH"
rustup toolchain install "$linux_rust" --profile minimal --component rustfmt
rustup toolchain install "$bridge_rust" --profile minimal --component rustfmt

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

source scripts/env-linux.sh
python3 scripts/prepare.py
python3 scripts/prepare-sodium.py
python3 scripts/export-icons.py
python3 scripts/prepare-linux-tools.py

[[ -x "$VCPKG_ROOT/vcpkg" ]] || "$VCPKG_ROOT/bootstrap-vcpkg.sh" -disableMetrics
"$VCPKG_ROOT/vcpkg" install \
  --x-manifest-root="$task_root/config/linux-vcpkg" \
  --x-install-root="$VCPKG_ROOT/installed" \
  --triplet "$VCPKG_DEFAULT_TRIPLET" \
  --host-triplet "$VCPKG_DEFAULT_HOST_TRIPLET"

cargo_expand_ver="$(python3 -c 'import json; print(json.load(open("config/source-lock.json"))["cargo_expand"])')"
bridge_ver="$(python3 -c 'import json; print(json.load(open("config/source-lock.json"))["bridge_codegen"])')"
[[ -x "$CARGO_HOME/bin/cargo-expand" ]] || cargo +"$bridge_rust" install cargo-expand --version "$cargo_expand_ver" --locked
[[ -x "$CARGO_HOME/bin/flutter_rust_bridge_codegen" ]] || cargo +"$bridge_rust" install flutter_rust_bridge_codegen --version "$bridge_ver" --features uuid --locked

flutter config --enable-linux-desktop --no-analytics
flutter precache --linux
cp config/flutter-pubspec.lock upstream/flutter/pubspec.lock
(cd upstream/flutter && flutter pub get)

export RUST_LOG=info
llvm_args=()
if [[ -n "${LLVM_ROOT:-}" ]]; then
  llvm_args=(--llvm-path "$LLVM_ROOT")
fi
(cd upstream && flutter_rust_bridge_codegen \
  --rust-input src/flutter_ffi.rs \
  --dart-output flutter/lib/generated_bridge.dart \
  --c-output flutter/macos/Runner/bridge_generated.h \
  "${llvm_args[@]}")
cp upstream/flutter/macos/Runner/bridge_generated.h upstream/flutter/ios/Runner/bridge_generated.h
sed -i 's/ffi.NativeFunction<ffi.Bool Function(DartPort/ffi.NativeFunction<ffi.Uint8 Function(DartPort/g' upstream/flutter/lib/generated_bridge.dart

echo 'Preparação concluída. Execute: bash scripts/build-linux.sh both'

