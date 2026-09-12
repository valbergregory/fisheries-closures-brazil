"""Cobertura EXÓGENA (cargueiros/tanques) por célula-mês para o caso camarão,
a partir da presença por VESSEL_ID (data/raw/camarao/gfw_presence_vid_*.json,
~300 MB por semestre — lidos em streaming por semestre). Adiciona
cargo_hours e nonfish_hours ao painel data/processed/panel_camarao.csv."""
from __future__ import annotations
import csv, glob, json, math
from collections import defaultdict
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]; STEP = 0.25
FISH_LIKE = {"FISHING", "GEAR", "CARRIER"}
def cc(v): return math.floor(round(v / 0.1) * 0.1 / STEP + 1e-9) * STEP + STEP / 2
P = ROOT / "data/processed/panel_camarao.csv"
rows = list(csv.DictReader(P.open(encoding="utf-8")))
cells = {(float(r["cell_lon"]), float(r["cell_lat"])) for r in rows}
cargo = defaultdict(float); nonf = defaultdict(float); n = 0
for fp in sorted(glob.glob(str(ROOT / "data/raw/camarao/gfw_presence_vid_camarao_*.json"))):
    try: d = json.loads(Path(fp).read_text(encoding="utf-8"))
    except Exception as e: print("ignorado:", Path(fp).name, e); continue
    if "entries" not in d: print("ignorado:", Path(fp).name); continue
    n += 1
    for _ds, recs in d["entries"][0].items():
        for r in recs:
            h = r.get("hours")
            if not h: continue
            c = (cc(r["lon"]), cc(r["lat"]))
            if c not in cells: continue
            y, m = r["date"].split("-"); k = (c[0], c[1], int(y), int(m))
            vt = (r.get("vesselType") or "UNKNOWN").upper()
            if vt in ("CARGO", "TANKER"): cargo[k] += h
            if vt not in FISH_LIKE: nonf[k] += h
    d = None
for r in rows:
    k = (float(r["cell_lon"]), float(r["cell_lat"]), int(r["year"]), int(r["month"]))
    r["cargo_hours"] = f"{cargo.get(k, 0):.4f}"; r["nonfish_hours"] = f"{nonf.get(k, 0):.4f}"
with P.open("w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print(f"arquivos: {n} | células×mês com cargo>0: {sum(1 for r in rows if float(r['cargo_hours'])>0)} de {len(rows)}")
