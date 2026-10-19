#!/usr/bin/env bash
# Run setup-macos.sh once before building.
set -euo pipefail
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'macOS compilation requires a Mac or a macOS runner.' >&2
  exit 1
fi
task_root="$(cd "$(dirname "$0")/.." && pwd)"
build_profile="${1:-both}"
case "$build_profile" in full|qs|both) ;; *) echo 'Expected full, qs or both' >&2; exit 1 ;; esac
cd "$task_root"
[[ -x .tools/python/bin/python3 && -x .tools/flutter/bin/flutter ]] || { echo 'Execute primeiro: bash scripts/setup-macos.sh' >&2; exit 1; }
source scripts/env-macos.sh
python3 scripts/prepare.py
python3 scripts/prepare-sodium.py
mac_arch="$(uname -m)"
app_version="$(python3 -c 'import json; print(json.load(open("config/client.json"))["version"])')"
[[ -f upstream/flutter/macos/Runner/bridge_generated.h ]] || { echo 'Bridge ausente; execute setup-macos.sh novamente.' >&2; exit 1; }
profiles=full
if [[ "$build_profile" == both ]]; then profiles='full qs'; else profiles="$build_profile"; fi
for current_profile in $profiles; do
  python3 scripts/prepare-macos.py "$current_profile"
  app_name="$(python3 -c 'import json,sys; print(json.load(open("config/client.json"))[sys.argv[1]+"_app_name"])' "$current_profile")"
  cd upstream
  cargo build --locked --release --lib --bin service --features "flutter,cf-$current_profile"
  cd flutter
  flutter build macos --release --build-name "$app_version" --build-number 1
  app_path="build/macos/Build/Products/Release/$app_name.app"
  cp ../target/release/service "$app_path/Contents/MacOS/service"
  cp ../LICENCE "$app_path/Contents/Resources/LICENCE.txt"
  cp ../../docs/NOTICE.txt "$app_path/Contents/Resources/NOTICE.txt"
  codesign --force --deep --sign - "$app_path"
  codesign --verify --deep --strict "$app_path"
  test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleName' "$app_path/Contents/Info.plist")" = "$app_name"
  lipo "$app_path/Contents/MacOS/$app_name" -verify_arch "$mac_arch"
  lipo "$app_path/Contents/Frameworks/liblibrustdesk.dylib" -verify_arch "$mac_arch"
  mkdir -p "$task_root/dist/macos/$current_profile"
  ditto "$app_path" "$task_root/dist/macos/$current_profile/$app_name.app"
  ln -sfn /Applications "$task_root/dist/macos/$current_profile/Applications"
  dmg="$task_root/dist/macos/$app_name-$app_version-$mac_arch.dmg"
  hdiutil create -volname "$app_name" -srcfolder "$task_root/dist/macos/$current_profile" -ov -format UDZO "$dmg"
  hdiutil verify "$dmg"
  (cd "$task_root/dist/macos" && shasum -a 256 "$(basename "$dmg")" > "$(basename "$dmg").sha256")
  cd "$task_root"
done
