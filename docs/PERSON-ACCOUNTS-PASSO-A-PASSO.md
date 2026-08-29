# Person Accounts — passo a passo

Decisão tomada: os clientes particulares passam a **Person Accounts**, o modelo standard da
Salesforce para B2C. Este documento é o guião da migração.

> ⚠️ **Person Accounts não se desativa.** Uma vez ligado, fica ligado para sempre nesta org.
> Por isso as fases 1 e 2 existem: confirmar tudo **antes** do ponto sem retorno.

---

## FASE 1 · Preparar — no terminal

### 1.1 Trazer e enviar o Record Type

```
git pull
python scripts/verificar_metadados.py
sf project deploy start -o terravista
```

Isto envia o Record Type **Empresa** para o objeto Account. É pré-requisito: a documentação
oficial exige que o Account tenha pelo menos um Record Type antes de ativar Person Accounts.

**Confirma** que o deploy diz `Succeeded`. Se falhar, para aqui e mostra-me o erro.

### 1.2 Carregar os dados de demonstração

```
sf apex run -f scripts/apex/carregar_dados_demo.apex -o terravista
```

Ainda não correu nenhuma vez. Fá-lo agora, **antes** de ativar Person Accounts — assim ficamos
com um estado conhecido e completo para comparar depois da migração.

Deve terminar sem erros. Se der erro, para e mostra-me.

---

## FASE 2 · Verificar os pré-requisitos — no Setup

### 2.1 Partilhas

Em **Setup**, na caixa de pesquisa rápida, escreve **Sharing Settings**.

Na tabela **Organization-Wide Defaults**, olha para duas linhas:

| Objeto | O que precisa de estar |
|---|---|
| **Contact** | *Controlled by Parent* |
| **Account** | qualquer valor, desde que o Contact esteja como acima |

A regra oficial é: **Contact em *Controlled by Parent***, **ou** Account e Contact ambos em
*Private*. Basta uma das duas.

Se o Contact já estiver em *Controlled by Parent* — que é o valor por omissão numa org nova —
não tens nada a fazer aqui.

### 2.2 Leitura em Contact

O perfil que usas tem de ter leitura em Contact além de Account. Como estás como
**System Administrator**, isto está garantido. Não precisas de fazer nada.

### 2.3 Check Readiness

Em **Setup**, pesquisa **Person Accounts**.

Nessa página há um botão **Check Readiness**. Carrega nele.

> 🛑 **PARA AQUI.** Copia-me o resultado do Check Readiness antes de fazeres mais alguma coisa.
> Se faltar algum pré-requisito, é agora que se descobre — não depois de uma ação irreversível.

---

## FASE 3 · Ativar

Os três pré-requisitos estão confirmados:

| # | Pré-requisito | Como foi confirmado |
|---|---|---|
| 1 | Account com pelo menos um Record Type | Record Type **Empresa**, ativo na org |
| 2 | Perfis com Read em Account têm Read em Contact | Verificado nos 30 perfis, todos em par |
| 3 | Contact em *Controlled by Parent* | Confirmado no ecrã de Sharing Settings |

> Nota de método: o `EntityDefinition.InternalSharingModel` devolve `ReadWrite` para o Contact
> mesmo quando ele está em *Controlled by Parent*. Levou a um alarme falso. **Para partilhas,
> a interface é a fonte de verdade, não aquela query.**

### 3.1 Ativar

1. **Setup** → pesquisa **Person Accounts**
2. Carrega em **Check Readiness** — confirma que passa
3. Carrega em **Enable Person Accounts**
4. Na mensagem de aviso, carrega em **Enable**

> ⚠️ O passo 4 é o ponto sem retorno.

### 3.2 Atribuir o Record Type ao perfil

A ativação cria automaticamente um Record Type de Person Account. Ele existe, mas **ninguém o
vê** até ser atribuído a um perfil — é a mesma lição que já apanhámos com os campos: criar
metadados e conceder acesso a metadados são operações distintas.

Em **Setup → Profiles → System Administrator**, nas definições do objeto **Account**, atribui
o Record Type de Person Account e deixa-o disponível.

### 3.3 Confirmar

Cria uma Account nova. Deve aparecer um ecrã a perguntar o Record Type, com **Empresa** e o de
Person Account. Se aparecer, está feito — diz-me e passo à migração.

---

---

## FASE 4 · Migrar os dados — trabalho meu

Depois de ativado, escrevo o script de conversão. O plano:

1. **Testar numa única conta.** Escolho uma sem histórico de vendas e converto-a.
2. Se correr bem, converto as restantes. Se correr mal, paramos com as outras intactas.
3. **12 das 13 vendas fechadas** estão em contas "Família X" — Família Marques (3),
   Marta e André Vieira (2), Família Amaral (2) e mais seis. É histórico real, não é
   descartável, e é por isso que não se converte tudo de uma vez.

Também terei de rever, depois da ativação:

| O quê | Porquê |
|---|---|
| Layout de Person Account | Nasce um layout novo que ninguém desenhou |
| Conversão de Leads | Um lead sem empresa passa a converter para Person Account |
| Permission Set | Pode precisar de visibilidade dos Record Types novos |
| Script de dados demo | Os compradores particulares passam a nascer como Person Accounts |
| List views e reports | Confirmar que nenhum filtra por um campo que mudou de sítio |

---

## Se alguma coisa correr mal

O script de dados é re-executável — apaga a carga anterior e recria tudo:

```
sf apex run -f scripts/apex/carregar_dados_demo.apex -o terravista
```

O que **não** se desfaz é a ativação de Person Accounts. Daí as fases 1 e 2.
