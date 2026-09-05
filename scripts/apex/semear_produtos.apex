/**
 * Catalogo de servicos da Terravista, e alguns negocios de servicos ja abertos.
 *
 * PORQUE E QUE OS SERVICOS NAO SAO LINHAS DA VENDA DO IMOVEL
 * Quando uma Opportunity tem produtos, o Salesforce calcula o Amount como a soma
 * das linhas e o campo deixa de ser editavel. Como
 * Comissao_Terravista__c = Amount x comissao do contrato, um certificado
 * energetico de 175 EUR numa venda de 250.000 EUR faria a comissao ser calculada
 * sobre os 175. Por isso os servicos vivem num negocio proprio, com Record Type
 * Servicos, ligado ao mesmo imovel.
 *
 * Correr depois do semear_org.apex - precisa dos imoveis e dos clientes.
 */
final String MARCA = 'TV-';

// --- Limpar o que este script criou antes ---------------------------------
Database.delete([SELECT Id FROM Opportunity
                 WHERE RecordType.DeveloperName = 'Servicos'], false);
Database.delete([SELECT Id FROM PricebookEntry
                 WHERE Product2.ProductCode LIKE 'TV-%'], false);
Database.delete([SELECT Id FROM Product2 WHERE ProductCode LIKE 'TV-%'], false);

// --- O catalogo -----------------------------------------------------------
// Precos de mercado do Porto em 2026. O credito habitacao fica a zero de
// proposito: quem paga a intermediacao e o banco, nao o cliente - poe-lo a
// cobrar ao cliente seria descrever mal o negocio.
String[] cat = new String[]{
  'CE|Certificado Energetico (SCE)|175|Obrigatorio por lei|Obrigatorio para vender ou arrendar. Emitido por perito qualificado ADENE.',
  'FTH|Ficha Tecnica da Habitacao|90|Obrigatorio por lei|Obrigatoria em imoveis construidos depois de 2004.',
  'CERT|Certidao Permanente e Caderneta Predial|35|Obrigatorio por lei|Documentacao predial necessaria a escritura.',
  'LIC|Pedido de Licenca de Utilizacao|300|Obrigatorio por lei|Tratamento do pedido junto da camara municipal.',
  'FOTO|Reportagem Fotografica Profissional|150|Valorizacao do imovel|Fotografia com equipamento profissional e tratamento de imagem.',
  'VIDEO|Video e Tour Virtual 360|320|Valorizacao do imovel|Visita virtual navegavel, publicada no anuncio.',
  'PLANTA|Planta 2D e 3D|120|Valorizacao do imovel|Levantamento e desenho da planta para o anuncio.',
  'STAGING|Home Staging|850|Valorizacao do imovel|Preparacao do imovel para visitas. Mobiliario e decoracao temporarios.',
  'AVAL|Avaliacao Imobiliaria|250|Apoio ao processo|Relatorio de avaliacao por perito registado na CMVM.',
  'JUR|Apoio Juridico ao Processo|400|Apoio ao processo|Revisao contratual e acompanhamento juridico ate a escritura.',
  'ESCRIT|Tratamento do Processo de Escritura|550|Apoio ao processo|Marcacao, documentacao e acompanhamento no notario.',
  'CRED|Intermediacao de Credito Habitacao|0|Apoio ao processo|Sem custo para o cliente: a intermediacao e paga pelo banco.',
  'SEGURO|Mediacao de Seguro Multirriscos|45|Apoio ao processo|Angariacao do seguro obrigatorio associado ao credito.',
  'B2BMKT|Plano de Marketing de Empreendimento|2500|Servicos a promotores|Campanha completa de lancamento de um empreendimento.',
  'B2BSTAND|Stand de Vendas no Local|4500|Servicos a promotores|Montagem e operacao de stand de vendas na obra.'
};

List<Product2> produtos = new List<Product2>();
for (String linha : cat) {
    List<String> c = linha.split('\\|');
    produtos.add(new Product2(
        Name = c[1], ProductCode = MARCA + c[0], IsActive = true,
        Categoria__c = c[3], Description = c[4]));
}
insert produtos;

// --- Tabela de precos -----------------------------------------------------
// A tabela standard vem inativa numa org nova. Sem a ativar, nenhuma linha de
// produto pode ser criada - e o erro que sai nao fala de tabela de precos.
Pricebook2 standard = [SELECT Id, IsActive FROM Pricebook2 WHERE IsStandard = true LIMIT 1];
if (!standard.IsActive) { standard.IsActive = true; update standard; }

Map<String, Decimal> precos = new Map<String, Decimal>();
for (String linha : cat) {
    List<String> c = linha.split('\\|');
    precos.put(MARCA + c[0], Decimal.valueOf(c[2]));
}
List<PricebookEntry> entradas = new List<PricebookEntry>();
for (Product2 p : [SELECT Id, ProductCode FROM Product2 WHERE ProductCode LIKE 'TV-%']) {
    entradas.add(new PricebookEntry(
        Pricebook2Id = standard.Id, Product2Id = p.Id,
        UnitPrice = precos.get(p.ProductCode), IsActive = true, UseStandardPrice = false));
}
insert entradas;

// --- Negocios de servicos -------------------------------------------------
Id rtServicos = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName()
                      .get('Servicos').getRecordTypeId();
Map<String, Id> pbe = new Map<String, Id>();
for (PricebookEntry e : [SELECT Id, Product2.ProductCode FROM PricebookEntry
                         WHERE Product2.ProductCode LIKE 'TV-%']) {
    pbe.put(e.Product2.ProductCode, e.Id);
}

List<Imovel__c> imoveis = [SELECT Id, Name, Contrato__r.AccountId FROM Imovel__c
                           WHERE Estado_Comercial__c = 'Disponivel' LIMIT 6];
Date HOJE = Date.today();
// Cada linha: imovel, fase, dias ate fechar, e os servicos vendidos.
String[] negocios = new String[]{
  '0|Servico Entregue|-40|TV-CE,TV-FOTO,TV-PLANTA',
  '1|Servico Entregue|-25|TV-CE,TV-FTH',
  '2|Servico Adjudicado|10|TV-CE,TV-FOTO,TV-VIDEO,TV-STAGING',
  '3|Servico Proposto|25|TV-AVAL,TV-JUR',
  '4|Servico Proposto|18|TV-CE,TV-ESCRIT,TV-SEGURO',
  '5|Perdido|-12|TV-STAGING,TV-VIDEO'
};

List<Opportunity> opps = new List<Opportunity>();
for (String n : negocios) {
    List<String> c = n.split('\\|');
    Imovel__c i = imoveis[Integer.valueOf(c[0])];
    opps.add(new Opportunity(
        Name = 'Serviços — ' + i.Name, RecordTypeId = rtServicos,
        AccountId = i.Contrato__r.AccountId, Imovel__c = i.Id,
        StageName = c[1], CloseDate = HOJE.addDays(Integer.valueOf(c[2])),
        Pricebook2Id = standard.Id, Linha_Negocio__c = 'B2C'));
}
insert opps;

List<OpportunityLineItem> linhas = new List<OpportunityLineItem>();
for (Integer k = 0; k < negocios.size(); k++) {
    for (String codigo : negocios[k].split('\\|')[3].split(',')) {
        linhas.add(new OpportunityLineItem(
            OpportunityId = opps[k].Id, PricebookEntryId = pbe.get(codigo), Quantity = 1));
    }
}
insert linhas;

System.debug(LoggingLevel.ERROR, 'Produtos: ' + produtos.size()
    + ' | Negocios de servicos: ' + opps.size() + ' | Linhas: ' + linhas.size());
