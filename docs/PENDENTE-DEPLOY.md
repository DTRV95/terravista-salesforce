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
| 1 | `descrever()` passa a levar o URL da fotografia no resumo (+1 teste) | **Sim** — sem isto o modelo não tem link nenhum para dar, e testar o agente gasta créditos por nada |

**Um deploy.** Depois:

```
sf apex run test --class-names MatchImoveisTest --result-format human -o terravista
```

Devem passar **9**.

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
