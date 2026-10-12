"""Fetch the exact upstream source for a checkout containing only the overlay."""
import json
import subprocess
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / "upstream"
lock = json.loads((root / "config/source-lock.json").read_text(encoding="utf-8"))
if not (source / "Cargo.toml").is_file():
    subprocess.run([
        "git", "clone", "--branch", lock["tag"], "--depth", "1",
        "https://github.com/rustdesk/rustdesk.git", str(source),
    ], check=True)
if (source / ".git").exists():
    commit = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source, text=True).strip()
    if commit != lock["commit"]:
        raise RuntimeError(f"Unexpected upstream commit: {commit}; expected {lock['commit']}")
    subprocess.run(["git", "submodule", "update", "--init", "--recursive"], cwd=source, check=True)
    common = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=source / "libs/hbb_common", text=True).strip()
    if common != lock["hbb_common_commit"]:
        raise RuntimeError(f"Unexpected hbb_common commit: {common}")
elif not (source / "libs/hbb_common/Cargo.toml").is_file():
    raise RuntimeError("Incomplete source archive: hbb_common is missing")
print(f"Source ready: RustDesk {lock['tag']} ({lock['commit']})")
