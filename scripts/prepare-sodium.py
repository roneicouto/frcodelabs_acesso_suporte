"""Make libsodium-sys select Android libraries separately from Windows host tools."""
import json
import re
import shutil
import subprocess
from pathlib import Path
from prepare import ROOT, SOURCE, replace_once, write_if_changed

destination = ROOT / "vendor/libsodium-sys"
if not destination.exists():
    metadata = json.loads(subprocess.check_output(["cargo", "metadata", "--format-version", "1", "--manifest-path", str(SOURCE / "Cargo.toml")]))
    package = next(package for package in metadata["packages"] if package["name"] == "libsodium-sys")
    shutil.copytree(Path(package["manifest_path"]).parent, destination)
build = destination / "build.rs"
replace_once(build, '    let lib_dir_isset = env::var("SODIUM_LIB_DIR").is_ok();', '''    let target = env::var("TARGET").unwrap_or_default();
    let target_key = format!("SODIUM_LIB_DIR_{}", target.replace('-', "_"));
    println!("cargo:rerun-if-env-changed={}", target_key);
    if let Ok(lib_dir) = env::var(&target_key) {
        env::set_var("SODIUM_LIB_DIR", lib_dir);
    }
    let lib_dir_isset = env::var("SODIUM_LIB_DIR").is_ok();''')
replace_once(build, '    let name = if cfg!(target_env = "msvc") {', '    let name = if env::var("TARGET").map_or(false, |target| target.contains("msvc")) {')
replace_once(SOURCE / "Cargo.toml", '[patch.crates-io]\n', '[patch.crates-io]\nlibsodium-sys = { path = "../vendor/libsodium-sys" }\n')
lock = SOURCE / "Cargo.lock"
text = lock.read_text(encoding="utf-8")
text = re.sub(r'(name = "libsodium-sys"\nversion = "0.2.7"\n)source = "[^"\n]+"\nchecksum = "[^"\n]+"\n', r'\1', text)
write_if_changed(lock, text)
print("libsodium-sys host/Android library selection patched; runtime API unchanged.")
