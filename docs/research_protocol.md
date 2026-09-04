# Protocolo científico
**Projeto:** Do Fishing Closures Protect Fish or Displace Fishing? Causal Evidence from Brazil's Seasonal Bans and Marine Protected Areas
**Versão:** 0.1 (primeira entrega, 2026-09-03) — hipóteses e desenhos são provisórios até a auditoria completa dos dados.

## 1. Problema científico

O Brasil regula a pressão pesqueira por defesos sazonais, áreas marinhas
protegidas (AMPs) e restrições de petrecho/modalidade. Métricas agregadas de
"efetividade" podem mascarar: deslocamento espacial para áreas vizinhas,
antecipação do esforço, intensificação pós-defeso, substituição de espécie ou
arte, atividade não observada (frota sem AIS), e transferência de pressão para
comunidades e ecossistemas próximos. O projeto separa:

1. redução efetiva do esforço;
2. deslocamento espacial;
3. deslocamento temporal (antecipação/compensação);
4. substituição de espécie/atividade;
5. efeitos distributivos (renda, trabalho);
6. resposta ao Seguro-Defeso (Lei 10.779/2003);
7. heterogeneidade por fiscalização.

## 2. Pergunta principal

> Do seasonal fishing bans and marine protected areas reduce total fishing
> pressure, or do they displace fishing effort across space, time, and species?

Perguntas secundárias: ver seção 3 do brief (esforço dentro/fora, antecipação,
compensação, fiscalização, Seguro-Defeso, industrial × artesanal, indicadores
de estoque, incidência distributiva). Registradas como estimandos em
`estimand_table.md`.

## 3. Hipóteses (provisórias)

| # | Hipótese | Teste primário |
|---|---|---|
| H1 | Restrições reduzem o esforço observado dentro da área/período tratado | ES/DiD no interior |
| H2 | Parte da redução é compensada em áreas próximas | anéis de distância (leakage espacial) |
| H3 | Antecipação antes e intensificação após a restrição | event study com janelas semanais |
| H4 | Fiscalização ↑ reduz deslocamento ilegal para dentro, pode ↑ deslocamento para áreas permitidas | interação com autos de infração |
| H5 | Seguro-Defeso suficiente e tempestivo reduz esforço no período proibido | timing de pagamento × esforço municipal |
| H6 | Atraso/cobertura incompleta ↑ descumprimento e deslocamento | dose-resposta por atraso |
| H7 | AMPs com maior capacidade institucional têm efeitos mais persistentes | heterogeneidade por gestão (CNUC) |
| H8 | Métricas agregadas superestimam efetividade ao ignorar leakage | decomposição (seção 7) |

## 4. Fundamentos econômicos

Tragédia dos comuns e recursos de acesso comum (Gordon 1954; Hardin 1968;
Ostrom 1990): sem exclusão, o esforço excede o ótimo e dissipa renda.
Regulação por comando-e-controle (defeso, AMP) cria **externalidades de
segunda ordem**: o esforço não desaparece — realoca-se no espaço, no tempo e
entre espécies (margens de substituição; Smith 1969 sobre alocação espacial de
frotas). A relação regulador–pescador é **principal–agente** com monitoramento
custoso: compliance depende de fiscalização percebida (Becker 1968) e de
legitimidade. O **Seguro-Defeso** não é mero controle: é transferência
compensatória que altera a restrição orçamentária intertemporal do pescador
artesanal — pode viabilizar o cumprimento (renda de reserva durante o defeso)
ou gerar **moral hazard** (registro sem atividade; pesca paralela ao
benefício). Atraso no pagamento equivale a choque de liquidez que desloca a
escolha para o descumprimento (H5/H6). **Leakage espacial** é o análogo
pesqueiro do vazamento em política climática: a avaliação correta exige a
mudança líquida, não a local.

## 5. Contribuição de Sistemas de Informação

Sistema: **Fisheries Regulation Knowledge Base and Spatial Compliance
Observatory** — normas fragmentadas (DOU, IBAMA, MMA, MPA, ICMBio) →
regras atômicas legíveis por máquina (esquema em
`config/policy_rule_schema.json`), versionadas, com validação humana
obrigatória, cruzáveis com posição × período × esforço × fiscalização ×
Seguro-Defeso.

- **Pessoas:** pescadores/comunidades (transparência de vigência), fiscais
  (priorização espacial), gestores (avaliação), pesquisadores (reprodutível).
- **Processos:** regulamentação → fiscalização → compensação → monitoramento
  → avaliação, como ciclo informacional único.
- **Tecnologia:** ontologia mínima da regra (espécie, área, período,
  modalidade, exceções, autoridade, vigência), banco espaço-temporal
  (Parquet+DuckDB), motor de exposição (célula×regra×data), mapas/alertas
  (Shiny), econometria (targets).

## 6. Outcomes

**Primários (esforço, AIS/GFW):** horas de pesca; presença (extensivo);
embarcações; entrada/saída de células; esforço por anel de distância à
fronteira; concentração espacial (Gini/entropia); antes/durante/depois.
**Secundários (condicionados a dados reais):** desembarques regionais (PMAP
onde existir), emprego formal (RAIS/CAGED CNAE 03), pagamentos Seguro-Defeso,
autos de infração, luzes noturnas/VBD.
**Separação explícita:** efeito sobre *esforço* ≠ efeito sobre *estoque*.
Sem dado de biomassa independente, o artigo NÃO afirma recuperação de estoque.

## 7. Decomposição do leakage (obrigatória no artigo)

```
redução dentro da restrição
+ aumento nas áreas próximas (anéis 0-10, 10-25, 25-50, 50-100 km)
+ aumento antes da restrição (janela de antecipação)
+ aumento depois da restrição (janela de compensação)
= mudança líquida observada
```

Nenhuma afirmação de conservação bem-sucedida com base só na primeira parcela.

## 8. Casos selecionados (ver matriz em feasibility_report.md)

- **Principal:** criação do MONA + APA de Trindade e Martim Vaz
  (Decreto 9.312, 19/03/2018) — evento único datado, polígonos oficiais
  recuperados, offshore (AIS confiável), pré/pós ≥ 2 anos.
- **Secundário:** mudança de calendário do defeso do camarão SE/S
  (Portaria SAP/MAPA 656/2022: mar–mai → 28/jan–30/abr a partir de 2023) —
  variação temporal real que separa efeito do defeso da sazonalidade.
- **Condicionais:** RDD geográfica na fronteira da APA; Seguro-Defeso
  (microdados CGU).

## 9. Pipeline (ordem targets)

configuração → catálogo jurídico → download normas → checksums → extração de
texto → **revisão humana (gate)** → registro de regras → polígonos → esforço →
ambiente → Seguro-Defeso/fiscalização → tratamento espaço-temporal → painel →
auditoria → descritivas → modelo principal → spillovers → robustez → figuras
→ tabelas → dashboard → artigo. Nada depende de objetos manuais no Global
Environment.

## 10. Ética e limitações declaradas

AIS não representa a pesca artesanal (viés de cobertura estrutural);
beneficiários do Seguro-Defeso ≠ pescadores ativos sem validação; esforço
aparente é inferência de modelo (GFW); estatística nacional de desembarque
descontinuada (~2011). Microdados do Seguro-Defeso contêm nomes — tratar como
dado pessoal público com finalidade legal, agregar antes de publicar.
