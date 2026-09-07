# Regras de avanço — o sistema não deixa mentir

Uma fase só se pode marcar quando o trabalho que ela representa foi mesmo feito.

---

## A limitação que decide a arquitetura

**Uma validation rule não consegue ver Tasks nem Events.** Nenhuma fórmula em Lead ou
Opportunity consegue contar registos filhos. Não há maneira de escrever *"só avança se
existir uma chamada"*.

A saída não é Apex:

```
Flow carimba o facto num campo  →  Validation rule lê o campo
```

É standard, é auditável — o campo fica visível no registo — e serve todos os casos.

---

## O que mudou

| Regra | Antes | Agora |
|---|---|---|
| Avanço do lead | `LastActivityDate` — qualquer actividade | `Data do 1º Contacto` — só uma **chamada concluída** |
| *Visita Agendada* (Lead) | Nada a verificava | Exige Evento no calendário |
| *Visita Realizada* (Opp) | Nada a verificava | Exige Evento no calendário |

O `LastActivityDate` não distingue uma chamada de um email nem de uma nota. Deixava
passar um lead que ninguém tinha ligado.

---

## A decisão mais importante: concluída, não criada

Houve a hipótese de carimbar a data quando a **tarefa existe**, em vez de quando a
chamada é **concluída**. É mais cómodo — e destruiria o projeto.

> Se a tarefa for criada automaticamente quando o lead entra, e a sua mera existência
> carimbar a data, **todos os leads ficam com latência zero no instante em que
> entram**. O gráfico que abre a apresentação — 13,7 horas contra uma meta de 2 —
> passa a ser uma linha recta no chão.

Duas automações que, isoladas, pareciam boas, anulavam a tese do projeto.

| | |
|---|---|
| **Recomendação** | Carimbar na **conclusão** da chamada |
| **Alternativa** | Carimbar na criação da tarefa |
| **Vantagem** | A métrica mede a realidade. E é honesto: uma tarefa aberta que ninguém fez **é** o problema do Case Study, não a prova de que foi resolvido |
| **Desvantagem** | Na demonstração é preciso marcar a tarefa como concluída antes de avançar — um clique a mais |
| **Risco da alternativa** | Alto e invisível: o sistema fica coerente e os números ficam falsos |

---

## O buraco que isto tapou

Ao construir o Flow descobriu-se que **o `Data_Primeiro_Contacto__c` só era preenchido
pelo script de dados**. Numa org real ficaria sempre vazio.

Ou seja: a métrica que abre a apresentação não tinha nada a alimentá-la. Os números
existiam porque um script os escrevia, não porque o sistema os produzia. O Flow
`Carimbar Primeiro Contacto` fecha isso — a partir de agora, quem regista uma chamada
alimenta o dashboard sem saber que o está a fazer.

---

## Porque é que o `ISCHANGED` está em todas

`ISCHANGED()` devolve falso numa criação. Sem ele, o `semear_org.apex` deixava de
correr: cria leads já em *Qualificado* e negócios já em *Escritura Realizada*, e as
regras bloqueavam a carga inteira.

O preço é conhecido e aceite: um registo **criado** directamente numa fase avançada
não é verificado. Só o **avanço** é. É a troca certa — a regra existe para disciplinar
o trabalho do dia a dia, não para policiar migrações de dados.

---

## As peças

| Peça | O que faz |
|---|---|
| `Lead.Data_Visita_Agendada__c` | Carimbo da visita no lead |
| `Opportunity.Data_Visita__c` | Carimbo da visita no negócio |
| Flow **Carimbar Primeiro Contacto** | Chamada concluída → carimba a data no lead |
| Flow **Carimbar Visita** | Evento agendado → carimba no lead **e** no negócio |
| Regra `Avanco_exige_contacto_registado` | Reescrita para ler o carimbo |
| Regra `Visita_agendada_exige_evento` | Nova |
| Regra `Visita_realizada_exige_evento` | Nova, só para venda e arrendamento |

O Flow da visita corre as duas actualizações sempre: a que não encontrar registo não
faz nada. É mais simples e mais barato do que decidir antes qual delas se aplica.

---

## Fica para depois

Os Flows que **criam tarefas** ao avançar de fase — *"ligar ao lead"*, *"enviar
proposta"*, *"marcar escritura"*. Não por serem má ideia, mas por sequência: um deploy
é atómico e os Flows são o metadata mais frágil deste projeto. Vale a pena provar o
padrão com dois antes de acrescentar mais três.
