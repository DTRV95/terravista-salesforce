# Como fazer deploys — guia de referência

Guia de consulta. A lista do que está a aguardar deploy está no `PENDENTE-DEPLOY.md`.

---

## Antes de começar

Abre o terminal **na pasta do projeto**:

```
cd $HOME\Downloads\terravista-salesforce
```

Confirma que estás ligado à org certa:

```
sf org list
```

Deve aparecer `terravista` com um `(D)` ao lado — é a org por omissão. Se não aparecer,
volta a ligar com `sf org login web -a terravista -s`.

---

## O ciclo normal — quatro comandos

### 1 · Trazer o que eu escrevi

```
git pull
```

Se disser *"Already up to date"*, não há nada de novo — não precisas de fazer deploy.

### 2 · Verificar antes de enviar

```
python scripts/verificar_metadados.py
```

Apanha em segundos os três erros que já nos custaram ciclos de deploy: descrições acima de
255 caracteres, API names com acentos, e permissões de campo declaradas em campos obrigatórios.

Se disser **"Sem problemas conhecidos"**, avança. Se apontar alguma coisa, **para e diz-me** —
não tentes corrigir à mão, senão o repositório e a org ficam a divergir.

### 3 · Ensaiar (opcional, mas vale a pena em deploys grandes)

```
sf project deploy start --dry-run -o terravista
```

Valida tudo contra a org **sem gravar nada**. É a rede de segurança: se falhar aqui, não
aconteceu nada. Usa-o sempre que o bloco tenha Flows ou alterações a campos obrigatórios.

### 4 · Enviar

```
sf project deploy start -o terravista
```

---

## Como ler o resultado

**Se correr bem**, aparece `Status: Succeeded` e a lista de componentes com `Created` ou `Changed`.

**Se falhar**, aparece uma tabela com o ficheiro, a linha e a mensagem. Duas coisas a saber:

> **O deploy é uma transação única.** Se um único componente falhar, **nada entra na org** —
> nem os componentes que estavam corretos. Não há estados a meio. Isso é bom: corriges e
> repetes o comando tal e qual, sem teres de perceber o que já tinha passado.

**O que fazer:** copia a mensagem de erro inteira e cola-ma. Não alteres ficheiros à mão.
O repositório é a fonte de verdade — se editares na org ou no editor, na próxima vez que eu
escrever por cima perde-se o teu trabalho.

---

## Carregar dados de demonstração

```
sf apex run -f scripts/apex/carregar_dados_demo.apex -o terravista
```

**Corre sempre depois do deploy**, nunca antes: os dados usam campos e valores que têm de
existir primeiro.

É re-executável. Apaga a carga anterior (tudo o que tem a marca `[DEMO]`) e cria tudo de novo.
Se estragares dados a testar, corres outra vez e volta ao estado limpo. Não toca nas vendas
reais do Aurora nem nos contratos.

---

## O que fazer na interface e não por deploy

Nem tudo se constrói em metadata. Estas coisas fazem-se no Setup e depois **trazem-se** para o
repositório:

| O quê | Comando para trazer |
|---|---|
| Reports e Dashboards | `sf project retrieve start -m Report -m Dashboard -o terravista` |
| Page Layouts | `sf project retrieve start -m Layout -o terravista` |
| List Views | `sf project retrieve start -m ListView -o terravista` |

Depois de trazer, guarda no git:

```
git add -A
git commit -m "retrieve: dashboards da Rita"
git push
```

> **A regra:** o que se **define** (campos, regras, fórmulas, Flows) escreve-se em metadata e
> faz-se deploy. O que se **compõe** visualmente (layouts, listas, dashboards) constrói-se na
> interface e faz-se retrieve. Tentar o contrário custa mais tempo do que poupa.

---

## Se alguma coisa correr mesmo mal

**Desfazer o último commit local** (antes de push):
```
git reset --hard HEAD~1
```

**Ver o que mudou desde o último deploy:**
```
git log --oneline -10
```

**Voltar a alinhar o repositório com o que está no GitHub:**
```
git fetch origin
git reset --hard origin/main
```

Este último **apaga alterações locais não guardadas**. Usa-o só quando quiseres deitar fora o
que tens em cima da mesa e recomeçar do que está no GitHub.
