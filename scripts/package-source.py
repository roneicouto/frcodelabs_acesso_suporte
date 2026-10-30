"""Package source and build instructions without tool caches or credentials."""
import json
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "upstream"
config = json.loads((ROOT / "config/client.json").read_text(encoding="utf-8"))
output = ROOT / "dist" / f"{config.get('full_app_name', 'FRCodeLabs')}-{config['version']}-source.zip"
output.parent.mkdir(parents=True, exist_ok=True)


def tracked_files(folder):
    result = subprocess.check_output(["git", "ls-files", "-z"], cwd=folder).decode("utf-8")
    return [folder / path for path in result.split("\0") if path and (folder / path).is_file()]


files = set(tracked_files(SOURCE))
files.update(tracked_files(SOURCE / "libs/hbb_common"))
files.update(SOURCE.glob("flutter/test/cf_service_recovery_test.dart"))
for pattern in ["libs/portable/src/cf_installer.rs", "src/cf_link.rs", "src/bridge_generated*.rs", "src/version.rs", "flutter/lib/generated_bridge*", "flutter/lib/cf_*.dart", "flutter/test/cf_update_test.dart", "flutter/assets/cf_*", "flutter/assets/logo*.png", "flutter/assets/icon.png", "flutter/macos/Runner/bridge_generated.h", "flutter/ios/Runner/bridge_generated.h"]:
    files.update(SOURCE.glob(pattern))
for folder in ["scripts", "config", "docs", "branding", "vendor"]:
    files.update(path for path in (ROOT / folder).rglob("*") if path.is_file() and "__pycache__" not in path.parts)
files.update([ROOT / "README.md", ROOT / "LICENCE", ROOT / "assets/id_ed25519.pub", ROOT / ".gitignore", ROOT / ".gitattributes"])
temporary = output.with_suffix(".tmp.zip")
with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6, strict_timestamps=False) as archive:
    for file in sorted(files):
        if file.is_file():
            archive.write(file, "fr-code-labs/" + file.relative_to(ROOT).as_posix())
temporary.replace(output)
print(f"Corresponding project source: {output}")
