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

## Bloco atual — um deploy só

| # | O quê | Bloqueia |
|---|---|---|
| 1 | `CAMPAIGN_SOURCE` no report da receita por campanha | **Sim** |
| 2 | Direção e Marketing correm como utilizador fixo (limite de 3 dinâmicos) | **Sim** |
| 3 | Record Type `Serviços` + business process + 3 fases | **Sim** — o `semear_produtos` precisa |
| 4 | `Product2.Categoria__c` + FLS | **Sim** |
| 5 | Guardas nas fórmulas de comissão contra o Record Type dos serviços | **Sim** |
| 6 | `Lead.Data_Entrada__c` + as duas fórmulas de latência a medir a partir dela | **Sim** — é o que desbloqueia os gráficos vazios |

```
git pull
sf project deploy start -d force-app/main/default/objects -d force-app/main/default/standardValueSets -d force-app/main/default/permissionsets -d force-app/main/default/reports -d force-app/main/default/dashboards -o terravista
sf apex run -f scripts/apex/semear_org.apex -o terravista
sf apex run -f scripts/apex/semear_produtos.apex -o terravista
```

O `SetAuditFields` **saiu** do permission set. Já não é preciso: a latência deixou
de medir a partir do `CreatedDate`.

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
