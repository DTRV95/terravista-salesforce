# A fotografia dentro da conversa

O consultor pergunta *"que imóveis tenho para a Claudia?"* e vê **as fotografias**,
não uma lista de nomes.

---

## Porque é que nada mais chega

| Tentativa | Resultado |
|---|---|
| `Foto_URL__c` no output da acção | Texto ou link. Não é imagem |
| Link markdown no texto | Continua um link azul |
| `Output Rendering = Object` | Cartão do registo, clicável. **Sem imagem** |
| **Custom Lightning Type + LWC** | ✅ É este. É a única via suportada |

---

## As peças

```
force-app/main/default/
├── lwc/imoveisSugeridos/          ← desenha os cartões com <img>
│   ├── imoveisSugeridos.js
│   ├── imoveisSugeridos.html
│   ├── imoveisSugeridos.css
│   └── imoveisSugeridos.js-meta.xml   (target lightning__AgentforceOutput)
└── lightningTypes/imoveisSugeridos/
    ├── schema.json                 ← aponta para MatchImoveis.Resultado
    └── lightningDesktopGenAi/
        └── renderer.json           ← aponta para c/imoveisSugeridos
```

`lightningDesktopGenAi` é o canal do **Employee Agent em Lightning Experience**, que
é o nosso. Há outras pastas para o chat de serviço e para mobile — não precisamos.

**Mudança no Apex:** os campos de `MatchImoveis.Resultado` levam agora `@AuraEnabled`
além de `@InvocableVariable`. A camada que liga a acção ao tipo lê a classe à procura
de `@AuraEnabled`; sem isso o output nunca chega ao componente.

---

## O que está por confirmar

A documentação oficial esteve em baixo (503) quando isto foi escrito, dos dois lados.
Portanto **dois ficheiros são reconstrução, não cópia**:

| Ficheiro | Dúvida |
|---|---|
| `schema.json` | A forma exacta de referenciar a classe Apex |
| `renderer.json` | A chave que aponta para o LWC |

O LWC em si não tem dúvida nenhuma — é LWC normal.

**Antes de deitar tempo a isto**, abre a página quando o site voltar e compara:
`developer.salesforce.com/docs/ai/agentforce/guide/lightning-types-example-collection-renderer.html`

Se os dois ficheiros estiverem certos, o deploy passa e a acção passa a desenhar-se
com o componente. Se estiverem errados, o deploy falha — o que é o bom caso, porque
falha **antes** da apresentação e não durante.

---

## Fotografias: dentro do Salesforce, não no Unsplash

As fotos passaram a ser um **Static Resource** (`fotos_imoveis`), servido pela própria
org. Antes eram URLs do Unsplash.

> Um URL externo depende da rede da sala onde apresentas e de um serviço de terceiros
> continuar de pé. Já falhou duas vezes neste projeto. Um Static Resource não depende
> de nada — e a fotografia é a parte da demonstração que toda a gente vê.

Larga três ficheiros em `force-app/main/default/staticresources/fotos_imoveis/`:
`predio.jpg`, `moradia.jpg`, `interior.jpg`. Depois corre o `preencher_carteira.apex`,
que constrói os URLs a partir do domínio da org com `URL.getOrgDomainUrl()`.
