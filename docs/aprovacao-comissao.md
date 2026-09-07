# Aprovação da comissão

Uma comissão de mediação abaixo de **4%** precisa de segunda assinatura.

---

## Porque é este o processo, e não outro

Consideraram-se quatro candidatos. Este ganhou por uma razão concreta:

> **É o único sítio do sistema onde uma pessoa sozinha pode dar dinheiro da
> empresa.** O `Comissao__c` do contrato alimenta a comissão de **todas** as vendas
> daquele contrato. Num empreendimento de 32 frações, um ponto percentual a menos são
> milhares de euros — decididos por quem assina o contrato, sem mais ninguém saber.

| Candidato | Porque não |
|---|---|
| Perder um negócio acima de X € | Atrasa o registo da realidade. O negócio continua perdido enquanto se espera, e o efeito prático é as pessoas não o marcarem |
| Exclusividade no contrato | Decisão comercial, não financeira. Um checkbox não justifica um processo |
| Desconto no preço do imóvel | Quem decide o preço é o proprietário, não a Terravista. Aprovar internamente seria modelar mal o negócio |

---

## Como funciona

| | |
|---|---|
| **Dispara quando** | O contrato tem comissão preenchida e **abaixo de 4%** |
| **Quem submete** | O dono do registo |
| **Quem aprova** | A direção |
| **Enquanto espera** | O registo fica **bloqueado** — só o administrador edita |
| **Se aprovado** | `Aprovação da Comissão` = *Aprovada* |
| **Se rejeitado** | *Rejeitada*, e o registo volta a editável |

Um passo só. Dois passos numa agência de dois consultores seria burocracia a fingir
de governo.

---

## A armadilha que este ficheiro evita — de olhos abertos

```
Comissao__c < 0.04      ← 4%
Comissao__c < 4         ← 400%
```

**Um campo Percent, em contexto de fórmula, vale a fração e não o número que se vê no
ecrã.**

Este projeto já teve uma validation rule partida exactamente por isto: comparava
`Comissao__c > 10` para travar comissões acima de 10%, e **só disparava acima de
1000%**. Esteve escrita e inútil durante dias, e o deploy aceitava-a todas as vezes.

> É o melhor exemplo do princípio que este projeto aprendeu à força: **um deploy que
> passa prova que a sintaxe foi aceite, não que a lógica está certa.**

---

## O campo que torna isto visível

Sem um campo de estado, um contrato à espera de decisão é indistinguível de um já
aprovado — a aprovação existiria no histórico e não no ecrã.

`Aprovação da Comissão` fica **ao lado da comissão** no layout, e **no painel de
destaques**: um contrato pendente vê-se de fora, sem abrir nada.

O campo é **só de leitura** para toda a gente. Quem o muda é o processo, não uma
pessoa — um estado de aprovação editável à mão não é um estado de aprovação.

---

## O que é preciso saber para o demonstrar

1. Abrir um contrato e pôr a comissão a **3%**
2. **Submeter para aprovação** — o botão está no painel de destaques
3. O campo passa a *Pendente* e o registo fica bloqueado
4. Aprovar — passa a *Aprovada* e desbloqueia

O aprovador está **escrito no ficheiro** (`terravista.david@agentforce.com`), o que
torna este processo dependente desta org — a mesma limitação dos dois dashboards que
correm como utilizador fixo. Não há forma de o parametrizar em metadata.

---

## Porque é que há um ficheiro de Workflow

Um processo de aprovação só sabe chamar **field updates**, que vivem em metadata de
Workflow. O `Contract.workflow-meta.xml` tem três, e **nenhuma workflow rule** — as
regras deste projeto vivem em Flows, que é o que a Salesforce recomenda desde que as
workflow rules deixaram de evoluir. Esta é a excepção permitida, e está lá escrito
porquê.
