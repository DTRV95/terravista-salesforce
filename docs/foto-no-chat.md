# A fotografia dentro da conversa

O objetivo: o consultor pergunta *"que imóveis tenho para o Jorge?"* e vê **as
fotografias**, não uma lista de nomes.

---

## O que é preciso, e o que não chega

| Tentativa | Resultado |
|---|---|
| Campo `Foto_URL__c` no output da ação | Aparece como texto ou link. Não é imagem |
| Link markdown no texto da resposta | Continua a ser um link azul |
| `Output Rendering = Object` | Cartão do registo, clicável. **Sem imagem** |
| **Custom Lightning Type com `renderer`** | ✅ É este |

## Como funciona

Um *custom Lightning type* deixa substituir o UI por omissão do Agentforce por um
Lightning Web Component nosso. Para output, o LWC usa o target
`lightning__AgentforceOutput`, e é aí que se pode desenhar um `<img>` com o
`Foto_URL__c` de cada imóvel.

**Restrição que nos serve:** só se pode fazer este override em ações cujo input ou
output seja uma **classe Apex**. `MatchImoveis.Resultado` é exatamente isso — foi
sorte, não desenho, mas é o que torna isto possível sem reescrever a ação.

Peças envolvidas:

1. Um bundle `lightningTypes` com o **schema** do output e um **`renderer.json`** a
   apontar para o LWC
2. Um **LWC** com `lightning__AgentforceOutput` nos targets, que recebe os imóveis e
   desenha o cartão com fotografia
3. A ação Apex ligada a esse tipo

---

## Estado

**Por fazer.** A estrutura exata dos ficheiros tem de sair da documentação oficial —
não se inventa metadata a partir de memória, que é como se perde uma tarde a
depurar um deploy que nunca podia funcionar.

Página a consultar:
`developer.salesforce.com/docs/ai/agentforce/guide/lightning-types-example-collection-renderer.html`

---

## Vale a pena? — decisão a tomar

| | |
|---|---|
| **Recomendação** | Fazer **depois** dos dashboards, não antes |
| **Alternativa** | Ficar pelo cartão clicável, que já funciona hoje |
| **Vantagem** | É o único ponto da demonstração que nenhum colega vai ter. LWC + Agentforce + Apex numa peça só é exatamente o que se mostra a quem contrata |
| **Desvantagem** | É a única parte do projeto que exige LWC. Não é configuração, e não há caminho pelo Setup |
| **Risco** | Alto em tempo, baixo em consequência: se falhar, o cartão clicável continua lá e a demonstração não parte |

Os dashboards são o requisito do enunciado; isto é o extra. Um extra bonito com o
requisito por fazer é o pior sítio onde estar a três semanas da apresentação.
