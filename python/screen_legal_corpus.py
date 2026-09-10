"""Triagem do corpus legal: recorta o ato de interesse e isola dispositivos.

PROBLEMA QUE ESTE MÓDULO RESOLVE (achado de 2026-09-10): os PDFs linkados na
tabela de defesos marinhos do IBAMA não são a norma isolada — são a PÁGINA
INTEIRA do Diário Oficial em que a norma foi publicada. Um mesmo arquivo pode
conter outros atos e matérias sem relação (tabelas de carreira, portarias de
pessoal). Extrair a regra exige recortar o ato correto dentro da página.

O que o script faz, sem julgar conteúdo:
 1. localiza cabeçalhos de atos (PORTARIA/INSTRUÇÃO NORMATIVA/DECRETO Nº X);
 2. delimita cada ato até o próximo cabeçalho;
 3. marca qual bloco corresponde ao ato-alvo (inferido do nome do arquivo);
 4. isola os dispositivos operativos: artigos com verbo proibitivo, períodos
    (datas por extenso ou numéricas) e coordenadas geográficas;
 5. grava um dossiê por norma em outputs/policies/screening/.

A saída é INSUMO para a estruturação da regra, sempre lida por humano antes
de virar registro (ver docs/policy_registry_protocol.md). Nenhum campo do
registro é preenchido automaticamente a partir daqui.
"""
from __future__ import annotations

import glob
import re
import unicodedata
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORPUS = ROOT / "data" / "legal" / "corpus_defesos_marinhos"
OUT = ROOT / "outputs" / "policies" / "screening"

# Cabeçalho de ato: caixa alta E data por extenso ("PORTARIA Nº 221, DE 3 DE
# MAIO DE 2021"). Sem exigir a data, citações de outras normas no corpo do
# texto seriam contadas como novos atos e o recorte sairia truncado.
ACT_HEAD = re.compile(
    r"(INSTRU[ÇC][ÃA]O\s+NORMATIVA(?:\s+INTERMINISTERIAL|\s+CONJUNTA)?|PORTARIA(?:\s+INTERMINISTERIAL|\s+CONJUNTA)?|DECRETO)"
    r"[^\n]{0,60}?N[ºo°\.]?\s*(\d+[\-\w]*)\s*,?\s*DE\s+\d{1,2}[ºo°]?\s*DE\s+[A-ZÇÃÉÊÔ]{4,}\s+DE\s+\d{4}",
)
# períodos: "de 1º de março a 31 de maio", "01/03 a 31/05", "15 de dezembro"
PERIOD = re.compile(
    r"(?:de\s+)?\d{1,2}[ºo°]?\s*(?:de\s+)?(?:janeiro|fevereiro|mar[çc]o|abril|maio|junho|julho|agosto|setembro|outubro|novembro|dezembro)"
    r"(?:\s+de\s+\d{4})?",
    re.I,
)
COORD = re.compile(r"\d{1,3}\s*[º°]\s*\d{0,2}\s*['’´]?\s*\d{0,2}\s*[\"”]?\s*(?:S|N|W|O|Sul|Norte|Oeste)\b", re.I)
BAN_VERB = re.compile(r"\b(proibir|proibida?s?|fica[m]?\s+proibid|veda[rd]|defeso|suspend)", re.I)
ARTICLE = re.compile(r"Art\.\s*\d+", re.I)


def deaccent(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s) if unicodedata.category(c) != "Mn")


def target_from_filename(stem: str) -> tuple[str, str]:
    """Nome do arquivo -> (tipo do ato, número) esperado. Ex.: '...n-o-15_2009' -> ('in', '15')."""
    m = re.search(r"n-o-_?(\d+[\-\w]*)_(\d{4})", stem)
    num = m.group(1) if m else ""
    kind = "in" if re.search(r"\bin_", stem) else ("portaria" if "portaria" in stem else "?")
    return kind, num.rstrip("_")


def split_acts(text: str) -> list[tuple[int, str, str]]:
    """[(posição, rótulo, número)] de cada cabeçalho de ato encontrado."""
    return [(m.start(), m.group(1).upper(), m.group(2)) for m in ACT_HEAD.finditer(text)]


def operative_lines(block: str) -> list[str]:
    """Frases do bloco que carregam proibição, período ou coordenada."""
    flat = re.sub(r"\s*\n\s*", " ", block)
    sentences = re.split(r"(?<=[.;])\s+(?=[A-ZÀ-Ú§]|Art\.)", flat)
    keep = []
    for s in sentences:
        s = s.strip()
        if len(s) < 25:
            continue
        if BAN_VERB.search(s) or (PERIOD.search(s) and ARTICLE.search(s)) or COORD.search(s):
            keep.append(re.sub(r"\s{2,}", " ", s))
    return keep


def screen(fp: Path) -> dict:
    text = fp.read_text(encoding="utf-8")
    acts = split_acts(text)
    kind, num = target_from_filename(fp.stem)
    # bloco-alvo: cabeçalho cujo número bate com o nome do arquivo
    target_idx = None
    for i, (pos, label, n) in enumerate(acts):
        if n == num and (kind == "?" or deaccent(label).lower().startswith(kind[:3])):
            target_idx = i
            break
    if target_idx is None:
        # sem cabeçalho do alvo: a norma pode estar na página sem o título
        # (recorte do DOU começando no meio) -> usa o texto inteiro
        block, note = text, "CABEÇALHO DO ATO-ALVO NÃO ENCONTRADO — bloco = arquivo inteiro; conferir manualmente"
    else:
        start = acts[target_idx][0]
        end = acts[target_idx + 1][0] if target_idx + 1 < len(acts) else len(text)
        block, note = text[start:end], ""
    return {
        "file": fp.name,
        "expected": f"{kind.upper()} nº {num}",
        "acts_in_page": [f"{l} {n}" for _, l, n in acts],
        "block_chars": len(block),
        "note": note,
        "operative": operative_lines(block),
        "coords": sorted(set(COORD.findall(block))),
    }


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    files = sorted(CORPUS.glob("*.txt"))
    summary = ["# Triagem do corpus legal — dossiês por norma", "",
               "Gerado por `python/screen_legal_corpus.py`. INSUMO para estruturação;",
               "nenhum campo do registro é preenchido automaticamente daqui.", ""]
    for fp in files:
        d = screen(fp)
        lines = [f"# {d['file']}", "",
                 f"- Ato esperado (pelo nome do arquivo): **{d['expected']}**",
                 f"- Atos detectados na página do DOU: {', '.join(d['acts_in_page']) or '(nenhum cabeçalho)'}",
                 f"- Tamanho do bloco recortado: {d['block_chars']} chars"]
        if d["note"]:
            lines.append(f"- ⚠ {d['note']}")
        if d["coords"]:
            lines += ["", "## Coordenadas citadas", ""] + [f"- {c}" for c in d["coords"]]
        lines += ["", "## Dispositivos operativos (proibição / período / área)", ""]
        lines += [f"{i+1}. {s}" for i, s in enumerate(d["operative"])] or ["(nenhum isolado — ler o texto integral)"]
        (OUT / f"{fp.stem}.md").write_text("\n".join(lines), encoding="utf-8")
        flag = " [!]" if d["note"] else ""
        summary.append(f"- `{fp.stem}` — {len(d['operative'])} dispositivos, "
                       f"{len(d['coords'])} coordenadas, {len(d['acts_in_page'])} atos na página"
                       f"{' ⚠ recorte a conferir' if d['note'] else ''}")
        print(f"{fp.stem[:50]:52s} disp={len(d['operative']):3d} coord={len(d['coords']):3d} "
              f"atos={len(d['acts_in_page']):2d}{flag}")
    (OUT / "INDEX.md").write_text("\n".join(summary), encoding="utf-8")
    print(f"\ndossiês -> {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
