# Dicionário de dados (estado da primeira entrega)

## `data/interim/pilot_panel_trindade.csv` (piloto diagnóstico — 124.080 linhas)

| Coluna | Tipo | Descrição |
|---|---|---|
| cell_lon, cell_lat | double | centro da célula 0,25° (EPSG:4326) |
| zone | factor | `mona` (proteção integral), `apa` (uso sustentável, fora do MONA), `outside` |
| dist_boundary_km | double | distância aproximada (equiretangular) do centro à fronteira da APA; recalcular com sf/geodésica na fase 1 |
| year, month | int | 2016-01 … 2020-12 |
| post | 0/1 | mês ≥ 2018-03 (Decreto 9.312 de 19/03/2018) |
| treated_mona | 0/1 | post × zone==mona |
| treated_apa | 0/1 | post × zone∈{mona, apa} |
| fishing_hours | NA | **vazio por construção** — aguarda GFW_TOKEN; nunca preencher com dado sintético |

## `data/raw/202401_SeguroDefeso.csv` (dentro do ZIP; amostra inspecionada)

| Coluna (original) | Descrição |
|---|---|
| MÊS REFERÊNCIA | AAAAMM da competência |
| UF / CÓDIGO MUNICÍPIO SIAFI / NOME MUNICÍPIO | localização do beneficiário |
| CPF FAVORECIDO | mascarado (\*\*\*.nnn.nnn-\*\*) |
| NIS FAVORECIDO | identificador social (chave de spell individual) |
| RGP FAVORECIDO | Registro Geral da Atividade Pesqueira — **chave de cruzamento com cadastros pesqueiros** |
| NOME FAVORECIDO | dado pessoal público — não publicar desagregado |
| VALOR PARCELA | R$ (vírgula decimal); 1.412,00 em 01/2024 (salário mínimo) |
| Codificação | Latin-1 (`;`-separado, aspas) |

Observação: há linhas duplicadas aparentes (mesmo NIS/mês) — investigar na
fase 1 (parcelas múltiplas vs. duplicação real) antes de qualquer agregação.

## `outputs/policies/*.json`

Campos definidos por `config/policy_rule_schema.json` (ver
`docs/policy_registry_protocol.md`).

## `data/legal/`

| Arquivo | Fonte oficial | SHA-256 |
|---|---|---|
| Portaria_SAP_MAPA_656_2022_ibama.pdf | gov.br/ibama (defesos-marinhos) | ver `data/metadata/checksums_legal.txt` |
| Portaria_SAP_MAPA_656_2022_dou.html | in.gov.br | idem |
| Portaria_SAP_MAPA_656_2022.txt | extraído do PDF (PyMuPDF) | idem |
| Decreto_9312_2018.html | planalto.gov.br | idem |

## `data/raw/uc_trindade_test.geojson`

GetFeature WFS 2.0 (`ICMBio:limiteucsfederais_a`, filtro `nomeuc ILIKE
'%trindade%'`), 2 features: MONA (cnuc 0000.00.3642) e APA (0000.00.3633),
`criacaoato = DEC 9.312 de 19/03/2018`, EPSG:4326.
