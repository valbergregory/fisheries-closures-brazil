"""Sondagem de viabilidade do caso "reforma do defeso da sardinha" (D10).

PERGUNTA: a frota de cerco/traineira que captura a sardinha-verdadeira é
observável no AIS/GFW a ponto de sustentar um desenho causal sobre a reforma
da IN MAPA 18/2020?

DESENHO DA SONDAGEM: horas de pesca aparente na faixa latitudinal da norma
(22°00'S–28°36'S), por arte e mês, somando dois anos antes (2018-2019) e dois
depois (2021-2022) da reforma (publicada em 12/06/2020). 2020 é excluído por
ser o ano da mudança e do choque da pandemia.

O QUE A REFORMA MUDOU (ver outputs/policies/IN_*_r*.json):
  - outubro e 2ª quinzena de fevereiro: LIVRE -> PROIBIDO
  - 15 de junho a 31 de julho:          PROIBIDO -> LIVRE
  - novembro a 1ª quinzena de fevereiro: PROIBIDO nos dois regimes

ALERTA TRANSVERSAL que esta sondagem produziu: a cobertura AIS na costa
SE/S cresceu 2-3x entre 2018 e 2022. Comparações de NÍVEL bruto entre anos
no GFW medem, em boa parte, expansão de cobertura — não esforço. Toda
estatística deste projeto precisa de controle contemporâneo (efeitos fixos de
período ou razão contra grupo de comparação). Ver docs/decisions_log.md D13.

Saídas: outputs/diagnostics/sardinha_probe.md e sardinha_probe.png.
Diagnóstico — não é resultado científico.
"""
from __future__ import annotations

import glob
import json
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT_MD = ROOT / "outputs" / "diagnostics" / "sardinha_probe.md"
OUT_PNG = ROOT / "outputs" / "diagnostics" / "sardinha_probe.png"

LAT_N, LAT_S = -22.0, -28.6  # 22°00'S e 28°36'S (Art. 4º da IN IBAMA 15/2009)
PRE_YEARS, POS_YEARS = {2018, 2019}, {2021, 2022}
# regime por mês: 'both' = proibido antes e depois; 'new' = só depois;
# 'old' = só antes; 'free' = livre nos dois
REGIME = {1: "both", 2: "both", 3: "free", 4: "free", 5: "free", 6: "old",
          7: "old", 8: "free", 9: "free", 10: "new", 11: "both", 12: "both"}
LABEL = {"both": "proibido nos dois regimes", "new": "passou a PROIBIDO (2020)",
         "old": "passou a LIVRE (2020)", "free": "livre nos dois regimes"}


def load():
    prof = defaultdict(lambda: defaultdict(lambda: [0.0, 0.0]))
    files = sorted(glob.glob(str(ROOT / "data" / "raw" / "gfw_effort_sardinha_*.json")))
    if not files:
        raise SystemExit("Sem arquivos GFW da sondagem — rodar a extração antes.")
    for fp in files:
        year = int(Path(fp).stem[-4:])
        slot = 0 if year in PRE_YEARS else (1 if year in POS_YEARS else None)
        if slot is None:
            continue
        d = json.loads(Path(fp).read_text(encoding="utf-8"))
        for _ds, entries in d["entries"][0].items():
            for e in entries:
                if e.get("hours") is None or not (LAT_S <= e["lat"] <= LAT_N):
                    continue
                month = int(e["date"].split("-")[1])
                prof[e.get("geartype", "?")][month][slot] += e["hours"]
    return prof, files


def main():
    prof, files = load()
    n_pre, n_pos = len(PRE_YEARS), len(POS_YEARS)
    totals = {g: sum(v[0] + v[1] for v in m.values()) for g, m in prof.items()}

    # normalizador de cobertura: crescimento agregado de TODAS as artes
    all_pre = sum(v[0] for m in prof.values() for v in m.values()) / n_pre
    all_pos = sum(v[1] for m in prof.values() for v in m.values()) / n_pos
    coverage_growth = all_pos / all_pre if all_pre else float("nan")

    lines = [
        "# Sondagem do caso sardinha (D10) — viabilidade no AIS",
        "",
        f"Faixa latitudinal da norma: 22°00'S–28°36'S. Anos: {sorted(PRE_YEARS)} (pré) "
        f"vs {sorted(POS_YEARS)} (pós); 2020 excluído (ano da reforma + pandemia).",
        f"Fonte: GFW 4wings report mensal, {len(files)} arquivos. **Diagnóstico, não resultado.**",
        "",
        "## 1. A frota de cerco é observável?",
        "",
        "| Arte | horas totais (4 anos) | % do total |",
        "|---|---:|---:|",
    ]
    grand = sum(totals.values())
    for g, t in sorted(totals.items(), key=lambda x: -x[1])[:8]:
        lines.append(f"| {g} | {t:,.0f} | {100*t/grand:.1f}% |")
    purse = sum(t for g, t in totals.items() if "purse_seine" in g)
    lines += [
        "",
        f"**Cerco (todas as variantes de purse seine): {purse:,.0f} h = "
        f"{100*purse/grand:.2f}% do esforço observado na área.** A pescaria-alvo da "
        "norma é praticamente invisível no AIS, enquanto o arrasto domina o registro.",
        "",
        f"## 2. Alerta de cobertura: o esforço observado cresceu {coverage_growth:.2f}x "
        "entre os dois períodos",
        "",
        "Esse crescimento agregado é dominado por expansão de cobertura AIS, não por "
        "aumento real de pressão pesqueira. **Qualquer comparação de nível bruto entre "
        "anos do GFW é enviesada para cima.** As razões da tabela abaixo devem ser lidas "
        f"contra a referência {coverage_growth:.2f}x, não contra 1,00x.",
        "",
        "## 3. Assinatura sazonal do cerco (`other_purse_seines`)",
        "",
        "| Mês | Regime | h/mês pré | h/mês pós | razão | vs. cobertura |",
        "|---|---|---:|---:|---:|---:|",
    ]
    g = "other_purse_seines"
    for m in range(1, 13):
        pre = prof[g][m][0] / n_pre
        pos = prof[g][m][1] / n_pos
        ratio = pos / pre if pre > 0 else float("nan")
        rel = ratio / coverage_growth if pre > 0 else float("nan")
        lines.append(f"| {m:02d} | {LABEL[REGIME[m]]} | {pre:,.0f} | {pos:,.0f} | "
                     f"{ratio:.2f}x | {rel:.2f} |")
    # média da razão relativa por regime (leitura auditável, sem adjetivo)
    by_regime = defaultdict(list)
    for m in range(1, 13):
        pre = prof[g][m][0] / n_pre
        if pre > 0:
            by_regime[REGIME[m]].append((prof[g][m][1] / n_pos) / pre / coverage_growth)
    means = {k: sum(v) / len(v) for k, v in by_regime.items() if v}

    lines += [
        "",
        "A coluna final (razão ÷ crescimento de cobertura) é a leitura defensável: "
        "valores abaixo de 1 indicam queda relativa ao que a expansão do AIS faria "
        "esperar; acima de 1, aumento relativo.",
        "",
        "## 4. Médias da razão relativa, por regime",
        "",
        "| Regime do mês | média (razão ÷ cobertura) | nº de meses |",
        "|---|---:|---:|",
    ]
    for k in ("both", "new", "old", "free"):
        if k in means:
            lines.append(f"| {LABEL[k]} | {means[k]:.2f} | {len(by_regime[k])} |")
    lines += [
        "",
        "## 5. Leitura",
        "",
        "**Nenhum mês supera 1,00 na coluna relativa** — ou seja, o cerco não acompanhou "
        "a expansão da cobertura AIS em mês algum, o que já indica que a série do cerco "
        "não é comparável entre períodos pelo nível.",
        "",
        f"A única ordenação visível é que os meses proibidos nos DOIS regimes ficam mais "
        f"baixos ({means.get('both', float('nan')):.2f}) do que os demais "
        f"({means.get('free', float('nan')):.2f} nos livres). Mas os dois meses que "
        "identificariam a reforma não se separam: outubro, que passou a ser proibido, "
        f"marca {means.get('new', float('nan')):.2f}, praticamente igual a junho-julho "
        f"({means.get('old', float('nan')):.2f}), que passou a ser livre — quando a "
        "hipótese previa movimento em direções OPOSTAS. Somado ao volume absoluto "
        "(ordem de 150–250 h/mês na área inteira), não há sinal aproveitável.",
        "",
        "**Recomendação ao pesquisador:** NÃO promover a sardinha a caso principal. "
        "Ela é juridicamente excelente (duas mudanças opostas, mesma área e frota, "
        "área por coordenadas explícitas) mas empiricamente fraca na única fonte de "
        "esforço disponível. Usos defensáveis: (i) caso ilustrativo da contribuição de "
        "SI — mostra que a tabela-resumo oficial do IBAMA registra apenas o regime "
        "alterado e perde o defeso de recrutamento suprimido; (ii) teste de "
        "sensibilidade da hipótese de observabilidade; (iii) motivação para buscar "
        "dado de desembarque da sardinha (o Anexo II da IN 18/2020 institui formulário "
        "de desembarque por embarcação — fonte a investigar).",
    ]
    OUT_MD.write_text("\n".join(lines), encoding="utf-8")
    print("\n".join(lines[:6]))
    print(f"...\nrelatório -> {OUT_MD.relative_to(ROOT)}")

    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    colors = {"both": "#7f8c8d", "new": "#c0392b", "old": "#27ae60", "free": "#bdc3c7"}
    fig, axes = plt.subplots(1, 2, figsize=(13, 5))
    months = range(1, 13)
    for ax, gear, title in [
        (axes[0], "other_purse_seines", "Cerco (other_purse_seines) — pescaria da sardinha"),
        (axes[1], "trawlers", "Arrasto (trawlers) — comparação de cobertura"),
    ]:
        pre = [prof[gear][m][0] / n_pre for m in months]
        pos = [prof[gear][m][1] / n_pos for m in months]
        ax.bar([m - 0.2 for m in months], pre, 0.4, label="pré (2018-19)", color="#34495e")
        ax.bar([m + 0.2 for m in months], pos, 0.4, label="pós (2021-22)", color="#5dade2")
        for m in months:
            ax.axvspan(m - 0.5, m + 0.5, color=colors[REGIME[m]], alpha=0.14, zorder=0)
        ax.set_title(title, fontsize=10)
        ax.set_xticks(list(months))
        ax.set_xlabel("mês")
        ax.legend(fontsize=8)
    axes[0].set_ylabel("horas de pesca aparente / mês")
    handles = [plt.Rectangle((0, 0), 1, 1, color=colors[k], alpha=0.35) for k in LABEL]
    fig.legend(handles, list(LABEL.values()), loc="lower center", ncol=4, fontsize=8,
               frameon=False, bbox_to_anchor=(0.5, -0.04))
    fig.suptitle("Reforma do defeso da sardinha (IN MAPA 18/2020) — sondagem de "
                 "viabilidade\nfaixa 22°00'S–28°36'S; DIAGNÓSTICO, não resultado causal",
                 fontsize=11)
    fig.tight_layout()
    fig.savefig(OUT_PNG, dpi=150, bbox_inches="tight")
    print(f"figura   -> {OUT_PNG.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
