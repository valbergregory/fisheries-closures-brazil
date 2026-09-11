"""B1+B2 — painel célula×mês do caso camarão SE/S (Portaria SAP/MAPA 656/2022).

Área de estudo (PROVISÓRIA, decisão D3 pendente): células 0,25° oceânicas
(máscara terra/mar do OISST) entre 21°18'S (divisa ES–RJ, coordenada citada
na Portaria 221/2021) e 33°45'S (Chuí), a até 200 km da célula de terra mais
próxima (proxy de plataforma). Esforço por VESSEL_ID (traz geartype e
firstTransmissionDate) -> horas de arrasto totais e da frota com AIS anterior
a 28/01/2023; presença total (por bandeira) como controle de cobertura.
"""
from __future__ import annotations
import csv, glob, json, math
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
STEP = 0.25
LAT_N, LAT_S = -21.30, -33.75
CUT = "2023-01-28"
COAST_KM = 200.0


def cc(v):
    return math.floor(round(v / 0.1) * 0.1 / STEP + 1e-9) * STEP + STEP / 2


# --- máscara terra/mar do OISST (um arquivo, um dia) via ncdf4 no R seria mais limpo;
# aqui lemos a lista de células oceânicas já exportada por R/08 para Trindade? Não cobre.
# Usamos o SST mensal do camarão, gerado por scripts/19 (R) antes deste script.
sst_file = ROOT / "data/interim/sst_camarao_monthly.csv"
ocean = set()
if sst_file.exists():
    with sst_file.open(encoding="utf-8") as fh:
        for r in csv.DictReader(fh):
            ocean.add((float(r["cell_lon"]), float(r["cell_lat"])))
else:
    raise SystemExit("Rodar scripts/19_camarao_sst_mask.R primeiro (gera sst_camarao_monthly.csv).")

# distância à terra: células da bbox ausentes na máscara oceânica = terra
lons = [round(-54.0 + STEP / 2 + i * STEP, 3) for i in range(int(14 / STEP))]
lats = [round(-34.5 + STEP / 2 + j * STEP, 3) for j in range(int(13.5 / STEP))]
land = [(x, y) for x in lons for y in lats if (x, y) not in ocean]


def dist_km(a, b):
    la1, lo1, la2, lo2 = map(math.radians, (a[1], a[0], b[1], b[0]))
    h = math.sin((la2 - la1) / 2) ** 2 + math.cos(la1) * math.cos(la2) * math.sin((lo2 - lo1) / 2) ** 2
    return 2 * 6371 * math.asin(math.sqrt(h))


cells = {}
for c in ocean:
    if not (LAT_S <= c[1] <= LAT_N):
        continue
    d = min(dist_km(c, l) for l in land) if land else float("nan")
    if d <= COAST_KM:
        cells[c] = d
print(f"células oceânicas na faixa RJ–RS a ate {COAST_KM:.0f} km da terra: {len(cells)} (terra na bbox: {len(land)})")

trawl_all = defaultdict(float); trawl_pre = defaultdict(float); other_all = defaultdict(float)
vessels = {}
for fp in sorted(glob.glob(str(ROOT / "data/raw/camarao/gfw_effort_vid_camarao_*.json"))):
    d = json.loads(Path(fp).read_text(encoding="utf-8"))
    if "entries" not in d:
        print("ignorado:", Path(fp).name); continue
    for _ds, recs in d["entries"][0].items():
        for r in recs:
            h = r.get("hours")
            if not h:
                continue
            c = (cc(r["lon"]), cc(r["lat"]))
            if c not in cells:
                continue
            y, m = r["date"].split("-"); k = (c[0], c[1], int(y), int(m))
            g = (r.get("geartype") or "").upper()
            ft = (r.get("firstTransmissionDate") or "")[:10]
            vessels[r["vesselId"]] = (g, ft, r.get("flag"))
            if g == "TRAWLERS":
                trawl_all[k] += h
                if ft and ft < CUT:
                    trawl_pre[k] += h
            else:
                other_all[k] += h
pres = defaultdict(float)
for fp in sorted(glob.glob(str(ROOT / "data/raw/camarao/gfw_presence_flag_camarao_*.json"))):
    d = json.loads(Path(fp).read_text(encoding="utf-8"))
    if "entries" not in d:
        continue
    for _ds, recs in d["entries"][0].items():
        for r in recs:
            h = r.get("hours")
            if not h:
                continue
            c = (cc(r["lon"]), cc(r["lat"]))
            if c in cells:
                y, m = r["date"].split("-"); pres[(c[0], c[1], int(y), int(m))] += h
n_trawl = sum(1 for v in vessels.values() if v[0] == "TRAWLERS")
n_trawl_pre = sum(1 for v in vessels.values() if v[0] == "TRAWLERS" and v[1] and v[1] < CUT)
print(f"embarcações: {len(vessels)} | arrasto: {n_trawl} | arrasto com AIS antes de {CUT}: {n_trawl_pre}")
out = ROOT / "data/processed/panel_camarao.csv"
years = sorted({k[2] for k in list(trawl_all) + list(pres)})
with out.open("w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh)
    w.writerow(["cell_lon", "cell_lat", "dist_land_km", "year", "month", "trawl_hours", "trawl_hours_prefleet", "other_hours", "presence_hours"])
    for (x, y), dkm in sorted(cells.items()):
        for yr in years:
            for mo in range(1, 13):
                k = (x, y, yr, mo)
                w.writerow([x, y, round(dkm, 1), yr, mo, f"{trawl_all.get(k, 0):.4f}", f"{trawl_pre.get(k, 0):.4f}",
                            f"{other_all.get(k, 0):.4f}", f"{pres.get(k, 0):.4f}"])
print(f"painel -> {out.relative_to(ROOT)} | anos {years[0]}-{years[-1]} | linhas {len(cells) * len(years) * 12}")
