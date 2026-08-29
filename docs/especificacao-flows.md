# Especificação dos Flows

Documento de construção. Os dois Flows constroem-se no **Flow Builder** e depois faz-se
`sf project retrieve start -m Flow` para os trazer para o repositório.

> **Porque não em metadata primeiro:** um Flow é composição, não definição. Escrever o XML à
> mão é possível mas ilegível e frágil; o Flow Builder gera-o correto à primeira e o `retrieve`
> versiona-o na mesma. É a mesma regra que já aplicámos a layouts e list views.

---

## Flow 1 · Sincronizar Opportunity → Imóvel

**Problema que resolve:** hoje fecha-se uma venda e o imóvel continua a aparecer como
*Disponível* na carteira. O estado do imóvel é a fonte dos Roll-Up do Contrato, portanto um
imóvel dessincronizado corrompe a percentagem comercializada do empreendimento.

**Nome:** `Sincronizar Estado do Imovel`
**Tipo:** Record-Triggered Flow
**Objeto:** Opportunity
**Trigger:** A record is created or updated
**Optimize the Flow for:** *Actions and Related Records* (após gravação)
— obrigatório: estamos a alterar um registo **relacionado**, não o `$Record`.

### Entry Conditions

Condition Requirements → **Formula Evaluates to True**:

```
AND(
  NOT(ISBLANK({!$Record.Imovel__c})),
  {!$Record.RecordType.DeveloperName} <> "Angariacao",
  OR( ISNEW(), ISCHANGED({!$Record.StageName}) )
)
```

Três guardas, cada uma com uma razão:

| Guarda | Porquê |
|---|---|
| `Imovel__c` preenchido | Sem imóvel não há nada para sincronizar |
| Record Type ≠ `Angariacao` | Numa angariação, *Contrato Assinado* significa **CMI assinado**, não imóvel vendido. Sem esta guarda, ganhar uma angariação marcava o imóvel como arrendado |
| Fase mudou | Evita que o Flow corra em cada gravação — cada execução desnecessária é limite de governor consumido |

### Decision · `Que estado comercial?`

| Outcome | Condição (`StageName` Equals) | Resultado |
|---|---|---|
| `Reservado` | `CPCV Assinado` | Imóvel → **Reservado** |
| `Vendido` | `Escritura Realizada` | Imóvel → **Vendido** |
| `Arrendado` | `Contrato Assinado` | Imóvel → **Arrendado** |
| `Libertar` | `Perdido` | Imóvel → **Disponível** *(condicional, ver abaixo)* |

**Default Outcome: não faz nada.** Deliberado. Um negócio que recua de *CPCV* para
*Negociação* **não** liberta o imóvel automaticamente — libertar carteira é uma decisão
comercial, não uma consequência mecânica de um clique enganado no Path.

### Update Records (4 elementos)

Em cada um: *Specify conditions to identify records, and set fields individually* →
Object **Imovel__c** → Condition: `Id` **Equals** `{!$Record.Imovel__c}` →
Set Field Value: `Estado_Comercial__c`.

**O elemento `Libertar` leva uma condição extra:**

```
Id                    Equals   {!$Record.Imovel__c}
Estado_Comercial__c   Equals   Reservado
```

**Porquê:** sem isto, perder um negócio antigo sobre um imóvel **já vendido a outra pessoa**
devolvia-o a *Disponível* e destruía o Roll-Up de vendas do empreendimento. Só se liberta o
que este negócio tinha reservado.

### Teste de aceitação
1. Negócio de habitação → *CPCV Assinado* → imóvel fica **Reservado**
2. O mesmo → *Escritura Realizada* → imóvel fica **Vendido**
3. Um negócio de **Angariação** → *Contrato Assinado* → o imóvel **não muda** ✔
4. Negócio reservado → *Perdido* → imóvel volta a **Disponível**
5. Negócio sobre imóvel **Vendido** → *Perdido* → imóvel **continua Vendido** ✔

---

## Flow 2 · Angariação ganha → cria Contrato e Task

**Problema que resolve:** quando se assina o CMI, o contrato passa a existir no mundo real mas
não no sistema. Fica a depender de o agente se lembrar de o criar — e é precisamente o
contrato que carrega a comissão de que depende toda a receita calculada.

**Nome:** `Angariacao Ganha Cria Contrato`
**Tipo:** Record-Triggered Flow · **Objeto:** Opportunity
**Trigger:** A record is created or updated
**Optimize the Flow for:** *Actions and Related Records*

### Entry Conditions — Formula Evaluates to True

```
AND(
  {!$Record.RecordType.DeveloperName} = "Angariacao",
  {!$Record.StageName} = "Contrato Assinado",
  ISCHANGED({!$Record.StageName})
)
```

`ISCHANGED` é o que garante **um contrato e não um por cada gravação** do registo já ganho.

### Formula Resource · `frmRegime`

```
IF({!$Record.Linha_Negocio__c} = "B2B",
   "Comercializacao de Empreendimento",
   "Mediacao a Particular")
```

`Regime__c` é obrigatório no Contract; deriva-se da linha de negócio em vez de se pedir outra vez.

### Create Records · Contrato

| Campo | Valor |
|---|---|
| `AccountId` | `{!$Record.AccountId}` |
| `Status` | `Draft` |
| `StartDate` | `{!$Flow.CurrentDate}` |
| `ContractTerm` | `6` — prazo típico de um CMI, ajustável à mão |
| `Regime__c` | `{!frmRegime}` |
| `Comissao__c` | deixar vazio — **ver nota abaixo** |
| `Localizacao__c` | `{!$Record.Imovel__r.Localizacao__c}` se existir |

Guardar o Id em `varContratoId`.

> **Porque é que a comissão fica vazia:** é o número mais sensível do modelo — alimenta
> `Comissao_Terravista__c` em todas as vendas do contrato. Um default inventado pela automação
> passa despercebido; um campo vazio obriga alguém a preenchê-lo. É por isso que existe a Task.

### Create Records · Task

| Campo | Valor |
|---|---|
| `Subject` | `Completar CMI: comissão, exclusividade e imóvel` |
| `WhatId` | `{!varContratoId}` |
| `OwnerId` | `{!$Record.OwnerId}` |
| `ActivityDate` | `{!$Flow.CurrentDate}` + 3 dias |
| `Priority` | `High` |
| `Status` | `Not Started` |
| `Description` | `O contrato foi criado automaticamente com o essencial. Falta: percentagem de comissão acordada, regime de exclusividade, e criar o registo de Imóvel com preço e área depois da avaliação.` |

### Update Records · ligar a Opportunity ao Contrato

`Id` Equals `{!$Record.Id}` → `ContractId` = `{!varContratoId}`

`ContractId` é **campo standard da Opportunity**. Zero custom para fechar o circuito.

### O que este Flow deliberadamente NÃO faz

**Não cria o Imóvel.** As nossas próprias validation rules exigem `Preco > 0` e `Area > 0`, e
no momento em que o CMI é assinado ainda ninguém mediu nem avaliou. Criar o registo obrigaria
a inventar números ou a desligar as regras — as duas piores opções.
A automação faz o trabalho mecânico; a pessoa faz o trabalho de campo.

### Teste de aceitação
1. Angariação → *Contrato Assinado* → aparece Contrato em *Draft* na conta certa
2. O regime corresponde à linha de negócio (B2B → Comercialização de Empreendimento)
3. Existe uma Task de alta prioridade no dono do negócio
4. A Opportunity mostra o Contrato no campo standard *Contract*
5. Gravar outra vez a Opportunity já ganha → **não cria um segundo contrato** ✔

---

## Alteração de metadados associada

`Imovel__c.Estado_Comercial__c` passou a ter um quarto valor: **`Arrendado`**.
Sem ele, ganhar um arrendamento marcava o imóvel como *Vendido* e inflacionava o Roll-Up
`Imoveis_Vendidos__c` — que continua a contar apenas `Vendido`, e por isso permanece correto.
