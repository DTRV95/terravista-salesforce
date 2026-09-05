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

---

## Related lists — onde se ganha tempo

Um layout bem feito não é só o que se lê no topo. **É o que se consegue decidir sem
abrir mais nada.** Cada related list foi desenhada com as colunas que permitem agir
na própria lista.

### A regra que guiou todas

> Se para perceber uma linha é preciso clicar nela, a coluna que falta é o problema.

| Ecrã | Lista | A coluna que faz a diferença |
|---|---|---|
| **Empresa** | Contratos de mediação | `% Comercializada`, `Imóveis Vendidos` |
| **Cliente Particular** | Negócios | `Imóvel`, `Dias Sem Atividade` |
| **Contrato** | Frações | `Dias Disponível` |
| **Imóvel** | Negócios | `Dias Sem Atividade` |

### A mais importante de todas

Na ficha de uma construtora, a primeira lista são os **contratos de mediação**, com o
número de frações, quantas venderam e a percentagem comercializada.

> Abrir a Construtora Nortágua e ver, sem clicar em nada, o ritmo de cada
> empreendimento. **É exactamente o relatório que o Miguel reconstruía à mão ao fim
> da tarde** — passa a ser a página do cliente.

### Duas que revelam relações que ninguém via

**Contratos na ficha de um particular.** Um comprador também pode ser
*proprietário*. Sem esta lista, a herança dos Silva Matos aparece como cliente e não
se vê que a Terravista lhe está a vender três imóveis.

**Campanhas na ficha do cliente.** É a ligação Marketing → Vendas do Case Study: a
Sofia deixa de não saber que aquele lead veio da campanha de Matosinhos.

### Onde as colunas de tempo entram

`Dias Sem Atividade` e `Dias Disponível` aparecem em quatro listas diferentes. Não é
repetição — é a tese do projeto aplicada ao trabalho de todos os dias.

Numa lista de 32 frações, 32 linhas iguais não dizem nada. Com os dias em que cada
uma está parada, a lista **ordena-se sozinha na cabeça de quem a lê**: as de cima
estão mal avaliadas ou mal mostradas, e qualquer das duas coisas se resolve.

### A lista que está vazia de propósito

Na Opportunity há uma lista de **produtos**, que só tem conteúdo no Record Type
*Serviços*. Numa venda de imóvel fica vazia — e tem de ficar: pôr-lhe produtos faria
o Salesforce recalcular o `Amount` e desfazer a comissão.
