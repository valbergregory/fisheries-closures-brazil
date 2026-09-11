"""Cobertura AIS EXÓGENA à pesca, por célula-mês (decisão do pesquisador,
2026-09-10, opção 1 do relatório da fase 1).

Fonte: 4wings report do dataset public-global-presence agrupado por
VESSEL_ID (data/raw/presence_vessel/*.json), que traz `vesselType` por
registro. Agrega horas de presença por célula 0,25° × mês × classe:
  - cargo_hours     : CARGO + TANKER (tráfego comercial; exógeno à pesca)
  - passenger_hours : PASSENGER
  - nonfish_hours   : tudo exceto FISHING, GEAR (boias/equipamento) e
                      CARRIER (navios-transportadores ligados à pesca)
  - fishing_pres    : FISHING (presença dos pesqueiros — endógena; só p/ auditoria)
  - n_vessels_nonfish: embarcações não-pesqueiras distintas na célula-mês
Escreve data/interim/coverage_exog_trindade.csv e faz o merge no painel piloto.
"""
from __future__ import annotations
import csv, glob, json, math
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "data" / "raw" / "presence_vessel"
OUT = ROOT / "data" / "interim" / "coverage_exog_trindade.csv"
PANEL = ROOT / "data" / "interim" / "pilot_panel_trindade.csv"
STEP = 0.25
FISH_LIKE = {"FISHING", "GEAR", "CARRIER"}

def cell_center(v): return math.floor(round(v / 0.1) * 0.1 / STEP + 1e-9) * STEP + STEP / 2

agg = defaultdict(lambda: defaultdict(float)); vessels = defaultdict(set); types = defaultdict(float)
n_files = 0
for fp in sorted(SRC.glob("gfw_presence_vid_trindade_20*.json")):
    d = json.loads(fp.read_text(encoding="utf-8"))
    if "entries" not in d: print("ignorado:", fp.name); continue
    n_files += 1
    for _ds, recs in d["entries"][0].items():
        for r in recs:
            h = r.get("hours")
            if h is None: continue
            vt = (r.get("vesselType") or "UNKNOWN").upper()
            y, m = r["date"].split("-")
            k = (cell_center(r["lon"]), cell_center(r["lat"]), int(y), int(m))
            types[vt] += h
            if vt in ("CARGO", "TANKER"): agg[k]["cargo_hours"] += h
            if vt == "PASSENGER": agg[k]["passenger_hours"] += h
            if vt == "FISHING": agg[k]["fishing_pres"] += h
            if vt not in FISH_LIKE:
                agg[k]["nonfish_hours"] += h; vessels[k].add(r.get("vesselId"))
print(f"arquivos: {n_files} | horas por tipo:", {k: round(v) for k, v in sorted(types.items(), key=lambda x: -x[1])})
cols = ["cargo_hours", "passenger_hours", "nonfish_hours", "fishing_pres"]
with OUT.open("w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh); w.writerow(["cell_lon", "cell_lat", "year", "month"] + cols + ["n_vessels_nonfish"])
    for k in sorted(agg):
        w.writerow(list(k) + [f"{agg[k][c]:.4f}" for c in cols] + [len(vessels[k])])
rows = list(csv.DictReader(PANEL.open(encoding="utf-8"))); hit = 0
for r in rows:
    k = (float(r["cell_lon"]), float(r["cell_lat"]), int(r["year"]), int(r["month"]))
    for c in cols: r[c] = f"{agg[k][c]:.4f}" if k in agg else "0"
    r["n_vessels_nonfish"] = str(len(vessels[k])) if k in agg else "0"; hit += k in agg
with PANEL.open("w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=list(rows[0].keys())); w.writeheader(); w.writerows(rows)
print(f"painel: {hit} de {len(rows)} células×mês com presença classificada -> {OUT.relative_to(ROOT)}")
