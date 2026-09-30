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

### 1. A correcao que importa — acesso ao objeto Imovel

**O erro:** nenhum permission set dava o objeto `Imovel__c`. So o perfil
System Administrator o tinha. A Carla e o Miguel, ambos Standard User, nao viam
os imoveis — nem o separador, nem os lookups. Passou despercebido porque a
demonstracao corre sempre com a conta de administrador.

As permissoes de CAMPO estavam todas la (11 campos de `Imovel__c`). Permissoes
de campo sem permissao de objeto nao dao acesso a nada e nao dao erro de deploy:
e por isso que isto se aguentou tanto tempo.

```
sf project deploy start -m "PermissionSet:Terravista_Acesso_Base" \
                        -m "PermissionSet:Terravista_Direcao" -o terravista
```

**Confirma depois do deploy**, com uma query e nao com a mensagem de sucesso:

```sql
SELECT Parent.Label, PermissionsRead, PermissionsEdit, PermissionsDelete
FROM ObjectPermissions WHERE SobjectType = 'Imovel__c'
```

Tem de devolver tres linhas: o perfil de administrador e os dois permission sets.

### 2. Descricoes curtas e mensagens de erro curtas

131 ficheiros. Todas as descricoes passaram a uma linha (media 55 caracteres,
nenhuma acima de 91) e 16 mensagens de validation rule passaram a dizer o que
fazer em vez de explicar porque. O racional completo de cada decisao foi para
`docs/JUSTIFICACOES.md` — nao se perdeu, saiu da org.

```
sf project deploy start -m "PermissionSet:Terravista_Acesso_Base" \
                        -m "PermissionSet:Terravista_Direcao" \
                        -m "CustomObject:Imovel__c" \
                        -m "CustomObject:Imovel_Interesse__c" \
                        -m "CustomObject:Lead" \
                        -m "CustomObject:Opportunity" \
                        -m "CustomObject:Contract" \
                        -m "CustomObject:Account" \
                        -m "CustomObject:Contact" \
                        -m "CustomObject:Case" \
                        -m "CustomObject:Product2" \
                        -m "CustomObject:User" \
                        -m "CustomObject:Activity" \
                        -m "Report:Terravista" \
                        -m "ReportType:Imoveis_da_Carteira" \
                        -m "ReportType:Imoveis_de_Interesse" \
                        -m "CustomApplication:Terravista" \
                        -m "ApprovalProcess:Contract.Comissao_Abaixo_do_Minimo" \
                        -o terravista
```

`CustomObject:X` leva os campos, as validation rules, os record types e os
business processes desse objeto. Nao leva os layouts nem as Lightning pages —
e por isso e que este deploy **nao mexe em nada do que ajustaste na org**.

**Os Flows ficam de fora de proposito.** Tres dos Flows da org nunca foram
retrieved (ver secao seguinte) e o `Plano_gerado_a_true` esta na versao 8. Um
deploy de Flow a partir deste repositorio arrisca repetir o que aconteceu ao
`Carimbar_Visita` a 28/09.

### 3. Dias Sem Atividade a dar negativo

`LastActivityDate` inclui Eventos futuros, por isso `TODAY() - LastActivityDate`
dava numeros negativos num negocio com visita marcada. Passou a
`MAX(0, TODAY() - LastActivityDate)`. Vai no `CustomObject:Opportunity` acima.

---

### 4. Lead Record Page — as secoes de qualificacao a esconderem-se

`FlexiPage:Lead_Record_Page` tem tres secoes com `visibilityRule` por record type,
para que uma Lead de angariacao deixe de pedir qualificacao de comprador.

**Este e o unico componente que escrevi sem ter um exemplo a funcionar no
repositorio** — um `grep visibilityRule` em todo o force-app devolvia zero. Faz
este deploy **sozinho**, antes de qualquer outro:

```
sf project deploy start -m "FlexiPage:Lead_Record_Page" -o terravista
```

Se falhar, o resto do que esta acima nao e afetado. Se passar, abre uma Lead de
Angariacao e confirma que as secoes de comprador desapareceram.

---

## Tres Flows da org que nao existem no repositorio

Estao ativos e a funcionar, mas nunca foram trazidos. Se a org se perder, perdem-se.

- `Converter_Lead_em_Visita_Agendada`
- `Copiar_Angariador_do_Contrato`
- `Proximo_Passo`

```
sf project retrieve start -m "Flow:Converter_Lead_em_Visita_Agendada" \
                          -m "Flow:Copiar_Angariador_do_Contrato" \
                          -m "Flow:Proximo_Passo" -o terravista
git add force-app && git commit -m "Versiona os tres Flows feitos na org"
```

**Nomeia os componentes um a um.** Um `-m "Flow"` sozinho traz todos e apaga
trabalho local — foi a licao de 28/09.

---

## Na org, a mao — duas coisas de nome

O nome do Flow **Plano gerado a true** aparece assim em Setup → Flows. E um nome
de debug num ecra que a LOBA vai abrir. Muda no Flow Builder: abre o Flow,
**Edit Properties**, Label para `Plano de Procura fora da Carteira`, Description
para `Gera o plano de procura quando nao ha imoveis em carteira para o perfil.`
Guarda como nova versao e ativa.

O `Renegociacao_Preco` tambem esta sem Description. Mesmo caminho:
`Carta de renegociacao de preco com o proprietario.`

---

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
