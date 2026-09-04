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
