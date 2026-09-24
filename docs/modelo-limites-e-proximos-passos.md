# Limites do modelo, e o que vem a seguir

Decisões de arquitectura que estão **identificadas e por implementar**. Não são
bugs: são limites conhecidos, com a razão pela qual se pararam ali e o desenho
do passo seguinte.

Saber nomear o limite do próprio modelo vale mais do que não o ter.

---

## 1. ~~Um negócio guarda um imóvel, não os que foram mostrados~~ — RESOLVIDO

Implementado a 24/09 com o objecto de junção `Imovel_Interesse__c`. A razão
pela qual se parou aqui durante semanas, e o desenho, ficam registados porque
a decisão que se rejeitou vale tanto como a que se tomou.

### O que estava

`Opportunity.Imovel__c` é um lookup único: guardava o imóvel em que o negócio
**aterrou**, não os que se mostraram pelo caminho. E o `Carimbar_Visita`
escrevia `Opportunity.Data_Visita__c` sem verificar se já estava preenchido —
segunda visita apagava a data da primeira. Ganhava sempre a última.

### O que se rejeitou, e porquê

Uma Opportunity por imóvel. É a solução óbvia e está errada: inflaciona o
pipeline de forma grave. Um comprador a quem se mostram cinco casas de 495 mil
apareceria com 2,5 milhões de pipeline para comprar **uma** casa. Qualquer
previsão de vendas passaria a ser ficção.

Um comprador é um negócio. Isso mantém-se.

### O que ficou

| | |
|---|---|
| `Imovel_Interesse__c` | uma linha por imóvel mostrado, dentro de um negócio |
| `Oportunidade__c` | Master-Detail → Opportunity (permite Roll-Up, e as linhas morrem com o negócio) |
| `Imovel__c` | Lookup com `deleteConstraint=Restrict` — apagar um imóvel não pode apagar o histórico |
| `Estado__c` | Sugerido / Visitado / Em espera / Proposta feita / Recusado |
| `Motivo_Recusa__c` | texto livre: a razão real raramente cabe numa picklist |
| `Opportunity.Imoveis_Mostrados__c` | Roll-Up count |
| `Opportunity.Imoveis_Recusados__c` | Roll-Up count filtrado |

**Uma linha por imóvel, nunca uma por visita.** O estado tem de ter uma verdade
única: um imóvel visitado três vezes e recusado no fim está *Recusado*, não
*Visitado* três vezes. As várias visitas ao mesmo imóvel são os **Eventos**
pendurados nessa linha — por isso o objecto tem `enableActivities`.

### O que isto obrigou a mudar

1. `AssistenteMarcarVisita` deixou de exigir que o negócio já estivesse preso
   àquele imóvel (`AND Imovel__c = :im.Id` saiu do WHERE). Era essa condição
   que impedia o segundo imóvel.
2. O `WhatId` do Evento passou a ser a linha de interesse e não o negócio.
3. O `Carimbar_Visita` ganhou um salto: `WhatId → linha de interesse → negócio`,
   com uma decisão pelo meio porque a maioria dos Eventos não tem linha
   nenhuma. Sem esse salto, a validation rule que exige a Data da Visita para
   avançar para "Visita Realizada" passaria a bloquear sempre.

### O que continua por responder

- **O imóvel não tem contador.** `Imovel__c` é lookup e não master, por isso
  não há Roll-Up do lado dele: "quantos clientes viram este imóvel" é um
  relatório, não um campo. Foi deliberado — master-detail no imóvel fazia as
  linhas morrerem com ele.
- **As leads não têm linha de interesse**, porque não têm negócio. Uma visita
  a uma lead continua a carimbar só `Lead.Data_Visita_Agendada__c`.
- **O `MatchImoveis` não cria linhas `Sugerido`.** Podia — e aí sim responderia
  a "que imóveis são muito sugeridos e nunca visitados". Não se fez porque o
  `MatchImoveis` lê, e uma classe que lê não deve começar a escrever sem que
  isso seja uma decisão própria.

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
