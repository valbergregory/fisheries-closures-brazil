"""Painel EMBARCAÇÃO × zona × mês a partir do esforço GFW por VESSEL_ID.

Objetivo (D14, passo 1): decompor o aumento de esforço na APA de Trindade
após 19/03/2018 em (a) embarcações NOVAS na região (sem esforço no bbox
antes), (b) REALOCADAS (pescavam no bbox, fora da APA, e passaram a pescar
dentro) e (c) INCUMBENTES (já pescavam na APA). Atração de fora da região
vs. deslocamento de dentro dela têm implicações opostas para o leakage.

Entrada: data/raw/effort_vessel/*.json (4wings, group-by VESSEL_ID, 0,1°)
         + zonas por célula 0,25° (data/processed/panel_trindade_phase1.csv)
Saída:   data/processed/vessel_zone_month_trindade.csv
"""
from __future__ import annotations
import csv, glob, json, math
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STEP = 0.25
def cell_center(v): return math.floor(round(v / 0.1) * 0.1 / STEP + 1e-9) * STEP + STEP / 2

zone_of = {}
with (ROOT / "data/processed/panel_trindade_phase1.csv").open(encoding="utf-8") as fh:
    for r in csv.DictReader(fh):
        zone_of[(float(r["cell_lon"]), float(r["cell_lat"]))] = r["zone"]

agg = defaultdict(float); meta = {}
files = sorted(glob.glob(str(ROOT / "data/raw/effort_vessel/gfw_effort_vid_trindade_*.json")))
for fp in files:
    d = json.loads(Path(fp).read_text(encoding="utf-8"))
    if "entries" not in d: print("ignorado:", Path(fp).name); continue
    for _ds, recs in d["entries"][0].items():
        for r in recs:
            h = r.get("hours")
            if not h: continue
            z = zone_of.get((cell_center(r["lon"]), cell_center(r["lat"])))
            if z is None: continue
            vid = r.get("vesselId") or r.get("mmsi") or "?"
            y, m = r["date"].split("-")
            agg[(vid, z, int(y), int(m))] += h
            meta.setdefault(vid, (r.get("flag"), r.get("geartype"), r.get("shipName"), r.get("mmsi")))
out = ROOT / "data/processed/vessel_zone_month_trindade.csv"
with out.open("w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh); w.writerow(["vessel_id", "flag", "geartype", "ship_name", "mmsi", "zone", "year", "month", "fishing_hours"])
    for (vid, z, y, m), h in sorted(agg.items()):
        f, g, n, mm = meta[vid]; w.writerow([vid, f, g, n, mm, z, y, m, f"{h:.4f}"])
print(f"arquivos: {len(files)} | linhas: {len(agg)} | embarcações: {len(meta)} -> {out.relative_to(ROOT)}")
