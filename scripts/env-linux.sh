#!/usr/bin/env bash
# Source this file; paths and versions stay scoped to the project.
task_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export CARGO_HOME="$task_root/.tools/cargo"
export RUSTUP_HOME="$task_root/.tools/rustup"
export RUSTUP_TOOLCHAIN="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["rust"])' "$task_root/config/source-lock.json")"

export PATH="$task_root/.tools/python/bin:$CARGO_HOME/bin:$task_root/.tools/flutter/bin:$PATH"
export VCPKG_ROOT="$task_root/.tools/vcpkg"
export VCPKG_DOWNLOADS="$task_root/.tools/downloads"
export FLUTTER_SUPPRESS_ANALYTICS=true

llvm_root=""
if command -v llvm-config >/dev/null 2>&1; then
  llvm_root="$(llvm-config --prefix 2>/dev/null || true)"
fi
if [[ -z "$llvm_root" || ! -d "$llvm_root/lib" ]]; then
  llvm_root="$(ls -d /usr/lib/llvm-* 2>/dev/null | sort -V | tail -n1 || true)"
fi
if [[ -n "$llvm_root" && -d "$llvm_root/lib" ]]; then
  export LLVM_ROOT="$llvm_root"
  export LIBCLANG_PATH="$llvm_root/lib"
fi

case "$(uname -m)" in
  x86_64)
    export VCPKG_DEFAULT_TRIPLET=x64-linux
    export DEB_ARCH=amd64
    export FLUTTER_LINUX_ARCH=x64
    ;;
  aarch64|arm64)
    export VCPKG_DEFAULT_TRIPLET=arm64-linux
    export DEB_ARCH=arm64
    export FLUTTER_LINUX_ARCH=arm64
    ;;
  *)
    echo "Unsupported Linux architecture: $(uname -m)" >&2
    return 1
    ;;
esac
export VCPKG_DEFAULT_HOST_TRIPLET="$VCPKG_DEFAULT_TRIPLET"
export SODIUM_LIB_DIR="$VCPKG_ROOT/installed/$VCPKG_DEFAULT_TRIPLET/lib"

