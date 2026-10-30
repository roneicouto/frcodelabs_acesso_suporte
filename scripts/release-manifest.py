"""Record only artifacts that actually exist, with hashes and build limits."""
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
config = json.loads((ROOT / "config/client.json").read_text(encoding="utf-8"))
artifacts = []
for pattern in ["windows/*.exe", "windows/*.dmg", "android/*.apk", "macos/*.dmg", "*.zip"]:
    for file in sorted((ROOT / "dist").glob(pattern)):
        with file.open("rb") as stream:
            digest = hashlib.file_digest(stream, "sha256").hexdigest()
        version = re.search(rf"{re.escape(config.get('full_app_name', 'FRCodeLabs'))}(?:QS)?-(\d+\.\d+\.\d+)", file.name, re.IGNORECASE)
        artifacts.append({"file": file.relative_to(ROOT / "dist").as_posix(), "customization_version": version.group(1) if version else config["version"], "bytes": file.stat().st_size, "sha256": digest})
manifest = {
    "product": config["product"],
    "customization_version": config["version"],
    "rustdesk_base": config["upstream_tag"],
    "update_repository": config["update_repository"],
    "artifacts": artifacts,
    "validation": {
        "windows_1.0.13_peers": "Four Full native tests passed: connection policy, embedded settings, saved-password/adaptive migration, and peer storage without Documents. Dart/Rust probe reads existing peers with empty Documents; Full/QS native libraries rebuilt.",
        "windows_1.0.12_recovery": "Missing service invokes existing native registration automatically; persistent two-minute restart-loop guard and explicit manual retry.",
        "windows_1.0.11_service": "Full installed service check/start with conditional UAC; missing/mismatched service offers original native repair. QS and portable excluded.",
        "windows_1.0.10_startup": "Initial update check bypasses 24-hour throttle; periodic background checks retain it.",
        "windows_1.0.8_installer": "Full package opens installer independent of download filename; QS remains portable.",
        "windows_1.0.7_hotfix": "PowerShell startup uses normal Dart child process with diagnostic pipes; updater survives parent exit.",
        "windows_policy_tests": "4 tests passed in Full and 3 in QS",
        "windows_1.0.5_updates": "8 Dart tests passed; 3 isolated PowerShell scenarios passed (Full/QS portable replacement/restart/backup and corrupt-file rejection)",
        "windows_1.0.4_main_version": "Full and QS home-screen version label analyzed; packaged customization metadata and notices checked",
        "windows_1.0.3_policy": "dark fixed; standard receiving password plus visible 8-character temporary password or local approval; adaptive migration; outbound Remember Password supported",
        "windows_1.0.3_updates": "5 tests passed for semantic version comparison, platform/profile selection, mixed versions, release filtering and URL validation",
        "windows_1.0.2_legal_assets": "Full and QS packaged complete AGPL license, notices and customization metadata verified",
        "windows_binary_smoke_test": "packaged DLL identity, installation restriction and executable version passed",
        "server_tcp_ports": "21115, 21116, 21117 reachable",
    },
}
output = ROOT / "dist/release-manifest.json"
output.write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
(ROOT / "dist/SHA256SUMS.txt").write_text("".join(f"{entry['sha256']}  {entry['file']}\n" for entry in artifacts), encoding="utf-8")
print(f"Recorded {len(artifacts)} actual artifacts in {output}")
