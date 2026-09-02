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
| 1 | `Tipologia__c = 'T4'` → `'T4+'` no teste novo | **Sim** — o teste falhava |
| 2 | Procura por nome deixa de tropeçar em acentos (+1 teste) | **Sim** — *Cláudia* não encontrava a `Claudia Marques`, e é assim que um português escreve |

**Um deploy.** Depois:

```
sf apex run test --class-names MatchImoveisTest --result-format human -o terravista
```

Devem passar **10**.

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
