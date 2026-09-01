# Matching de imóveis — a camada de IA

Como se constrói. A camada determinística já está feita (`MatchImoveis.cls`, 6 testes a passar).

---

## A arquitetura

```
Botão na página do cliente
        ↓
Flow  "Sugerir Imóveis"
        ↓
1. Apex  MatchImoveis  →  candidatos reais (SOQL) + notas do cliente
        ↓
2. Prompt Template     →  ordena, justifica, assinala impedimentos
        ↓
3. Update Record       →  escreve em Account.Sugestoes_Imoveis__c
```

> **O SOQL encontra. O modelo julga e explica.**
> O modelo nunca recebe a pergunta *"que imóveis existem?"*. Recebe uma lista fechada
> e a pergunta *"destes, qual serve, e porque é que o outro não serve?"*.

---

## Passo 1 · O Prompt Template

**Setup → Prompt Builder → New Prompt Template**

| Campo | Valor |
|---|---|
| Template Type | **Flex** |
| Name | `Sugerir Imóveis ao Cliente` |
| Model | o modelo por omissão da org |

### Input — um só

| Campo | Valor |
|---|---|
| Name / API Name | `Cliente` |
| Source Type | `Object` |
| Object | `Account` |
| Require when template runs | ✅ |

Os inputs de um template Flex são **objetos**, não texto solto. Por isso a lista de
candidatos que o Apex produz é escrita antes num campo do próprio cliente,
`Candidatos_Imoveis__c`, e o prompt lê-a de lá.

> **Isto é melhor do que passar texto directamente.** A lista fica visível no
> registo, ao lado da resposta. Consegue-se provar, olhando para o ecrã, que o
> modelo só viu imóveis reais — e é exactamente a pergunta que um júri faz.

### O texto do prompt

```
És assistente de um consultor imobiliário de uma agência do Porto.
O consultor vai falar com {!$Input:Cliente.Name} e precisa de saber que imóveis
lhe deve mostrar, e por que ordem.

IMÓVEIS DISPONÍVEIS PARA ESTE CLIENTE:
{!$Input:Cliente.Candidatos_Imoveis__c}

O QUE SABEMOS DO CLIENTE (notas escritas pelo consultor):
{!$Input:Cliente.Notas_Preferencias__pc}

ORÇAMENTO: {!$Input:Cliente.Orcamento_Min__pc} a {!$Input:Cliente.Orcamento_Max__pc} EUR

REGRAS QUE TENS DE CUMPRIR:
1. Usa APENAS os imóveis da lista acima. Nunca menciones um imóvel que não esteja
   lá. Se a lista estiver vazia, diz apenas que não há nada em carteira que sirva.
2. Lê as notas com atenção. Se o cliente disse que alguma coisa é condição
   absoluta ou inegociável, um imóvel que não a cumpra NÃO deve ser recomendado —
   mesmo que cumpra todos os outros critérios. Diz explicitamente porquê.
3. Não inventes características que não estejam na lista. Se não sabes se um
   prédio tem elevador, escreve "por confirmar" em vez de assumir.

RESPONDE ASSIM, em português de Portugal:

RECOMENDO MOSTRAR
Para cada imóvel recomendado, uma linha: nome, e numa frase porque encaixa
neste cliente em concreto.

MOSTRAR COM CUIDADO
Imóveis que servem mas têm um senão. Diz qual é o senão.

NÃO MOSTRAR
Imóveis da lista que não deves mostrar, e a razão. Se não houver nenhum,
escreve "Nenhum".

A CONFIRMAR ANTES DA VISITA
No máximo duas perguntas que o consultor deve esclarecer com o cliente.

Sê breve. O consultor lê isto entre duas chamadas.
```

### Porque é que o prompt está escrito assim

| Instrução | O que evita |
|---|---|
| *"Usa APENAS os imóveis da lista"* | O modelo inventar um "Aurora 4ºE" que não existe. É o risco que mata a credibilidade |
| *"condição absoluta → NÃO recomendar"* | O caso do Jorge Teixeira: encaixa em tipologia, zona e orçamento, mas o prédio não tem elevador |
| *"por confirmar" em vez de assumir* | O modelo preencher lacunas com invenções plausíveis |
| Secção **NÃO MOSTRAR** | Obriga o modelo a justificar exclusões. É onde está o valor real — um filtro só diz o que passa |
| *"Sê breve"* | Um parágrafo de três linhas que ninguém lê é o mesmo que nada |

---

## Passo 2 · Testar no painel, antes de ativar

O Prompt Builder tem painel de teste. **Usa-o antes de ativar o template.**

| # | Cliente | O que tem de acontecer |
|---|---|---|
| 1 | **Jorge Teixeira** | O T3 da Foz aparece em **NÃO MOSTRAR** ou **COM CUIDADO**, com o elevador citado |
| 2 | **Sofia Almada** | As notas dizem "vista mar inegociável" e nenhum imóvel diz ter vista mar → tem de perguntar, não assumir |
| 3 | **Cláudia Marques** | Investidora, decide depressa: deve recomendar sem grandes reservas |
| 4 | Cliente sem imóveis compatíveis | Diz que não há nada. **Não inventa** |

O teste 4 é o mais importante. É onde um modelo mal instruído inventa.

---

## Passo 3 · O Flow que liga tudo

**Screen Flow** ou **Quick Action** na página da Account.

1. **Apex Action** → `Encontrar imóveis para um cliente`, com `clienteId = {!recordId}`
2. **Update Records** → `Candidatos_Imoveis__c` = `resumo` do Apex
3. **Prompt Template Action** → input `Cliente` = o registo da Account
4. **Update Records** → `Sugestoes_Imoveis__c` = resposta do prompt

A ordem importa: o campo dos candidatos tem de estar escrito **antes** de o prompt correr.

Põe o campo `Sugestões de Imóveis` no layout da Account e o botão ao lado.

---

## Créditos — o risco da apresentação

Cada execução gasta créditos Einstein, e uma Developer Edition tem poucos.

**Testa o necessário e depois pára.** Não voltes a correr o prompt até ensaiares
a apresentação. Se os créditos acabarem no dia, a demonstração morre em direto.

**Plano B:** guarda uma captura do melhor resultado. E lembra-te que a camada 1
sozinha — o botão que filtra a carteira pelo perfil do cliente — funciona sem
gastar um único crédito, porque é SOQL.
