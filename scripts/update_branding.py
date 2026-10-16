import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
BRANDING_DIR = ROOT / "branding"
FR_DIR = BRANDING_DIR / "frcodelabs"

def process_symbol():
    logo_path = FR_DIR / "logo.png"
    if not logo_path.exists():
        logo_path = FR_DIR / "logo_big.png"
    
    im = Image.open(logo_path).convert("RGBA")
    bbox = im.getbbox()
    if bbox:
        cropped = im.crop(bbox)
    else:
        cropped = im
        
    target_size = 1024
    symbol = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
    
    max_dim = 800
    w, h = cropped.size
    scale = max_dim / max(w, h)
    new_w, new_h = int(w * scale), int(h * scale)
    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    
    offset_x = (target_size - new_w) // 2
    offset_y = (target_size - new_h) // 2
    symbol.paste(resized, (offset_x, offset_y), resized)
    
    symbol_path = BRANDING_DIR / "cf-link-symbol.png"
    symbol.save(symbol_path, "PNG")
    print(f"Saved symbol to {symbol_path}")
    return symbol, cropped

def process_wordmark(cropped_symbol):
    # Proporção aproximada 3:1 (largura 900 x altura 300)
    w_total = 960
    h_total = 320
    wordmark = Image.new("RGBA", (w_total, h_total), (0, 0, 0, 0))
    
    # Redimensiona o símbolo para ocupar altura de ~240px
    s_h = 240
    scale = s_h / cropped_symbol.height
    s_w = int(cropped_symbol.width * scale)
    sym_resized = cropped_symbol.resize((s_w, s_h), Image.Resampling.LANCZOS)
    
    # Cola o símbolo na esquerda com margem
    pad_left = 30
    sym_y = (h_total - s_h) // 2
    wordmark.paste(sym_resized, (pad_left, sym_y), sym_resized)
    
    # Desenha o texto "FR CODE LABS" à direita
    draw = ImageDraw.Draw(wordmark)
    
    font = None
    font_paths = [
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        "/usr/share/fonts/truetype/freefont/FreeSansBold.ttf",
    ]
    for fp in font_paths:
        if os.path.exists(fp):
            try:
                font = ImageFont.truetype(fp, 76)
                break
            except Exception:
                pass
    if font is None:
        font = ImageFont.load_default()
        
    text = "FR CODE LABS"
    text_x = pad_left + s_w + 35
    
    # Calcular altura do texto para centralizar verticalmente com o símbolo
    try:
        t_bbox = draw.textbbox((0, 0), text, font=font)
        t_h = t_bbox[3] - t_bbox[1]
    except Exception:
        t_h = 60
        
    text_y = (h_total - t_h) // 2 - 5
    # Cor grafite / preto moderno do tema (#111827)
    draw.text((text_x, text_y), text, fill=(17, 24, 39, 255), font=font)
    
    wordmark_path = BRANDING_DIR / "cf-link-wordmark.png"
    wordmark.save(wordmark_path, "PNG")
    print(f"Saved wordmark to {wordmark_path}")

def process_ico(symbol):
    ico_path = BRANDING_DIR / "cf-link.ico"
    symbol.save(ico_path, sizes=[(s, s) for s in (16, 24, 32, 48, 64, 128, 256)])
    print(f"Saved ICO to {ico_path}")

if __name__ == "__main__":
    symbol, cropped = process_symbol()
    process_wordmark(cropped)
    process_ico(symbol)
