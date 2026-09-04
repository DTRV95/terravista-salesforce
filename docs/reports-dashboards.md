# Reports e dashboards

Requisito do enunciado, e a parte que um júri lê primeiro. Seis reports e um
dashboard, todos em metadata — versionados, não construídos à mão na org.

---

## Os seis reports

| Report | A pergunta a que responde | Agrupa por |
|---|---|---|
| **Comissões por consultor** | *Quanto tenho a receber?* | Consultor |
| **Margem mensal** | *O que sobra para a empresa?* | Mês da escritura |
| **Pipeline por fase** | *Onde está o negócio por fechar?* | Fase |
| **Angariações a pagar** | *Quanto devemos a quem angariou?* | Angariador |
| **Vendas por linha de negócio** | *Quanto é B2B e quanto é B2C?* | Linha de negócio |
| **Carteira disponível** | *O que está parado, e há quanto tempo?* | Tipo de imóvel |

Quatro deles filtram por **Escritura Realizada**, e isso não é detalhe:

> Uma comissão só se paga quando o negócio fecha, e a angariação só se paga
> quando o imóvel vende. Um report de comissões sem esse filtro mostra dinheiro
> que ainda não existe — e é o tipo de número que faz uma empresa tomar decisões
> erradas.

O **Pipeline por fase** leva os `Dias Sem Atividade` na tabela de propósito: uma
fase avançada parada há muito tempo é o sinal mais útil que um pipeline dá, e não
aparece em nenhum total.

---

## O dashboard

**Terravista — Direção**, seis componentes, a correr como **`LoggedInUser`**.

| | |
|---|---|
| **Recomendação** | Um dashboard dinâmico, a correr como quem o abre |
| **Alternativa** | Um dashboard fixo por consultor |
| **Vantagem** | Um consultor abre e vê as comissões *dele*; a direcção abre e vê tudo. Um dashboard só, e ninguém vê quanto ganha o colega |
| **Desvantagem** | Depende do modelo de partilha estar bem feito. Se a partilha estiver larga, toda a gente vê tudo |
| **Risco** | Baixo. E é a resposta directa ao *"os consultores conseguirem ver as comissões a receber"* |

---

## O que pode falhar no primeiro deploy

Os campos custom são previsíveis (`Opportunity.Comissao_Consultor__c`). Os
**standard usam nomes antigos** — `USERS.NAME` para o dono, `CLOSE_DATE`,
`AMOUNT`, `OPPORTUNITY_STAGE` — e esses não se adivinham com segurança.

Os seis foram escritos de uma vez **de propósito**: assim o primeiro deploy
devolve todos os nomes errados ao mesmo tempo, em vez de um por deploy.

Se um nome estiver errado, o erro diz qual. Corrige-se e repete-se uma vez.
