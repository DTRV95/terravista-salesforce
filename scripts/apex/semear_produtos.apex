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
  'CE|Certificado Energetico (SCE)|175|Obrigatorio por lei|'
    + 'Obrigatorio para vender ou arrendar, emitido por perito qualificado ADENE. '
    + 'Sem ele o imovel nao pode sequer ser anunciado.',
  'DOC|Tratamento Documental|150|Obrigatorio por lei|'
    + 'Ficha tecnica da habitacao, certidao permanente e caderneta predial. '
    + 'Vendidos juntos porque e assim que sao pedidos: ninguem chega a escritura '
    + 'com um so destes documentos.',
  'AVAL|Avaliacao Imobiliaria|250|Apoio ao processo|'
    + 'Relatorio por perito registado na CMVM. E o servico que resolve a '
    + 'discussao de preco com o proprietario com um numero em vez de uma opiniao.'
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
                           WHERE Estado_Comercial__c = 'Disponivel' LIMIT 5];
Date HOJE = Date.today();
// Cada linha: imovel, fase, dias ate fechar, e os servicos vendidos.
String[] negocios = new String[]{
  '0|Servico Entregue|-40|TV-CE,TV-DOC',
  '1|Servico Entregue|-25|TV-CE',
  '2|Servico Adjudicado|10|TV-CE,TV-DOC,TV-AVAL',
  '3|Servico Proposto|18|TV-AVAL',
  '4|Perdido|-12|TV-CE,TV-AVAL'
};

List<Opportunity> opps = new List<Opportunity>();
for (String n : negocios) {
    List<String> c = n.split('\\|');
    Imovel__c i = imoveis[Integer.valueOf(c[0])];
    opps.add(new Opportunity(
        Name = 'Serviços — ' + i.Name, RecordTypeId = rtServicos,
        AccountId = i.Contrato__r.AccountId, Imovel__c = i.Id,
        StageName = c[1], CloseDate = HOJE.addDays(Integer.valueOf(c[2])),
        Pricebook2Id = standard.Id, Linha_Negocio__c = 'B2C',
        // A regra Motivo_obrigatorio_ao_perder aplica-se a TODOS os Record
        // Types, servicos incluidos: um negocio perdido sem razao registada nao
        // ensina nada a equipa. O motivo aqui e o preco - certificados e
        // avaliacoes sao servicos de mercado e o cliente compara.
        Motivo_Perda__c = (c[1] == 'Perdido') ? 'Preco' : null));
}
insert opps;

List<OpportunityLineItem> linhas = new List<OpportunityLineItem>();
for (Integer k = 0; k < negocios.size(); k++) {
    for (String codigo : negocios[k].split('\\|')[3].split(',')) {
        // O UnitPrice tem de ir explicito. Na interface o Salesforce copia-o da
        // tabela de precos; pela API nao copia, e a linha e recusada sem ele.
        // Vem do mesmo mapa que serviu para criar as entradas da tabela, por
        // isso nao ha dois sitios onde o preco possa divergir.
        linhas.add(new OpportunityLineItem(
            OpportunityId = opps[k].Id, PricebookEntryId = pbe.get(codigo),
            Quantity = 1, UnitPrice = precos.get(codigo)));
    }
}
insert linhas;

System.debug(LoggingLevel.ERROR, 'Produtos: ' + produtos.size()
    + ' | Negocios de servicos: ' + opps.size() + ' | Linhas: ' + linhas.size());
