"""Apply upstream Flutter workarounds only to the project-owned SDK."""
import subprocess
from pathlib import Path
from prepare import replace_once

root = Path(__file__).resolve().parents[1]
sdk = root / ".tools/flutter"
patch = root / "upstream/.github/patches/flutter_3.24.4_dropdown_menu_enableFilter.diff"
applied = subprocess.run(["git", "apply", "--reverse", "--check", str(patch)], cwd=sdk, capture_output=True).returncode == 0
if not applied:
    subprocess.run(["git", "apply", "--check", str(patch)], cwd=sdk, check=True)
    subprocess.run(["git", "apply", str(patch)], cwd=sdk, check=True)
replace_once(
    sdk / "packages/flutter/lib/src/scheduler/binding.dart",
    "        _setFramesEnabledState(false);",
    "        // CF Link: upstream workaround for Flutter issue 133533.\n        // _setFramesEnabledState(false);",
)
print("Private macOS Flutter SDK prepared.")
