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

Um Record Type novo **não fica visível sozinho** — nem para um System
Administrator. A visibilidade vive no perfil, e o `Admin.profile-meta.xml` lista
todos os Record Types da Opportunity um a um. Faltava lá o `Servicos`, e por isso
o `semear_produtos` não conseguia criar os negócios de serviços.

```
git pull
sf project deploy start -d force-app/main/default/profiles -o terravista
sf apex run -f scripts/apex/semear_leads.apex -o terravista
sf apex run -f scripts/apex/semear_produtos.apex -o terravista
```

O `semear_org` já correu e não precisa de repetir. Os outros dois são
re-executáveis: cada um apaga o que criou antes de recriar.

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
