"""Apply the binary and GTK application identity for the selected Linux profile."""
import argparse
import json
import re
from prepare import ROOT, SOURCE, write_if_changed

parser = argparse.ArgumentParser()
parser.add_argument("profile", choices=["full", "qs"])
args = parser.parse_args()

config = json.loads((ROOT / "config/client.json").read_text(encoding="utf-8"))
app_name = config[f"{args.profile}_app_name"]
bin_name = app_name.lower()
app_id = config.get(f"android_{args.profile}_package", f"com.frcodelabs.remote.{args.profile}")
visible_title = f"{config['product']} QS" if args.profile == "qs" else config["product"]

cmake_file = SOURCE / "flutter/linux/CMakeLists.txt"
cmake_text = cmake_file.read_text(encoding="utf-8")
cmake_text, n_bin = re.subn(r'^set\(BINARY_NAME "[^"]+"\)$', f'set(BINARY_NAME "{bin_name}")', cmake_text, flags=re.M)
cmake_text, n_id = re.subn(r'^set\(APPLICATION_ID "[^"]+"\)$', f'set(APPLICATION_ID "{app_id}")', cmake_text, flags=re.M)
if n_bin != 1 or n_id != 1:
    raise RuntimeError(f"Unexpected CMakeLists.txt structure in {cmake_file} (BINARY_NAME={n_bin}, APPLICATION_ID={n_id})")
write_if_changed(cmake_file, cmake_text)

app_cc = SOURCE / "flutter/linux/my_application.cc"
cc_text = app_cc.read_text(encoding="utf-8")
cc_text, n_icon = re.subn(
    r'gtk_icon_theme_load_icon\(theme, "[^"]+",',
    f'gtk_icon_theme_load_icon(theme, "{bin_name}",',
    cc_text,
)
cc_text, n_hbar = re.subn(
    r'gtk_header_bar_set_title\(header_bar, "[^"]+"\);',
    f'gtk_header_bar_set_title(header_bar, "{visible_title}");',
    cc_text,
)
cc_text, n_win = re.subn(
    r'gtk_window_set_title\(window, "[^"]+"\);',
    f'gtk_window_set_title(window, "{visible_title}");',
    cc_text,
)
if n_icon != 1 or n_hbar != 1 or n_win != 1:
    raise RuntimeError(f"Unexpected my_application.cc structure in {app_cc} (icon={n_icon}, hbar={n_hbar}, win={n_win})")
write_if_changed(app_cc, cc_text)

print(f"Linux {args.profile}: binary={bin_name}, app_id={app_id}, title={visible_title}")

