# Pendente de deploy

**A regra:** só se faz deploy quando alguma coisa **bloqueia o passo seguinte**.
Tudo o resto acumula aqui.

Se este ficheiro disser "nada pendente", não faças deploy nenhum — mesmo que tenha
havido commits. Documentação, scripts e testes não precisam de ir para a org.

```
git pull
python scripts/verificar_metadados.py
sf project deploy start -o terravista
```

---

## Bloco 24/09 — Imovel_Interesse__c (LEVAR, e tem de ir tudo junto)

Um deploy e atomico, e este e o caso em que isso importa: o Flow carimba pela
linha de interesse, e o Apex poe o WhatId nela. Se um for sem o outro, a
validation rule que exige a Data da Visita bloqueia todas as oportunidades.

```
git pull
python scripts/verificar_metadados.py
sf project deploy start \
  -m "CustomObject:Imovel_Interesse__c" \
  -m "CustomField:Opportunity.Imoveis_Mostrados__c" \
  -m "CustomField:Opportunity.Imoveis_Recusados__c" \
  -m "PermissionSet:Terravista_Acesso_Base" \
  -m "Flow:Carimbar_Visita" \
  -m "ApexClass:AssistenteMarcarVisita" \
  -m "ApexClass:AssistenteTest" \
  --test-level RunSpecifiedTests --tests AssistenteTest --tests MatchImoveisTest \
  -o terravista
```

Depois do deploy, na org e a mao (o repositorio nao toca na UI):
- related list "Imoveis de Interesse" na pagina da Opportunity
- campos "Imoveis Mostrados" e "Imoveis Recusados" na mesma pagina

---

## Bloco atual — falta TRAZER da org, nao levar

A org tem quatro coisas que o repositorio nao tem. Nada disto se deploya: faz-se
retrieve, ao contrario do habitual.

- `Lead.Sem_Imoveis__c` — checkbox criada a mao
- `Gerar Plano de Procura - Criacao` — Flow
- `Gerar Plano de Procura - Alteracao` — Flow
- O prompt template de Field Generation

```
git pull
sf project retrieve start -m "CustomField:Lead.Sem_Imoveis__c" -m "Flow" -o terravista
git status
```

Ve o que apareceu, confirma que os dois Flows novos estao la, e faz commit.

O prompt template tem um tipo de metadata proprio que nao esta provado neste
projeto. Procura-o com `sf project list metadata --metadata-type` ou pelo
Metadata Coverage Report antes de o tentares trazer.

Continua pendente de LEVAR, de blocos anteriores:

```
sf project deploy start -m "Workflow:Contract" \
                        -m "ApprovalProcess:Contract.Comissao_Abaixo_do_Minimo" -o terravista

sf project deploy start -m "CustomField:Lead.Plano_de_Procura__c" \
                        -m "PermissionSet:Terravista_Acesso_Base" \
                        -m "Layout:Lead-Lead Compra" \
                        -m "Layout:Lead-Lead Arrendamento" -o terravista
```

O ApprovalProcess continua ausente da org — confirmado por SOQL, ProcessDefinition
devolve zero. O contrato 00000138 tem comissao a 3% e e o caso perfeito para o
demonstrar.

---

## A ordem completa dos scripts de dados

**Quatro, não três.** O `semear_org` apaga e recria os imóveis; quem se esquecer do
`preencher_carteira` fica com o **Elevador vazio nos 45**, e o caso do Jorge Teixeira
— o ponto alto da demonstração — deixa de funcionar **em silêncio**.

```
1. sf apex run -f scripts/apex/semear_org.apex        -o terravista
2. sf apex run -f scripts/apex/semear_leads.apex      -o terravista
3. sf apex run -f scripts/apex/preencher_carteira.apex -o terravista
4. sf apex run -f scripts/apex/semear_produtos.apex   -o terravista
```

O `semear_org` passa a escrever esta lista no log ao terminar. Estava só na
documentação, e foi exactamente por isso que falhou.

---

## O que NÃO precisa de deploy

- `docs/` — guiões, especificações, este ficheiro
- `scripts/apex/` — correm com `sf apex run`, não vão para a org
- `scripts/verificar_metadados.py` — corre local

---

## Como vamos trabalhar daqui para a frente

| Situação | O que digo |
|---|---|
| Escrevi metadata que bloqueia o teu próximo passo | *"Precisa de deploy, e porquê"* |
| Escrevi documentação ou scripts | *"Acumulado. Não faças deploy"* |
| Vários blocos acumulados | *"Agora vale a pena: são N coisas"* |

Se eu pedir um deploy sem dizer o que bloqueia, **pergunta porquê antes de correres**.
