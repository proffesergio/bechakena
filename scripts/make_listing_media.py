"""Render the editable, screenshot-based listing artwork (requires PyMuPDF)."""

import base64
from html import escape
from pathlib import Path

import pymupdf

ROOT = Path(__file__).resolve().parent.parent
MEDIA = ROOT / "site/public/media"


def text(x, y, value, size=24, color="#173b2c", weight=400):
    return f'<text x="{x}" y="{y}" font-family="Arial, sans-serif" font-size="{size}" font-weight="{weight}" fill="{color}">{escape(value)}</text>'


def rect(x, y, w, h, color, radius=0):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{color}"/>'


def capture(name, x, y, w, h):
    encoded = base64.b64encode((MEDIA / name).read_bytes()).decode()
    return f'<image x="{x}" y="{y}" width="{w}" height="{h}" href="data:image/png;base64,{encoded}"/>'


def mark(x, y, size):
    return f'<g transform="translate({x} {y}) scale({size / 40})">{rect(0, 0, 40, 40, "#a8ec9c", 12)}<path d="M11 13h6.5a5 5 0 0 1 0 10H11V13Zm0 10h10a4 4 0 0 1 0 8H11V13m16-4v11m-4-6h8" fill="none" stroke="#123c2d" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/></g>'


def render(name, width, height, content):
    source = f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}">{content}</svg>'
    (MEDIA / f"{name}.svg").write_text(source, encoding="utf-8")
    with pymupdf.open(stream=source.encode(), filetype="svg") as svg:
        with pymupdf.open("pdf", svg.convert_to_pdf()) as pdf:
            pix = pdf[0].get_pixmap(alpha=False)
            assert (pix.width, pix.height) == (width, height)
            pix.save(MEDIA / f"{name}.png")
    print(f"{name}.png: {width} x {height}")


def main():
    cover = rect(0, 0, 1920, 1080, "#123c2d")
    cover += '<circle cx="1630" cy="320" r="460" fill="#1d4d38"/><circle cx="1710" cy="420" r="330" fill="#2b6144"/>'
    cover += mark(90, 70, 64) + text(176, 114, "BechaKena", 43, "#f5f8ec", 700)
    cover += rect(1470, 77, 360, 49, "#2d5942", 24) + text(1500, 110, "RETAIL + RESTAURANT", 21, "#c9edb6", 700)
    cover += text(90, 220, "OFFLINE-FIRST POINT OF SALE", 23, "#b8f08b", 700)
    cover += text(84, 355, "Big days.", 116, "#f7f8f2", 700)
    cover += text(84, 480, "Simple selling.", 116, "#b8f08b", 700)
    cover += text(90, 551, "Run your shop. Serve your tables.", 32, "#d0e2cf")
    cover += text(90, 600, "Keep the day moving, even offline.", 32, "#d0e2cf")
    for i, label in enumerate(("Checkout + inventory", "Baki khata + reports", "Tables + kitchen tickets")):
        y = 683 + i * 57
        cover += rect(91, y - 23, 25, 25, "#b8f08b", 8)
        cover += text(135, y, label, 28, "#edf6e7", 400)
    cover += rect(953, 201, 904, 671, "#062a1e", 25)
    cover += rect(940, 184, 904, 671, "#e4ecdd", 22)
    cover += text(963, 220, "BECHAKENA / RETAIL CHECKOUT", 16, "#365b42", 700)
    cover += capture("pos-en.png", 953, 240, 878, 610)
    cover += rect(1390, 769, 398, 60, "#123c2d", 15) + text(1415, 807, "ACTUAL APP / SAMPLE DATA", 19, "#edf8e4", 700)
    cover += rect(0, 924, 1920, 156, "#0a2e21")
    cover += text(90, 975, "THE PRODUCT STACK", 18, "#a9c6a7", 700)
    cover += text(90, 1030, "Flutter / Dart", 32, "#edf6e7", 700)
    cover += text(430, 1030, "Riverpod", 32, "#edf6e7", 700)
    cover += text(710, 1030, "Drift / SQLite", 32, "#edf6e7", 700)
    cover += text(1140, 975, "BILINGUAL", 18, "#a9c6a7", 700)
    cover += text(1140, 1030, "Bangla + English", 32, "#edf6e7", 700)
    cover += text(1535, 975, "WEB SHOWCASE", 18, "#a9c6a7", 700)
    cover += text(1535, 1030, "Next.js / React", 32, "#edf6e7", 700)
    render("cover", 1920, 1080, cover)

    square = rect(0, 0, 1080, 1080, "#f7f8f2")
    square += '<circle cx="940" cy="600" r="400" fill="#e4efda"/>'
    square += mark(62, 46, 49) + text(129, 81, "BechaKena", 30, weight=700)
    square += rect(770, 51, 248, 40, "#e6efde", 20) + text(790, 78, "RETAIL + RESTAURANT", 16, weight=700)
    square += rect(62, 120, 956, 1, "#d3dfcc")
    square += text(62, 170, "OFFLINE-FIRST POINT OF SALE", 16, "#006a4e", 700)
    square += text(57, 258, "Big days. Simple selling.", 73, weight=700)
    square += text(62, 307, "Checkout, inventory, baki khata and restaurant orders.", 25, "#53675c")
    square += text(62, 346, "Bangla + English. Your data, on your device.", 25, "#53675c")
    square += rect(62, 381, 227, 49, "#006a4e", 25) + text(86, 413, "Explore the demo", 22, "#ffffff", 700)
    square += text(315, 412, "Built for the everyday entrepreneur", 20, "#53675c")
    square += rect(58, 483, 679, 517, "#cedec4", 22)
    square += rect(62, 466, 665, 517, "#ffffff", 18)
    square += text(83, 499, "BECHAKENA / RETAIL CHECKOUT", 14, "#53675c", 700)
    square += capture("pos-en.png", 74, 518, 641, 445)
    labels = (("01 / SELL", "Barcode", "checkout"), ("02 / TRACK", "Stock +", "customer dues"), ("03 / SERVE", "Tables +", "kitchen tickets"))
    for i, (label, title, second) in enumerate(labels):
        x, y = 762, 484 + i * 164
        square += rect(x, y, 256, 140, "#edf2e7", 13)
        square += text(x + 20, y + 29, label, 12, "#006a4e", 700)
        square += text(x + 20, y + 72, title, 27, weight=700)
        square += text(x + 20, y + 107, second, 27, weight=700)
    square += text(62, 1053, "Flutter / Dart  ·  Riverpod  ·  Drift / SQLite", 18, "#53675c")
    square += text(770, 1053, "ACTUAL APP · SAMPLE DATA", 14, "#53675c")
    render("landing-square", 1080, 1080, square)


if __name__ == "__main__":
    main()
