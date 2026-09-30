# Justificacoes das decisoes de configuracao

As descricoes na org foram encurtadas para leitura rapida. O racional completo
de cada decisao fica aqui, para consulta e para a apresentacao.

## applications/Terravista.app-meta.xml

- **Agora:** Agência imobiliária do Grande Porto: habitação, arrendamento e terrenos.
- **Racional:** Agência imobiliária do Grande Porto. Mediação a particulares e a empresas: habitação, arrendamento e terrenos.

## approvalProcesses/Contract.Comissao_Abaixo_do_Minimo.approvalProcess-meta.xml

- **Agora:** A direção aprova. Um único passo.
- **Racional:** A direção decide. Um passo só: dois passos numa agência de dois consultores seria burocracia a fingir de governo.

- **Agora:** Comissão abaixo de 4% exige aprovação da direção.
- **Racional:** Uma comissão abaixo de 4% precisa de segunda assinatura. É o único sítio onde uma pessoa sozinha pode dar dinheiro da empresa: o Comissao__c alimenta a comissão de TODAS as vendas do contrato.

## flows/Angariacao_Ganha_Cria_Contrato.flow-meta.xml

- **Agora:** Angariacao ganha: cria o contrato de mediacao em rascunho e uma tarefa ao agente.
- **Racional:** Quando uma angariacao chega a Contrato Assinado, cria o CMI em rascunho e uma Task para o agente completar o que so se sabe no terreno. Nao cria o Imovel: nessa altura ainda ninguem mediu nem avaliou.

## flows/Carimbar_Primeiro_Contacto.flow-meta.xml

- **Agora:** Carimba a Data do 1o Contacto quando uma chamada ao lead e concluida.
- **Racional:** Quando uma chamada e dada por concluida num lead, carimba a Data do 1o Contacto. E este Flow que alimenta a metrica de latencia: sem ele o campo so existia porque o script de dados o escrevia, e numa org real ficaria sempre vazio.

## flows/Carimbar_Visita.flow-meta.xml

- **Agora:** Carimba a data da visita no lead e no negocio quando se agenda um Evento.
- **Racional:** Quando se agenda um Evento, carimba a data da visita no lead e no negocio. Sem isto nenhuma validation rule consegue exigir uma visita, porque uma formula nao ve Eventos.

## flows/Sincronizar_Estado_do_Imovel.flow-meta.xml

- **Agora:** Mantem o Estado Comercial do imovel em sincronia com a fase do negocio.
- **Racional:** Mantem Imovel__c.Estado_Comercial__c em sincronia com a fase do negocio. Exclui o Record Type Angariacao, onde Contrato Assinado significa CMI assinado e nao imovel transacionado.

## objects/Account/fields/Candidatos_Imoveis__c.field-meta.xml

- **Agora:** Imoveis encontrados por SOQL para este cliente, antes da geracao por AI.
- **Racional:** Lista de imoveis que o SOQL encontrou para este cliente, escrita pelo Flow antes de chamar o Prompt Template. Fica visivel de proposito: e a prova de que o modelo so viu registos reais.

## objects/Account/fields/Notas_Criterios__c.field-meta.xml

- **Agora:** Critérios de procura desta construtora, em texto livre.
- **Racional:** Responde diretamente a PP9: o conhecimento sobre o que cada construtora procura deixa de estar apenas na cabeca dos agentes.

## objects/Account/fields/Orcamento_Max__c.field-meta.xml

- **Agora:** Tecto de investimento da construtora num terreno.
- **Racional:** Tecto de investimento desta construtora num terreno. NAO confundir com o campo homonimo do Contact (Orcamento_Max__pc), que e o orcamento do cliente particular. As etiquetas eram iguais e trocaram-se no layout.

## objects/Account/fields/Procura_ABC_Minima_m2__c.field-meta.xml

- **Agora:** Area bruta de construcao minima exigida pela construtora.
- **Racional:** Area bruta de construcao minima abaixo da qual a construtora nao avanca.

## objects/Account/fields/Procura_Zonas__c.field-meta.xml

- **Agora:** Zonas onde esta construtora procura terreno.
- **Racional:** Zonas onde esta construtora procura terreno. NAO confundir com o campo homonimo do Contact (Procura_Zonas__pc), que serve o cliente particular. Os dois tinham a mesma etiqueta e trocaram-se no layout de Person Account.

## objects/Account/fields/Sugestoes_Imoveis__c.field-meta.xml

- **Agora:** Sugestoes de imoveis geradas por AI a partir dos registos encontrados por SOQL.
- **Racional:** Sugestoes geradas para este cliente. O conteudo vem de um Prompt Template, mas os imoveis vem sempre de SOQL - o modelo ordena e justifica, nunca inventa registos.

## objects/Account/recordTypes/Empresa.recordType-meta.xml

- **Agora:** Construtoras, promotores e empresas compradoras.
- **Racional:** Conta empresarial: construtoras, promotores, sociedades proprietarias e empresas compradoras. Existe tambem porque ter pelo menos um Record Type em Account e pre-requisito para ativar Person Accounts.

## objects/Activity/fields/Resultado_Visita__c.field-meta.xml

- **Agora:** Resultado da visita. Preencher depois do Evento.
- **Racional:** Preencher apos uma visita (Event). O motivo da rejeicao vale mais que o que foi visto: e o que alimenta o matching por AI. Campos em Activity aparecem em Task e Event.

## objects/Case/businessProcesses/Pos_Escritura.businessProcess-meta.xml

- **Agora:** Estados de um pedido de pos-escritura.
- **Racional:** Os estados por que passa um pedido de pos-escritura. Um record type de Case EXIGE um Business Process: e ele que diz que valores do Status ficam disponiveis.

## objects/Case/fields/Imovel__c.field-meta.xml

- **Agora:** Imóvel a que o pedido diz respeito.
- **Racional:** O imóvel a que o pedido diz respeito. Sem ele, um pedido de pós-escritura sobre "o apartamento" não tem âncora nenhuma no modelo e não se consegue reportar por imóvel.

## objects/Case/recordTypes/Pos_Escritura.recordType-meta.xml

- **Agora:** Pedidos após o fecho do negócio: documentação, chaves, certificados, condomínio.
- **Racional:** Pedidos que chegam depois de o negócio fechar: documentação, chaves, certificado energético, condomínio. Um pedido de informação sobre um imóvel à venda é um Lead, não um Case.

## objects/Contact/fields/Financiamento__c.field-meta.xml

- **Agora:** Capacidade de financiamento do cliente. Vem do lead na conversao.
- **Racional:** Estado atual da capacidade de financiamento. Recebe o valor do Lead na conversao. Fonte de verdade unica: a Opportunity le daqui pela relacao, nao tem copia.

## objects/Contact/fields/Notas_Preferencias__c.field-meta.xml

- **Agora:** Preferencias em texto livre. Materia-prima do matching por AI.
- **Racional:** Campo NAO estruturado. E a materia-prima do matching por AI: o que os filtros nao capturam (rejeitou dois T2 por causa do andar, quer vista mas nao para a rua, precisa de garagem para dois carros).

## objects/Contact/fields/Procura_Zonas__c.field-meta.xml

- **Agora:** Zonas de interesse, separadas por virgula. Ex.: Matosinhos, Foz.
- **Racional:** Zonas de interesse, separadas por virgula. Ex: Matosinhos, Foz, Campanha.

## objects/Contract/fields/Data_Envio_Contrato__c.field-meta.xml

- **Agora:** Data de envio do contrato ao proprietário para assinatura.
- **Racional:** Quando o contrato foi enviado ao proprietário para assinar. O standard tem CustomerSignedDate mas não tem "enviado" — e é a diferença entre os dois que diz quem está a demorar.

## objects/Contract/fields/Estado_Aprovacao__c.field-meta.xml

- **Agora:** Estado do pedido de aprovação da comissão.
- **Racional:** Estado do pedido de aprovação da comissão. Sem este campo, um contrato à espera de decisão é indistinguível de um já aprovado — a aprovação existiria no histórico e não no ecrã.

## objects/Contract/fields/Exclusivo__c.field-meta.xml

- **Agora:** Contrato de mediação em regime de exclusividade.
- **Racional:** Regime de exclusividade do contrato de mediação (CMI em regime de exclusividade).

## objects/Contract/fields/Nome_Empreendimento__c.field-meta.xml

- **Agora:** Nome do empreendimento. Vazio em mediação a particular.
- **Racional:** Preenchido apenas em contratos de comercialização de empreendimento (ex.: "Edifício Aurora"). Vazio em mediação a particular.

## objects/Contract/fields/Percentagem_Comercializada__c.field-meta.xml

- **Agora:** Percentagem de frações do empreendimento já vendidas.
- **Racional:** Ritmo de comercialização do empreendimento, sem qualquer automação. Protegido contra divisão por zero.

## objects/Contract/fields/Regime__c.field-meta.xml

- **Agora:** Regime de mediacao: particular ou empreendimento.
- **Racional:** Distingue os dois regimes de mediacao de forma explicita. Antes inferia-se de Nome_Empreendimento__c estar preenchido, o que e fragil. Campo e nao Record Type porque so muda a escala, nao o que se pergunta.

## objects/Contract/validationRules/Comissao_entre_0_e_10.validationRule-meta.xml

- **Agora:** Protege a formula da comissao de erros de introducao (45 em vez de 4,5).
- **Racional:** Defende a formula Comissao_Terravista__c. Uma comissao mal introduzida - 45 em vez de 4,5 - multiplicava a faturacao por dez sem dar erro. O limite e 0.10 e nao 10: num campo Percent, o valor em contexto de formula e o da API dividido por 100.

## objects/Imovel_Interesse__c/Imovel_Interesse__c.object-meta.xml

- **Agora:** Imóvel mostrado a um cliente dentro de um negócio. Uma linha por imóvel.
- **Racional:** Um imóvel mostrado a um cliente, dentro de um negócio. Existe porque Opportunity.Imovel__c é um lookup único: guarda onde o negócio aterrou e apaga o que se mostrou pelo caminho. Uma linha por imóvel; as visitas são os Eventos ligados a ela.

## objects/Imovel_Interesse__c/fields/Data_Proposta__c.field-meta.xml

- **Agora:** Data em que a proposta foi feita.
- **Racional:** Quando a proposta foi feita. Sem ela não se sabe quem chegou primeiro, e no dia em que houver duas propostas é a primeira pergunta que o proprietário faz.

## objects/Imovel_Interesse__c/fields/Estado__c.field-meta.xml

- **Agora:** Estado deste imóvel para este cliente.
- **Racional:** Onde é que este imóvel ficou, para este cliente. É a verdade única da linha: um imóvel visitado três vezes e recusado no fim está Recusado, não Visitado três vezes.

## objects/Imovel_Interesse__c/fields/Imovel__c.field-meta.xml

- **Agora:** Imóvel mostrado. Lookup: apagar o imóvel não apaga o histórico.
- **Racional:** O imóvel mostrado. Lookup e não Master-Detail: o imóvel não é dono deste registo, e apagar um imóvel não pode apagar o histórico do que foi mostrado a quem.

## objects/Imovel_Interesse__c/fields/Motivo_Recusa__c.field-meta.xml

- **Agora:** Razão da recusa do cliente, em texto livre.
- **Racional:** Porque é que o cliente disse que não. Texto e não picklist: a razão real raramente cabe numa lista, e é ela que diz se o imóvel está mal posicionado no preço ou se foi só este cliente.

## objects/Imovel_Interesse__c/fields/Oportunidade__c.field-meta.xml

- **Agora:** Negócio a que este interesse pertence. Master-Detail para o roll-up.
- **Racional:** O negócio a que este interesse pertence. Master-Detail para permitir o Roll-Up Summary nativo na Opportunity e para as linhas morrerem com o negócio — um interesse sem negócio não quer dizer nada.

## objects/Imovel_Interesse__c/fields/Valor_Proposta__c.field-meta.xml

- **Agora:** Valor oferecido por este cliente para este imóvel.
- **Racional:** Quanto este cliente ofereceu por este imóvel. Vive aqui e não na Opportunity porque duas propostas concorrentes sobre o mesmo imóvel só se vêem lado a lado se estiverem na junção.

## objects/Imovel__c/Imovel__c.object-meta.xml

- **Agora:** Imóvel angariado pela Terravista. Serve particulares e empreendimentos.
- **Racional:** Imóvel angariado pela Terravista. Serve as duas linhas de negócio: um imóvel de particular (B2C) e uma fração de empreendimento (B2B) são o mesmo conceito — o que os distingue é o Contrato de Mediação a que pertencem.

## objects/Imovel__c/fields/Area_Bruta_Construcao_m2__c.field-meta.xml

- **Agora:** Area bruta de construcao permitida pelo PDM. So em terrenos.
- **Racional:** Area bruta de construcao permitida pelo PDM. So relevante em terrenos: e o que determina o valor para uma construtora.

## objects/Imovel__c/fields/Contrato__c.field-meta.xml

- **Agora:** Contrato de mediação ao abrigo do qual o imóvel é comercializado.
- **Racional:** Contrato de Mediação Imobiliária ao abrigo do qual este imóvel é comercializado. Master-Detail para permitir Roll-Up Summary nativo no Contract.

## objects/Imovel__c/fields/Data_Disponibilizacao__c.field-meta.xml

- **Agora:** Data em que o imovel ficou disponivel para venda.
- **Racional:** Momento em que o imovel ficou disponivel para venda. Base da metrica "tempo ate a primeira proposta", meta de 3 dias uteis.

## objects/Imovel__c/fields/Dias_Disponivel__c.field-meta.xml

- **Agora:** Dias que o imovel esta em carteira sem vender.
- **Racional:** Ha quantos dias este imovel esta parado. Um imovel que nao sai passados 60 dias esta mal posicionado no preco - e o sinal para renegociar com o proprietario antes de queimar a relacao.

## objects/Imovel__c/fields/Elevador__c.field-meta.xml

- **Agora:** Indica se o edificio tem elevador.
- **Racional:** Existe para o modelo nao ter de adivinhar. Um modelo preenche sempre uma lacuna com o que soa plausivel: sem este campo, chegou a afirmar que um predio tinha elevador porque o cliente queria um. A correcao nao e endurecer o prompt, e nao haver lacuna.

## objects/Imovel__c/fields/Estado_Comercial__c.field-meta.xml

- **Agora:** Estado comercial do imóvel. Sincronizado por Flow com o negócio.
- **Racional:** Fonte de verdade do estado do imóvel. Alimenta os Roll-Up Summary no Contract. Deve ser mantido em sincronia com a Opportunity de venda por Flow, nunca editado à mão quando existe Opportunity associada.

## objects/Imovel__c/fields/Finalidade__c.field-meta.xml

- **Agora:** Venda ou arrendamento. Distingue a leitura do preco.
- **Racional:** Sem este campo o Preco e ambiguo: 620.000 numa moradia a venda e 850 num T1 para arrendar. Qualquer soma ou media misturava os dois. Todo o relatorio de valores filtra por aqui.

## objects/Imovel__c/fields/Foto_URL__c.field-meta.xml

- **Agora:** URL da fotografia do imovel.
- **Racional:** Fotografia do imovel. Preenchida apenas nos imoveis usados na demonstracao: um link partido a frente do juri custa mais do que a foto vale.

## objects/Imovel__c/fields/Foto__c.field-meta.xml

- **Agora:** Mostra a fotografia do imovel no registo.
- **Racional:** Mostra a fotografia no registo. Um campo Url so mostra um link azul - para se ver a imagem e preciso uma formula com IMAGE(). O IF evita a imagem partida no terreno, que nao tem foto.

## objects/Imovel__c/fields/Localizacao__c.field-meta.xml

- **Agora:** Freguesia e concelho. Criterio central de matching.
- **Racional:** Freguesia e concelho. Criterio central de matching com o perfil de procura.

## objects/Imovel__c/fields/Tipo_Solo__c.field-meta.xml

- **Agora:** Classificacao do solo em PDM. Aplica-se a terrenos.
- **Racional:** Classificacao do solo em PDM. Aplica-se quando Tipo_Imovel__c = Terreno.

## objects/Imovel__c/validationRules/Area_tem_de_ser_positiva.validationRule-meta.xml

- **Agora:** Area zero provoca divisao por zero no preco por m2.
- **Racional:** Area zero provoca divisao por zero em qualquer calculo de preco por m2.

## objects/Imovel__c/validationRules/Preco_tem_de_ser_positivo.validationRule-meta.xml

- **Agora:** Preco zero destroi qualquer media ou soma de carteira.
- **Racional:** Um imovel a zero euros destroi qualquer media de preco por m2 e qualquer soma de carteira.

## objects/Lead/fields/Data_Atribuicao__c.field-meta.xml

- **Agora:** Momento em que o lead foi atribuido a um agente. Meta: 5 minutos.
- **Racional:** Momento em que o lead saiu da fila para um agente. Meta: menos de 5 minutos.

## objects/Lead/fields/Data_Entrada__c.field-meta.xml

- **Agora:** Data de entrada do lead. Base das métricas de latência.
- **Racional:** Quando o lead entrou. Numa org real coincide com o CreatedDate; num histórico de demonstração, este é o campo que se pode preencher sem permissões especiais. As duas métricas de latência medem a partir daqui.

## objects/Lead/fields/Data_Primeiro_Contacto__c.field-meta.xml

- **Agora:** Momento do primeiro contacto real. Meta: 2 horas uteis.
- **Racional:** Momento do primeiro contacto real com o cliente. Meta: menos de 2 horas uteis.

## objects/Lead/fields/Data_Visita_Agendada__c.field-meta.xml

- **Agora:** Carimbado por Flow quando se agenda um Evento no lead.
- **Racional:** Carimbado por Flow quando se agenda um Evento no lead. Existe porque uma validation rule NAO consegue ver Eventos - nenhuma fórmula em Lead consegue contar registos filhos. O Flow regista o facto, a regra lê o campo.

## objects/Lead/fields/Fase_Obra__c.field-meta.xml

- **Agora:** Fase da obra: em projeto, em construcao ou concluido.
- **Racional:** Muda tudo no planeamento: em projeto significa venda na planta e 18 meses ate a primeira escritura; concluido vende-se em seis.

## objects/Lead/fields/Fiador__c.field-meta.xml

- **Agora:** Existencia de fiador. Pesa na pontuacao de um arrendamento.
- **Racional:** Ocupa na pontuacao o lugar que o financiamento ocupa numa compra. E o que trava um arrendamento, nao o credito.

## objects/Lead/fields/Horas_Ate_Primeiro_Contacto__c.field-meta.xml

- **Agora:** Horas entre a entrada do lead e o primeiro contacto. Meta: 2 horas.
- **Racional:** Latencia entre a entrada do lead e o primeiro contacto real. Meta: menos de 2 horas uteis.

## objects/Lead/fields/Imoveis_Sugeridos__c.field-meta.xml

- **Agora:** Imoveis da carteira que correspondem ao perfil. Escrito por Flow.
- **Racional:** Resumo devolvido pelo MatchImoveis: os imoveis REAIS da carteira que correspondem ao perfil desta lead. Escrito por Flow, nunca a mao. O Prompt Template Flex le daqui - o modelo nunca procura imoveis, so apresenta os que o SOQL encontrou.

## objects/Lead/fields/Imovel_Pretendido__c.field-meta.xml

- **Agora:** Imóvel que o lead quer comprar ou arrendar, tipicamente vindo do site.
- **Racional:** O imóvel por que o lead se interessou, tipicamente vindo do site. Não confundir com os campos Imovel_Tipo__c, Imovel_Localizacao__c e Imovel_Area_m2__c: esses descrevem o imóvel que o cliente quer VENDER, numa angariação. Este é o que ele quer COMPRAR.

## objects/Lead/fields/Minutos_Ate_Atribuicao__c.field-meta.xml

- **Agora:** Minutos entre a entrada do lead e a atribuicao. Meta: 5 minutos.
- **Racional:** Latencia entre a entrada do lead e a atribuicao a um agente. Meta: menos de 5 minutos.

## objects/Lead/fields/Notas_Preferencias__c.field-meta.xml

- **Agora:** Preferencias em texto livre. Materia-prima do matching por AI.
- **Racional:** Campo nao estruturado. Materia-prima do matching por AI.

## objects/Lead/fields/Numero_Fracoes__c.field-meta.xml

- **Agora:** Numero de fracoes a comercializar.
- **Racional:** Numero de fracoes a comercializar. Determina a escala do negocio e a comissao negociavel por volume.

## objects/Lead/fields/Plano_de_Procura__c.field-meta.xml

- **Agora:** Plano de procura fora da carteira, gerado por AI.
- **Racional:** Plano de procura fora da carteira, gerado por Prompt Template a partir do perfil da lead. Serve a partilha de angariacao. So leva links se a geracao passar por uma ferramenta de pesquisa real: um modelo sem pesquisa inventa URLs plausiveis e inexistentes.

## objects/Lead/fields/Pontuacao_Lead__c.field-meta.xml

- **Agora:** Pontuacao objetiva do lead, de 0 a 100.
- **Racional:** Pontuacao objetiva 0-100. Substitui deliberadamente o campo Rating standard: um rating escolhido a mao e uma opiniao, nao um dado.

## objects/Lead/fields/Sem_Imoveis__c.field-meta.xml

- **Agora:** Marcado pelo Flow quando nao ha imoveis em carteira para este perfil.
- **Racional:** Marcado pelo Flow depois de gerar o Plano de Procura. Existe porque Rich Text nao pode ser usado em filtros, nem em SOQL nem nos criterios de entrada de um Flow. Sem ele, o Flow regerava o plano em cada gravacao.

## objects/Lead/fields/Tipo_de_Perda__c.field-meta.xml

- **Agora:** Distingue o lead que nunca foi viavel do que se perdeu por demora.
- **Racional:** Separa o que nunca foi viavel (problema de marketing) do que era viavel e perdemos (problema nosso). Da a metrica percentagem de leads perdidos por falha nossa.

## objects/Lead/fields/Valor_Pretendido__c.field-meta.xml

- **Agora:** Valor que o proprietario pretende obter.
- **Racional:** Valor que o proprietario pretende obter. Comparar com a avaliacao para medir expectativa realista.

## objects/Lead/recordTypes/Angariacao.recordType-meta.xml

- **Agora:** Proprietário que quer vender ou arrendar o seu imóvel.
- **Racional:** Proprietário que quer vender ou arrendar o seu imóvel. A Terravista ganha um imóvel na carteira — e é o que alimenta o negócio.

## objects/Lead/recordTypes/Angariacao_Empreendimento.recordType-meta.xml

- **Agora:** Construtora que confia a comercialização de um empreendimento.
- **Racional:** Construtora que confia a comercialização de um empreendimento. Avalia-se o empreendimento, não um imóvel: número de frações, fase de obra, licenciamento. Um contrato dá origem a N imóveis.

## objects/Lead/recordTypes/Arrendamento.recordType-meta.xml

- **Agora:** Quer arrendar. Qualifica-se por fiador e comprovativo de rendimentos.
- **Racional:** Quer arrendar. Qualifica-se por fiador e comprovativo de rendimentos — perguntar por pré-aprovação de crédito não faz sentido aqui.

## objects/Lead/recordTypes/Compra.recordType-meta.xml

- **Agora:** Quer comprar. Qualifica-se por financiamento, orçamento e prazo.
- **Racional:** Quer comprar. Qualifica-se por financiamento, orçamento e prazo de decisão.

## objects/Lead/recordTypes/Interessado.recordType-meta.xml

- **Agora:** Substituido por Compra e Arrendamento. Desativado para preservar o historico.
- **Racional:** SUBSTITUIDO por Compra e Arrendamento. Desativado e nao apagado: preserva o historico dos registos ja associados.

## objects/Lead/validationRules/Avanco_exige_contacto_registado.validationRule-meta.xml

- **Agora:** Exige a Data do 1o Contacto, carimbada quando a chamada e concluida.
- **Racional:** Antes media por LastActivityDate, que nao distingue uma chamada de um email. Passa a exigir a Data do 1o Contacto, carimbada por Flow quando a chamada e dada por CONCLUIDA - uma tarefa aberta que ninguem fez e o problema, nao a prova.

## objects/Lead/validationRules/Conclusao_prevista_no_futuro.validationRule-meta.xml

- **Agora:** So valida na criacao ou alteracao, para nao bloquear registos historicos.
- **Racional:** Guardada por ISNEW/ISCHANGED para nao bloquear a edicao de registos historicos que ja nasceram com data passada.

## objects/Lead/validationRules/Convertido_so_pelo_botao_converter.validationRule-meta.xml

- **Agora:** Impede marcar o estado Convertido a mao, sem conversao real.
- **Racional:** Status e IsConverted sao coisas diferentes: marcar o estado nao converte nada, fica um lead que diz estar convertido sem Contacto, Conta nem Oportunidade. Esta regra fecha essa porta - so a operacao de conversao pode la chegar.

## objects/Lead/validationRules/Motivo_obrigatorio_ao_desqualificar.validationRule-meta.xml

- **Agora:** Garante a metrica de perdas: sem motivo nao ha analise.
- **Racional:** Sem esta regra o motivo fica vazio na maioria dos registos e a metrica de perdas nao existe.

## objects/Lead/validationRules/Orcamento_minimo_nao_excede_maximo.validationRule-meta.xml

- **Agora:** Um intervalo invertido faz o matching nao devolver nada.
- **Racional:** Um intervalo invertido faz o matching nao devolver nada, sem que ninguem perceba porque.

## objects/Lead/validationRules/Visita_agendada_exige_evento.validationRule-meta.xml

- **Agora:** Le a data carimbada por Flow: uma validation rule nao ve Eventos.
- **Racional:** Uma fase chamada Visita Agendada sem visita no calendario e uma mentira que o sistema conta a si proprio. A data e carimbada por Flow: uma validation rule nao ve Eventos, por isso le o campo.

## objects/Opportunity/businessProcesses/Servicos.businessProcess-meta.xml

- **Agora:** Fases da venda de servicos, distintas da venda de imoveis.
- **Racional:** Venda de servicos: certificado energetico, avaliacao, fotografia, apoio ao processo. Fases proprias, e nao as da venda de imoveis.

## objects/Opportunity/fields/Angariador__c.field-meta.xml

- **Agora:** Quem trouxe o imovel para a carteira. Copiado do dono do contrato.
- **Racional:** Quem trouxe o imovel para a carteira. Copiado do dono do Contrato de Mediacao. E um lookup e nao uma formula porque atravessar Imovel - Contrato - Owner excede o que uma formula consegue.

## objects/Opportunity/fields/Comissao_Angariacao__c.field-meta.xml

- **Agora:** Metade da comissao que remunera a angariacao. So existe com venda.
- **Racional:** Metade da comissao que remunera quem trouxe o imovel. So existe quando ha venda: um CMI assinado nao paga nada ate uma fracao ser vendida.

## objects/Opportunity/fields/Comissao_Angariador__c.field-meta.xml

- **Agora:** Valor que o angariador recebe deste negocio.
- **Racional:** O que o angariador recebe deste negocio. Se for a mesma pessoa que vendeu, este valor esta ja incluido na Comissao do Consultor - nao se somam os dois.

## objects/Opportunity/fields/Comissao_Consultor__c.field-meta.xml

- **Agora:** Valor que o dono do negocio recebe.
- **Racional:** O que o dono do negocio recebe. Leva sempre a parte da venda; leva TAMBEM a da angariacao quando foi ele proprio a trazer o imovel. Um campo Percent chega as formulas ja em decimal - por isso nao se divide por 100.

## objects/Opportunity/fields/Comissao_Terravista__c.field-meta.xml

- **Agora:** Receita da agencia: comissao do contrato sobre o valor do negocio.
- **Racional:** Receita real da agencia. O campo Amount e o preco do imovel (volume transacionado), nao a faturacao da Terravista. A percentagem vem do contrato de mediacao associado ao imovel. Nao dividir por 100: um campo Percent ja chega as formulas em decimal.

## objects/Opportunity/fields/Comissao_Venda__c.field-meta.xml

- **Agora:** Metade da comissao que remunera quem fechou o negocio.
- **Racional:** Metade da comissao que remunera quem encontrou o comprador e fechou o negocio.

## objects/Opportunity/fields/Data_CPCV__c.field-meta.xml

- **Agora:** Data do Contrato Promessa de Compra e Venda.
- **Racional:** Data do Contrato Promessa de Compra e Venda. Não se reaproveitou o objeto Contract: esse é o contrato de mediação, onde a Terravista é parte e que é dono dos imóveis. No CPCV as partes são o comprador e o vendedor, e a Terravista é só mediadora.

## objects/Opportunity/fields/Data_Visita__c.field-meta.xml

- **Agora:** Carimbado por Flow quando se agenda um Evento no negócio.
- **Racional:** Carimbado por Flow quando se agenda um Evento no negócio. Mesmo motivo do campo homólogo no Lead: uma validation rule não vê Eventos.

## objects/Opportunity/fields/Dias_Sem_Atividade__c.field-meta.xml

- **Agora:** Dias desde a ultima atividade registada no negocio.
- **Racional:** Usa LastActivityDate, que e standard e se preenche sozinho com Tasks e Events. Zero campos custom para alimentar, zero automacao. Negocios a adormecer sem ninguem dar por isso.

## objects/Opportunity/fields/Imoveis_Mostrados__c.field-meta.xml

- **Agora:** Quantos imóveis foram mostrados neste negócio.
- **Racional:** Quantos imóveis foram mostrados neste negócio. Roll-Up nativo sobre Imovel_Interesse__c: não há automação a manter, e por isso não há forma de ficar dessincronizado.

## objects/Opportunity/fields/Imoveis_Recusados__c.field-meta.xml

- **Agora:** Quantos dos imóveis mostrados o cliente recusou.
- **Racional:** Quantos dos imóveis mostrados o cliente recusou. Lido ao lado dos Imóveis Mostrados, diz se o problema é a carteira ou o perfil que se registou do cliente.

## objects/Opportunity/fields/Imovel__c.field-meta.xml

- **Agora:** Imovel objeto deste negocio.
- **Racional:** Imovel objeto desta oportunidade. Lookup e nao Master-Detail: a oportunidade sobrevive ao imovel ser removido da carteira.

## objects/Opportunity/fields/Linha_Negocio__c.field-meta.xml

- **Agora:** Segmento de cliente: particular ou empresa.
- **Racional:** Segmento de cliente, nao processo. Separado do Record Type de proposito: permite responder a "e se um investidor B2B comprar uma moradia?".

## objects/Opportunity/fields/Margem_Terravista__c.field-meta.xml

- **Agora:** O que sobra para a agencia depois de pagas as comissoes.
- **Racional:** O que sobra para a agencia depois de pagar a quem vendeu e a quem angariou. So desconta o angariador quando e outra pessoa - caso contrario ja esta contado na comissao do consultor.

## objects/Opportunity/fields/Motivo_Perda__c.field-meta.xml

- **Agora:** Motivo da perda do negocio.
- **Racional:** Porque morreu este negocio. Facto da transacao, distinto da capacidade de financiamento da pessoa.

## objects/Opportunity/fields/Proximo_Passo__c.field-meta.xml

- **Agora:** Leitura do negócio gerada por AI: o que está em risco e o que fazer.
- **Racional:** Leitura do estado do negócio gerada por Prompt Template: o que está em risco e o que fazer a seguir. É Rich Text e não Long Text Area porque o Prompt Builder não oferece os Long Text Area como destino — foi o que nos travou no Plano de Procura da Lead.

## objects/Opportunity/fields/Sinal__c.field-meta.xml

- **Agora:** Sinal entregue na assinatura do CPCV.
- **Racional:** Sinal entregue na assinatura do CPCV. É o que vincula as partes e o que o comprador perde se desistir — por isso é o primeiro número que alguém pergunta quando um negócio cai.

## objects/Opportunity/fields/Valor_Estimado_Angariacao__c.field-meta.xml

- **Agora:** Comissao futura estimada de um contrato. Nao e receita.
- **Racional:** Comissao futura estimada de um CMI. NAO E RECEITA: uma angariacao so paga quando um imovel do contrato for vendido. Existe para nunca ser somada a faturacao real.

## objects/Opportunity/fields/Valor_Estimado_Venda__c.field-meta.xml

- **Agora:** Pipeline de venda e arrendamento em aberto. Nao e faturacao.
- **Racional:** Valor de negocios de venda ou arrendamento ainda em aberto. E pipeline, nao faturacao. Separado da angariacao porque as duas coisas nao se somam.

## objects/Opportunity/recordTypes/Angariacao.recordType-meta.xml

- **Agora:** Conquistar o contrato de mediação de um imóvel. O Amount não é receita.
- **Racional:** Conquistar o contrato de mediação de um imóvel: é uma venda, perdida contra agências concorrentes. ATENÇÃO: o Amount é o valor estimado do imóvel, não receita — excluir dos relatórios de faturação.

## objects/Opportunity/recordTypes/Arrendamento.recordType-meta.xml

- **Agora:** Arrendamento de imóvel: fiador, caução e duração.
- **Racional:** Arrendamento de imóvel. Processo sem escritura, com fiador, caução e duração.

## objects/Opportunity/recordTypes/Servicos.recordType-meta.xml

- **Agora:** Venda de servicos associados a um imovel. Usa produtos e tabela de precos.
- **Racional:** Venda de servicos associados a um imovel. Usa produtos e tabela de precos.

## objects/Opportunity/recordTypes/Venda_Habitacao.recordType-meta.xml

- **Agora:** Venda de apartamento, moradia ou fração.
- **Racional:** Venda de apartamento, moradia ou fração. O comprador pode ser particular ou empresa.

## objects/Opportunity/recordTypes/Venda_Terreno.recordType-meta.xml

- **Agora:** Venda de terreno. Inclui avaliação de viabilidade construtiva.
- **Racional:** Venda de terreno a construtora ou a particular. Inclui avaliação de viabilidade construtiva.

## objects/Opportunity/validationRules/Avanco_exige_atividade_registada.validationRule-meta.xml

- **Agora:** Um negocio nao avanca sem atividade registada. Perdido fica de fora.
- **Racional:** Mesma logica do Lead. Um negocio que avanca sem uma unica atividade registada e um negocio que so existe na cabeca do agente - o problema numero um do Case Study. Perdido fica de fora: um negocio pode morrer sem nunca ter havido contacto.

## objects/Opportunity/validationRules/Cliente_obrigatorio_a_partir_da_proposta.validationRule-meta.xml

- **Agora:** Nao se faz uma proposta sem cliente identificado.
- **Racional:** Nao se faz uma proposta a ninguem. Exige limpeza previa: os negocios do Aurora foram criados sem Account.

## objects/Opportunity/validationRules/Data_de_fecho_nao_pode_estar_no_passado.validationRule-meta.xml

- **Agora:** So obriga a atualizar a data quando o negocio avanca de fase.
- **Racional:** Guardada por ISCHANGED(StageName) para nao bloquear a edicao livre de registos atrasados - so obriga a atualizar quando o negocio avanca.

## objects/Opportunity/validationRules/Imovel_obrigatorio_apos_visita.validationRule-meta.xml

- **Agora:** Sem imovel a comissao calcula zero e a faturacao fica errada.
- **Racional:** Sem imovel a formula Comissao_Terravista__c devolve zero, porque nao alcanca o contrato de mediacao. Um negocio fechado sem imovel soma 0 EUR a faturacao sem dar erro.

## objects/Opportunity/validationRules/Nao_reabrir_negocio_fechado.validationRule-meta.xml

- **Agora:** Reabrir um negocio fechado altera os relatorios historicos.
- **Racional:** Reabrir um negocio de julho muda retroativamente todos os relatorios historicos, e ninguem percebe porque e que os numeros de ontem deixaram de bater certo.

## objects/Opportunity/validationRules/Proxima_acao_obrigatoria_em_negociacao.validationRule-meta.xml

- **Agora:** Negociacoes de terreno arrastam-se: obriga a definir o passo seguinte.
- **Racional:** PP8 literal: negociacoes de terreno arrastam-se meses e e facil perder o fio a meada. O funil existe por causa disto.

## objects/Opportunity/validationRules/Valor_obrigatorio_a_partir_da_proposta.validationRule-meta.xml

- **Agora:** Sem valor nao ha comissao, pipeline nem previsao.
- **Racional:** Sem valor nao ha comissao calculada, nem pipeline, nem forecast. A partir da proposta o numero tem de existir.

## objects/Opportunity/validationRules/Viabilidade_antes_de_negociar_terreno.validationRule-meta.xml

- **Agora:** Nao se negoceia um terreno sem tipo de solo e area de construcao.
- **Racional:** Atravessa o lookup ate ao imovel. Negociar um terreno sem saber o tipo de solo e a area bruta de construcao admissivel e negociar a olho.

## objects/Opportunity/validationRules/Visita_realizada_exige_evento.validationRule-meta.xml

- **Agora:** So se aplica a venda e arrendamento. Nao bloqueia cargas de dados.
- **Racional:** Homologa da regra do Lead. So se aplica a venda e ao arrendamento: um terreno negoceia-se sem visita agendada no CRM, e uma angariacao tem visita de avaliacao, que e outra coisa. O ISCHANGED deixa passar as cargas de dados.

## objects/Product2/fields/Categoria__c.field-meta.xml

- **Agora:** Familia do servico. Picklist propria, versionada com o projeto.
- **Racional:** Familia do servico. O campo standard Family faria o mesmo, mas numa org nova nao traz valores nenhuns e defini-los obriga a mexer no value set standard; esta picklist e nossa e fica versionada com o vocabulario do negocio.

## objects/User/fields/Percentagem_Comissao__c.field-meta.xml

- **Agora:** Quota da comissao da Terravista que fica para este consultor.
- **Racional:** Quota da comissao da Terravista que fica para este consultor. Vive no User e nao no negocio: a percentagem e da pessoa, nao da venda. Mudar aqui recalcula o historico todo.

## permissionsets/Terravista_Acesso_Base.permissionset-meta.xml

- **Agora:** Acesso do consultor. As datas carimbadas por Flow ficam so de leitura.
- **Racional:** Acesso do CONSULTOR. Da tudo o que e preciso para trabalhar e NAO da edicao nos campos que medem o proprio consultor: as datas de primeiro contacto e de visita sao carimbadas por Flow e ficam so de leitura. Para as corrigir existe o Terravista_Direcao.

## permissionsets/Terravista_Direcao.permissionset-meta.xml

- **Agora:** Acesso da direcao: corrigir datas carimbadas, apagar registos e ver toda a carteira.
- **Racional:** Acesso da DIRECAO, por cima do Terravista_Acesso_Base. Da as tres coisas que um consultor nao pode ter: corrigir as datas que o medem, apagar registos, e ver a carteira de toda a gente. Atribui-se a quem responde pelo resultado, nao a quem o produz.

## reportTypes/Imoveis_da_Carteira.reportType-meta.xml

- **Agora:** Imoveis da carteira, com o contrato de mediacao a que pertencem.
- **Racional:** Imoveis da carteira, com o contrato de mediacao a que pertencem.

## reportTypes/Imoveis_de_Interesse.reportType-meta.xml

- **Agora:** Imoveis mostrados a clientes, com o estado e a proposta.
- **Racional:** Imoveis mostrados a clientes, com o estado em que ficaram e a proposta feita, se houve.

## reports/Terravista/Angariacoes_a_Pagar.report-meta.xml

- **Agora:** Quanto se deve a quem angariou. So conta imoveis ja escriturados.
- **Racional:** Quanto se deve a quem angariou. A angariacao so se paga quando o imovel vende, por isso o filtro e a escritura - antes disso o valor e estimativa, nao divida.

## reports/Terravista/Carga_por_Consultor.report-meta.xml

- **Agora:** Negocios abertos por consultor. Apoia a atribuicao de leads.
- **Racional:** Quantos negocios abertos tem cada consultor. Resolve a decisao que se tomava a olho: a quem atribuir sem saber quem esta ocupado.

## reports/Terravista/Carteira_Parada.report-meta.xml

- **Agora:** Imoveis por vender e ha quanto tempo estao em carteira.
- **Racional:** O que esta em carteira por vender, e ha quanto tempo. Um imovel parado ha muito tempo ou esta mal avaliado ou esta mal mostrado - qualquer das duas coisas se resolve.

## reports/Terravista/Comissoes_por_Consultor.report-meta.xml

- **Agora:** Comissoes a receber por consultor. So negocios fechados.
- **Racional:** Quanto cada consultor tem a receber. So conta o que ja fez escritura - uma comissao so se paga quando o negocio fecha.

## reports/Terravista/Conversao_por_Origem.report-meta.xml

- **Agora:** Taxa de conversao de leads por origem.
- **Racional:** Quantos leads de cada origem chegam a qualificado e quantos morrem pelo caminho. Contar leads sem contar o que lhes acontece premeia a origem que traz volume mau.

## reports/Terravista/Latencia_Primeiro_Contacto.report-meta.xml

- **Agora:** Tempo medio ate ao primeiro contacto com o lead.
- **Racional:** Quanto tempo demoramos a ligar de volta. E a metrica que a agencia nunca conseguiu ver, e a que explica os negocios perdidos.

## reports/Terravista/Leads_Sem_Contacto.report-meta.xml

- **Agora:** Fila de trabalho: leads ainda nao contactados.
- **Racional:** Leads que ainda nao foram contactados. E a lista sobre a qual se age hoje - nao um indicador, uma fila de trabalho.

## reports/Terravista/Leads_por_Origem.report-meta.xml

- **Agora:** Quantos leads entram por cada origem.
- **Racional:** Quantos leads entram por cada origem. E o denominador de tudo o resto que o marketing mede.

## reports/Terravista/Margem_Mensal.report-meta.xml

- **Agora:** Margem da agencia por mes, depois das comissoes.
- **Racional:** O que sobra para a empresa depois de pagas as comissoes. A comissao bruta sozinha nao diz nada - o que interessa e a margem.

## reports/Terravista/Perdidos_Por_Demora.report-meta.xml

- **Agora:** Leads perdidos por demora no contacto, com as horas de espera.
- **Racional:** Separa o que se perdeu por culpa nossa do que nunca foi viavel. A media de horas ao lado prova a ligacao: os que se perderam sao os que esperaram mais.

## reports/Terravista/Pipeline_B2C.report-meta.xml

- **Agora:** Negocio de particulares ainda em aberto.
- **Racional:** O negocio B2C que ainda nao fechou. Separado do B2B porque sao dois ciclos de venda diferentes e misturados nao se le nenhum.

## reports/Terravista/Pipeline_por_Fase.report-meta.xml

- **Agora:** Negocios em aberto por fase, com os dias sem atividade.
- **Racional:** Onde esta o negocio que ainda nao fechou. Inclui os dias sem atividade: uma fase avancada parada ha muito tempo e o sinal mais util que um pipeline da.

## reports/Terravista/Propostas_por_Imovel.report-meta.xml

- **Agora:** Propostas em aberto por imovel: valor e data de cada uma.
- **Racional:** Propostas em aberto, agrupadas por imovel. E a lista que o consultor leva a reuniao com o proprietario quando ha mais do que um interessado: quanto ofereceu cada um, e quem chegou primeiro.

## reports/Terravista/Receita_por_Campanha.report-meta.xml

- **Agora:** Comissao gerada por cada campanha.
- **Racional:** Quanto e que cada campanha deu de comissao, e nao quantos leads trouxe. E a pergunta que o marketing nunca conseguia responder a direcao.

## reports/Terravista/Ritmo_Empreendimentos.report-meta.xml

- **Agora:** Percentagem de cada empreendimento ja colocada.
- **Racional:** Quanto de cada empreendimento ja esta colocado. E o relatorio que o Miguel reconstruia a mao, e o que permite prestar contas a construtora sem o pedir a ninguem.

## reports/Terravista/Vendas_por_Linha_Negocio.report-meta.xml

- **Agora:** Vendas de particulares e de empreendimentos, separadas.
- **Racional:** Quanto vem de particulares e quanto vem de empreendimentos. Sao dois negocios diferentes com o mesmo nome.

## staticresources/fotos_imoveis.resource-meta.xml

- **Agora:** Fotografias dos imoveis, servidas pelo proprio Salesforce.
- **Racional:** Fotografias dos imoveis, servidas pelo proprio Salesforce. Um URL externo depende da rede da sala onde se apresenta e de um servico de terceiros continuar de pe; um Static Resource nao depende de nada.
