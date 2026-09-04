# Estratégia de identificação

## Caso principal: MONA/APA Trindade e Martim Vaz (Decreto 9.312, 19/03/2018)

**Por que identifica:** evento único, datado (assinatura 19/03, publicação
20/03/2018), polígonos oficiais (WFS ICMBio), offshore (1.100+ km da costa —
frota industrial/atuneira com AIS, sem contaminação artesanal invisível),
grande (MONA 6,77 Mha proibição total; APA 40,4 Mha uso regulado), com ≥2 anos
de AIS pré e pós.

**Desenhos:**
1. **Event study / DiD espacial** — células 0,25° (ou H3), zonas
   {MONA, APA\MONA, anéis externos 0–10/10–25/25–50/50–100 km, controle
   >100 km na mesma faixa latitudinal}; efeitos fixos célula e mês×ano;
   janela 2016-01–2020-12 (parar antes de choques COVID tardios; sensível em
   robustez).
2. **Synthetic DiD** — a região tratada como unidade única; doadores: montes
   submarinos/bancos comparáveis fora da UC (cadeia Vitória–Trindade fora do
   MONA, elevações do Rio Grande) — responde à crítica de "unidade tratada
   única".
3. **RDD geográfica (condicional)** — distância assinada à fronteira da
   APA/MONA; bandwidths 10–50 km; donut 0–5 km (incerteza GPS/AIS +
   dissuasão de borda). Só vale se houver continuidade de profundidade e
   produtividade na fronteira (checar com batimetria GEBCO + clorofila) — as
   fronteiras são retas administrativas em mar aberto, o que ajuda (não
   seguem feição natural) mas exige teste de sorting.

**Ameaças e respostas:**
| Ameaça | Resposta |
|---|---|
| Antecipação (anúncio da consulta pública 2017) | event study com leads; janela de anúncio separada |
| Choques ambientais coincidentes | controles SST/clorofila; placebo em áreas não tratadas |
| Cobertura AIS muda no tempo | controle de cobertura satelital por célula×mês (GFW fornece) |
| Esforço = zero estrutural em muitas células | modelos de contagem/zero-inflados; margem extensiva separada |
| Poucos clusters espaciais | wild cluster bootstrap; randomization/permutation inference com polígonos placebo |
| Correlação espacial | erros Conley; SDID |
| Leakage contamina o controle | anéis intermediários EXCLUÍDOS do controle; decomposição explícita |

## Caso secundário: mudança de calendário do defeso do camarão SE/S

Portaria 656/2022: até 2022, defeso 01/03–31/05 (regime IN 189/2008 +
transição §1º); desde 2023, 28/01–30/04. **Identificação:** o MESMO conjunto
de células/frota passa a ser proibido em fev (antes livre) e liberado em mai
(antes proibido). Comparação dentro-célula, entre anos, nas janelas
28/01–28/02 e 01/05–31/05, controlando sazonalidade por harmônicos/mês do
ano e SST — separa efeito do defeso da sazonalidade biológica, que um
calendário fixo idêntico todos os anos jamais separaria. Complemento: frota
de arrasto (tratada) × outras artes na mesma área (comparação, com cautela
por substituição — H2/H4).

## Caso condicional: Seguro-Defeso

Microdados CGU (município×mês×indivíduo, com RGP). Estratégia candidata:
variação em **tempestividade** dos pagamentos entre municípios/anos (atraso
administrativo) × esforço AIS local e outcomes municipais. Pré-condição:
demonstrar que o atraso não é correlacionado com demanda local por pesca
(teste de balanceamento). Nunca interpretar pagamento agregado como adesão
individual.

## Inferência

Clusters no nível do polígono/zona são poucos → wild cluster bootstrap
(fixest/boottest), permutação com polígonos placebo deslocados ao longo da
costa/oceano, e Conley HAC como padrão espacial. Randomization inference
pré-especificada para o caso Trindade.

## Plano de robustez (mapeado a ameaças)

buffers alternativos; exclusão de células limítrofes; bandwidths e donut
(RDD); polígonos placebo (geográficos) e datas placebo (temporais); falsos
defesos (espécies não reguladas); tendências específicas de zona; controles
climáticos (SST, anomalias) e de produtividade (clorofila); interação com
fiscalização (autos ICMBio); efeitos por porto de origem (quando
identificável); esforço agregado × presença; sensibilidade à resolução
(0,25°/0,1°/H3) e à frequência (semana/mês); correção de cobertura AIS;
janelas de antecipação; persistência (horizonte longo até 2024, condicional
a cobertura).
