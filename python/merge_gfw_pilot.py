"""Preenche o painel piloto de Trindade com esforço REAL do GFW (API 4wings).

Entrada: data/raw/gfw_effort_trindade_*.json (report mensal 0,1°, 2016–2020,
         group-by GEARTYPE) + data/interim/pilot_panel_trindade.csv (grade
         0,25° × mês com zonas/tratamento, esforço = NA).
Saída:   data/interim/pilot_panel_trindade.csv (colunas fishing_hours e
         vessels preenchidas; 0 quando nenhum esforço reportado na célula),
         outputs/diagnostics/pilot_effort_summary.md (antes/depois por zona),
         outputs/diagnostics/map_trindade_effort.png (mapa pré/pós).

DIAGNÓSTICO de viabilidade — não é resultado científico. Agregação 0,1°→0,25°
por atribuição do canto da célula GFW à célula-mãe (floor). Meses sem entrada
= 0 horas (o report do GFW omite células sem esforço; zero aqui significa
"nenhum esforço aparente detectado", condicionado à cobertura AIS).
"""
from __future__ import annotations

import csv
import glob
import json
import math
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PANEL = ROOT / "data" / "interim" / "pilot_panel_trindade.csv"
OUT_MD = ROOT / "outputs" / "diagnostics" / "pilot_effort_summary.md"
OUT_PNG = ROOT / "outputs" / "diagnostics" / "map_trindade_effort.png"
STEP = 0.25


def cell_center(v: float) -> float:
    return math.floor(round(v / 0.1) * 0.1 / STEP + 1e-9) * STEP + STEP / 2


def load_effort():
    """(lon_c, lat_c, year, month) -> [hours, vessel_ids] somados sobre geartypes."""
    agg = defaultdict(lambda: [0.0, 0])
    gears = defaultdict(float)
    files = sorted(glob.glob(str(ROOT / "data" / "raw" / "gfw_effort_trindade_20*.json")))
    for fp in files:
        d = json.loads(Path(fp).read_text(encoding="utf-8"))
        for ds, entries in d["entries"][0].items():
            for e in entries:
                if e.get("hours") is None:
                    continue
                y, m = e["date"].split("-")
                key = (cell_center(e["lon"]), cell_center(e["lat"]), int(y), int(m))
                agg[key][0] += e["hours"]
                agg[key][1] += e.get("vesselIDs") or 0
                gears[e.get("geartype", "?")] += e["hours"]
    return agg, gears, files


def main():
    agg, gears, files = load_effort()
    print(f"arquivos GFW: {len(files)} | combinações célula×mês com esforço: {len(agg)}")
    print("horas por geartype:", {k: round(v) for k, v in
                                  sorted(gears.items(), key=lambda x: -x[1])})

    rows = list(csv.DictReader(PANEL.open(encoding="utf-8")))
    matched = 0
    unmatched_keys = set(agg)
    for r in rows:
        key = (float(r["cell_lon"]), float(r["cell_lat"]),
               int(r["year"]), int(r["month"]))
        if key in agg:
            r["fishing_hours"] = f"{agg[key][0]:.4f}"
            r["vessels"] = str(agg[key][1])
            matched += 1
            unmatched_keys.discard(key)
        else:
            r["fishing_hours"] = "0"
            r["vessels"] = "0"
    print(f"células×mês do painel com esforço >0: {matched} de {len(rows)}")
    if unmatched_keys:
        print(f"[ATENÇÃO] {len(unmatched_keys)} chaves GFW fora da grade do painel "
              f"(borda do bbox) — ex.: {sorted(unmatched_keys)[:3]}")

    fields = list(rows[0].keys())
    with PANEL.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)

    # ---- estatísticas antes/depois por zona (médias mensais por célula) ----
    stats = defaultdict(lambda: [0.0, 0])  # (zone, period) -> [hours_sum, n_obs]
    for r in rows:
        period = "pos" if r["post"] == "1" else "pre"
        k = (r["zone"], period)
        stats[k][0] += float(r["fishing_hours"])
        stats[k][1] += 1
    lines = ["# Piloto Trindade — esforço GFW antes/depois (DIAGNÓSTICO)", "",
             "Média de horas de pesca aparente por célula-mês (grade 0,25°, "
             "2016-01–2020-12; pós = a partir de 2018-03, Decreto 9.312/2018).",
             "Fonte: GFW 4wings report v4.0, acesso 2026-09-04. NÃO é resultado "
             "causal: sem controles, sem inferência.", "",
             "| Zona | Pré (média h/célula-mês) | Pós | Δ% |",
             "|---|---|---|---|"]
    for zone in ("mona", "apa", "outside"):
        pre = stats[(zone, "pre")][0] / max(stats[(zone, "pre")][1], 1)
        pos = stats[(zone, "pos")][0] / max(stats[(zone, "pos")][1], 1)
        delta = (pos / pre - 1) * 100 if pre > 0 else float("nan")
        lines.append(f"| {zone} | {pre:.3f} | {pos:.3f} | {delta:+.1f}% |")
        print(f"{zone:8s} pre={pre:8.3f} pos={pos:8.3f} delta={delta:+.1f}%")
    lines += ["", "Horas totais por geartype na região (2016–2020): " +
              ", ".join(f"{k}={round(v)}" for k, v in
                        sorted(gears.items(), key=lambda x: -x[1]))]
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")
    print(f"resumo -> {OUT_MD.relative_to(ROOT)}")

    # ---- mapa pré/pós ----
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    from matplotlib.colors import LogNorm

    cells = {}
    for r in rows:
        k = (float(r["cell_lon"]), float(r["cell_lat"]))
        z = cells.setdefault(k, {"zone": r["zone"], "pre": 0.0, "pos": 0.0})
        z["pos" if r["post"] == "1" else "pre"] += float(r["fishing_hours"])

    geo = json.loads((ROOT / "data" / "raw" / "uc_trindade_test.geojson")
                     .read_text(encoding="utf-8"))

    def rings(g):
        return ([g["coordinates"][0]] if g["type"] == "Polygon"
                else [p[0] for p in g["coordinates"]])

    fig, axes = plt.subplots(1, 2, figsize=(15, 6.5), sharey=True)
    vmax = max(max(c["pre"], c["pos"]) for c in cells.values())
    for ax, period, label in [(axes[0], "pre", "Pré (2016-01–2018-02)"),
                              (axes[1], "pos", "Pós (2018-03–2020-12)")]:
        xs = [k[0] for k in cells]
        ys = [k[1] for k in cells]
        vs = [max(cells[k][period], 0.01) for k in cells]
        sc = ax.scatter(xs, ys, c=vs, s=14, marker="s", cmap="viridis",
                        norm=LogNorm(vmin=0.01, vmax=vmax))
        for f in geo["features"]:
            col = "#c0392b" if f["properties"]["sigla_cate"] == "MONA" else "#e67e22"
            for ring in rings(f["geometry"]):
                ax.plot(*zip(*ring), color=col, lw=1.5)
        ax.set_title(label)
        ax.set_xlabel("Longitude")
        ax.set_aspect("equal")
    axes[0].set_ylabel("Latitude")
    fig.colorbar(sc, ax=axes, label="horas de pesca aparente (log; total do período)",
                 shrink=0.85)
    fig.suptitle("Esforço GFW — região de Trindade e Martim Vaz "
                 "(MONA vermelho, APA laranja) — DIAGNÓSTICO", y=0.98)
    fig.savefig(OUT_PNG, dpi=150, bbox_inches="tight")
    print(f"mapa -> {OUT_PNG.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
