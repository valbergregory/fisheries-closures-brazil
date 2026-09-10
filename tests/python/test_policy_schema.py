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
    # Validada pelo pesquisador em 2026-09-07 — não pode regredir para false
    # sem que a autoria da validação seja revista.
    assert rule["validation"]["human_validated"] is True
    assert rule["validation"]["validated_by"]


def test_sardine_reform_rules_are_opposite():
    """As regras da sardinha devem representar as DUAS janelas de 2009 e a
    janela única de 2020 — é o par que sustenta a discussão da D10."""
    pol = ROOT / "outputs" / "policies"
    r1 = json.loads((pol / "IN_IBAMA_15_2009_r1.json").read_text(encoding="utf-8"))
    r2 = json.loads((pol / "IN_IBAMA_15_2009_r2.json").read_text(encoding="utf-8"))
    novo = json.loads((pol / "IN_MAPA_18_2020_r1.json").read_text(encoding="utf-8"))
    assert (r1["period"]["start"], r1["period"]["end"]) == ("11-01", "02-15")
    assert (r2["period"]["start"], r2["period"]["end"]) == ("06-15", "07-31")
    assert (novo["period"]["start"], novo["period"]["end"]) == ("10-01", "02-28")
    # o regime de 2009 foi substituído; o de 2020 é o vigente
    assert r1["status"]["revoked"] and r2["status"]["revoked"]
    assert not novo["status"]["revoked"]
    # mesma espécie e mesma faixa latitudinal nos três
    for r in (r1, r2, novo):
        assert r["species"][0]["scientific_name"] == "Sardinella brasiliensis"
        assert r["area"]["geometry_status"] == "explicit_coordinates"
