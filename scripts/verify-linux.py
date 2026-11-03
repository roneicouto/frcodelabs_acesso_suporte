"""Smoke-check the packaged Debian (.deb) installers for Full and QS without installing them."""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def inspect_profile(profile: str):
    config = json.loads((ROOT / "config/client.json").read_text(encoding="utf-8"))
    version = config["version"]
    app_name = config["qs_app_name"] if profile == "qs" else config["full_app_name"]
    pkg_name = app_name.lower()
    profile_label = "QS" if profile == "qs" else "Full"

    deb_candidates = sorted((ROOT / "dist/linux").glob(f"{app_name}-{version}-*.deb"))
    if not deb_candidates:
        raise FileNotFoundError(f"Missing versioned .deb for profile={profile} in dist/linux/")
    deb_path = deb_candidates[0]
    arch = deb_path.stem.split("-")[-1]
    release_deb = ROOT / "dist/linux" / f"{config['full_app_name']}-Linux-{profile_label}-{arch}.deb"
    assert release_deb.is_file(), f"Missing release asset copy: {release_deb}"

    control_out = subprocess.check_output(["dpkg-deb", "-I", str(deb_path)], text=True)
    assert f"Package: {pkg_name}" in control_out, control_out
    assert f"Version: {version}" in control_out, control_out

    contents_out = subprocess.check_output(["dpkg-deb", "-c", str(deb_path)], text=True)
    assert f"./usr/share/{pkg_name}/{pkg_name}" in contents_out, contents_out
    assert f"./usr/share/{pkg_name}/lib/librustdesk.so" in contents_out, contents_out
    assert f"./usr/share/applications/{pkg_name}.desktop" in contents_out, contents_out
    assert f"./usr/share/{pkg_name}/LICENCE.txt" in contents_out, contents_out
    assert f"./usr/share/{pkg_name}/NOTICE.txt" in contents_out, contents_out

    if profile == "full":
        assert f"./usr/share/{pkg_name}/files/systemd/{pkg_name}.service" in contents_out, contents_out
    else:
        assert ".service" not in contents_out, f"QS package must not ship a systemd service:\n{contents_out}"

    with tempfile.TemporaryDirectory(prefix=f"verify-deb-{profile}-") as tmpdir:
        subprocess.run(["dpkg-deb", "-R", str(deb_path), tmpdir], check=True)
        tmp = Path(tmpdir)
        postinst = (tmp / "DEBIAN/postinst").read_text(encoding="utf-8")
        if profile == "full":
            assert f"systemctl enable {pkg_name}" in postinst, postinst
        else:
            assert "systemctl" not in postinst, postinst

        bin_bytes = (tmp / f"usr/share/{pkg_name}/{pkg_name}").read_bytes()
        assert pkg_name.encode("utf-8") in bin_bytes, f"Expected binary identity {pkg_name} in executable"

        assert (tmp / f"usr/share/{pkg_name}/lib/libapp.so").is_file(), "Missing Flutter AOT libapp.so"

        so_bytes = (tmp / f"usr/share/{pkg_name}/lib/librustdesk.so").read_bytes()
        assert b"rustdesk_core_main" in so_bytes, "Expected rustdesk_core_main symbol in librustdesk.so"
        assert b"hide-server-settings" in so_bytes, "Expected overlay settings in librustdesk.so"
        if profile == "qs":
            assert b"allow-only-conn-window-open" in so_bytes, "Expected QS restriction in librustdesk.so"
        else:
            assert b"only connects to IDs on the company server" in so_bytes, "Expected Full connection policy in librustdesk.so"

    print(f"{profile}: {deb_path.name} verified (package={pkg_name}, version={version}, arch={arch})")


if __name__ == "__main__":
    arg = sys.argv[1] if len(sys.argv) == 2 else "both"
    profiles = ["full", "qs"] if arg == "both" else [arg]
    for p in profiles:
        inspect_profile(p)

