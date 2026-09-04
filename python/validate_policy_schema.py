"""Valida registros de regras contra config/policy_rule_schema.json.

Implementação em stdlib puro (sem jsonschema instalado): verifica campos
obrigatórios, tipos básicos e enums — suficiente para o gate de qualidade do
registro regulatório. Se o pacote `jsonschema` for adicionado ao ambiente
(uv/pyproject), este módulo passa a usá-lo automaticamente.

Uso:
    python python/validate_policy_schema.py outputs/policies/*.json
"""
from __future__ import annotations

import glob
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCHEMA = json.loads((ROOT / "config" / "policy_rule_schema.json").read_text(encoding="utf-8"))

TYPE_MAP = {"object": dict, "array": list, "string": str,
            "integer": int, "boolean": bool, "number": (int, float)}


def _check(obj, schema, path, errors):
    stype = schema.get("type")
    if isinstance(stype, list):
        pytypes = tuple(TYPE_MAP[t] for t in stype if t != "null")
        if obj is None:
            if "null" in stype:
                return
        elif not isinstance(obj, pytypes):
            errors.append(f"{path}: tipo {type(obj).__name__}, esperado {stype}")
            return
    elif stype:
        if stype == "null":
            if obj is not None:
                errors.append(f"{path}: esperado null")
            return
        if not isinstance(obj, TYPE_MAP[stype]):
            errors.append(f"{path}: tipo {type(obj).__name__}, esperado {stype}")
            return
    if "enum" in schema and obj not in schema["enum"]:
        errors.append(f"{path}: valor {obj!r} fora do enum {schema['enum']}")
    if isinstance(obj, dict):
        for req in schema.get("required", []):
            if req not in obj:
                errors.append(f"{path}: campo obrigatório ausente: {req}")
        for key, sub in schema.get("properties", {}).items():
            if key in obj:
                _check(obj[key], sub, f"{path}.{key}", errors)
    if isinstance(obj, list) and "items" in schema:
        for i, item in enumerate(obj):
            _check(item, schema["items"], f"{path}[{i}]", errors)


def validate_file(fp: Path) -> list[str]:
    try:
        import jsonschema  # type: ignore
        try:
            jsonschema.validate(json.loads(fp.read_text(encoding="utf-8")), SCHEMA)
            return []
        except jsonschema.ValidationError as e:  # pragma: no cover
            return [str(e)]
    except ImportError:
        pass
    errors: list[str] = []
    _check(json.loads(fp.read_text(encoding="utf-8")), SCHEMA, fp.stem, errors)
    return errors


def main(patterns: list[str]) -> int:
    files = [Path(p) for pat in patterns for p in glob.glob(pat)]
    if not files:
        print("Nenhum arquivo de regra encontrado.")
        return 1
    failed = False
    for fp in files:
        errs = validate_file(fp)
        rule = json.loads(fp.read_text(encoding="utf-8"))
        pending = not rule.get("validation", {}).get("human_validated", False)
        flag = " [VALIDAÇÃO HUMANA PENDENTE]" if pending else ""
        if errs:
            failed = True
            print(f"[FALHA] {fp.name}{flag}")
            for e in errs:
                print(f"   - {e}")
        else:
            print(f"[OK] {fp.name} — esquema válido{flag}")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:] or ["outputs/policies/*.json"]))
