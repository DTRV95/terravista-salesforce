# O Agente — sugerir imóveis em conversa

O que falta para o consultor perguntar *"que imóveis tenho para o Jorge?"* e receber
imóveis reais e clicáveis.

---

## O que já está feito

`MatchImoveis` aceita **Id ou nome** do cliente e devolve `List<Imovel__c>` — registos
reais, não texto. É isso que faz o chat mostrar cartões clicáveis em vez de uma lista
escrita.

E resolve o nome em **SOQL**, nunca pelo modelo:

| Situação | O que devolve |
|---|---|
| Nome único | os imóveis desse cliente |
| Nome ambíguo | *"Há mais do que um cliente com esse nome: A, B. Pergunta qual."* |
| Nome desconhecido | *"Não encontrei nenhum cliente com o nome X."* |

> Pedir a um modelo o Id de um registo é pedir-lhe que o invente. A ambiguidade
> resolve-se **perguntando**, nunca adivinhando: escolher um cliente ao acaso dava uma
> resposta confiante sobre a pessoa errada, que é pior do que não responder.

---

## Passo 1 · Deploy e testes

```
git pull
sf project deploy start -o terravista
sf apex run test --class-names MatchImoveisTest --result-format human -o terravista
```

São agora **9 testes**. Os três novos cobrem a procura por nome, a ambiguidade e o nome
desconhecido — os três caminhos que o agente vai usar.

---

## Passo 2 · A Agent Action

Em Setup, na área do Agentforce, cria uma **ação nova do tipo Apex** e escolhe
`MatchImoveis`.

**A descrição da ação é a peça mais importante de todo o agente.** É por ela que o
planeador decide quando a chamar. Uma descrição vaga faz o agente ignorar a ação ou
usá-la em alturas erradas.

**Descrição da ação:**

```
Encontra imóveis disponíveis na carteira da Terravista que correspondem ao perfil
de procura de um cliente. Usa esta ação sempre que alguém perguntar que imóveis
mostrar, sugerir ou apresentar a um cliente. Devolve apenas imóveis reais da
carteira.
```

**Descrição dos inputs:**

| Input | Descrição |
|---|---|
| `Id do Cliente` | Usa quando estás na página de um cliente. |
| `Nome do Cliente` | Usa quando o utilizador refere o cliente pelo nome. |
| `Finalidade` | `Venda` ou `Arrendamento`. Por omissão, Venda. |

---

## Passo 3 · O Agente e o Tópico

Cria um agente de empregado com um tópico **Carteira de Imóveis**, e liga-lhe a ação.

**Instruções do tópico** — é aqui que vive tudo o que estava no Prompt Template:

```
Ajudas consultores imobiliários da Terravista a decidir que imóveis mostrar a cada
cliente.

Usa SEMPRE a ação "Encontrar imóveis para um cliente". Nunca respondas de memória
sobre a carteira.

Nunca menciones um imóvel que a ação não tenha devolvido. Se a ação não devolver
nada, diz que não há nada em carteira que sirva — não sugiras alternativas
inventadas.

Lê as notas do cliente com atenção. Se o cliente disse que alguma coisa é condição
absoluta ou inegociável, um imóvel que não a cumpra NÃO deve ser recomendado, mesmo
que cumpra todos os outros critérios. Diz explicitamente porquê.

Não inventes características que a ação não tenha devolvido. Se não sabes se um
prédio tem elevador, escreve "por confirmar" em vez de assumir.

Quando a ação disser que há mais do que um cliente com esse nome, pergunta ao
utilizador qual deles antes de continuares.

Cada imóvel traz no fim da linha "foto: <URL>". Escreve esse URL como um link
markdown com o texto "ver fotografia". Copia o URL tal e qual — nunca o alteres
nem inventes um. Se um imóvel não trouxer "foto:", não inventes link nenhum.

Responde em português de Portugal, breve. O consultor lê isto entre duas chamadas.
Para cada imóvel diz numa frase porque encaixa neste cliente em concreto, e assinala
os que têm um senão.
```

---

## O que o chat mostra — e o que não mostra

| | Onde aparece |
|---|---|
| **Cartão clicável do imóvel** | No chat, se a ação tiver `Show in conversation` e `Output Rendering = Object` |
| **Caracterização** (tipologia, zona, área, preço, piso, elevador) | No texto da resposta, vinda do resumo do Apex |
| **Link para a fotografia** | No texto, como link markdown — o URL vai no resumo |
| **A imagem em si** | ❌ Nunca. O chat do Agentforce mostra texto e cartões, não imagens |

> A fotografia vê-se **clicando no cartão** e abrindo o registo do imóvel, onde o
> campo de fórmula `Foto__c` a mostra. Não há configuração que meta a imagem dentro
> da conversa — quem prometer isso ao júri fica a dever.

---

## Passo 4 · Testar — com disciplina

Cada mensagem ao agente gasta vários pedidos: o planeador decide, a ação corre, a
resposta é gerada. **Escreve as perguntas antes de abrires o chat.**

| # | Pergunta | O que tem de acontecer |
|---|---|---|
| 1 | *Que imóveis tenho para o Jorge Teixeira?* | Devolve o T3 da Foz **e avisa do elevador** |
| 2 | *E para a Sofia Almada?* | Não inventa vista mar. Pergunta ou marca "por confirmar" |
| 3 | *Que imóveis tenho para o Silva?* | Nome que não existe → diz que não encontrou |
| 4 | *Sugere imóveis para a Cláudia Marques* | Recomenda sem grandes reservas |

**Quando a resposta sair boa, captura de ecrã imediatamente.** Depois pára até ao ensaio.

---

## Riscos, por ordem de probabilidade

| Risco | O que fazer |
|---|---|
| **O planeador não chama a ação** e responde de cor | Rever a descrição da ação — é quase sempre isso |
| **Créditos acabam** antes da apresentação | Testar pouco e gravar. Ver o consumo em Setup |
| O modelo recomenda o imóvel do Jorge apesar do elevador | Subir de modelo — o GPT 5 Mini pode não apanhar a nuance |

O primeiro risco é o mais provável e o menos óbvio: um agente que ignora a ação
**parece** funcionar, porque responde qualquer coisa. Verifica sempre se os imóveis
que ele nomeia existem mesmo.
