"""Extrai texto integral de PDFs de normas em data/legal/ (PyMuPDF).

Uso: python python/extract_legal_text.py [arquivo.pdf ...]
Sem argumentos: processa todos os PDFs de data/legal/ sem .txt correspondente.
A saída .txt é INSUMO para estruturação; nunca substitui a leitura humana.
"""
import sys
from pathlib import Path

import fitz  # pymupdf

ROOT = Path(__file__).resolve().parents[1]
LEGAL = ROOT / "data" / "legal"


def extract(pdf: Path) -> Path:
    out = pdf.with_suffix(".txt")
    doc = fitz.open(pdf)
    text = "\n".join(page.get_text() for page in doc)
    out.write_text(text, encoding="utf-8")
    print(f"[OK] {pdf.name}: {len(doc)} páginas -> {out.name} ({len(text)} chars)")
    return out


if __name__ == "__main__":
    targets = ([Path(a) for a in sys.argv[1:]]
               or [p for p in LEGAL.glob("*.pdf") if not p.with_suffix(".txt").exists()])
    if not targets:
        print("Nada a extrair.")
    for pdf in targets:
        extract(pdf)
