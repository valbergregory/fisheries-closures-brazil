"""Piloto de viabilidade — cruzamento espaço-temporal mínimo (diagnóstico).

Caso: criação do MONA das Ilhas de Trindade, Martim Vaz e Monte Columbia e da
APA do Arquipélago de Trindade e Martim Vaz (Decreto 9.312, de 19/03/2018).

O QUE ESTE SCRIPT FAZ (somente diagnóstico de plumbing — NÃO é resultado
científico):
 1. valida os polígonos reais baixados do WFS ICMBio/INDE
    (data/raw/uc_trindade_test.geojson): fechamento de anéis, faixas de
    coordenadas, bbox;
 2. constrói grade regular de 0,25° sobre o bbox + margem;
 3. classifica cada centro de célula por ponto-em-polígono (ray casting):
    dentro do MONA (proteção integral), dentro da APA (uso sustentável),
    fora (controle candidato);
 4. cruza com o calendário de tratamento mensal 2016-01..2020-12
    (tratado = dentro E >= 2018-03-19); a coluna de esforço fica NA até o
    token do Global Fishing Watch ser configurado;
 5. desenha o mapa diagnóstico (outputs/diagnostics/map_trindade_pilot.png).

Sem dependências geoespaciais externas: geometria implementada em Python puro
(suficiente para diagnóstico; o pipeline de produção usará R/sf via renv).
"""
from __future__ import annotations

import csv
import json
import math
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GEOJSON = ROOT / "data" / "raw" / "uc_trindade_test.geojson"
OUT_DIAG = ROOT / "outputs" / "diagnostics"
OUT_PANEL = ROOT / "data" / "interim" / "pilot_panel_trindade.csv"

TREATMENT_DATE = date(2018, 3, 19)  # Decreto 9.312/2018 (publicado 20/03/2018)
GRID_STEP = 0.25
MARGIN = 2.0  # graus além do bbox da APA (anel de controle)


def load_features():
    d = json.loads(GEOJSON.read_text(encoding="utf-8"))
    feats = {}
    for f in d["features"]:
        sigla = f["properties"]["sigla_cate"]
        feats[sigla] = f
    return feats


def rings_of(geom):
    """Anéis externos de um (Multi)Polygon como listas de (lon, lat)."""
    if geom["type"] == "Polygon":
        return [geom["coordinates"][0]]
    return [part[0] for part in geom["coordinates"]]


def validate_polygon(name, geom):
    ok = True
    n_pts = 0
    for i, ring in enumerate(rings_of(geom)):
        n_pts += len(ring)
        if ring[0] != ring[-1]:
            print(f"  [FALHA] {name} anel {i}: não fechado")
            ok = False
        for lon, lat in ring:
            if not (-180 <= lon <= 180 and -90 <= lat <= 90):
                print(f"  [FALHA] {name}: coordenada fora de faixa ({lon},{lat})")
                ok = False
                break
    lons = [p[0] for r in rings_of(geom) for p in r]
    lats = [p[1] for r in rings_of(geom) for p in r]
    bbox = (min(lons), min(lats), max(lons), max(lats))
    print(f"  [{'OK' if ok else 'FALHA'}] {name}: {len(rings_of(geom))} anel(is), "
          f"{n_pts} vértices, bbox={tuple(round(v, 3) for v in bbox)}")
    return ok, bbox


def point_in_geom(lon, lat, geom):
    """Ray casting nos anéis externos (suficiente: sem buracos no dado)."""
    for ring in rings_of(geom):
        inside = False
        n = len(ring)
        j = n - 1
        for i in range(n):
            xi, yi = ring[i]
            xj, yj = ring[j]
            if (yi > lat) != (yj > lat):
                x_cross = (xj - xi) * (lat - yi) / (yj - yi) + xi
                if lon < x_cross:
                    inside = not inside
            j = i
        if inside:
            return True
    return False


def dist_to_boundary_km(lon, lat, geom):
    """Distância aproximada (equiretangular, km) ao segmento de anel mais próximo."""
    coslat = math.cos(math.radians(lat))
    best = float("inf")
    for ring in rings_of(geom):
        for (x1, y1), (x2, y2) in zip(ring[:-1], ring[1:]):
            ax, ay = (x1 - lon) * coslat, (y1 - lat)
            bx, by = (x2 - lon) * coslat, (y2 - lat)
            dx, dy = bx - ax, by - ay
            seg2 = dx * dx + dy * dy
            t = 0.0 if seg2 == 0 else max(0.0, min(1.0, -(ax * dx + ay * dy) / seg2))
            px, py = ax + t * dx, ay + t * dy
            best = min(best, px * px + py * py)
    return math.sqrt(best) * 111.32


def main():
    OUT_DIAG.mkdir(parents=True, exist_ok=True)
    OUT_PANEL.parent.mkdir(parents=True, exist_ok=True)

    feats = load_features()
    mona, apa = feats["MONA"], feats["APA"]
    print("== 1. Validação dos polígonos (WFS ICMBio/INDE) ==")
    ok1, _ = validate_polygon("MONA Trindade/Martim Vaz/Monte Columbia",
                              mona["geometry"])
    ok2, bbox_apa = validate_polygon("APA Arquipélago Trindade e Martim Vaz",
                                     apa["geometry"])
    if not (ok1 and ok2):
        sys.exit("Polígonos inválidos — interromper piloto.")

    print("== 2-3. Grade 0,25° e classificação ==")
    x0 = math.floor((bbox_apa[0] - MARGIN) / GRID_STEP) * GRID_STEP
    x1 = math.ceil((bbox_apa[2] + MARGIN) / GRID_STEP) * GRID_STEP
    y0 = math.floor((bbox_apa[1] - MARGIN) / GRID_STEP) * GRID_STEP
    y1 = math.ceil((bbox_apa[3] + MARGIN) / GRID_STEP) * GRID_STEP
    cells = []
    lat = y0
    while lat < y1:
        lon = x0
        while lon < x1:
            clon, clat = lon + GRID_STEP / 2, lat + GRID_STEP / 2
            in_mona = point_in_geom(clon, clat, mona["geometry"])
            in_apa = point_in_geom(clon, clat, apa["geometry"])
            zone = "mona" if in_mona else ("apa" if in_apa else "outside")
            d_km = dist_to_boundary_km(clon, clat, apa["geometry"])
            cells.append((clon, clat, zone, round(d_km, 1)))
            lon += GRID_STEP
        lat += GRID_STEP
    from collections import Counter
    cnt = Counter(z for _, _, z, _ in cells)
    print(f"  células: {len(cells)} | dentro MONA: {cnt['mona']} | "
          f"dentro APA (fora MONA): {cnt['apa']} | fora: {cnt['outside']}")

    print("== 4. Painel célula × mês (esforço = NA até token GFW) ==")
    months = [(y, m) for y in range(2016, 2021) for m in range(1, 13)]
    with OUT_PANEL.open("w", newline="", encoding="utf-8") as fh:
        w = csv.writer(fh)
        w.writerow(["cell_lon", "cell_lat", "zone", "dist_boundary_km",
                    "year", "month", "post", "treated_mona", "treated_apa",
                    "fishing_hours"])
        for clon, clat, zone, d_km in cells:
            for y, m in months:
                post = int(date(y, m, 1) >= date(TREATMENT_DATE.year,
                                                 TREATMENT_DATE.month, 1))
                w.writerow([clon, clat, zone, d_km, y, m, post,
                            int(post and zone == "mona"),
                            int(post and zone in ("mona", "apa")), "NA"])
    n_rows = len(cells) * len(months)
    print(f"  painel: {n_rows} linhas ({len(cells)} células × {len(months)} meses)"
          f" -> {OUT_PANEL.relative_to(ROOT)}")

    print("== 5. Mapa diagnóstico ==")
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    fig, ax = plt.subplots(figsize=(9, 7))
    colors = {"mona": "#c0392b", "apa": "#e67e22", "outside": "#bdc3c7"}
    for clon, clat, zone, _ in cells:
        ax.plot(clon, clat, "s", ms=2.4, color=colors[zone], alpha=0.7)
    for geom, col, lab in [(apa["geometry"], "#d35400", "APA (Decreto 9.312/2018)"),
                           (mona["geometry"], "#922b21", "MONA (Decreto 9.312/2018)")]:
        first = True
        for ring in rings_of(geom):
            xs, ys = zip(*ring)
            ax.plot(xs, ys, color=col, lw=1.6, label=lab if first else None)
            first = False
    ax.set_title("Piloto diagnóstico — MONA/APA Trindade e Martim Vaz\n"
                 "grade 0,25°; polígonos reais (WFS ICMBio/INDE); "
                 "SEM dados de esforço (aguarda token GFW)")
    ax.set_xlabel("Longitude")
    ax.set_ylabel("Latitude")
    ax.legend(loc="lower left", fontsize=8)
    ax.set_aspect("equal")
    out_png = OUT_DIAG / "map_trindade_pilot.png"
    fig.savefig(out_png, dpi=150, bbox_inches="tight")
    print(f"  mapa: {out_png.relative_to(ROOT)}")
    print("== Piloto concluído (diagnóstico apenas) ==")


if __name__ == "__main__":
    main()
