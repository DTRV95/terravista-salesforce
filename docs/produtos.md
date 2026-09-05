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

## O catálogo

| | Serviço | Preço |
|---|---|---|
| **Obrigatório por lei** | Certificado Energético (SCE) | 175 € |
| | Ficha Técnica da Habitação | 90 € |
| | Certidão Permanente e Caderneta Predial | 35 € |
| | Pedido de Licença de Utilização | 300 € |
| **Valorização do imóvel** | Reportagem Fotográfica Profissional | 150 € |
| | Vídeo e Tour Virtual 360º | 320 € |
| | Planta 2D e 3D | 120 € |
| | Home Staging | 850 € |
| **Apoio ao processo** | Avaliação Imobiliária | 250 € |
| | Apoio Jurídico ao Processo | 400 € |
| | Tratamento do Processo de Escritura | 550 € |
| | Intermediação de Crédito Habitação | **0 €** |
| | Mediação de Seguro Multirriscos | 45 € |
| **Serviços a promotores** | Plano de Marketing de Empreendimento | 2.500 € |
| | Stand de Vendas no Local | 4.500 € |

O crédito à habitação está a **zero de propósito**: quem paga a intermediação é o
banco, não o cliente. Pô-lo a cobrar ao cliente descreveria mal o negócio, e é o
tipo de detalhe que um júri que conheça o sector nota.

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

O script cria 15 produtos, as entradas na tabela de preços e **6 negócios de
serviços** com linhas reais — dois entregues, um adjudicado, dois propostos e um
perdido.

> A tabela de preços standard vem **inativa** numa org nova. O script activa-a. Sem
> isso nenhuma linha de produto pode ser criada, e o erro que sai não fala de tabela
> de preços nenhuma.

---

## O que falta

Um report de receita de serviços. Fica para depois do deploy, quando souber os
tokens do report type de produtos — escrever reports às cegas já custou quatro
rondas neste projeto.
