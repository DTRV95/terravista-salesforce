# Produtos e serviços

Uma agência imobiliária não vive só da comissão. Vende serviços à volta de cada
imóvel — e alguns nem são opcionais: sem certificado energético não se vende.

---

## A decisão que teve de ser tomada primeiro

A comissão da Terravista assenta no `Amount` da oportunidade:

```
Comissao_Terravista__c = Amount × Contrato.Comissao__c
```

E o Salesforce, **quando uma Opportunity tem produtos, calcula o `Amount` como a
soma das linhas** e torna o campo não editável.

> Pôr um certificado energético de 175 € como linha de produto numa venda de
> 250.000 € faria a comissão passar a ser calculada sobre os 175 €. Não é um
> arredondamento — é o modelo de negócio inteiro a desfazer-se em silêncio, sem
> erro nenhum.

| | |
|---|---|
| **Recomendação** | Os serviços vivem numa oportunidade **própria**, Record Type `Serviços`, ligada ao mesmo imóvel |
| **Alternativa** | Linhas de produto na venda do imóvel |
| **Vantagem** | O `Amount` da venda continua a ser o preço da casa. Product2, Pricebook e OpportunityLineItem entram tal como a Salesforce os desenhou |
| **Desvantagem** | Dois registos por negócio em vez de um. Ligam-se pelo imóvel |
| **Risco** | Baixo. O inverso é alto e silencioso |

**As fases de fecho também são próprias.** Reutilizar *Escritura Realizada* metia os
serviços dentro dos quatro reports de comissões — 175 € a aparecer ao lado de
250.000 €. As fases novas são `Serviço Proposto → Serviço Adjudicado → Serviço
Entregue`, mais `Perdido`.

E as duas fórmulas passaram a excluir este Record Type: `Comissao_Terravista__c`
devolve 0, e `Valor_Estimado_Venda__c` não conta serviços como vendas por fechar.

---

## O catálogo — três serviços

| | Serviço | Preço |
|---|---|---|
| **Obrigatório por lei** | Certificado Energético (SCE) | 175 € |
| **Obrigatório por lei** | Tratamento Documental | 150 € |
| **Apoio ao processo** | Avaliação Imobiliária | 250 € |

Três, e não quinze. Um catálogo comprido não conta melhor a história — dá mais
linhas para um júri duvidar de cada uma. Estes três chegam porque cobrem os dois
casos que interessam:

- **O que não é opcional.** Sem certificado energético o imóvel não pode sequer ser
  anunciado. É a prova de que a agência vende serviços que o cliente *tem* de
  comprar, e não extras que pode dispensar.
- **O que resolve um problema real.** A avaliação é o serviço que acaba a discussão
  de preço com o proprietário — com um número em vez de uma opinião.

O **Tratamento Documental** junta ficha técnica, certidão permanente e caderneta
predial num só produto. Não é preguiça a modelar: é assim que são pedidos. Ninguém
chega à escritura com um só destes documentos, e três produtos de 35 € a 90 € a
serem sempre vendidos juntos são três linhas para dizer uma coisa só.

A categoria é um campo nosso e não o `Family` standard. O `Family` faria o mesmo,
mas numa org nova não traz valores nenhuns e defini-los obriga a mexer no value set
standard — esta picklist fica versionada com o vocabulário do negócio.

---

## Como correr

```
sf project deploy start -d force-app/main/default/objects -d force-app/main/default/standardValueSets -d force-app/main/default/permissionsets -o terravista
sf apex run -f scripts/apex/semear_produtos.apex -o terravista
```

Corre **depois** do `semear_org.apex`: precisa dos imóveis e dos clientes.

O script cria 3 produtos, as entradas na tabela de preços e **5 negócios de
serviços** com linhas reais — dois entregues, um adjudicado, um proposto e um
perdido.

> A tabela de preços standard vem **inativa** numa org nova. O script activa-a. Sem
> isso nenhuma linha de produto pode ser criada, e o erro que sai não fala de tabela
> de preços nenhuma.

---

## O que falta

Um report de receita de serviços. Fica para depois do deploy, quando souber os
tokens do report type de produtos — escrever reports às cegas já custou quatro
rondas neste projeto.
