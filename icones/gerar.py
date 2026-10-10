#!/usr/bin/env python3
# Gera o tema de ícones "Prisma" do CypherOS (SVGs + index.theme).
# Uso: python3 gerar.py   -> escreve em ./Prisma
import os
import re
import shutil

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Prisma")

CIANO, VIOLETA = "#38E1FF", "#A78BFA"
NAVY_A, NAVY_B = "#0B1020", "#161B33"
ESCURO = "#0B1020"


def fmt(v):
    s = f"{v:.3f}".rstrip("0").rstrip(".")
    return "0" if s in ("-0", "") else s


# Mesmos auxiliares do Icons.qml
def circle(cx, cy, r):
    return f"M{fmt(cx - r)} {fmt(cy)}a{fmt(r)} {fmt(r)} 0 1 0 {fmt(2 * r)} 0a{fmt(r)} {fmt(r)} 0 1 0 {fmt(-2 * r)} 0"


def rrect(x, y, w, h, r):
    return (f"M{fmt(x + r)} {fmt(y)}h{fmt(w - 2 * r)}a{fmt(r)} {fmt(r)} 0 0 1 {fmt(r)} {fmt(r)}"
            f"v{fmt(h - 2 * r)}a{fmt(r)} {fmt(r)} 0 0 1 {fmt(-r)} {fmt(r)}h{fmt(-(w - 2 * r))}"
            f"a{fmt(r)} {fmt(r)} 0 0 1 {fmt(-r)} {fmt(-r)}v{fmt(-(h - 2 * r))}"
            f"a{fmt(r)} {fmt(r)} 0 0 1 {fmt(r)} {fmt(-r)}z")


# Glifos 24x24 portados do Icons.qml (+ alguns novos no mesmo traço)
G = {
    "logo": "M12 2l9 5v10l-9 5-9-5V7zM12 7.5l4.5 2.5v4.5L12 17l-4.5-2.5V10z",
    "wifi": "M2 9a15 15 0 0 1 20 0M5 13a10 10 0 0 1 14 0M8.5 16.5a5 5 0 0 1 7 0M12 20h.01",
    "bluetooth": "M7 7l10 10-5 5V2l5 5L7 17",
    "settings": circle(12, 12, 3) + "M12 2v3M12 19v3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M2 12h3M19 12h3M4.9 19.1L7 17M17 7l2.1-2.1",
    "terminal": rrect(3, 4, 18, 16, 3) + "M7 9l3 3-3 3M12 15h5",
    "folder": "M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z",
    "camera": rrect(3, 5, 18, 14, 2) + circle(12, 12, 3),
    "play": "M7 4l13 8-13 8z",
    "calc": rrect(5, 2, 14, 20, 2) + "M8 6h8M8 11h.01M12 11h.01M16 11h.01M8 15h.01M12 15h.01M16 15h.01M8 19h8",
    "chip": rrect(6, 6, 12, 12, 2) + "M9 2v4M15 2v4M9 18v4M15 18v4M2 9h4M2 15h4M18 9h4M18 15h4",
    "trash": "M3 6h18M8 6V4h8v2M6 6l1 15h10l1-15",
    "music": "M9 18V5l12-2v13M9 18a3 3 0 1 1-6 0 3 3 0 0 1 6 0zM21 16a3 3 0 1 1-6 0 3 3 0 0 1 6 0z",
    "cloud": "M7 18a5 5 0 1 1 1-9.9A6 6 0 0 1 19 10a4 4 0 0 1 0 8z",
    "file": "M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9zM14 3v6h6",
    "profile": circle(12, 8, 4) + "M4 21a8 8 0 0 1 16 0",
    "crop": "M6 2v14a2 2 0 0 0 2 2h14M2 6h14a2 2 0 0 1 2 2v14",
    "pen": "M16 3l5 5L8 21H3v-5zM13 6l5 5",
    "network": "M7 4v14M3.5 14.5L7 18l3.5-3.5M17 20V6M13.5 9.5L17 6l3.5 3.5",
    "copy": rrect(8, 8, 13, 13, 2) + "M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3",
    "download": "M12 3v12M7 10l5 5 5-5M4 19h16",
    "package": "M12 2l9 5v10l-9 5-9-5V7zM3 7l9 5 9-5M12 12v10",
    "wallpaper": rrect(3, 3, 18, 18, 3) + "M3 16l5-5 4 4 3-3 6 6" + circle(15.5, 8.5, 1.5),
    # novos
    "monitor": "M8 21h8M12 17v4" + rrect(2, 3, 20, 14, 2) + "M5.5 13.5l3.5-3.5 2.5 2.5 2-2 3.5 3.5",
    "desktop": rrect(2, 3, 20, 14, 2) + "M8 21h8M12 17v4",
    "image": rrect(3, 4, 18, 16, 3) + "M3 16l5-5 4 4 2.5-2.5L21 19" + circle(15.5, 9, 1.5),
    "video": rrect(2, 4, 20, 16, 3) + "M10 9l5 3-5 3z",
    "film": rrect(3, 3, 18, 18, 2) + "M8 3v18M16 3v18M3 8h5M3 12h18M3 16h5M16 8h5M16 16h5",
    "pulse": rrect(2, 3, 20, 18, 3) + "M5 12h3l2-4 3 8 2-4h4",
    "editor": "M4 5h12M4 9h12M4 13h6M4 17h4M19.5 9.5l2 2L14 19h-2v-2z",
    "shot": "M3 8V6a3 3 0 0 1 3-3h2M16 3h2a3 3 0 0 1 3 3v2M21 16v2a3 3 0 0 1-3 3h-2M8 21H6a3 3 0 0 1-3-3v-2" + circle(12, 12, 3.5),
    "help": circle(12, 12, 9) + "M9.2 9.3a2.9 2.9 0 0 1 5.6 1c0 1.9-2.8 2.5-2.8 4M12 17.5h.01",
    "users": circle(9, 8, 3.5) + "M2.5 20.5a6.5 6.5 0 0 1 13 0M16 4.6a3.5 3.5 0 0 1 0 6.8M18.5 14.6a6.5 6.5 0 0 1 3 5.9",
    "store": "M4 8h16l-1.2 11a2 2 0 0 1-2 1.8H7.2a2 2 0 0 1-2-1.8zM8.5 8a3.5 3.5 0 0 1 7 0M12 11.5v5M9.5 14l2.5 2.5 2.5-2.5",
    "home": "M3 11l9-8 9 8M5.5 9v11h4.5v-6h4v6h4.5V9",
    "doc": "M7 4h7l4 4v12H7zM10 11h5M10 14.5h5M10 18h3",
    "template": rrect(4, 3, 16, 18, 2) + "M4 9h16M10 9v12",
    "share": circle(18, 5, 2.5) + circle(6, 12, 2.5) + circle(18, 19, 2.5) + "M8.3 10.8l7.4-4.4M8.3 13.2l7.4 4.4",
    "globe": circle(12, 12, 9) + "M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18",
    "nodes": circle(12, 5, 2.5) + circle(5, 18, 2.5) + circle(19, 18, 2.5) + "M10.7 7.2l-4.4 8.6M13.3 7.2l4.4 8.6M7.5 18h9",
    "lines": "M5 6h14M5 10h14M5 14h14M5 18h9",
    "code": "M8 7l-5 5 5 5M16 7l5 5-5 5M14 4l-4 16",
    "prompt": "M5 7l5 5-5 5M12 18h7",
    "palette": ("M12 3a9 9 0 0 0 0 18c1.2 0 2-.8 2-1.9 0-1.4-1.1-1.7-1.1-3 0-1.2.9-2.1 2.1-2.1h2"
                "a4 4 0 0 0 4-4c0-4-4-7-9-7zM7.5 12h.01M9 7.8h.01M14 7h.01M17.2 10h.01"),
}


def engrenagem(n=8, re_=9.5, ri=7.2, rc=3):
    """Engrenagem com n dentes, raio externo re_, interno ri e furo rc."""
    import math
    pts = []
    passo = 2 * math.pi / n
    for i in range(n):
        a = i * passo - math.pi / 2
        for da, r in ((-0.30, ri), (-0.17, re_), (0.17, re_), (0.30, ri)):
            pts.append((12 + r * math.cos(a + da * passo * 1.6), 12 + r * math.sin(a + da * passo * 1.6)))
    return "M" + "L".join(f"{fmt(x)} {fmt(y)}" for x, y in pts) + "z" + circle(12, 12, rc)


G["gear"] = engrenagem()

# ---------------------------------------------------------------- utilitários


def ident(nome):
    return "p-" + re.sub(r"[^a-zA-Z0-9]", "-", nome) + "-"


def grad(id_, x1, y1, x2, y2, c1, c2, o1=1, o2=1):
    return (f'<linearGradient id="{id_}" gradientUnits="userSpaceOnUse" x1="{fmt(x1)}" y1="{fmt(y1)}" '
            f'x2="{fmt(x2)}" y2="{fmt(y2)}"><stop offset="0" stop-color="{c1}" stop-opacity="{o1}"/>'
            f'<stop offset="1" stop-color="{c2}" stop-opacity="{o2}"/></linearGradient>')


def doc(defs, corpo):
    return ('<?xml version="1.0" encoding="UTF-8"?>\n'
            '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">'
            f"<defs>{''.join(defs)}</defs>{corpo}</svg>\n")


def glifo(d, cx, cy, tam, traco, cor, extra=""):
    """Glifo 24x24 centrado em (cx, cy) com tamanho `tam` px e traço `traco` px (escala 64)."""
    k = tam / 24
    return (f'<g transform="translate({fmt(cx - 12 * k)} {fmt(cy - 12 * k)}) scale({fmt(k)})">'
            f'{extra}<path d="{d}" fill="none" stroke="{cor}" stroke-width="{fmt(traco / k)}" '
            'stroke-linecap="round" stroke-linejoin="round"/></g>')


# ---------------------------------------------------------------- apps

def icone_app(nome, d, preench=None):
    p = ident(nome)
    defs = [
        grad(p + "bg", 0, 4, 0, 60, NAVY_A, NAVY_B),
        grad(p + "bd", 4, 4, 60, 60, CIANO, VIOLETA),
        grad(p + "hl", 0, 4, 0, 30, "#FFFFFF", "#FFFFFF", 0.10, 0),
        grad(p + "gl", 3, 3, 21, 21, CIANO, VIOLETA),
        '<radialGradient id="%sau" cx="32" cy="32" r="24" gradientUnits="userSpaceOnUse">'
        '<stop offset="0" stop-color="%s" stop-opacity="0.16"/>'
        '<stop offset="1" stop-color="%s" stop-opacity="0"/></radialGradient>' % (p, VIOLETA, VIOLETA),
        f'<filter id="{p}br" filterUnits="userSpaceOnUse" x="0" y="0" width="64" height="64">'
        '<feGaussianBlur stdDeviation="1.6"/></filter>',
        f'<filter id="{p}sh" filterUnits="userSpaceOnUse" x="0" y="0" width="64" height="64">'
        '<feGaussianBlur stdDeviation="1.2"/></filter>',
    ]
    tam = 32
    extra = f'<path d="{preench}" fill="url(#{p}gl)" fill-opacity="0.22"/>' if preench else ""
    corpo = (
        f'<rect x="4" y="5.5" width="56" height="56" rx="14" fill="#000" fill-opacity="0.35" filter="url(#{p}sh)"/>'
        f'<rect x="4" y="4" width="56" height="56" rx="14" fill="url(#{p}bg)"/>'
        f'<rect x="4" y="4" width="56" height="56" rx="14" fill="url(#{p}au)"/>'
        f'<rect x="4" y="4" width="56" height="56" rx="14" fill="url(#{p}hl)"/>'
        f'<rect x="4.75" y="4.75" width="54.5" height="54.5" rx="13.25" fill="none" '
        f'stroke="url(#{p}bd)" stroke-width="1.5"/>'
        f'<path d="M18 5.6h28" stroke="#FFFFFF" stroke-opacity="0.22" stroke-width="0.8" stroke-linecap="round"/>'
        f'<g filter="url(#{p}br)" opacity="0.7">{glifo(d, 32, 32, tam, 4.2, f"url(#{p}gl)")}</g>'
        + glifo(d, 32, 32, tam, 3.2, f"url(#{p}gl)", extra)
    )
    return doc(defs, corpo)


APPS = {
    "terminal": (["utilities-terminal", "org.gnome.Terminal", "cypher-term"], G["terminal"]),
    "settings": (["preferences-system", "org.gnome.Settings"], G["gear"]),
    "store": (["system-software-install", "org.gnome.Software"], G["store"]),
    "pulse": (["utilities-system-monitor", "org.gnome.SystemMonitor"], G["pulse"]),
    "folder": (["system-file-manager", "org.gnome.Nautilus"], G["folder"]),
    "editor": (["accessories-text-editor", "org.gnome.TextEditor"], G["editor"]),
    "calc": (["accessories-calculator", "org.gnome.Calculator"], G["calc"]),
    "image": (["image-viewer", "org.gnome.Loupe"], G["image"]),
    "video": (["multimedia-video-player"], G["video"]),
    "music": (["multimedia-audio-player"], G["music"]),
    "shot": (["accessories-screenshot"], G["shot"]),
    "palette": (["preferences-desktop-theme"], G["palette"]),
    "wallpaper": (["preferences-desktop-wallpaper"], G["monitor"]),
    "help": (["help-browser"], G["help"]),
    "users": (["system-users"], G["users"]),
    "wifi": (["preferences-system-network"], G["wifi"]),
    "bluetooth": (["bluetooth"], G["bluetooth"]),
}
LOGO = ["cypheros", "distributor-logo", "start-here"]

# ---------------------------------------------------------------- pastas

# silhueta da pasta (escala 64)
PASTA_FUNDO = ("M5 15a4 4 0 0 1 4-4h13.3a4 4 0 0 1 2.9 1.2l3.6 3.6a4 4 0 0 0 2.9 1.2H55a4 4 0 0 1 4 4"
               "V50a4 4 0 0 1-4 4H9a4 4 0 0 1-4-4z")
PASTA_FRENTE = "M5 25a4 4 0 0 1 4-4h46a4 4 0 0 1 4 4v25a4 4 0 0 1-4 4H9a4 4 0 0 1-4-4z"
PASTA_ABERTA = ("M13.4 24H59a3 3 0 0 1 2.9 3.8l-5.9 23.3A3.9 3.9 0 0 1 52.2 54H7a3 3 0 0 1-2.9-3.7"
                "l5.4-23.3A4 4 0 0 1 13.4 24z")


def defs_pasta(p):
    return [
        grad(p + "fu", 5, 11, 59, 54, "#1C9BBE", "#6A4FC9"),
        grad(p + "fr", 5, 21, 59, 54, "#5DE8FF", "#B9A3FF"),
        grad(p + "lz", 0, 21, 0, 34, "#FFFFFF", "#FFFFFF", 0.35, 0),
        f'<filter id="{p}sh" filterUnits="userSpaceOnUse" x="0" y="0" width="64" height="64">'
        '<feGaussianBlur stdDeviation="1.4"/></filter>',
    ]


def icone_pasta(nome, d=None, aberta=False):
    p = ident(nome)
    frente = PASTA_ABERTA if aberta else PASTA_FRENTE
    corpo = (
        f'<path d="{PASTA_FUNDO}" transform="translate(0 1.5)" fill="#000" fill-opacity="0.35" filter="url(#{p}sh)"/>'
        f'<path d="{PASTA_FUNDO}" fill="url(#{p}fu)"/>'
        # folha de papel espiando
        f'<rect x="10" y="17" width="44" height="12" rx="2.5" fill="#E9EEFF" fill-opacity="0.85"/>'
        f'<path d="{frente}" fill="url(#{p}fr)" fill-opacity="0.94"/>'
        f'<path d="{frente}" fill="url(#{p}lz)"/>'
    )
    if not aberta:
        corpo += '<path d="M9 21.6h46" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1" stroke-linecap="round"/>'
    if d:
        cx = 33 if aberta else 32
        corpo += f'<g opacity="0.82">{glifo(d, cx, 38.5, 17, 2.7, ESCURO)}</g>'
    return doc(defs_pasta(p), corpo)


PASTAS = {
    "folder": None,
    "folder-documents": G["doc"],
    "folder-download": G["download"],
    "folder-music": G["music"],
    "folder-pictures": G["image"],
    "folder-videos": G["play"],
    "folder-desktop": G["desktop"],
    "user-desktop": G["desktop"],
    "folder-templates": G["template"],
    "folder-publicshare": G["share"],
    "folder-remote": G["cloud"],
    "network-workgroup": G["nodes"],
    "user-home": G["home"],
}


def icone_lixeira(nome, cheia=False):
    p = ident(nome)
    defs = [
        grad(p + "co", 14, 22, 50, 58, "#5DE8FF", "#B9A3FF"),
        grad(p + "tp", 10, 12, 54, 20, "#1C9BBE", "#6A4FC9"),
        grad(p + "lz", 0, 22, 0, 40, "#FFFFFF", "#FFFFFF", 0.30, 0),
        f'<filter id="{p}sh" filterUnits="userSpaceOnUse" x="0" y="0" width="64" height="64">'
        '<feGaussianBlur stdDeviation="1.4"/></filter>',
    ]
    corpo_lata = "M14 22h36l-2.9 30.4a4 4 0 0 1-4 3.6H20.9a4 4 0 0 1-4-3.6z"
    tampa = rrect(10, 14, 44, 7, 3.5) + rrect(25, 9, 14, 7, 2.5)
    corpo = f'<path d="{corpo_lata}" transform="translate(0 1.5)" fill="#000" fill-opacity="0.35" filter="url(#{p}sh)"/>'
    if cheia:
        # tampa inclinada e papéis amassados saindo da lata
        corpo += f'<g transform="rotate(-12 10 21) translate(-1 -1.5)"><path d="{rrect(10, 14, 44, 7, 3.5)}" fill="url(#{p}tp)"/></g>'
        corpo += (
            '<path d="M19 23l1-8 7.5-3 5 4.5-1.5 6.5z" fill="#E9EEFF"/>'
            '<path d="M30 23l3-9.5 8.5-.5 4.5 6-2 4z" fill="#D4DBF5"/>'
            '<path d="M23 16.5l4 1.2M35.5 16l5 1.5M38.5 14l.6 4.5" stroke="#7C86B0" stroke-width="1.1" stroke-linecap="round" fill="none"/>'
        )
    else:
        corpo += f'<path d="{tampa}" fill="url(#{p}tp)"/>'
    corpo += (
        f'<path d="{corpo_lata}" fill="url(#{p}co)" fill-opacity="0.95"/>'
        f'<path d="{corpo_lata}" fill="url(#{p}lz)"/>'
        f'<path d="M24.5 28l.8 21M32 28v21M39.5 28l-.8 21" stroke="{ESCURO}" stroke-opacity="0.6" '
        'stroke-width="2.6" stroke-linecap="round" fill="none"/>'
    )
    return doc(defs, corpo)

# ---------------------------------------------------------------- tipos de arquivo


PAGINA = "M17 4h22l13 13v39a4 4 0 0 1-4 4H17a4 4 0 0 1-4-4V8a4 4 0 0 1 4-4z"
DOBRA = "M39 4v9a4 4 0 0 0 4 4h9z"


def icone_mime(nome, d, rotulo=None):
    p = ident(nome)
    defs = [
        grad(p + "bg", 0, 4, 0, 60, "#1A2040", "#0E1328"),
        grad(p + "bd", 13, 4, 52, 60, CIANO, VIOLETA),
        grad(p + "gl", 3, 3, 21, 21, CIANO, VIOLETA),
        grad(p + "fx", 13, 0, 52, 0, CIANO, VIOLETA),
        grad(p + "do", 39, 4, 52, 17, "#7FEEFF", "#C7B6FF"),
        f'<filter id="{p}br" filterUnits="userSpaceOnUse" x="0" y="0" width="64" height="64">'
        '<feGaussianBlur stdDeviation="1.3"/></filter>',
        f'<clipPath id="{p}cp"><path d="{PAGINA}"/></clipPath>',
    ]
    gy = 28 if rotulo else 31
    tam = 20 if rotulo else 22
    corpo = f'<path d="{PAGINA}" fill="url(#{p}bg)"/>'
    if rotulo:
        corpo += (f'<rect x="13" y="43" width="39" height="11" fill="url(#{p}fx)" clip-path="url(#{p}cp)"/>'
                  f'<text x="32.5" y="51.6" text-anchor="middle" font-family="Inter, \'DejaVu Sans\', sans-serif" '
                  f'font-size="{8.6 if len(rotulo) < 4 else 7.6}" font-weight="800" letter-spacing="0.6" '
                  f'fill="{ESCURO}">{rotulo}</text>')
    else:
        corpo += f'<rect x="13" y="50" width="39" height="3" fill="url(#{p}fx)" clip-path="url(#{p}cp)"/>'
    corpo += (
        f'<path d="{PAGINA}" fill="none" stroke="url(#{p}bd)" stroke-width="1.5" stroke-linejoin="round"/>'
        f'<path d="{DOBRA}" fill="url(#{p}do)"/>'
        f'<g filter="url(#{p}br)" opacity="0.6">{glifo(d, 32.5, gy, tam, 3.6, f"url(#{p}gl)")}</g>'
        + glifo(d, 32.5, gy, tam, 2.8, f"url(#{p}gl)")
    )
    return doc(defs, corpo)


MIMES = {
    "text-x-generic": (G["lines"], None),
    "application-pdf": (G["lines"], "PDF"),
    "image-x-generic": (G["image"], None),
    "audio-x-generic": (G["music"], None),
    "video-x-generic": (G["video"], None),
    "application-x-executable": (G["gear"], "BIN"),
    "text-x-script": (G["code"], None),
    "application-zip": (G["package"], "ZIP"),
    "package-x-generic": (G["package"], None),
    "application-x-shellscript": (G["prompt"], "SH"),
}

# ---------------------------------------------------------------- saída

DIRS = [("scalable/apps", "Applications"), ("scalable/places", "Places"), ("scalable/mimetypes", "MimeTypes")]


def escrever(ctx, nome, svg):
    with open(os.path.join(RAIZ, "scalable", ctx, nome + ".svg"), "w") as f:
        f.write(svg)


def main():
    if os.path.isdir(RAIZ):
        shutil.rmtree(RAIZ)
    for d, _ in DIRS:
        os.makedirs(os.path.join(RAIZ, d))
    n = 0
    for nomes, d in APPS.values():
        for nome in nomes:
            escrever("apps", nome, icone_app(nome, d)); n += 1
    for nome in LOGO:
        escrever("apps", nome, icone_app(nome, G["logo"], preench="M12 7.5l4.5 2.5v4.5L12 17l-4.5-2.5V10z")); n += 1
    for nome, d in PASTAS.items():
        escrever("places", nome, icone_pasta(nome, d)); n += 1
    escrever("places", "folder-open", icone_pasta("folder-open", aberta=True)); n += 1
    escrever("places", "user-trash", icone_lixeira("user-trash")); n += 1
    escrever("places", "user-trash-full", icone_lixeira("user-trash-full", cheia=True)); n += 1
    for nome, (d, r) in MIMES.items():
        escrever("mimetypes", nome, icone_mime(nome, d, r)); n += 1

    tema = ["[Icon Theme]", "Name=Prisma", "Comment=Ícones do CypherOS: vidro escuro e gradiente ciano-violeta",
            "Inherits=Papirus-Dark,hicolor", "Example=folder",
            "Directories=" + ",".join(d for d, _ in DIRS), ""]
    for d, ctx in DIRS:
        tema += [f"[{d}]", "Size=64", "MinSize=8", "MaxSize=512", "Type=Scalable", f"Context={ctx}", ""]
    with open(os.path.join(RAIZ, "index.theme"), "w") as f:
        f.write("\n".join(tema))
    print(f"{n} ícones gerados em {RAIZ}")


if __name__ == "__main__":
    main()
