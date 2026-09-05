# Reports e dashboards

O Notion define a tese do projeto, e ela não é o pipeline:

> *"A maioria dos projetos mostra um dashboard de pipeline: quanto vale, quantos
> negócios, quem vende mais. O diferenciador deste projeto é medir **latência** —
> o tempo entre as coisas acontecerem."*

A primeira versão destes reports foi construída a partir do modelo de dados e não
do plano, e ficou sem os dois componentes que o Notion marca como o coração da
apresentação. Estão agora construídos, e são os primeiros do dashboard.

---

## Os nove reports

| Report | A pergunta a que responde | Persona |
|---|---|---|
| **Latência até ao 1º contacto** | *Quanto tempo demoramos a ligar de volta?* | Rita |
| **Perdidos por demora** | *Perdemos por culpa nossa ou nunca foi viável?* | Rita |
| Comissões por consultor | *Quanto tenho a receber?* | Todos |
| Margem mensal | *O que sobra para a empresa?* | Rita |
| Pipeline por fase | *Onde está o negócio por fechar?* | Rita, Miguel |
| Angariações a pagar | *Quanto devemos a quem angariou?* | Rita |
| Vendas por linha de negócio | *Quanto é B2B, quanto é B2C?* | Rita |
| Ritmo dos empreendimentos | *Quanto de cada empreendimento está colocado?* | Miguel |
| Carteira disponível | *O que está parado, e há quanto tempo?* | Miguel |

---

## Os dados de latência não existiam

As duas fórmulas de latência medem a partir do `CreatedDate`. Como o `semear_org`
criava tudo no mesmo instante, **os 10 leads tinham os carimbos todos vazios** — os
dois componentes principais dariam gráficos em branco.

O `semear_org.apex` passa a criar 24 leads espalhados por 12 semanas, com
`CreatedDate` próprio. Isso exige duas coisas:

1. A permissão **`SetAuditFields`** — já está no permission set
2. O visto em **Setup → User Interface → Enable "Set Audit Fields upon Record Creation"**

> Não é um truque para embelezar números. É a permissão que a Salesforce tem
> exactamente para carregar dados históricos, e sem ela nenhuma métrica que meça
> tempo decorrido pode ser demonstrada numa org criada ontem.

**A história que os números contam não é favorável, e é de propósito.** A atribuição
é rápida — a Assignment Rule funciona. O primeiro contacto é que demora: 26 horas há
três meses, 4 horas na semana passada, com a meta nas 2. E os leads que se perderam
são os que esperaram mais. Um dashboard que só mostra o que corre bem não serve para
decidir nada.

---

## O dashboard

**Terravista — Direção**, com a latência na coluna da esquerda, antes das comissões.
**Terravista — B2B**, com o ritmo dos empreendimentos — o relatório que o Miguel
reconstruía à mão.

Ambos correm como **`LoggedInUser`**: um consultor abre e vê as comissões *dele*, a
direcção abre e vê tudo, e ninguém vê quanto ganha o colega.

### O que falta face ao plano do Notion

Os dashboards da **Sofia (Apoio)** e da **Inês (Marketing)** ainda não estão feitos.
Precisam de reports sobre Task e CampaignMember, e desses ainda não construí nenhum.
Ficam para depois do primeiro deploy — só faz sentido escrever mais oito reports
quando souber que os nomes de coluna destes nove estão certos.

Uma correcção ao plano: o Notion diz *Desempenho por agente → Opportunity Splits*.
Os Splits foram rejeitados depois, por não funcionarem sobre campos de fórmula. O
report de comissões substitui-os.

---

## O que pode falhar no primeiro deploy

Os campos custom são previsíveis (`Opportunity.Comissao_Consultor__c`). Os
**standard usam nomes antigos** — `USERS.NAME`, `CLOSE_DATE`, `AMOUNT`,
`OPPORTUNITY_STAGE`, `LEAD.LAST_NAME` — e esses não se adivinham com segurança.
O mesmo vale para os nomes dos report types: `Opportunity`, `LeadList`, `Contracts`,
`Imovel__c`.

Vão todos juntos **de propósito**: assim o primeiro deploy devolve todos os nomes
errados ao mesmo tempo, em vez de um por deploy.

---

## O que o primeiro deploy ensinou

Doze erros, seis causas. Nenhuma delas se adivinhava — a documentação da Salesforce
estava inacessível, e a verdade foi obtida a construir um report real na UI e a
descarregar o metadata dele.

| # | O que estava errado | O que é verdade |
|---|---|---|
| 1 | `<column>s!Campo</column>` | O prefixo `s!`/`a!` **não existe**. O tipo de agregação é um elemento à parte: `<aggregate>Sum</aggregate>` |
| 2 | `<legendPosition>Right</legendPosition>` | Não é aceite. Um gráfico real da org nem sequer define este elemento |
| 3 | `<reportType>Contracts</reportType>` | `ContractList` |
| 4 | `<field>LEAD.LAST_NAME</field>` | `LAST_NAME` — os reports usam tokens **sem prefixo**, ao contrário das list views |
| 5 | `<scope>organization</scope>` em Lead | Não é válido. `team` é, e como o admin está no topo da hierarquia vê tudo na prática |
| 6 | `backgroundFadeDir` | `backgroundFadeDirection` |

> **A lição que fica:** um deploy que passa prova que a sintaxe foi aceite, não que
> a lógica está certa — já sabíamos. O reverso também é verdade: quando não há
> documentação, **a org é a documentação**. Constrói-se a coisa na interface, faz-se
> `retrieve`, e lê-se o que a Salesforce escreveu.

### Os dois que não eram nomes errados

**`Imovel__c` não tinha report type nenhum.** Não era o nome que estava errado — é
que o `Imovel__c` é o lado *detail* de uma relação Master-Detail com o Contract, e
objectos nessa posição não recebem report type automático. Criou-se um report type
custom, `Imoveis_da_Carteira`, que é metadata deployável como tudo o resto.

**`SetAuditFields` não aparecia em lado nenhum** porque a permissão só passa a
existir no esquema depois de se ligar a preferência da org:
**Setup → User Interface → Enable "Set Audit Fields upon Record Creation"**.
Procurá-la antes disso é procurar uma coisa que ainda não foi criada.

Saiu do permission set para não bloquear o deploy, e o `semear_org` passa a
verificar se consegue escrever o `CreatedDate`. Se não conseguir, **não cria a
coorte** e escreve porquê no log — uma linha vazia com aviso é melhor do que datas
erradas sem aviso.

### Segunda ronda de correcções

O primeiro lote não chegou. Uma segunda leitura do metadata real da org deu mais seis:

| O que estava errado | O que é verdade |
|---|---|
| `USERS.NAME` | `FULL_NAME` |
| `OPPORTUNITY_STAGE` | `STAGE_NAME` |
| `<scope>` em `Ritmo_Empreendimentos` | Não se declara neste report type |
| `<field>NAME</field>` no report type | `Name` — a capitalização conta |
| Títulos de gráfico compridos | Há limite de comprimento |
| Dashboards sem `chartAxisRange` e `sortBy` | Os componentes reais trazem-nos |

Onze erros no primeiro deploy, seis causas; e depois mais seis causas na segunda
volta. Não é sinal de descuido — é o que custa escrever metadata de reports sem
documentação acessível.

> Se houver uma terceira volta, a decisão certa deixa de ser corrigir à mão e passa
> a ser **construir os reports na interface e fazer `retrieve`**. O tempo até à
> apresentação vale mais do que a elegância de os ter escrito à mão.

### Terceira ronda — o `__c` que não está em lado nenhum

Onze erros passaram a dois, e os dois eram o mesmo:

```
<reportType>Imoveis_da_Carteira</reportType>     ← recusado
<reportType>Imoveis_da_Carteira__c</reportType>  ← aceite
```

O `fullName` do report type **não** leva sufixo, e o ficheiro dele não o menciona em
lado nenhum. Mas a **referência** a partir de um report leva `__c`. São duas grafias
para a mesma coisa, e a única forma de o descobrir foi construir um report na
interface contra esse report type e fazer `retrieve`.

> É o mesmo padrão de sempre neste projeto: o Salesforce tem nomes que a
> documentação não expõe, e a org sabe-os todos. Perguntar à org é mais rápido do
> que procurar a resposta.

O `Terravista_B2B` falhava por arrasto — não tinha problema nenhum de si.

### Quarta ronda — o cifrão

Debaixo do `__c` estava outro nome escondido:

```
<field>Imovel__c.Tipologia__c</field>   ← recusado
<field>Imovel__c$Tipologia__c</field>   ← aceite
```

Num report cuja base é um **report type custom**, a tabela separa-se do campo por
`$`. O ponto só funciona quando a base é um objecto standard — e é exactamente por
isso que os reports de Contract, Lead e Opportunity passaram todos à primeira, com
`Contract.Nome_Empreendimento__c` e companhia.

O Salesforce só reporta o primeiro campo inválido de cada componente, por isso um
erro escondia sete.

---

## Cinco dashboards, um por departamento

| Dashboard | A pergunta que responde | Componentes |
|---|---|---|
| **Direção** | *Está a crescer ou a estagnar, e onde estão os gargalos?* | **15 — todos** |
| **Marketing** | *Que campanha compensa?* | 5 |
| **B2B** | *Onde está cada negociação e que frações tenho por colocar?* | 5 |
| **B2C** | *Que negócios tenho em curso e o que tenho para mostrar?* | 5 |
| **Apoio ao Cliente** | *Quem está a ficar para trás neste momento?* | 5 |

A Direção tem **tudo**, e é o único sítio onde as fronteiras entre equipas
desaparecem — que é precisamente o problema nº4 do Case Study. Os outros quatro
mostram só o que aquela pessoa decide com.

Os quinze componentes assentam em **quinze reports**, e vários são partilhados: a
latência aparece na Direção, no B2C e no Apoio, porque o primeiro contacto é
trabalho da Carla, fila de trabalho da Sofia e indicador da Rita — a mesma verdade
vista de três sítios. Um report, três dashboards.

### Decisões de ordem, que não são arbitrárias

- Na **Direção**, a latência ocupa o canto superior esquerdo. É onde o olho cai, e é
  a tese do projeto.
- No **Marketing**, a receita por campanha vem **antes** do número de leads. Uma
  campanha que traz muitos leads maus parece boa em qualquer dashboard que conte
  leads — e foi assim que se justificou investimento durante anos.
- No **Apoio**, os dois primeiros são *filas de trabalho*, não indicadores. Abre-se
  aquele dashboard para agir, não para saber.

### Reports novos

| Report | Para quem |
|---|---|
| Leads por origem | Marketing, Apoio |
| Conversão por origem | Marketing |
| Receita por campanha | Marketing |
| Leads sem 1º contacto | Apoio, Marketing |
| Carga por consultor | Apoio |
| Pipeline B2C | B2C |
