"""Export the generated symbol to native platform icon sizes."""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
symbol = Image.open(ROOT / "branding/cf-link-symbol.png").convert("RGBA")
symbol.save(ROOT / "branding/cf-link.ico", sizes=[(s, s) for s in (16, 24, 32, 48, 64, 128, 256)])
for destination in ["res/icon.ico", "flutter/windows/runner/resources/app_icon.ico"]:
    (ROOT / "upstream" / destination).write_bytes((ROOT / "branding/cf-link.ico").read_bytes())
symbol.resize((1024, 1024), Image.Resampling.LANCZOS).save(ROOT / "upstream/flutter/macos/Runner/AppIcon.icns")
for density, size in [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]:
    folder = ROOT / "upstream/flutter/android/app/src/main/res" / f"mipmap-{density}"
    folder.mkdir(parents=True, exist_ok=True)
    symbol.resize((size, size), Image.Resampling.LANCZOS).save(folder / "ic_launcher.png")
    symbol.resize((size, size), Image.Resampling.LANCZOS).save(folder / "ic_launcher_round.png")
    symbol.resize((size // 2, size // 2), Image.Resampling.LANCZOS).save(folder / "ic_stat_logo.png")
    foreground_size = round(size * 108 / 48)
    artwork_size = round(foreground_size * 0.81)
    foreground = Image.new("RGBA", (foreground_size, foreground_size))
    artwork = symbol.resize((artwork_size, artwork_size), Image.Resampling.LANCZOS)
    margin = (foreground_size - artwork_size) // 2
    foreground.alpha_composite(artwork, (margin, margin))
    foreground.save(folder / "ic_launcher_foreground.png")
print("Windows ICO and macOS / Android icon sizes exported.")
wordmark = Image.open(ROOT / "branding/cf-link-wordmark.png").convert("RGBA")
wordmark.resize((96, 32), Image.Resampling.LANCZOS).save(ROOT / "upstream/libs/portable/src/res/label.png")
