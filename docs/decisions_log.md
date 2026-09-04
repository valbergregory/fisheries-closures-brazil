# Registro de decisões

| ID | Data | Decisão | Justificativa | Status |
|---|---|---|---|---|
| D1 | 2026-09-03 | Caso principal = criação MONA/APA Trindade e Martim Vaz (Dec. 9.312/2018); secundário = mudança de calendário do defeso camarão SE/S (Port. 656/2022) | matriz de seleção em feasibility_report.md: data nítida, polígono oficial recuperado, AIS compatível, pré/pós suficientes | proposta — aguarda aprovação do pesquisador |
| D2 | 2026-09-03 | Grade do piloto = 0,25° regular; H3 (res. 6/7) reavaliado na fase 1 | zero dependências no piloto; alinhamento com OISST; H3 exige h3jsr | aberta |
| D3 | — | Geometria operacional de "Mar Territorial + ZEE por UF" (defesos) | candidatas: Marine Regions v12, Marinha/LEPLAC, construção própria a partir da linha de base | pendente |
| D4 | — | CRS métrico para buffers (EPSG:5641 vs 31983 vs azimutal customizado p/ Trindade) | Trindade está longe das zonas UTM usuais | pendente |
| D5 | — | Extensão spatial do DuckDB vs sf para o motor de exposição | testar na fase 1; PostGIS só com necessidade concreta | pendente |
| D6 | — | Frequência do painel principal (mês) e de antecipação (semana) | trade-off ruído × dinâmica fina | pendente |
| D7 | 2026-09-03 | Piloto geométrico em Python puro (stdlib+matplotlib), produção em R/sf via renv | sf/terra não instalados; regra "não instalar globalmente"; piloto não podia esperar | fechada |
| D8 | 2026-09-03 | Leitura do Art. 2º §3º da Port. 656/2022 (inconsistência *P. subtilis*/“camarão-branco”) | requer decisão jurídica do pesquisador; afeta codificação de exceção | pendente — Valber |
| D9 | 2026-09-03 | Microdados Seguro-Defeso tratados como dado pessoal público: uso interno individual (spells RGP), publicação só agregada | LGPD art. 7º §3º/uso de dado tornado público; finalidade acadêmica | proposta |
