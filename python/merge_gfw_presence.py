"""Adiciona ao painel de Trindade as horas de PRESENÇA AIS (todas as
embarcações, dataset public-global-presence, group-by FLAG) por célula-mês.

Uso: denominador/controle de cobertura (D13). presence_hours = horas em que
qualquer embarcação com AIS foi observada na célula. A razão
fishing_hours / presence_hours é a fração do tempo observado em pesca —
normaliza a detecção, mas inclui os próprios pesqueiros no denominador
(limitação documentada). Sem group-by por tipo de embarcação nesta API.
"""
from __future__ import annotations
import csv, glob, json, math
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "data" / "interim" / "pilot_panel_trindade.csv"
STEP = 0.25

def cell_center(v): return math.floor(round(v / 0.1) * 0.1 / STEP + 1e-9) * STEP + STEP / 2

agg = defaultdict(float); n_files = 0
for fp in sorted(glob.glob(str(ROOT / "data/raw/gfw_presence_trindade_20*.json"))):
    d = json.loads(Path(fp).read_text(encoding="utf-8"))
    if "entries" not in d: print("ignorado (erro):", fp); continue
    n_files += 1
    for _ds, entries in d["entries"][0].items():
        for e in entries:
            if e.get("hours") is None: continue
            y, m = e["date"].split("-")
            agg[(cell_center(e["lon"]), cell_center(e["lat"]), int(y), int(m))] += e["hours"]
rows = list(csv.DictReader(PANEL.open(encoding="utf-8")))
hit = 0
for r in rows:
    k = (float(r["cell_lon"]), float(r["cell_lat"]), int(r["year"]), int(r["month"]))
    r["presence_hours"] = f"{agg.get(k, 0.0):.4f}"; hit += k in agg
with PANEL.open("w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print(f"arquivos de presença: {n_files} | células×mês com presença>0: {hit} de {len(rows)}")
