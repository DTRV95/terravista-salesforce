# Pendente de deploy

Acumula-se aqui. **Um deploy por sessão de trabalho**, não um por alteração.
Só se abre exceção quando uma alteração bloqueia o trabalho seguinte — e nesse caso está marcada.

```
git pull
python scripts/verificar_metadados.py
sf project deploy start -o terravista
```

---

## Bloco atual — 29/08/2026 *(2.ª tentativa)*

> A 1.ª tentativa falhou num erro só. Como o deploy é transacional (`rollbackOnError`), **nada
> entrou na org** — nem a correção da comissão, nem o valor `Arrendado`, nem o Flow 1. Repete-se
> o comando tal e qual.

| # | Alteração | Ficheiro | Testar depois |
|---|---|---|---|
| 1 | `Estado_Comercial__c` ganha o valor **Arrendado** | `objects/Imovel__c/fields/Estado_Comercial__c` | O valor aparece no picklist do Imóvel |
| 2 | **Correção crítica** na regra `Comissao_entre_0_e_10` | `objects/Contract/validationRules/` | Meter 45 na comissão de um contrato → **tem de dar erro** |
| 3 | Flow `Sincronizar Estado do Imovel` | `flows/` | Ver testes de aceitação abaixo |
| 4 | Flow `Angariacao Ganha Cria Contrato` | `flows/` | Ver testes de aceitação abaixo |

O nº 1 tem de ir **antes** dos Flows — o Flow 1 refere o valor `Arrendado` e a validação de deploy falha se ele não existir. Vão todos no mesmo comando, portanto não é problema: o deploy é uma transação única.

### Porque é que o nº 2 é crítico

A regra comparava `Comissao__c > 10`. Num campo **Percent**, o valor em contexto de fórmula é o
da API a dividir por 100 — uma comissão de 4,5% vale `0,045` na fórmula. A regra só disparava
acima de **1000%**. Estava documentada como a mais importante das 17 e não apanhava nada.

Confirmado por dois caminhos:
- `Percentagem_Comercializada__c` calcula `12/32 = 0,375` e a API devolve `37,5`
- a fórmula da comissão com `/100` dava 167,40 € em vez de 16.740 €

O limite passou a `0.10`. A mensagem de erro não muda.

---

## Depois do deploy — carregar os dados de demonstração

```
sf apex run -f scripts/apex/carregar_dados_demo.apex -o terravista
```

Cria o pipeline aberto que faltava: 9 negócios em 4 Record Types, 10 atividades,
3 leads por contactar, 2 contratos novos e 2 imóveis (um de arrendamento, um terreno).

**É re-executável.** Tudo o que cria leva a marca `[DEMO]` na descrição e a primeira secção
apaga a carga anterior antes de criar a nova. Não toca nas 12 vendas do Aurora nem nos
contratos reais. Se estragares dados a testar, corres outra vez e volta ao estado limpo.

Correr **depois** do deploy: o negócio da Marta Rios usa o estado `Arrendado`, e o teste
do Flow 1 assenta neste pipeline.

---

## Testes de aceitação dos Flows

### Flow 1 · Sincronizar Estado do Imóvel
1. Negócio de habitação → **CPCV Assinado** → imóvel fica *Reservado*
2. O mesmo → **Escritura Realizada** → imóvel fica *Vendido*
3. Negócio de **Angariação** → **Contrato Assinado** → o imóvel **não muda**
4. Negócio reservado → **Perdido** → imóvel volta a *Disponível*
5. Negócio sobre imóvel já **Vendido** → **Perdido** → imóvel **continua Vendido**

O nº 3 e o nº 5 são os que interessam. São os dois casos em que uma automação ingénua
destruía dados: o nº 3 marcava como transacionado um imóvel que ainda nem entrou na carteira,
e o nº 5 devolvia à carteira um imóvel já vendido a outra pessoa, corrompendo o Roll-Up.

### Flow 2 · Angariação Ganha Cria Contrato
1. Angariação → **Contrato Assinado** → aparece um Contrato em *Draft* na conta certa
2. O `Regime__c` corresponde à linha de negócio (B2B → Comercialização de Empreendimento)
3. Existe uma Task de prioridade Alta atribuída ao dono do negócio
4. A Opportunity mostra o contrato no campo standard **Contract**
5. Gravar outra vez a Opportunity já ganha → **não cria um segundo contrato**

O nº 5 é garantido pelo `ISCHANGED(StageName)` nas entry conditions. É também o que impede o
Flow 2 de se auto-disparar quando o seu próprio último passo atualiza a Opportunity.

---

## Riscos conhecidos deste deploy

| Risco | Se acontecer |
|---|---|
| `ISNEW()` recusado nas entry conditions do Flow 1 | Tirar `OR(ISNEW(), ...)` e deixar só `ISCHANGED({!$Record.StageName})`. Perde-se apenas o caso raro de um negócio criado já em CPCV |
| `$Record.RecordType.DeveloperName` recusado na fórmula de entrada | Substituir por um elemento Decision logo a seguir ao Start, com a mesma condição |
| `Draft` recusado no `Status` do Contrato | Confirmar o valor exato do picklist standard ContractStatus na org |
| ~~Comparar um picklist com `=` numa fórmula de Flow~~ | **Aconteceu.** `{!$Record.StageName} = "Contrato Assinado"` foi recusado no deploy. Corrigido com `ISPICKVAL()` nos dois sítios do Flow 2 |

Nenhum destes parte dados — falham no deploy, que é onde se quer que falhem.
