# Protocolo do registro regulatório

## Unidade: a regra atômica

Uma **regra** = (espécie(s)) × (área) × (período) × (modalidade/arte), com
exceções e vigência. Uma norma gera 1..n regras (ex.: Portaria 656/2022 →
regra r1 = defeso RJ–RS; regra r2 futura = defeso ES; regras de petrecho não
entram como defeso). Esquema: `config/policy_rule_schema.json`; instâncias em
`outputs/policies/*.json`; validador: `python/validate_policy_schema.py`.

## Cadeia de custódia da norma

1. Localizar na fonte oficial (DOU/in.gov.br, gov.br, Planalto). Fontes
   privadas (legisweb etc.) NUNCA são autoridade — no máximo pista de busca.
2. Baixar e preservar em `data/legal/` (PDF/HTML + `.txt` extraído).
3. Registrar SHA-256 em `data/metadata/checksums_legal.txt`.
4. Catalogar em `config/policy_sources.yml` (`retrieved: true` só com arquivo
   local + checksum).

## Estruturação e validação humana (gate obrigatório)

- Extração de texto assistida (PyMuPDF/OCR) é INSUMO; os campos da regra são
  preenchidos lendo o texto, citando artigo/parágrafo em `notes`/`exceptions`.
- `validation.human_validated = false` até o pesquisador conferir campo a
  campo contra o texto oficial. `build_policy_registry(require_validated =
  TRUE)` bloqueia uso científico de regra pendente. Nenhum LLM é autoridade
  sobre conteúdo normativo.
- Divergências internas da norma (ex.: Art. 2º §3º da Portaria 656/2022, que
  rotula *Penaeus subtilis* como camarão-branco contra o próprio Art. 1º)
  ficam registradas em `open_issues` e decididas pelo pesquisador (formação
  jurídica) com justificativa em `docs/decisions_log.md`.

## Vigência e versionamento

- `status.amendment_check_pending = true` até busca ativa por normas
  posteriores (DOU + página IBAMA). Revogação preenche `revoked_by`.
- Alteração de campo após validação ⇒ `version += 1` e nova validação.
- O calendário regulatório derivado (regra × ano civil) é gerado por código a
  partir de `period` + `transitional_provisions`, nunca digitado à mão.

## Geometria operacional

`geometry_status` distingue: coordenadas explícitas na norma; área nomeada
resolvível (ex.: "Mar Territorial e ZEE de RJ…RS" → polígonos oficiais de
limite marítimo); área nomeada não resolvida (bloqueia uso espacial);
polígono anexo (UC via WFS ICMBio/CNUC). A fonte da geometria fica em
`geometry_source` e a escolha é uma decisão registrada (D3).
