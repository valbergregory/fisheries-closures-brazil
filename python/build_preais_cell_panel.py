"""Esforço por célula-mês SOMENTE de embarcações com AIS anterior à
designação (primeira transmissão < 2018-03-19). Remove o confundidor de
adoção de AIS pela frota (docs/phase1_report.md §11). Adiciona a coluna
fishing_hours_preais ao painel piloto."""
from __future__ import annotations
import csv, glob, json, math
from collections import defaultdict
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]; STEP = 0.25; CUT = "2018-03-19"
def cc(v): return math.floor(round(v / 0.1) * 0.1 / STEP + 1e-9) * STEP + STEP / 2
agg = defaultdict(float); n_old = set(); n_new = set()
for fp in glob.glob(str(ROOT / "data/raw/effort_vessel/*.json")):
    d = json.loads(Path(fp).read_text(encoding="utf-8"))
    for _ds, recs in d["entries"][0].items():
        for r in recs:
            h = r.get("hours"); ft = (r.get("firstTransmissionDate") or "")[:10]
            if not h: continue
            if ft and ft < CUT:
                n_old.add(r["vesselId"]); y, m = r["date"].split("-")
                agg[(cc(r["lon"]), cc(r["lat"]), int(y), int(m))] += h
            else: n_new.add(r["vesselId"])
print(f"embarcações com AIS pré-designação: {len(n_old)} | adotantes/sem data: {len(n_new)}")
P = ROOT / "data/interim/pilot_panel_trindade.csv"
rows = list(csv.DictReader(P.open(encoding="utf-8"))); hit = 0
for r in rows:
    k = (float(r["cell_lon"]), float(r["cell_lat"]), int(r["year"]), int(r["month"]))
    r["fishing_hours_preais"] = f"{agg.get(k, 0.0):.4f}"; hit += k in agg
with P.open("w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print(f"células×mês com esforço pré-AIS > 0: {hit}")
