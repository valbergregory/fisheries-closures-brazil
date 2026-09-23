"""Painel NACIONAL célula×mês para o controle geográfico (pergunta do
pesquisador em 23/09: por que não usar toda a costa?).

Regiões e seus regimes de defeso do camarão:
  SES (RJ-RS)  — Portaria SAP/MAPA 656/2022: calendário MUDOU em 2023
                 (fev abriu->fechou; mai fechou->abriu)   => TRATADA
  N   (AP/PA)  — Portaria MDIC/MMA 75/2017: 15/12 a 15/02, INALTERADO
  NE  (CE-BA)  — IN MMA 14/2004: duas janelas, INALTERADO
As duas últimas são controles: se a queda de fevereiro no SE/S for uma
tendência nacional do arrasto, ela deve aparecer nelas também.

Saída: data/processed/panel_costa.csv (só células oceânicas a <=100 km da
costa, mesmo critério da D3; distância calculada em scripts/34).
"""
from __future__ import annotations
import csv, glob, json, math
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STEP = 0.25
CUT = "2023-01-28"


def cc(v):
    return math.floor(round(v / 0.1) * 0.1 / STEP + 1e-9) * STEP + STEP / 2


def collect(region, pattern_effort, pattern_presence):
    trawl, trawl_pre, other, pres = (defaultdict(float) for _ in range(4))
    gear = defaultdict(float)
    vessels = {}
    for fp in sorted(glob.glob(str(ROOT / "data/raw/costa" / pattern_effort))):
        try:
            d = json.loads(Path(fp).read_text(encoding="utf-8"))
        except Exception as e:
            print("  ignorado:", Path(fp).name, e); continue
        if "entries" not in d:
            continue
        for _ds, recs in d["entries"][0].items():
            for r in recs:
                h = r.get("hours")
                if not h:
                    continue
                k = (cc(r["lon"]), cc(r["lat"]), int(r["date"][:4]), int(r["date"][5:7]))
                g = (r.get("geartype") or "UNKNOWN").upper()
                ft = (r.get("firstTransmissionDate") or "")[:10]
                vessels[r.get("vesselId")] = (g, ft)
                gear[(k[0], k[1], k[2], k[3], g)] += h
                if g == "TRAWLERS":
                    trawl[k] += h
                    if ft and ft < CUT:
                        trawl_pre[k] += h
                else:
                    other[k] += h
    for fp in sorted(glob.glob(str(ROOT / "data/raw/costa" / pattern_presence))):
        try:
            d = json.loads(Path(fp).read_text(encoding="utf-8"))
        except Exception:
            continue
        if "entries" not in d:
            continue
        for _ds, recs in d["entries"][0].items():
            for r in recs:
                h = r.get("hours")
                if h:
                    pres[(cc(r["lon"]), cc(r["lat"]), int(r["date"][:4]), int(r["date"][5:7]))] += h
    n_tr = sum(1 for v in vessels.values() if v[0] == "TRAWLERS")
    print(f"{region}: {len(vessels)} embarcações ({n_tr} arrasto) | "
          f"{sum(trawl.values()):,.0f} h de arrasto | {len({(k[0], k[1]) for k in trawl})} células com arrasto")
    return trawl, trawl_pre, other, pres, gear


rows = []
gear_rows = []
for region, pe, pp in [("N", "gfw_effort_vid_norte_*.json", "gfw_presence_flag_norte_*.json"),
                       ("NE", "gfw_effort_vid_nordeste_*.json", "gfw_presence_flag_nordeste_*.json")]:
    trawl, trawl_pre, other, pres, gear = collect(region, pe, pp)
    cells = sorted({(k[0], k[1]) for k in list(trawl) + list(pres)})
    for (x, y) in cells:
        for yr in range(2018, 2025):
            for mo in range(1, 13):
                k = (x, y, yr, mo)
                rows.append([region, x, y, yr, mo, f"{trawl.get(k, 0):.4f}", f"{trawl_pre.get(k, 0):.4f}",
                             f"{other.get(k, 0):.4f}", f"{pres.get(k, 0):.4f}"])
    for k, v in gear.items():
        gear_rows.append([region, k[0], k[1], k[2], k[3], k[4], f"{v:.4f}"])

out = ROOT / "data/processed/panel_costa_raw.csv"
with out.open("w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh)
    w.writerow(["region", "cell_lon", "cell_lat", "year", "month", "trawl_hours",
                "trawl_hours_prefleet", "other_hours", "presence_hours"])
    w.writerows(rows)
outg = ROOT / "data/processed/panel_costa_gear.csv"
with outg.open("w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh)
    w.writerow(["region", "cell_lon", "cell_lat", "year", "month", "geartype", "hours"])
    w.writerows(gear_rows)
print(f"painel bruto -> {out.relative_to(ROOT)} ({len(rows)} linhas)")
print("Próximo: Rscript scripts/34_costa_distance.R (distância à costa e filtro D3)")
