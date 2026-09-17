# Pendente de deploy

**A regra:** só se faz deploy quando alguma coisa **bloqueia o passo seguinte**.
Tudo o resto acumula aqui.

Se este ficheiro disser "nada pendente", não faças deploy nenhum — mesmo que tenha
havido commits. Documentação, scripts e testes não precisam de ir para a org.

```
git pull
python scripts/verificar_metadados.py
sf project deploy start -o terravista
```

---

## Bloco atual — approval process e campo da Lead

Duas coisas que estao no repositorio e NAO estao na org. Confirmado por SOQL em
17/09: ProcessDefinition devolve zero registos.

E o preco dos deploys dirigidos, que fazemos para nao desfazer os ajustes
manuais na org (list views afixadas, icone do tab dos Imoveis). Nada entra
sozinho: um ficheiro commitado nao esta na org ate um deploy o levar la.

```
git pull
python scripts/verificar_metadados.py

sf project deploy start -m "Workflow:Contract" \
                        -m "ApprovalProcess:Contract.Comissao_Abaixo_do_Minimo" -o terravista

sf project deploy start -m "CustomField:Lead.Plano_de_Procura__c" \
                        -m "Layout:Lead-Lead Compra" \
                        -m "Layout:Lead-Lead Arrendamento" -o terravista
```

O Workflow vai no mesmo deploy que o approval process, nao a seguir: o approval
referencia tres field updates que vivem la (Comissao_Aprovada, Comissao_Pendente,
Comissao_Rejeitada). Separados, o primeiro deploy referencia accoes que a org
ainda nao conhece e falha inteiro.

Dependencias ja verificadas na org: Estado_Aprovacao__c existe no Contract, o
aprovador terravista.david@agentforce.com existe e esta activo, e os campos da
pagina de aprovacao existem todos.

**A seguir ao deploy:** abrir um contrato e procurar o botao Submit for
Approval. Se nao aparecer, falta a related list Approval History no layout do
Contrato - hoje so tem Imovel__c.Contrato__c e RelatedActivityList. Acrescenta-se
em Setup e faz-se retrieve; o token de metadata dessa related list nao esta
provado neste projeto.

**Antes da apresentacao:** correr uma verificacao de ponta a ponta do que esta
no repositorio e nao esta na org. Ja aconteceu duas vezes no mesmo dia - o
Plano_de_Procura__c e este approval process. Descobrir isto a meio da
demonstracao custa mais do que a meia hora que a verificacao leva.

---

## A ordem completa dos scripts de dados

**Quatro, não três.** O `semear_org` apaga e recria os imóveis; quem se esquecer do
`preencher_carteira` fica com o **Elevador vazio nos 45**, e o caso do Jorge Teixeira
— o ponto alto da demonstração — deixa de funcionar **em silêncio**.

```
1. sf apex run -f scripts/apex/semear_org.apex        -o terravista
2. sf apex run -f scripts/apex/semear_leads.apex      -o terravista
3. sf apex run -f scripts/apex/preencher_carteira.apex -o terravista
4. sf apex run -f scripts/apex/semear_produtos.apex   -o terravista
```

O `semear_org` passa a escrever esta lista no log ao terminar. Estava só na
documentação, e foi exactamente por isso que falhou.

---

## O que NÃO precisa de deploy

- `docs/` — guiões, especificações, este ficheiro
- `scripts/apex/` — correm com `sf apex run`, não vão para a org
- `scripts/verificar_metadados.py` — corre local

---

## Como vamos trabalhar daqui para a frente

| Situação | O que digo |
|---|---|
| Escrevi metadata que bloqueia o teu próximo passo | *"Precisa de deploy, e porquê"* |
| Escrevi documentação ou scripts | *"Acumulado. Não faças deploy"* |
| Vários blocos acumulados | *"Agora vale a pena: são N coisas"* |

Se eu pedir um deploy sem dizer o que bloqueia, **pergunta porquê antes de correres**.
