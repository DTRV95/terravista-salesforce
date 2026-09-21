# Limites do modelo, e o que vem a seguir

Decisões de arquitectura que estão **identificadas e por implementar**. Não são
bugs: são limites conhecidos, com a razão pela qual se pararam ali e o desenho
do passo seguinte.

Saber nomear o limite do próprio modelo vale mais do que não o ter.

---

## 1. Um negócio guarda um imóvel, não os que foram mostrados

### O que está hoje

`Opportunity.Imovel__c` é um lookup único. Guarda o imóvel em que o negócio
**aterrou**, não os que se mostraram pelo caminho.

Verificado na org em 21/09: existe **1 Event** em toda a base de dados,
`Subject = "Visita"`, com `WhatId = null`. Não há registo, em lado nenhum, de
que imóveis foram apresentados a que clientes.

E há um segundo ponto, no `AssistenteMarcarVisita`:

```apex
WhatId = negocios.isEmpty() ? im.Id : negocios[0].Id
```

Quando já existe negócio aberto, o Event liga-se **ao negócio** e o imóvel
visitado sobrevive apenas no texto do assunto (`'Visita — ' + im.Name`). Texto
não se reporta, não se filtra, não se conta.

### Porque não se fez uma Opportunity por imóvel

Seria a solução óbvia e está errada: inflaciona o pipeline de forma grave. Um
comprador a quem se mostram cinco casas de 495 mil apareceria com 2,5 milhões
de pipeline para comprar **uma** casa. Qualquer previsão de vendas passaria a
ser ficção.

Um comprador é um negócio. Isso mantém-se.

### O passo seguinte: `Imovel_Interesse__c`

Objecto de junção entre `Opportunity` e `Imovel__c`:

| Campo | Tipo | Para quê |
|---|---|---|
| `Oportunidade__c` | Master-Detail → Opportunity | o negócio |
| `Imovel__c` | Lookup → Imovel__c | o imóvel candidato |
| `Estado__c` | Picklist | Sugerido / Visitado / Recusado / Proposta feita / Em espera |
| `Motivo_Recusa__c` | Text | porque é que o cliente disse que não |
| `Data_Visita__c` | DateTime | quando foi visto |

**O que isto responde, e que hoje se perde:** que imóveis são muito visitados
e nunca comprados. Esse imóvel está mal posicionado no preço, e é o sinal para
renegociar com o proprietário antes de queimar a relação.

Pipeline honesto **e** histórico completo, sem escolher entre os dois.

### Correcção barata, independente deste objecto

No `AssistenteMarcarVisita`, pôr `WhatId = im.Id` em vez do negócio. Perde-se a
visita na timeline do negócio, ganha-se na do imóvel — e é no imóvel que a
informação é reutilizável. É uma linha.

---

## 2. Dois clientes querem o mesmo imóvel ao mesmo tempo

### O critério é de negócio, não técnico

No imobiliário português não reserva quem disse primeiro que queria. Reserva
**quem faz proposta formal aceite pelo proprietário e paga sinal**.

Interesse verbal não vincula ninguém. Dois clientes podem dizer "quero" na
mesma tarde e não há conflito nenhum. O conflito existe quando há duas
propostas — e quem decide não é a agência, é o proprietário. Pode aceitar a
mais baixa se vier com menos condições ou sem financiamento.

### O que está hoje

O `Imovel__c.Estado_Comercial__c` com `Disponivel → Reservado → Vendido`. O
cadeado certo existe. Verificado em 21/09: nenhum imóvel tem dois negócios
abertos — mas nada o impede, é sorte dos dados.

### O que falta

**Saber para quem está reservado.** Um `Reservado_Para__c` no imóvel, lookup
para a Opportunity. Sem isso sabe-se que está reservado e não se sabe porquê.

**Impedir o segundo.** Validation rule na Opportunity: não avança para Proposta
Aceite se o imóvel estiver `Reservado` e o `Reservado_Para__c` não for este
negócio.

**Prazo da reserva.** Um `Reserva_Valida_Ate__c` — tipicamente o prazo para
assinar o CPCV. Passado isso, o imóvel volta a `Disponivel` sozinho e o segundo
interessado deixa de estar bloqueado por quem desistiu.

### O segundo interessado não morre: fica em espera

Liga-se ao ponto 1. No `Imovel_Interesse__c`, o segundo fica em `Em espera`. Se
o primeiro negócio cair — e cai, quase sempre no financiamento — há uma lista,
por ordem, de quem mais quis aquela casa. Liga-se no próprio dia em vez de
recomeçar do zero.

*Um imóvel que teve três interessados e caiu não volta ao mercado às cegas.
Volta com uma lista de espera.*

### O limite honesto

Uma validation rule **não bloqueia linhas**. Se dois consultores gravarem no
mesmo instante, as duas transacções avaliam a regra antes de qualquer uma ter
gravado, e as duas passam.

Resolver isso a sério exigiria um trigger com `SELECT ... FOR UPDATE` sobre o
imóvel.

**Decisão: não fazer.** Numa agência de dois consultores a probabilidade de
duas gravações no mesmo milissegundo é desprezável, e o custo do erro é um
telefonema. Não compensa o risco de deadlocks e a complexidade.

A regra resolve o caso realista — dois consultores em momentos diferentes. Não
resolve a corrida verdadeira, e isso é sabido, não esquecido.
