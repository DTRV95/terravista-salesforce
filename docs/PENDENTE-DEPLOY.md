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

## Bloco atual — layout de Person Account

**Bloqueia o passo seguinte?** Sim. A ficha do cliente particular mostra os
campos da construtora, que estao sempre vazios. Enquanto assim for, qualquer
teste ao agente parece errado mesmo com o codigo certo.

Feito em 14/09 (etiquetas + matching em Leads, 15/15 testes verdes):
`CustomField:Account.Procura_Zonas__c`, `CustomField:Account.Orcamento_Max__c`,
`ApexClass:MatchImoveis`, `ApexClass:MatchImoveisTest`.

Falta:

```
git pull
python scripts/verificar_metadados.py
sf project deploy start -m "Layout:PersonAccount-Person Account Layout" -o terravista
```

**Se falhar**, o mais provavel e um destes tres, por esta ordem:

1. Um token de related list recusado. Apagar os tres blocos `<relatedLists>`
   e repetir: as seccoes de campos sao o que interessa.
2. `PersonEmail` ou `PersonMobilePhone` nao disponiveis nesta org. Apagar
   esses dois `<layoutItems>`.
3. A plataforma recusar alterar layouts de Person Account por metadata. Nesse
   caso o ficheiro serve na mesma: diz exactamente que campos por em que
   seccao, e faz-se o mesmo a mao em Setup em tres minutos.

Um deploy e atomico: se falhar, nada entrou e nao ficaste a meio.

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
