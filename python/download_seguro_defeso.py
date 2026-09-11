"""B4 — Seguro-Defeso (CGU): baixa os ZIPs mensais e agrega por município ×
competência. Microdados ficam em data/raw/seguro_defeso/ (fora do Git, D9);
só o agregado vai para data/processed/seguro_defeso_municipio_mes.csv.
Uso: python python/download_seguro_defeso.py 2019-01 2024-12
"""
from __future__ import annotations
import csv, io, sys, time, zipfile, urllib.request
from collections import defaultdict
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]; RAW = ROOT / "data/raw/seguro_defeso"; RAW.mkdir(parents=True, exist_ok=True)
URL = "https://dadosabertos-download.cgu.gov.br/PortalDaTransparencia/saida/seguro-defeso/{ym}_SeguroDefeso.zip"
y0, m0 = map(int, sys.argv[1].split("-")); y1, m1 = map(int, sys.argv[2].split("-"))
months = []; y, m = y0, m0
while (y, m) <= (y1, m1):
    months.append(f"{y}{m:02d}"); m += 1
    if m == 13: y, m = y + 1, 1
agg = defaultdict(lambda: {"parcelas": 0, "beneficiarios": set(), "rgp": set(), "valor": 0.0})
for ym in months:
    dest = RAW / f"{ym}_SeguroDefeso.zip"
    if not dest.exists() or dest.stat().st_size < 1000:
        req = urllib.request.Request(URL.format(ym=ym), headers={"User-Agent": "Mozilla/5.0 research-compendium"})
        try:
            with urllib.request.urlopen(req, timeout=180) as r, dest.open("wb") as fh: fh.write(r.read())
        except Exception as e:
            print(f"{ym}: FALHA {e}"); continue
        time.sleep(1.5)
    try:
        z = zipfile.ZipFile(dest); name = [n for n in z.namelist() if n.lower().endswith(".csv")][0]
        with z.open(name) as f:
            rd = csv.DictReader(io.TextIOWrapper(f, encoding="latin-1"), delimiter=";")
            n = 0
            for r in rd:
                k = (r.get("MÊS REFERÊNCIA") or r.get("MÊS REFERÊNCIA".encode("latin-1").decode("latin-1"), ""), r.get("UF", ""), r.get("CÓDIGO MUNICÍPIO SIAFI", ""), r.get("NOME MUNICÍPIO", ""))
                a = agg[k]; a["parcelas"] += 1; a["beneficiarios"].add(r.get("NIS FAVORECIDO", "")); a["rgp"].add(r.get("RGP FAVORECIDO", ""))
                try: a["valor"] += float((r.get("VALOR PARCELA") or "0").replace(".", "").replace(",", "."))
                except ValueError: pass
                n += 1
        print(f"{ym}: {n} parcelas")
    except Exception as e:
        print(f"{ym}: erro ao ler {e}")
out = ROOT / "data/processed/seguro_defeso_municipio_mes.csv"
with out.open("w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh); w.writerow(["mes_referencia", "uf", "cod_municipio_siafi", "municipio", "n_parcelas", "n_beneficiarios", "n_rgp", "valor_total"])
    for (ym, uf, cod, nome), a in sorted(agg.items()):
        w.writerow([ym, uf, cod, nome, a["parcelas"], len(a["beneficiarios"]), len(a["rgp"]), f"{a['valor']:.2f}"])
print("agregado ->", out.relative_to(ROOT), "| linhas:", len(agg))
