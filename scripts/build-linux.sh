#!/usr/bin/env bash
# Run setup-linux.sh once before building.
set -euo pipefail
if [[ "$(uname -s)" != Linux ]]; then
  echo 'Linux compilation requires a Linux machine or runner.' >&2
  exit 1
fi
task_root="$(cd "$(dirname "$0")/.." && pwd)"
build_profile="${1:-both}"
case "$build_profile" in full|qs|both) ;; *) echo 'Expected full, qs or both' >&2; exit 1 ;; esac
cd "$task_root"
[[ -x .tools/python/bin/python3 && -x .tools/flutter/bin/flutter ]] || { echo 'Execute primeiro: bash scripts/setup-linux.sh' >&2; exit 1; }

source scripts/env-linux.sh
python3 scripts/prepare.py
python3 scripts/prepare-sodium.py
python3 scripts/export-icons.py

[[ -f upstream/flutter/lib/generated_bridge.dart ]] || { echo 'Bridge ausente; execute setup-linux.sh novamente.' >&2; exit 1; }
sed -i 's/ffi.NativeFunction<ffi.Bool Function(DartPort/ffi.NativeFunction<ffi.Uint8 Function(DartPort/g' upstream/flutter/lib/generated_bridge.dart

app_version="$(python3 -c 'import json; print(json.load(open("config/client.json"))["version"])')"
base_full_name="$(python3 -c 'import json; print(json.load(open("config/client.json"))["full_app_name"])')"
company_name="$(python3 -c 'import json; print(json.load(open("config/client.json"))["company"])')"
product_name="$(python3 -c 'import json; print(json.load(open("config/client.json"))["product"])')"

if [[ "$build_profile" == both ]]; then
  profiles='full qs'
else
  profiles="$build_profile"
fi

mkdir -p "$task_root/dist/linux"

for current_profile in $profiles; do
  python3 scripts/prepare-linux.py "$current_profile"
  app_name="$(python3 -c 'import json,sys; print(json.load(open("config/client.json"))[sys.argv[1]+"_app_name"])' "$current_profile")"
  pkg_name="$(printf '%s' "$app_name" | tr '[:upper:]' '[:lower:]')"
  if [[ "$current_profile" == qs ]]; then
    visible_name="${product_name} QS"
    profile_label="QS"
    pkg_desc="${product_name} Quick Support - Cliente de suporte remoto (somente recebimento)"
  else
    visible_name="${product_name}"
    profile_label="Full"
    pkg_desc="${product_name} - Cliente completo de suporte remoto"
  fi

  cd "$task_root/upstream"
  cargo build --locked --release --lib --features "flutter,unix-file-copy-paste,cf-$current_profile"

  cd "$task_root/upstream/flutter"
  rm -rf "build/linux/$FLUTTER_LINUX_ARCH/release/bundle"
  flutter build linux --release --build-name "$app_version" --build-number 1

  bundle_dir="build/linux/$FLUTTER_LINUX_ARCH/release/bundle"
  cp -f ../target/release/liblibrustdesk.so "$bundle_dir/lib/librustdesk.so"
  strip --strip-debug "$bundle_dir/lib/librustdesk.so" || true
  [[ -x "$bundle_dir/$pkg_name" ]] || { echo "Binário esperado não encontrado: $bundle_dir/$pkg_name" >&2; exit 1; }
  [[ -f "$bundle_dir/lib/librustdesk.so" ]] || { echo "Biblioteca nativa não encontrada: $bundle_dir/lib/librustdesk.so" >&2; exit 1; }

  stage_dir="$task_root/dist/linux/stage-$current_profile"
  rm -rf "$stage_dir"
  mkdir -p \
    "$stage_dir/DEBIAN" \
    "$stage_dir/usr/bin" \
    "$stage_dir/usr/share/$pkg_name" \
    "$stage_dir/usr/share/applications" \
    "$stage_dir/usr/share/icons/hicolor/32x32/apps" \
    "$stage_dir/usr/share/icons/hicolor/64x64/apps" \
    "$stage_dir/usr/share/icons/hicolor/128x128/apps" \
    "$stage_dir/usr/share/icons/hicolor/256x256/apps"

  cp -a "$bundle_dir/." "$stage_dir/usr/share/$pkg_name/"
  cp "$task_root/LICENCE" "$stage_dir/usr/share/$pkg_name/LICENCE.txt"
  cp "$task_root/docs/NOTICE.txt" "$stage_dir/usr/share/$pkg_name/NOTICE.txt"

  cp "$task_root/upstream/res/32x32.png" "$stage_dir/usr/share/icons/hicolor/32x32/apps/$pkg_name.png"
  cp "$task_root/upstream/res/64x64.png" "$stage_dir/usr/share/icons/hicolor/64x64/apps/$pkg_name.png"
  cp "$task_root/upstream/res/128x128.png" "$stage_dir/usr/share/icons/hicolor/128x128/apps/$pkg_name.png"
  cp "$task_root/upstream/res/128x128@2x.png" "$stage_dir/usr/share/icons/hicolor/256x256/apps/$pkg_name.png"

  cat > "$stage_dir/usr/share/applications/$pkg_name.desktop" <<EOF
[Desktop Entry]
Name=$visible_name
GenericName=Suporte Remoto
Comment=$pkg_desc
Exec=/usr/bin/$pkg_name %u
Icon=$pkg_name
Terminal=false
Type=Application
StartupNotify=true
Categories=Network;RemoteAccess;GTK;
Keywords=suporte;remoto;frcodelabs;linux;
StartupWMClass=$pkg_name
EOF

  if [[ "$current_profile" == full ]]; then
    mkdir -p "$stage_dir/usr/share/$pkg_name/files/systemd"
    cat > "$stage_dir/usr/share/$pkg_name/files/systemd/$pkg_name.service" <<EOF
[Unit]
Description=$visible_name Service
Requires=network.target
After=systemd-user-sessions.service

[Service]
Type=simple
ExecStart=/usr/bin/$pkg_name --service
ExecStop=/usr/bin/pkill -f "$pkg_name --"
PIDFile=/run/$pkg_name.pid
KillMode=mixed
TimeoutStopSec=30
User=root
LimitNOFILE=100000
Environment="PULSE_LATENCY_MSEC=60" "PIPEWIRE_LATENCY=1024/48000"

[Install]
WantedBy=multi-user.target
EOF

    cat > "$stage_dir/usr/share/$pkg_name/files/polkit" <<'EOF'
#!/bin/sh
EOF
    chmod 0755 "$stage_dir/usr/share/$pkg_name/files/polkit"

    cat > "$stage_dir/usr/share/applications/$pkg_name-link.desktop" <<EOF
[Desktop Entry]
Name=$visible_name
NoDisplay=true
MimeType=x-scheme-handler/$pkg_name;
TryExec=/usr/bin/$pkg_name
Exec=/usr/bin/$pkg_name %u
Icon=$pkg_name
Terminal=false
Type=Application
StartupNotify=false
StartupWMClass=$pkg_name
EOF

    cat > "$stage_dir/DEBIAN/preinst" <<EOF
#!/bin/bash
set -e
case "\${1:-}" in
  install|upgrade)
    if [ -d /run/systemd/system ]; then
      systemctl stop $pkg_name >/dev/null 2>&1 || true
      sleep 1
    fi
    ;;
esac
exit 0
EOF

    cat > "$stage_dir/DEBIAN/postinst" <<EOF
#!/bin/bash
set -e
if [ "\${1:-}" = configure ]; then
  ln -f -s /usr/share/$pkg_name/$pkg_name /usr/bin/$pkg_name
  if [ -d /run/systemd/system ]; then
    rm -f /etc/systemd/system/$pkg_name.service /usr/lib/systemd/system/$pkg_name.service /usr/lib/systemd/user/$pkg_name.service >/dev/null 2>&1 || true
    mkdir -p /usr/lib/systemd/system/
    cp /usr/share/$pkg_name/files/systemd/$pkg_name.service /usr/lib/systemd/system/$pkg_name.service
    systemctl daemon-reload || true
    systemctl enable $pkg_name || true
    systemctl start $pkg_name || true
  fi
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database -q /usr/share/applications || true
  command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi
exit 0
EOF

    cat > "$stage_dir/DEBIAN/prerm" <<EOF
#!/bin/bash
set -e
case "\${1:-}" in
  remove|upgrade)
    rm -f /usr/bin/$pkg_name
    if [ -d /run/systemd/system ]; then
      systemctl stop $pkg_name >/dev/null 2>&1 || true
      systemctl disable $pkg_name >/dev/null 2>&1 || true
      rm -f /etc/systemd/system/$pkg_name.service /usr/lib/systemd/system/$pkg_name.service /usr/lib/systemd/user/$pkg_name.service >/dev/null 2>&1 || true
      systemctl daemon-reload >/dev/null 2>&1 || true
    fi
    ;;
esac
exit 0
EOF

    cat > "$stage_dir/DEBIAN/postrm" <<EOF
#!/bin/bash
set -e
case "\${1:-}" in
  purge)
    rm -rf /root/.config/$pkg_name || true
    ;;
esac
exit 0
EOF
    chmod 0755 "$stage_dir/DEBIAN/preinst" "$stage_dir/DEBIAN/postinst" "$stage_dir/DEBIAN/prerm" "$stage_dir/DEBIAN/postrm"
  else
    cat > "$stage_dir/DEBIAN/postinst" <<EOF
#!/bin/bash
set -e
if [ "\${1:-}" = configure ]; then
  ln -f -s /usr/share/$pkg_name/$pkg_name /usr/bin/$pkg_name
  command -v update-desktop-database >/dev/null 2>&1 && update-desktop-database -q /usr/share/applications || true
  command -v gtk-update-icon-cache >/dev/null 2>&1 && gtk-update-icon-cache -q -t -f /usr/share/icons/hicolor || true
fi
exit 0
EOF

    cat > "$stage_dir/DEBIAN/prerm" <<EOF
#!/bin/bash
set -e
case "\${1:-}" in
  remove|upgrade)
    rm -f /usr/bin/$pkg_name
    pkill -f "/usr/share/$pkg_name/$pkg_name" >/dev/null 2>&1 || true
    ;;
esac
exit 0
EOF

    cat > "$stage_dir/DEBIAN/postrm" <<EOF
#!/bin/bash
set -e
case "\${1:-}" in
  purge)
    rm -rf /root/.config/$pkg_name || true
    ;;
esac
exit 0
EOF
    chmod 0755 "$stage_dir/DEBIAN/postinst" "$stage_dir/DEBIAN/prerm" "$stage_dir/DEBIAN/postrm"
  fi

  installed_kb="$(du -sk "$stage_dir/usr" | awk '{print $1}')"
  cat > "$stage_dir/DEBIAN/control" <<EOF
Package: $pkg_name
Section: net
Priority: optional
Version: $app_version
Architecture: $DEB_ARCH
Installed-Size: $installed_kb
Maintainer: $company_name <suporte@frcodelabs.com>
Depends: libgtk-3-0t64 | libgtk-3-0, libxcb-randr0, libxdo3 | libxdo4, libxfixes3, libxcb-shape0, libxcb-xfixes0, libasound2t64 | libasound2, libpulse0, libsystemd0, curl, libva2, libva-drm2, libva-x11-2, libgstreamer-plugins-base1.0-0, gstreamer1.0-pipewire
Recommends: libayatana-appindicator3-1 | libappindicator3-1
Description: $pkg_desc
 Cliente personalizado da $company_name baseado no RustDesk $app_version para distribuicoes Debian, Ubuntu e Linux Mint.
EOF

  (
    cd "$stage_dir"
    find usr -type f -exec md5sum {} + | LC_ALL=C sort -k2 > DEBIAN/md5sums
  )
  chmod 0644 "$stage_dir/DEBIAN/control" "$stage_dir/DEBIAN/md5sums"

  deb_versioned="$task_root/dist/linux/${app_name}-${app_version}-${DEB_ARCH}.deb"
  deb_release="$task_root/dist/linux/${base_full_name}-Linux-${profile_label}-${DEB_ARCH}.deb"
  dpkg-deb --root-owner-group -b "$stage_dir" "$deb_versioned"
  cp "$deb_versioned" "$deb_release"
  (
    cd "$task_root/dist/linux"
    sha256sum "$(basename "$deb_versioned")" > "$(basename "$deb_versioned").sha256"
    sha256sum "$(basename "$deb_release")" > "$(basename "$deb_release").sha256"
  )
  rm -rf "$stage_dir"
  cd "$task_root"
done

