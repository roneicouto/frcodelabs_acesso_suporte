"""Smoke-check the actual packaged Windows DLLs without installing or opening UI."""
import ctypes
import os
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def inspect_profile(profile):
    folder = ROOT / "dist/windows" / profile
    os.add_dll_directory(str(folder))
    library = ctypes.CDLL(str(folder / "librustdesk.dll"))
    count = ctypes.c_int()
    library.rustdesk_core_main_args.argtypes = [ctypes.POINTER(ctypes.c_int)]
    library.rustdesk_core_main_args.restype = ctypes.POINTER(ctypes.c_void_p)
    arguments = library.rustdesk_core_main_args(ctypes.byref(count))
    if arguments:
        library.free_c_args.argtypes = [ctypes.POINTER(ctypes.c_void_p), ctypes.c_int]
        library.free_c_args(arguments, count)
    name = ctypes.create_unicode_buffer(256)
    library.get_rustdesk_app_name.argtypes = [ctypes.c_wchar_p, ctypes.c_int]
    assert library.get_rustdesk_app_name(name, 256) == 0
    expected = "CFLinkQS" if profile == "qs" else "CFLink"
    assert name.value == expected, name.value
    disabled = library.rustdesk_is_disable_installation()
    assert disabled == int(profile == "qs"), disabled
    result = subprocess.run([str(folder / f"{expected}.exe"), "--version"], capture_output=True, text=True, timeout=20)
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == "1.5.0", result.stdout
    print(f"{profile}: DLL loads; name={name.value}; installation_disabled={disabled}; base={result.stdout.strip()}")


if __name__ == "__main__":
    if len(sys.argv) == 2:
        inspect_profile(sys.argv[1])
    else:
        for profile in ["full", "qs"]:
            subprocess.run([sys.executable, __file__, profile], check=True)
