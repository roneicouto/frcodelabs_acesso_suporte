"""Record only artifacts that actually exist, with hashes and build limits."""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
config = json.loads((ROOT / "config/client.json").read_text(encoding="utf-8"))
artifacts = []
for pattern in ["windows/*.exe", "android/*.apk", "macos/*.dmg", "*.zip"]:
    for file in sorted((ROOT / "dist").glob(pattern)):
        with file.open("rb") as stream:
            digest = hashlib.file_digest(stream, "sha256").hexdigest()
        version = re.search(rf"{re.escape(config.get('full_app_name', 'FRCodeLabs'))}(?:QS)?-(\d+\.\d+\.\d+)", file.name)
        artifacts.append({"file": file.relative_to(ROOT / "dist").as_posix(), "customization_version": version.group(1) if version else None, "bytes": file.stat().st_size, "sha256": digest})
manifest = {
    "product": config["product"],
    "customization_version": config["version"],
    "rustdesk_base": config["upstream_tag"],
    "id_server": config["id_server"],
    "relay_server": config["relay_server"],
    "artifacts": artifacts,
    "validation": {
        "windows_policy_tests": "2 tests passed in Full and 2 in QS",
        "windows_1.0.1_policy": "dark theme cannot be overwritten; QS temporary password length 8; password or local approval",
        "windows_1.0.2_legal_assets": "Full and QS packaged complete AGPL license, notices and customization metadata verified; dialog interaction requires pilot test",
        "windows_binary_smoke_test": "packaged DLL identity, installation restriction and executable version passed",
        "server_tcp_ports": "21115, 21116, 21117 reachable",
        "two_device_remote_session": "not tested",
        "android_physical_device": "not tested",
        "android_release": "APKs 1.0.0; later dark/password/legal UI changes not rebuilt for Android in this Windows pilot",
        "android_apk_signatures": "Full and QS APK Signature Scheme v2 verified",
        "android_package_identity": "Full and QS labels, separate package IDs and arm64-v8a verified",
        "android_native_alignment": "LOAD segments aligned to 16 KB",
        "macos_build": "requires a Mac or macOS runner; not built here",
    },
}
output = ROOT / "dist/release-manifest.json"
output.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
(ROOT / "dist/SHA256SUMS.txt").write_text("".join(f"{entry['sha256']}  {entry['file']}\n" for entry in artifacts), encoding="utf-8")
print(f"Recorded {len(artifacts)} actual artifacts in {output}")
