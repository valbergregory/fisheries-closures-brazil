"""C3 — lote 1 de regras estruturadas a partir dos dispositivos lidos nos
dossiês (outputs/policies/screening/). Só entram campos LIDOS no texto; o que
não foi conferido fica vazio ou em open_issues. Todas com human_validated=false."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "outputs/policies"
C = "data/legal/corpus_defesos_marinhos/"
URL = ("https://www.gov.br/ibama/pt-br/assuntos/biodiversidade/"
       "biodiversidade-aquatica/periodos-de-defeso/defesos-marinhos")


def rule(rid, norm, ntype, auth, species, area, uf, gstat, start, end, rec,
         first, mode, files, pub, dou, notes, issues):
    r = {
        "rule_id": rid, "norm_id": norm, "norm_type": ntype, "issuing_authority": auth,
        "legal_basis": ["ver preâmbulo no texto (não transcrito)"],
        "species": [{"common_name": c, "scientific_name": s} for c, s in species],
        "area": {"description": area, "uf": uf, "geometry_status": gstat,
                 "geometry_source": "", "geometry_file": ""},
        "period": {"start": start, "end": end, "recurrence": rec,
                   "first_effective_year": first, "transitional_provisions": []},
        "fishing_mode": mode, "gear": [], "affected_group": "", "exceptions": [],
        "seguro_defeso_linked": False, "enforcement_notes": "",
        "status": {"in_force_as_of": "2026-09-11", "revoked": False, "revoked_by": "",
                   "amended_by": [], "amendment_check_pending": True},
        "source": {"publication_date": pub, "dou_reference": dou, "official_source_url": URL,
                   "local_files": [C + f for f in files],
                   "sha256": {"note": "ver data/metadata/checksums_legal.txt"}},
        "extraction": {"method": "pdf_text_assisted", "extracted_at": "2026-09-11",
                       "extracted_by": "Claude (assistente), a partir dos dispositivos isolados por python/screen_legal_corpus.py"},
        "validation": {"human_validated": False, "validated_by": None, "validated_at": None,
                       "open_issues": issues},
        "version": 1, "notes": notes,
    }
    (OUT / f"{rid}.json").write_text(json.dumps(r, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return rid


IB = "IBAMA"
MMA = "Secretaria-Geral / Ministério do Meio Ambiente (SG/MMA) — Portaria Interministerial"
MAPA = "SAP/MAPA"
NE_UF = ["AP", "PA", "MA", "PI", "CE", "RN", "PB", "PE", "AL", "SE", "BA", "ES"]
LAGOSTAS = [("lagosta vermelha", "Panulirus argus"), ("lagosta verde", "Panulirus laevicauda"),
            ("lagosta pintada", "Panulirus echinatus")]

done = [
    rule("INI_MPA_MMA_02_2009_r1", "INI_MPA_MMA_02_2009", "portaria_interministerial",
         "MPA/MMA (Instrução Normativa Interministerial)", [("anchova", "Pomatomus saltatrix")],
         "litoral sul do país (Art. 4º)", ["PR", "SC", "RS"], "named_area_unresolved",
         "12-01", "03-31", "annual", 2009, ["captura"], ["anchova_ini_mpa_mma_n-o-02_2009.pdf"], "", "",
         "Art. 4º: proibir anualmente de 1º/dez a 31/mar a captura da anchova no litoral sul.",
         ["data de publicação e nº do DOU a confirmar (cabeçalho não detectado na página)",
          "nome científico não citado no dispositivo lido — atribuído pela tabela IBAMA",
          "delimitar 'litoral sul' (UFs pela tabela IBAMA)"]),
    rule("PORT_IBAMA_70_2003_r1", "PORT_IBAMA_70_2003", "portaria", IB,
         [("camarão branco", "Litopenaeus schmitti"), ("camarão rosa", "Farfantepenaeus paulensis")],
         "interior da Baía da Babitonga, SC (Art. 1º)", ["SC"], "named_area_resolvable",
         "11-01", "01-31", "annual", 2003, ["pesca"], ["camaroes_portaria_ibama_n-o-70_2003.pdf"],
         "2003-11-03", "DOU 03/11/2003, nº 213, Seção 1, p. 64",
         "Art. 1º; grafia 'schimitti' no original.", ["confirmar data de assinatura"]),
    rule("PORT_SG_MMA_41_2018_r1", "PORT_SG_MMA_41_2018", "portaria_interministerial", MMA,
         [("garoupa-verdadeira", "Epinephelus marginatus")],
         "conferir Art. 1º (tabela IBAMA: todas as águas brasileiras)", [], "named_area_unresolved",
         "11-01", "02-28", "annual", 2018,
         ["pesca direcionada, transporte, desembarque e comercialização — todos os métodos e embarcações (Art. 2º)"],
         ["garoupa-verdadeira_portaria_sg_mma_n-o-41_2018.pdf"], "2018-07-30",
         "DOU 30/07/2018 (Portarias 40–43 de 27/07/2018)", "Art. 2º.",
         ["área não lida no dispositivo — conferir Art. 1º", "confirmar data/página do DOU"]),
    rule("PORT_SG_MMA_43_2018_r1", "PORT_SG_MMA_43_2018", "portaria_interministerial", MMA,
         [("gurijuba", "Sciades parkeri")],
         "conferir Art. 1º (tabela IBAMA: todas as águas brasileiras)", [], "named_area_unresolved",
         "11-17", "03-31", "annual", 2018,
         ["pesca direcionada, transporte, desembarque e comercialização — todos os métodos e embarcações (Art. 3º)"],
         ["gurijuba_portaria_sg_mma_n-o-43_2018.pdf"], "2018-07-30", "DOU 30/07/2018", "Art. 3º.",
         ["área — conferir Art. 1º", "confirmar DOU"]),
    rule("PORT_SG_MMA_42_2018_r1", "PORT_SG_MMA_42_2018", "portaria_interministerial", MMA,
         [("pargo", "Lutjanus purpureus")], "conferir Art. 1º (tabela IBAMA: AP à divisa AL–SE)",
         ["AP", "PA", "MA", "PI", "CE", "RN", "PB", "PE", "AL"], "named_area_unresolved",
         "12-15", "04-30", "annual", 2018, ["pesca (Art. 4º)"], ["pargo_portaria_sg_mma_n-o-42_2018.pdf"],
         "2018-07-30", "DOU 30/07/2018",
         "Art. 4º; §2º: transporte/comércio proibidos de 16/fev a 30/abr.",
         ["área — conferir Art. 1º", "UFs pela tabela IBAMA"]),
    rule("PORT_SAP_MAPA_221_2021_r1", "PORT_SAP_MAPA_221_2021", "portaria", MAPA, LAGOSTAS,
         "da fronteira com a Guiana Francesa (meridiano 51°38' — grafado 'N' no texto) ao paralelo 21°18'S (divisa ES–RJ)",
         NE_UF, "explicit_coordinates", "11-01", "04-30", "annual", 2021,
         ["pesca (Art. 9º); período de pesca 1º/mai–31/out (Art. 8º)"],
         ["lagosta_portaria_sap_mapa_n-o-221_2021.pdf"], "", "",
         "Art. 9º; §1º declaração de estoque nov–jan; §2º proibição de transporte/comércio fev–abr.",
         ["data de publicação a confirmar (MPA: 08/06/2021)", "limite leste (ZEE) a definir — D11"]),
    rule("PORT_SAP_MAPA_221_2021_r2", "PORT_SAP_MAPA_221_2021", "portaria", MAPA, LAGOSTAS,
         "faixa de até 4 milhas náuticas da costa a partir das Linhas de Base Retas (Decreto 8.400/2015), entre a Guiana Francesa e 21°18'S",
         NE_UF, "explicit_coordinates", "2021-06-08", "", "permanent", 2021,
         ["pesca de lagosta a menos de 4 mn da costa"], ["lagosta_portaria_sap_mapa_n-o-221_2021.pdf"], "", "",
         "Restrição ESPACIAL PERMANENTE (D12). Data de início = data da portaria, a confirmar.",
         ["confirmar vigência e data", "buffer de 4 mn a partir das linhas de base retas — geometria construível"]),
    rule("IN_IBAMA_33_2004_r1", "IN_IBAMA_33_2004", "instrucao_normativa", IB,
         [("manjuba", "Anchoviella spp.")], "conferir Art. 1º (tabela IBAMA: litoral sul de SP)", ["SP"],
         "named_area_unresolved", "12-26", "01-25", "annual", 2004,
         ["pesca (Art. 7º, a partir da safra 2004/2005)"], ["manjuba_in_ibama_n-o-33_2004.pdf"], "", "",
         "Art. 7º.", ["área e espécie — conferir Art. 1º", "data DOU"]),
    rule("PORT_IBAMA_SUPES_ES_01_1998_r1", "PORT_IBAMA_SUPES_ES_01_1998", "portaria",
         "IBAMA / Superintendência no Espírito Santo", [("manjuba", "Anchoviella spp.")],
         "Espírito Santo (Art. 2º/4º)", ["ES"], "named_area_unresolved", "04-15", "05-15", "annual", 1998,
         ["pesca mencionada no Art. 1º"], ["manjuba_portaria_ibama_supes_es_n-o-01_1998.pdf"], "", "",
         "Art. 2º: duas janelas — 15/abr–15/mai (r1) e 1º/jul–31/dez (r2). Texto de OCR ruim.",
         ["texto com erros de OCR — conferir no original", "r2 (1º/jul–31/dez) a estruturar", "espécie pela tabela IBAMA"]),
    rule("IN_IBAMA_105_2006_r1", "IN_IBAMA_105_2006", "instrucao_normativa", IB, [("mexilhão", "Perna perna")],
         "estoques naturais nos estados ES, RJ, SP, PR, SC e RS (Art. 3º)", ["ES", "RJ", "SP", "PR", "SC", "RS"],
         "named_area_resolvable", "09-01", "12-31", "annual", 2006,
         ["extração, abastecimento de cultivos, transporte, beneficiamento, industrialização, armazenamento e comercialização"],
         ["mexilhao_in_ibama_n-o-105_2006.pdf"], "", "", "Art. 3º.",
         ["data DOU", "Art. 1º cita outro período (truncado) — conferir se há segunda regra"]),
    rule("PORT_SUDEPE_40_1986_r1", "PORT_SUDEPE_40_1986", "portaria", "SUDEPE", [("ostras", "Crassostrea spp.")],
         "todo o litoral de SP e região estuarino-lagunar de Paranaguá, PR", ["SP", "PR"], "named_area_resolvable",
         "12-18", "02-18", "annual", 1986, ["extração"], ["ostras_portaria_sudepe_n-o-40_1986.pdf"], "", "",
         "Item I. Texto OCR de 1986.", ["data DOU", "espécie pela tabela IBAMA", "vigência após 40 anos — conferir revogação"]),
    rule("IN_IBAMA_10_2009_r1", "IN_IBAMA_10_2009", "instrucao_normativa", IB,
         [("robalo", "Centropomus parallelus"), ("robalo-branco", "Centropomus undecimalis"), ("camurim/barriga-mole", "Centropomus spp.")],
         "Espírito Santo (Art. 2º refere a Superintendência do IBAMA no ES)", ["ES"], "named_area_unresolved",
         "05-01", "06-30", "annual", 2009, ["pesca (Art. 1º); competições de pesca proibidas 1º/mai–31/ago (Art. 5º)"],
         ["robalo_robalo-branco_e_camurim_in_ibama_n-o-10_2009.pdf"], "2009-04-27", "assinada em 27/04/2009 — DOU a confirmar",
         "Art. 1º; declaração de estoque até 8/mai (Art. 2º).", ["nomes científicos pela tabela IBAMA (dispositivo truncado)", "DOU"]),
    rule("PORT_SG_MMA_59C_2018_r1", "PORT_SG_MMA_59C_2018", "portaria_interministerial", MMA,
         [("caranha", "Lutjanus cyanopterus"), ("sirigado", "Mycteroperca bonaci"),
          ("garoupa-de-são-tomé", "Epinephelus morio"), ("badejo-amarelo", "Mycteroperca interstitialis")],
         "conferir Art. 1º (tabela IBAMA: todas as águas brasileiras)", [], "named_area_unresolved",
         "08-01", "09-30", "annual", 2019, ["pesca (Art. 5º)"],
         ["sirigado_badejo-amarelo_garoupa-de-sao-tome_e_caranha_portaria_sg_mma_n-o-59-c_2018.pdf"], "", "",
         "Art. 5º: a partir de 2019.", ["área — Art. 1º", "DOU"]),
]
print(len(done), "regras geradas")
