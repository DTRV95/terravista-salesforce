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

## Bloco atual

| # | O quê | Bloqueia |
|---|---|---|
| 1 | Record Type `Serviços` + business process + 3 fases novas | **Sim** — sem isto o `semear_produtos.apex` não corre |
| 2 | `Product2.Categoria__c` + FLS | **Sim** — o script preenche-o |
| 3 | Guardas nas fórmulas de comissão contra o Record Type novo | **Sim** — sem elas os serviços entram nos números de comissões |

```
sf project deploy start -d force-app/main/default/objects -d force-app/main/default/standardValueSets -d force-app/main/default/permissionsets -o terravista
sf apex run -f scripts/apex/semear_produtos.apex -o terravista
```

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
