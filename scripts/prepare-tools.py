"""Compatibility patches confined to the project's own Flutter SDK."""
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SDK = ROOT / ".tools/flutter"
source = SDK / "packages/flutter_tools/lib/src/windows/visual_studio.dart"
text = source.read_text(encoding="utf-8")
if "18 => 'Visual Studio 18 2026'" not in text:
    old = "17 => 'Visual Studio 17 2022',"
    if text.count(old) != 1:
        raise RuntimeError("Unexpected Flutter Visual Studio detector")
    source.write_text(text.replace(old, "18 => 'Visual Studio 18 2026',\n      " + old), encoding="utf-8")
    snapshot = SDK / "bin/cache/flutter_tools.snapshot"
    if snapshot.is_file():
        snapshot.unlink()
patch = ROOT / "upstream/.github/patches/flutter_3.24.4_dropdown_menu_enableFilter.diff"
applied = subprocess.run(["git", "apply", "--reverse", "--check", str(patch)], cwd=SDK, capture_output=True).returncode == 0
if not applied:
    subprocess.run(["git", "apply", "--check", str(patch)], cwd=SDK, check=True)
    subprocess.run(["git", "apply", str(patch)], cwd=SDK, check=True)
print("Private Flutter SDK prepared for VS 2026 and the upstream dropdown patch.")
plugins = SDK / "packages/flutter_tools/lib/src/flutter_plugins.dart"
text = plugins.read_text(encoding="utf-8")
marker = "// CF Link: use directory junctions when Windows symlink privilege is absent."
if marker not in text:
    old = """    } on FileSystemException catch (e) {
      handleSymlinkException("""
    new = """    } on FileSystemException catch (e) {
      // CF Link: use directory junctions when Windows symlink privilege is absent.
      if (globals.platform.isWindows && e.osError?.errorCode == 1314) {
        final junction = globals.processManager.runSync(<String>[
          'cmd.exe', '/c', 'mklink', '/J', link.path, path,
        ]);
        if (junction.exitCode == 0) {
          continue;
        }
      }
      handleSymlinkException("""
    if text.count(old) != 1:
        raise RuntimeError("Unexpected Flutter plugin symlink handler")
    plugins.write_text(text.replace(old, new), encoding="utf-8")
    snapshot = SDK / "bin/cache/flutter_tools.snapshot"
    if snapshot.is_file():
        snapshot.unlink()
print("Private Flutter SDK can create plugin junctions without changing Windows Developer Mode.")
