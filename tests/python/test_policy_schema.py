"""pytest — o registro regulatório deve validar contra o esquema e nunca
regredir nos campos críticos da regra 656/2022."""
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def test_all_rules_validate():
    r = subprocess.run([sys.executable, str(ROOT / "python" / "validate_policy_schema.py"),
                        str(ROOT / "outputs" / "policies" / "*.json")],
                       capture_output=True, text=True)
    assert r.returncode == 0, r.stdout + r.stderr


def test_rule_656_core_fields():
    rule = json.loads((ROOT / "outputs" / "policies" /
                       "PORT_SAP_MAPA_656_2022_r1.json").read_text(encoding="utf-8"))
    assert rule["period"]["start"] == "01-28"
    assert rule["period"]["end"] == "04-30"
    assert rule["period"]["first_effective_year"] == 2023
    assert set(rule["area"]["uf"]) == {"RJ", "SP", "PR", "SC", "RS"}
    assert rule["seguro_defeso_linked"] is True
    # Uso científico exige validação humana — este teste DOCUMENTA a pendência:
    # quando o pesquisador validar, atualizar para assert True.
    assert rule["validation"]["human_validated"] is False
