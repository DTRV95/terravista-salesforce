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
| 1 | Campo de fórmula `Foto__c` — mostra a imagem com `IMAGE()` | **Sim** — um campo Url só mostra um link azul, nunca a fotografia |
| 2 | `Elevador__c` e `Foto_URL__c` postos no layout do Imóvel | **Sim** — os campos existiam e estavam preenchidos, mas fora do ecrã |
| 3 | FLS de `Foto__c` (só leitura — é fórmula) | **Sim** — sem FLS o campo comporta-se como se não existisse |

**Um deploy.** Já verificado na org: `Foto__c` ainda **não** existe lá, e os dados já
lá estão (44 dos 45 imóveis com foto; o terreno não tem, de propósito).

Depois do deploy, abre um imóvel do tipo `Fracao`. Se aparecer o ícone de imagem
partida em vez da fotografia, o bloqueio é a CSP do Lightning:
**Setup → CSP Trusted Sites → New Trusted Site**, URL `https://images.unsplash.com`,
com `allow_img_src` ligado.

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
