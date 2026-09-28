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

## Feito a 28/09 — confirmado por query, nao por mensagem de deploy

| O que | Como se confirmou |
|---|---|
| `Imovel_Interesse__c` + roll-ups | `EntityDefinition` devolve o objecto |
| `Case.Pos_Escritura` + Business Process | `RecordType` com `BusinessProcessId` preenchido |
| `Lead.Imovel_Pretendido__c`, `Case.Imovel__c` | no deploy dos 16 componentes |
| `Carimbar_Visita` com o salto pela linha de interesse | `FlowDefinitionView` diz `VersionNumber 2` |
| `ApprovalProcess Comissao_Abaixo_do_Minimo` | `ProcessDefinition` deixou de devolver zero |

### As tres licoes deste dia, que custaram uma tarde

**1. Um deploy verde nao prova que alguma coisa mudou.** O `Carimbar_Visita`
correu com "sucesso", 16 de 16 componentes, e ficou na versao 1 de 7 de
Setembro. O deploy mandou de volta o que ja la estava. So a query o denunciou.

**2. Um retrieve traz o que a org tem, nao o que o repositorio devia ter.**
Foi um `-m "Flow"` - todos os Flows - que apagou noventa linhas de trabalho
acabado de escrever. O retrieve vai ANTES do deploy, e nunca sobre os mesmos
componentes.

**3. Perguntar a org e mais barato do que testar hipoteses.** O
"Picklist value not found" custou horas de variacoes; uma query de cinco
segundos ao `CaseStatus` mostrava que o valor nao existia. O mesmo com o
`AccountId` do layout de aprovacao: uma query a `FieldDefinition` mostrou dois
erros de uma vez, e poupou uma viagem.

---

## Continua pendente de LEVAR

```
sf project deploy start -m "CustomField:Lead.Plano_de_Procura__c" \
                        -m "Layout:Lead-Lead Compra" \
                        -m "Layout:Lead-Lead Arrendamento" -o terravista
```

**Cuidado com os Layouts:** so corre isto se souberes que nao mexeste nesses
dois na org. Se mexeste, faz `retrieve` deles primeiro e ve o `git diff`.

## Na org, a mao - sem isto nao se ve nada do que foi deployado

- related list **Imoveis de Interesse** na pagina da Opportunity
- campos **Imoveis Mostrados** e **Imoveis Recusados** na mesma pagina
- record type **Pos-Escritura** atribuido ao perfil
- campo **Imovel** no layout do Case
- campo **Imovel Pretendido** no layout de Lead do record type Compra

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
