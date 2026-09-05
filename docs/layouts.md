# Page Layouts — o que se vê e porquê

Um layout não é decoração. É a decisão sobre **o que uma pessoa lê antes de tomar
uma decisão**, e cada campo a mais esconde um campo que interessa.

---

## O problema que estava lá

Três coisas erradas, encontradas ao rever o que existia:

**1. Uma só layout de Account para empresas e pessoas.** A ficha da Cláudia Marques,
que quer um T2 em Matosinhos, mostrava *Indústria*, *Website*, *Empresa-Mãe* e
critérios de procura de **terreno** — tipo de solo, área bruta de construção. Campos
de construtora numa pessoa que quer casa.

**2. A layout de Contact ainda tinha o perfil de comprador.** Mas depois da migração
para Person Accounts, **um Contact nunca é um comprador** — é uma pessoa dentro de
uma empresa. O Alberto da Nortágua, a Rita dos Edifícios do Norte.

**3. `Motivo_Perda__c` era exigido por uma validation rule e não estava na layout.**

> Este terceiro é o mais grave, e é um bug a sério: quem tentasse marcar um negócio
> como Perdido era **impedido de gravar e não tinha onde escrever o motivo**. Uma
> regra que bloqueia sem dar saída não protege dados — ensina a contornar o sistema.

---

## Cliente Particular (Person Account)

A ordem segue **a chamada telefónica**, não o modelo de dados:

| Secção | Porquê aqui |
|---|---|
| **Quem é** | Nome, telefone, telemóvel, email, origem, responsável |
| **O que procura** | Perfil, tipologia, zonas, orçamento, financiamento |
| **O que sabemos dele** | Notas em texto livre, a **uma coluna** |
| **Sugestões do sistema** | O que a IA propôs, e a lista de candidatos que ela viu |
| **Morada** | No fim — só interessa quando já há visita marcada |

As notas ocupam a largura toda de propósito: é onde está o que nenhum campo
estruturado apanha. *"Elevador é condição absoluta."* *"Vista mar inegociável."* É
essa frase que decide um negócio, não a tipologia.

A secção das sugestões mostra **as duas coisas**: o que o modelo respondeu e a lista
fechada que ele recebeu. Consegue-se provar, olhando para o ecrã, que ele só viu
imóveis reais — e é exactamente a pergunta que um júri faz.

---

## Empresa

Construtoras, promotoras e investidores. Aqui os critérios de procura são **de
terreno**, porque é isso que esta gente compra: tipo de solo, ABC mínima, zonas,
orçamento máximo.

A secção chama-se **"Como decidem"** e não "Notas". O nome importa: é onde se escreve
*"decide com o conselho, reúne a primeira segunda-feira do mês"* — informação que
muda quando se liga, não um campo de despejo.

---

## Contact

Saiu daqui o perfil de procura inteiro. Os campos continuam a existir no objeto —
é deles que nascem os campos `__pc` do Person Account — mas mostrá-los numa ficha de
contacto empresarial é pedir a alguém que os preencha para nada.

O que fica é o que interessa num interlocutor: **como se lhe chega, que peso tem na
decisão, e quando reúne.**

---

## Opportunity

| Mudança | Porquê |
|---|---|
| `Motivo_Perda__c` entra | A validation rule exigia-o e não havia onde o escrever |
| `Comissao_Consultor__c` e `Margem_Terravista__c` entram | Só se via a comissão da empresa — o número que interessa à direcção, não a quem vende |
| `Angariador__c` entra, ao lado das comissões | É o campo que decide se metade da comissão vai para outra pessoa |
| `Dias_Sem_Atividade__c` entra | Um sinal que só existe num relatório semanal chega tarde |

Pôr a comissão do consultor ao lado da margem da empresa é uma escolha deliberada:
**quem vende vê o que ganha, e a empresa vê o que sobra**, no mesmo ecrã. Esconder
um dos dois números faz o outro parecer arbitrário.

---

## O que faz isto funcionar

Sem **atribuição por Record Type**, uma layout nova não muda nada no ecrã — o
Salesforce continua a mostrar a que já lá estava. Foi por isso que a
`Account-Account Layout` servia empresas e pessoas ao mesmo tempo.

```
Account.Empresa        → Account-Empresa
Account.PersonAccount  → Account-Cliente Particular
(sem Record Type)      → Account-Empresa
```

A `Account-Account Layout` saiu do repositório. **Continua a existir na org** — um
deploy não apaga o que se remove do source — mas já não está atribuída a nada. Para
a apagar de vez seria preciso um `destructiveChanges`, e não vale o risco a quatro
semanas da apresentação.
