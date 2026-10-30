"""Apply the app bundle identity for the selected macOS profile."""
import argparse
import json
import re
from prepare import ROOT, SOURCE, write_if_changed

parser = argparse.ArgumentParser()
parser.add_argument("profile", choices=["full", "qs"])
args = parser.parse_args()
config = json.loads((ROOT / "config/client.json").read_text(encoding="utf-8"))
lock = json.loads((ROOT / "config/source-lock.json").read_text(encoding="utf-8"))
name = config[f"{args.profile}_app_name"]
folder = SOURCE / "flutter/macos/Runner"
settings = folder / "Configs/AppInfo.xcconfig"
text = settings.read_text(encoding="utf-8")
text = re.sub(r'^PRODUCT_NAME = .*$', f'PRODUCT_NAME = {name}', text, flags=re.M)
text = re.sub(r'^PRODUCT_BUNDLE_IDENTIFIER = .*$', f'PRODUCT_BUNDLE_IDENTIFIER = com.carriez.{name}', text, flags=re.M)
write_if_changed(settings, text)
plist = folder / "Info.plist"
text = plist.read_text(encoding="utf-8")
text = re.sub(r'(<key>CFBundleURLName</key>\s*<string>).*?(</string>)', rf'\g<1>com.carriez.{name}\g<2>', text)
text = re.sub(r'(<key>CFBundleURLSchemes</key>\s*<array>\s*<string>).*?(</string>)', rf'\g<1>{name.lower()}\g<2>', text)
write_if_changed(plist, text)
minimum = lock["macos_minimum"]
for path, pattern, replacement in [
    (SOURCE / "flutter/macos/Podfile", r"platform :osx, '[0-9.]+'", f"platform :osx, '{minimum}'"),
    (SOURCE / "flutter/macos/Runner.xcodeproj/project.pbxproj", r'MACOSX_DEPLOYMENT_TARGET = [0-9.]+;', f'MACOSX_DEPLOYMENT_TARGET = {minimum};'),
    (SOURCE / "Cargo.toml", r'osx_minimum_system_version = "[0-9.]+"', f'osx_minimum_system_version = "{minimum}"'),
]:
    original = path.read_text(encoding="utf-8")
    if not re.search(pattern, original):
        raise RuntimeError(f"Missing macOS deployment target in {path}")
    write_if_changed(path, re.sub(pattern, replacement, original))
print(f"macOS {args.profile}: {name}.app")
