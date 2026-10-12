#!/usr/bin/env bash
# Source this file; paths and versions stay scoped to the project.
task_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export CARGO_HOME="$task_root/.tools/cargo"
export RUSTUP_HOME="$task_root/.tools/rustup"
export RUSTUP_TOOLCHAIN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["rust_macos"])' "$task_root/config/source-lock.json")"
export PATH="$task_root/.tools/python/bin:$CARGO_HOME/bin:$task_root/.tools/flutter/bin:$PATH"
export VCPKG_ROOT="$task_root/.tools/vcpkg"
export VCPKG_DOWNLOADS="$task_root/.tools/downloads"
export MACOSX_DEPLOYMENT_TARGET="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["macos_minimum"])' "$task_root/config/source-lock.json")"
export FLUTTER_XCODE_MACOSX_DEPLOYMENT_TARGET="$MACOSX_DEPLOYMENT_TARGET"
export FLUTTER_XCODE_ARCHS="$(uname -m)"
export FLUTTER_XCODE_ONLY_ACTIVE_ARCH=YES
export COCOAPODS_DISABLE_STATS=true
export FLUTTER_SUPPRESS_ANALYTICS=true
export LIBCLANG_PATH="$(brew --prefix llvm)/lib"
export LLVM_ROOT="$(brew --prefix llvm)"
case "$(uname -m)" in
  arm64) export VCPKG_DEFAULT_TRIPLET=arm64-osx ;;
  x86_64) export VCPKG_DEFAULT_TRIPLET=x64-osx ;;
  *) echo 'Unsupported Mac architecture' >&2; return 1 ;;
esac
export VCPKG_DEFAULT_HOST_TRIPLET="$VCPKG_DEFAULT_TRIPLET"
export SODIUM_LIB_DIR="$VCPKG_ROOT/installed/$VCPKG_DEFAULT_TRIPLET/lib"
