# Tabela de estimandos (pré-registro interno — v0.1, revisar antes da fase 2)

| # | Pergunta | Unidade | Tratamento | Outcome | Comparação | Horizonte | Estimando | Interpretação | Ameaças principais | Teste correspondente |
|---|---|---|---|---|---|---|---|---|---|---|
| E1 | Esforço cai dentro da AMP? | célula×mês | dentro MONA × pós 19/03/2018 | horas de pesca (asinh); presença | células >100 km, mesma faixa lat. | −24 a +33 meses | ATT dinâmico (ES) | efeito no esforço APARENTE, não estoque | antecipação; cobertura AIS | leads; controle de cobertura |
| E2 | Esforço cai na APA (uso sustentável)? | célula×mês | dentro APA\MONA × pós | idem | idem | idem | ATT | dose menor de restrição | idem | idem |
| E3 | Esforço sobe nos anéis vizinhos? | célula×mês | anel 0–10/10–25/25–50/50–100 km × pós | horas; presença | controle >100 km | idem | ATT por anel | leakage espacial (H2) | anel contaminado no controle | exclusão de anéis do controle |
| E4 | Há antecipação pré-criação? | célula×semana | janela anúncio (consulta 2017→decreto) | horas | mesmas células, anos anteriores | −12 a 0 meses | coef. de leads | corrida ao recurso (H3) | choque ambiental coincidente | placebo em áreas remotas |
| E5 | Mudança líquida é menor que a local? | região×mês | agregação E1−E4 | Σ horas | — | pós | decomposição (seção 7 protocolo) | H8 | dupla contagem de anéis | partição exaustiva e disjunta |
| E6 | Novo calendário (2023) desloca esforço no tempo? | célula×semana | janela 28/01–28/02 (nova proibição); 05 (liberação) | horas de arrasto | mesma célula, anos 2019–2022 | 2019–2024 | DiD dentro-célula entre janelas | H3 temporal | sazonalidade biológica; preço/combustível | harmônicos sazonais; SST; falso defeso em espécie livre |
| E7 | Fiscalização modera o efeito? | célula×mês | E1 × intensidade de autos (ICMBio/IBAMA) | horas dentro | terciles de fiscalização | pós | heterogeneidade do ATT | H4; correlação ≠ causa da fiscalização | fiscalização endógena ao descumprimento | usar fiscalização PRÉ-tratamento |
| E8 | Pagamento tempestivo do Seguro-Defeso reduz esforço no defeso? | município×mês | atraso do pagamento (dias) | esforço AIS costeiro; proxy atividade | municípios pagos em dia | por defeso | dose-resposta | H5/H6; artesanal mal observado por AIS — interpretar como frota AIS local | atraso correlacionado a características locais | balanceamento; FE município; eventos de atraso administrativo em massa |
| E9 | Quem suporta os custos? | município×trim. | exposição da frota local à área fechada | emprego CNAE 03; massa Seguro-Defeso | municípios pouco expostos | ±3 anos | ES distributivo | incidência de curto prazo | migração de trabalhadores | RAIS por vínculo |

Notas: (i) todo estimando sobre esforço refere-se a **esforço aparente da
frota com AIS**; (ii) E8/E9 só avançam se os testes de pré-condição passarem;
(iii) inferência: wild cluster bootstrap + permutação espacial (ver
identification_strategy.md).
