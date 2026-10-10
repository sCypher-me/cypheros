#!/usr/bin/env python3
# Gera o tema de cursor Prisma: SVG -> PNG (Chromium headless) -> XCursor.
# Uso: python3 gerar.py            (gera tema + previa e valida)
#      python3 gerar.py --checar   (so valida os arquivos ja gerados)
import io, json, os, shutil, struct, subprocess, sys, tempfile
from PIL import Image

AQUI = os.path.dirname(os.path.abspath(__file__))
FONTE = os.path.join(AQUI, "fonte")
TEMA = os.path.join(AQUI, "Prisma")
CURSORES = os.path.join(TEMA, "cursors")
TAMANHOS = [24, 32, 48, 64]
BASE = 32

XCUR_MAGIC = b"Xcur"
XCUR_IMAGEM = 0xFFFD0002

# Renderizador: uma unica sessao do Chromium para todos os quadros
JS = r"""
const fs = require('fs');
const { chromium } = require(process.argv[2]);
const tarefas = JSON.parse(fs.readFileSync(process.argv[3], 'utf8'));
(async () => {
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const p = await b.newPage({ deviceScaleFactor: 1 });
  for (const t of tarefas) {
    await p.setViewportSize({ width: t.tam, height: t.tam });
    const svg = t.svg.replace('width="32" height="32"', `width="${t.tam}" height="${t.tam}"`);
    await p.setContent(`<html><body style="margin:0;background:transparent">${svg}</body></html>`);
    if (t.ang !== null) {
      await p.evaluate(([a, cx, cy]) => {
        document.getElementById('giro').setAttribute('transform', `rotate(${a} ${cx} ${cy})`);
      }, [t.ang, t.cx, t.cy]);
    }
    await p.screenshot({ path: t.saida, omitBackground: true, clip: { x: 0, y: 0, width: t.tam, height: t.tam } });
  }
  await b.close();
})().catch(e => { console.error(e); process.exit(1); });
"""


def renderizar(hot, tmp):
    raiz = subprocess.check_output(["npm", "root", "-g"], text=True).strip()
    tarefas = []
    for nome, h in hot.items():
        svg = open(os.path.join(FONTE, nome + ".svg")).read()
        quadros = h.get("quadros", 1)
        cx, cy = h.get("centro", [16, 16])
        for tam in TAMANHOS:
            for q in range(quadros):
                tarefas.append({
                    "svg": svg, "tam": tam, "cx": cx, "cy": cy,
                    "ang": (360.0 * q / quadros) if quadros > 1 else None,
                    "saida": os.path.join(tmp, f"{nome}-{tam}-{q:02d}.png"),
                })
    jt = os.path.join(tmp, "tarefas.json")
    js = os.path.join(tmp, "render.js")
    json.dump(tarefas, open(jt, "w"))
    open(js, "w").write(JS)
    subprocess.check_call(["node", js, os.path.join(raiz, "playwright"), jt])


def argb_premult(img):
    img = img.convert("RGBA")
    out = bytearray()
    for r, g, b, a in img.get_flattened_data():
        r, g, b = (r * a + 127) // 255, (g * a + 127) // 255, (b * a + 127) // 255
        out += struct.pack("<I", (a << 24) | (r << 16) | (g << 8) | b)
    return bytes(out)


def escrever_xcursor(caminho, imagens):
    """imagens: lista de (tam_nominal, PIL.Image, xhot, yhot, atraso_ms)."""
    n = len(imagens)
    pos = 16 + 12 * n
    toc, blocos = b"", b""
    for tam, img, xh, yh, atraso in imagens:
        w, h = img.size
        bloco = struct.pack("<9I", 36, XCUR_IMAGEM, tam, 1, w, h, xh, yh, atraso) + argb_premult(img)
        toc += struct.pack("<3I", XCUR_IMAGEM, tam, pos)
        blocos += bloco
        pos += len(bloco)
    with open(caminho, "wb") as f:
        f.write(XCUR_MAGIC + struct.pack("<3I", 16, 0x10000, n) + toc + blocos)


def ler_xcursor(caminho):
    """Leitor minimo: devolve lista de dicts com tam, w, h, xhot, yhot, atraso."""
    d = open(caminho, "rb").read()
    assert d[:4] == XCUR_MAGIC, "magic invalido"
    hsize, ver, n = struct.unpack_from("<3I", d, 4)
    assert hsize == 16
    res = []
    for i in range(n):
        tipo, sub, pos = struct.unpack_from("<3I", d, hsize + 12 * i)
        assert tipo == XCUR_IMAGEM
        cab, tipo2, sub2, v, w, h, xh, yh, atraso = struct.unpack_from("<9I", d, pos)
        assert cab == 36 and tipo2 == tipo and sub2 == sub and v == 1
        assert pos + 36 + 4 * w * h <= len(d), "pixels truncados"
        assert xh < w and yh < h, "hotspot fora da imagem"
        res.append({"tam": sub, "w": w, "h": h, "xhot": xh, "yhot": yh, "atraso": atraso})
    return res


def hotspot(v, tam):
    return min(tam - 1, int(v * tam / BASE))


def checar(hot):
    erros = 0
    for nome, h in hot.items():
        quadros = h.get("quadros", 1)
        imgs = ler_xcursor(os.path.join(CURSORES, nome))
        for tam in TAMANHOS:
            sel = [i for i in imgs if i["tam"] == tam]
            ok = (len(sel) == quadros and all(i["w"] == tam and i["h"] == tam for i in sel)
                  and all(i["xhot"] == hotspot(h["x"], tam) and i["yhot"] == hotspot(h["y"], tam) for i in sel)
                  and all((i["atraso"] > 0) == (quadros > 1) for i in sel))
            if not ok:
                erros += 1
                print(f"  ERRO {nome} @{tam}: {sel}")
        print(f"  ok {nome:14s} {len(imgs):3d} imagens, quadros={quadros}, hot@32={imgs[[i['tam'] for i in imgs].index(32)]['xhot']},{imgs[[i['tam'] for i in imgs].index(32)]['yhot']}")
    print("validacao:", "sem erros" if not erros else f"{erros} erros")
    return erros == 0


def previa(hot, tmp):
    nomes = list(hot.keys())
    tam, cel, cols = 48, 76, 11
    linhas = (len(nomes) + cols - 1) // cols
    W, H = cols * cel + 20, 2 * (linhas * cel + 10) + 10
    folha = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    fundos = [(11, 16, 32, 255), (236, 238, 244, 255)]
    for k, cor in enumerate(fundos):
        y0 = 5 + k * (linhas * cel + 15)
        folha.paste(Image.new("RGBA", (W, linhas * cel + 10), cor), (0, y0))
        for i, nome in enumerate(nomes):
            q = 3 if hot[nome].get("quadros", 1) > 1 else 0
            img = Image.open(os.path.join(tmp, f"{nome}-{tam}-{q:02d}.png")).convert("RGBA")
            x = 10 + (i % cols) * cel + (cel - tam) // 2
            y = y0 + 5 + (i // cols) * cel + (cel - tam) // 2
            folha.alpha_composite(img, (x, y))
            # marca do hotspot (ponto vermelho de 1px)
            hx, hy = x + hotspot(hot[nome]["x"], tam), y + hotspot(hot[nome]["y"], tam)
            folha.putpixel((hx, hy), (255, 40, 80, 255))
    folha.convert("RGB").save(os.path.join(AQUI, "previa.png"))


def main():
    hot = json.load(open(os.path.join(FONTE, "hotspots.json")))
    if "--checar" in sys.argv:
        sys.exit(0 if checar(hot) else 1)
    tmp = tempfile.mkdtemp(prefix="prisma-")
    try:
        print("renderizando...")
        renderizar(hot, tmp)
        shutil.rmtree(TEMA, ignore_errors=True)
        os.makedirs(CURSORES)
        for nome, h in hot.items():
            quadros = h.get("quadros", 1)
            atraso = h.get("atraso", 0) if quadros > 1 else 0
            imagens = []
            for tam in TAMANHOS:
                for q in range(quadros):
                    img = Image.open(os.path.join(tmp, f"{nome}-{tam}-{q:02d}.png"))
                    imagens.append((tam, img, hotspot(h["x"], tam), hotspot(h["y"], tam), atraso))
            escrever_xcursor(os.path.join(CURSORES, nome), imagens)
        tema = "[Icon Theme]\nName=Prisma\nComment=Cursor do CypherOS\nInherits=Adwaita\n"
        open(os.path.join(TEMA, "index.theme"), "w").write(tema)
        open(os.path.join(TEMA, "cursor.theme"), "w").write("[Icon Theme]\nName=Prisma\nInherits=Prisma\n")
        previa(hot, tmp)
        print(f"{len(hot)} cursores em {CURSORES}")
    finally:
        shutil.rmtree(tmp, ignore_errors=True)
    sys.exit(0 if checar(hot) else 1)


if __name__ == "__main__":
    main()
