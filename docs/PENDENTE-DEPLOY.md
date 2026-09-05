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

## Bloco atual — um deploy, três scripts

```
git pull
sf project deploy start -d force-app/main/default/objects -d force-app/main/default/standardValueSets -d force-app/main/default/permissionsets -d force-app/main/default/reports -d force-app/main/default/dashboards -o terravista
sf apex run -f scripts/apex/semear_org.apex -o terravista
sf apex run -f scripts/apex/semear_leads.apex -o terravista
sf apex run -f scripts/apex/semear_produtos.apex -o terravista
```

**A ordem dos três scripts importa.** O `semear_org` apaga tudo e cria empresas,
pessoas, contratos, imóveis e negócios. O `semear_leads` liga-se às campanhas que o
primeiro criou. O `semear_produtos` precisa dos imóveis e dos clientes.

> **Um deploy é atómico.** Se um só componente falhar, *nada* do lote entra na org —
> mesmo que o relatório mostre 145 de 146 como criados. Esses estados dizem o que
> teria acontecido, não o que ficou. Já nos enganou uma vez.

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
