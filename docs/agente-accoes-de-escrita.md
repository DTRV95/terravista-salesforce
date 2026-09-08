# O agente que escreve

O agente deixa de só ler. Passa a criar clientes, marcar visitas e criar tarefas
a partir do que o consultor lhe diz.

---

## Porque é que isto muda o projeto

Um agente que responde é uma demonstração. **Um agente que escreve é um sistema.**

E há um momento que nenhum outro projeto vai ter:

```
O agente cria o Evento da visita
        ↓
O Flow "Carimbar Visita" preenche a Data da Visita
        ↓
A validation rule deixa de bloquear a fase
        ↓
O consultor avança para "Visita Realizada"
```

**A IA desbloqueia uma regra de negócio.** Não está ao lado do sistema — está lá
dentro, a mexer na automação e no governo de dados que foram construídos antes dela.

Por isso o evento se liga ao **negócio** e não ao imóvel quando há um em curso. Ligar
ao imóvel registava a visita na mesma, mas não carimbava nada — e a corrente ficava a
meio.

---

## As três regras

Sugerir um imóvel errado é embaraçoso e desfaz-se com uma frase. **Criar um cliente
errado fica na base de dados.** Por isso esta classe é governada por três regras, e
cada uma tem um teste.

### 1 · Nunca criar sem procurar primeiro

Antes de criar uma ficha, procura por alguém com o mesmo apelido. Se encontrar,
**não cria** — devolve a lista e manda o agente perguntar.

> É o mesmo princípio da ambiguidade no matching: perguntar é sempre melhor do que
> adivinhar. Num registo novo, a diferença é que o erro fica para sempre.

### 2 · Nunca inventar valores

O que o consultor não disser fica **em branco**.

> Um campo vazio é informação — diz que ninguém perguntou. Um campo preenchido por
> adivinhação **mente**, e é indistinguível de um valor que o cliente disse. Ninguém
> volta atrás para verificar.

### 3 · O agente não tem privilégios

A classe corre `with sharing` e as validation rules aplicam-se-lhe como a qualquer
pessoa. Quando o DML falha, a resposta devolve **a mensagem da própria regra**, para
o consultor perceber o que faltou.

> É a resposta à pergunta que qualquer jurado sério faz: *"e se a IA fizer asneira?"*
> Faz o mesmo que uma pessoa faria: é recusada.

---

## As três acções

| Acção | O que faz | O que recusa |
|---|---|---|
| **Criar cliente particular** | Ficha nova com o perfil de procura | Nome incompleto · apelido que já existe |
| **Marcar visita** | Evento ligado ao cliente e ao negócio | Sem data · cliente ou imóvel ambíguo ou desconhecido |
| **Criar tarefa** | Tarefa **aberta**, para hoje se não disserem quando | Sem assunto · cliente ambíguo |

A tarefa nasce sempre **aberta**. Uma tarefa criada já concluída diria que o trabalho
estava feito quando ainda nem começou — e dispararia os carimbos de latência com uma
data falsa, exactamente o erro que discutimos ao desenhar os Flows.

---

## Testes

Dez, um por decisão. Os que interessam mais:

| Teste | O que protege |
|---|---|
| `nao_duplica_quando_ja_existe_o_apelido` | A regra 1. Confirma que **continua a haver só uma ficha** |
| `o_que_nao_foi_dito_fica_em_branco` | A regra 2, campo a campo |
| `marca_a_visita_e_liga_ao_negocio_em_curso` | Que o `WhatId` é o negócio — sem isso a corrente parte |
| `sem_data_pergunta_em_vez_de_assumir` | Que **não fica nenhum evento** criado |
| `a_tarefa_nasce_aberta` | Que o estado é `Not Started` |

---

## Como testar no agente, com poucos créditos

Escreve as perguntas **antes** de abrir o chat. Cada mensagem gasta vários pedidos.

| # | Dizer ao agente | Tem de acontecer |
|---|---|---|
| 1 | *Cria ficha para a Mariana Bragança, procura T2 em Matosinhos até 220 mil* | Cria e devolve o cartão |
| 2 | *Cria ficha para o João Marques* | **Avisa que já existe** um Marques e pergunta |
| 3 | *Marca visita do Jorge Teixeira ao T3 da Foz para sábado às 15h* | Cria o evento **e a Data da Visita preenche-se** |
| 4 | *Marca visita do Jorge ao T3 da Foz* (sem hora) | **Pergunta a hora**, não assume |
| 5 | *Lembra-me de ligar à Claudia amanhã* | Tarefa aberta, prazo amanhã |

O teste 4 é o mais importante. É onde um agente mal desenhado inventa uma hora.

---

## O que fica de fora, de propósito

**Apagar e alterar.** O agente cria; não modifica nem elimina. Um agente que apaga
registos a pedido é um risco que nenhuma agência aceitaria, e a demonstração não
ganha nada com isso.

**Criar contratos e negócios.** São decisões com dinheiro. O contrato tem a comissão
que alimenta tudo, e já tem um processo de aprovação para descer abaixo de 4% —
deixar um modelo criá-lo seria contradizer essa decisão na frase seguinte.
