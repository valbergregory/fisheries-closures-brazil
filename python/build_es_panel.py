"""C4 — painel do Espírito Santo (controle espacial): o ES tem calendário
PRÓPRIO na Portaria 656/2022 (Art. 3º: 1º/dez a 28/fev) e sua frota não pode
operar fora do ES (Art. 8º §1º). Em fevereiro o ES está FECHADO nos dois
regimes; em maio está LIVRE nos dois. Logo o ES serve de controle para a
tendência regional do arrasto.
"""
from __future__ import annotations
import csv, glob, json, math
from collections import defaultdict
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]; STEP = 0.25; CUT = "2023-01-28"
def cc(v): return math.floor(round(v / 0.1) * 0.1 / STEP + 1e-9) * STEP + STEP / 2
trawl = defaultdict(float); trawl_pre = defaultdict(float); other = defaultdict(float); pres = defaultdict(float)
gear = defaultdict(float); vessels = {}
for fp in sorted(glob.glob(str(ROOT / "data/raw/es/gfw_effort_vid_es_*.json"))):
    d = json.loads(Path(fp).read_text(encoding="utf-8"))
    if "entries" not in d: continue
    for _ds, recs in d["entries"][0].items():
        for r in recs:
            h = r.get("hours")
            if not h: continue
            k = (cc(r["lon"]), cc(r["lat"]), int(r["date"][:4]), int(r["date"][5:7]))
            g = (r.get("geartype") or "UNKNOWN").upper(); ft = (r.get("firstTransmissionDate") or "")[:10]
            vessels[r["vesselId"]] = (g, ft)
            gear[(k[0], k[1], k[2], k[3], g)] += h
            if g == "TRAWLERS":
                trawl[k] += h
                if ft and ft < CUT: trawl_pre[k] += h
            else: other[k] += h
for fp in sorted(glob.glob(str(ROOT / "data/raw/es/gfw_presence_flag_es_*.json"))):
    d = json.loads(Path(fp).read_text(encoding="utf-8"))
    if "entries" not in d: continue
    for _ds, recs in d["entries"][0].items():
        for r in recs:
            h = r.get("hours")
            if h: pres[(cc(r["lon"]), cc(r["lat"]), int(r["date"][:4]), int(r["date"][5:7]))] += h
cells = sorted({(k[0], k[1]) for k in list(trawl) + list(pres)})
out = ROOT / "data/processed/panel_es.csv"
with out.open("w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh); w.writerow(["cell_lon","cell_lat","year","month","trawl_hours","trawl_hours_prefleet","other_hours","presence_hours"])
    for (x, y) in cells:
        for yr in range(2018, 2025):
            for mo in range(1, 13):
                k = (x, y, yr, mo)
                w.writerow([x, y, yr, mo, f"{trawl.get(k,0):.4f}", f"{trawl_pre.get(k,0):.4f}", f"{other.get(k,0):.4f}", f"{pres.get(k,0):.4f}"])
n_tr = sum(1 for v in vessels.values() if v[0] == "TRAWLERS")
print(f"ES: {len(cells)} células | {len(vessels)} embarcações ({n_tr} arrasto) | horas de arrasto {sum(trawl.values()):.0f}")
print(f"painel -> {out.relative_to(ROOT)}")
