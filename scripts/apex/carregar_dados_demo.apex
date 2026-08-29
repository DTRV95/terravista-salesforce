/*
 * Carga de dados de demonstracao — pipeline aberto
 * --------------------------------------------------------------------------
 * Correr com:  sf apex run -f scripts/apex/carregar_dados_demo.apex -o terravista
 *
 * E RE-EXECUTAVEL. Tudo o que cria leva a marca [DEMO] na descricao; a primeira
 * seccao apaga a carga anterior antes de criar a nova. Nao toca em nada que nao
 * tenha essa marca — as 12 vendas do Aurora e os contratos reais ficam intactos.
 */

final String MARCA    = '[DEMO]';                        // texto legivel na descricao
final String MARCA_AC = 'DEMO';                          // Account.AccountNumber
final String MARCA_LD = 'https://demo.terravista.local'; // Lead.Website

/*  PORQUE NAO SE FILTRA PELA DESCRICAO
 *  Description e um Long Text Area em Account, Opportunity, Contract e Lead, e
 *  o SOQL NAO deixa filtrar por campos desse tipo. A primeira versao deste script
 *  usava 'WHERE Description LIKE' e rebentava na primeira linha.
 *  A marca vive agora em campos de texto normais, que sao filtraveis.  */
final Date   HOJE   = Date.today();

// ===== 0 · LIMPAR A CARGA ANTERIOR ==========================================
List<Opportunity> oppsAntigas = [SELECT Id, Imovel__c FROM Opportunity WHERE Account.AccountNumber = :MARCA_AC];
Set<Id> imoveisALibertar = new Set<Id>();
for (Opportunity o : oppsAntigas) if (o.Imovel__c != null) imoveisALibertar.add(o.Imovel__c);
if (!oppsAntigas.isEmpty()) delete oppsAntigas;

// devolver a carteira os imoveis que a carga anterior tinha reservado
List<Imovel__c> aLibertar = new List<Imovel__c>();
for (Imovel__c im : [SELECT Id, Estado_Comercial__c FROM Imovel__c WHERE Id IN :imoveisALibertar]) {
    if (im.Estado_Comercial__c != 'Vendido') { im.Estado_Comercial__c = 'Disponivel'; aLibertar.add(im); }
}
if (!aLibertar.isEmpty()) update aLibertar;

// apagar contratos demo (o Master-Detail leva os imoveis atras) e depois as contas
List<Contract> contratosAntigos = [SELECT Id FROM Contract WHERE Account.AccountNumber = :MARCA_AC];
if (!contratosAntigos.isEmpty()) delete contratosAntigos;
List<Lead> leadsAntigos = [SELECT Id FROM Lead WHERE Website = :MARCA_LD];
if (!leadsAntigos.isEmpty()) delete leadsAntigos;
List<Account> contasAntigas = [SELECT Id FROM Account WHERE AccountNumber = :MARCA_AC];
if (!contasAntigas.isEmpty()) delete contasAntigas;

System.debug('Limpeza: ' + oppsAntigas.size() + ' negocios, ' + contratosAntigos.size() + ' contratos, ' + contasAntigas.size() + ' contas.');

// ===== 1 · RECORD TYPES =====================================================
Map<String, Id> rtOpp  = new Map<String, Id>();
Map<String, Id> rtLead = new Map<String, Id>();
for (RecordType rt : [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE SobjectType IN ('Opportunity','Lead')]) {
    if (rt.SobjectType == 'Opportunity') rtOpp.put(rt.DeveloperName, rt.Id); else rtLead.put(rt.DeveloperName, rt.Id);
}

// ===== 2 · CONTAS =========================================================
// MODELO: um Account nunca representa uma pessoa disfarcada de empresa.
//   · Particulares  -> Person Account (record type de tipo pessoa). A pessoa E a
//     conta; os campos de perfil vivem no proprio registo com sufixo __pc.
//   · Empresas      -> Account de record type Empresa, com Contactos dentro.
Id rtPessoa  = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;
Id rtEmpresa = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = 'Empresa' LIMIT 1].Id;

Map<String, Account> contas = new Map<String, Account>();

// --- Particulares: Person Accounts ---------------------------------------
contas.put('ferraz', new Account(RecordTypeId=rtPessoa, AccountNumber=MARCA_AC,
    FirstName='Nuno', LastName='Ferraz', PersonEmail='nuno.ferraz@exemplo.pt', PersonMobilePhone='912000101',
    Perfil_Comprador__pc='Habitacao Propria', Procura_Tipologia__pc='T2', Procura_Zonas__pc='Matosinhos',
    Orcamento_Min__pc=150000, Orcamento_Max__pc=200000, Financiamento__pc='Em analise',
    Notas_Preferencias__pc='Primeira casa. Nao quer r/c. Precisa de garagem.',
    Description=MARCA+' comprador particular'));

contas.put('peixoto', new Account(RecordTypeId=rtPessoa, AccountNumber=MARCA_AC,
    FirstName='Carla', LastName='Peixoto', PersonEmail='carla.peixoto@exemplo.pt', PersonMobilePhone='912000102',
    Perfil_Comprador__pc='Habitacao Propria', Procura_Tipologia__pc='T3', Procura_Zonas__pc='Matosinhos, Leca da Palmeira',
    Orcamento_Min__pc=250000, Orcamento_Max__pc=300000, Financiamento__pc='Pre-aprovado',
    Notas_Preferencias__pc='Dois filhos em idade escolar. Quer perto da escola basica de Leca.',
    Description=MARCA+' compradora particular'));

contas.put('almada', new Account(RecordTypeId=rtPessoa, AccountNumber=MARCA_AC,
    FirstName='Sofia', LastName='Almada', PersonEmail='sofia.almada@exemplo.pt', PersonMobilePhone='912000104',
    Perfil_Comprador__pc='Habitacao Propria', Procura_Tipologia__pc='T4+', Procura_Zonas__pc='Foz, Matosinhos',
    Orcamento_Min__pc=450000, Orcamento_Max__pc=560000, Financiamento__pc='Pre-aprovado',
    Notas_Preferencias__pc='Vem de Lisboa. Quer vista mar, e o unico ponto inegociavel.',
    Description=MARCA+' compradora particular'));

contas.put('casal', new Account(RecordTypeId=rtPessoa, AccountNumber=MARCA_AC,
    FirstName='Bruno', LastName='Casal', PersonEmail='bruno.casal@exemplo.pt', PersonMobilePhone='912000105',
    Perfil_Comprador__pc='Habitacao Propria', Procura_Tipologia__pc='T3', Procura_Zonas__pc='Matosinhos',
    Orcamento_Min__pc=320000, Orcamento_Max__pc=370000, Financiamento__pc='Pre-aprovado',
    Notas_Preferencias__pc='CPCV assinado. Escritura dependente da entrega da obra.',
    Description=MARCA+' comprador particular'));

contas.put('rios', new Account(RecordTypeId=rtPessoa, AccountNumber=MARCA_AC,
    FirstName='Marta', LastName='Rios', PersonEmail='marta.rios@exemplo.pt', PersonMobilePhone='912000106',
    Perfil_Comprador__pc='Habitacao Propria', Procura_Tipologia__pc='T2', Procura_Zonas__pc='Porto',
    Orcamento_Max__pc=1100,
    Notas_Preferencias__pc='Arrendamento. Tem fiador. Contrato minimo de 2 anos.',
    Description=MARCA+' arrendataria'));

contas.put('vilar', new Account(RecordTypeId=rtPessoa, AccountNumber=MARCA_AC,
    FirstName='Pedro', LastName='Vilar', PersonEmail='pedro.vilar@exemplo.pt', PersonMobilePhone='912000107',
    Perfil_Comprador__pc='Habitacao Propria', Procura_Tipologia__pc='T2', Procura_Zonas__pc='Matosinhos',
    Orcamento_Min__pc=150000, Orcamento_Max__pc=190000, Financiamento__pc='Nao iniciado',
    Notas_Preferencias__pc='Banco recusou o credito. Volta a tentar daqui a 6 meses.',
    Description=MARCA+' negocio perdido'));

contas.put('vasconcelos', new Account(RecordTypeId=rtPessoa, AccountNumber=MARCA_AC,
    FirstName='Isabel', LastName='Vasconcelos', PersonEmail='isabel.vasconcelos@exemplo.pt', PersonMobilePhone='912000108',
    Notas_Preferencias__pc='Proprietaria. Herdou o T2 e prefere arrendar a vender.',
    Description=MARCA+' proprietaria - arrendamento'));

// --- Empresas e outras partes contratantes -------------------------------
contas.put('nobre', new Account(RecordTypeId=rtEmpresa, AccountNumber=MARCA_AC,
    Name='Nobre Investimentos, Unipessoal Lda',
    Description=MARCA+' investidor - compra para arrendar'));

contas.put('ameal', new Account(RecordTypeId=rtEmpresa, AccountNumber=MARCA_AC,
    Name='Quinta do Ameal, Lda', Description=MARCA+' proprietaria - terreno'));

contas.put('douro', new Account(RecordTypeId=rtEmpresa, AccountNumber=MARCA_AC,
    Name='Construtora Douro Vale, S.A.', Description=MARCA+' construtora compradora de terreno',
    Procura_Tipo_Solo__c='Urbanizavel', Procura_ABC_Minima_m2__c=2000,
    Procura_Zonas__c='Maia, Matosinhos, Valongo', Orcamento_Max__c=600000,
    Notas_Criterios__c='So avanca com PIP aprovado. Prefere lotes acima de 2000 m2 de ABC.'));

// Heranca indivisa: uma parte contratante coletiva, nao uma pessoa
contas.put('herdeiros', new Account(RecordTypeId=rtEmpresa, AccountNumber=MARCA_AC,
    Name='Herdeiros de Silva Matos', Description=MARCA+' angariacao em curso'));

insert contas.values();

// ===== 2b · CONTACTOS DAS EMPRESAS ========================================
// So as contas empresariais levam Contactos. Os Person Accounts ja SAO a pessoa.
insert new List<Contact>{
    new Contact(AccountId=contas.get('douro').Id, FirstName='Alvaro', LastName='Sequeira',
                Email='alvaro.sequeira@dourovale.pt', Phone='229000200',
                Notas_Preferencias__c='Director de expansao. Decide com o conselho, reune a primeira segunda-feira do mes.'),
    new Contact(AccountId=contas.get('nobre').Id, FirstName='Ricardo', LastName='Nobre',
                Email='ricardo.nobre@exemplo.pt', Phone='912000103', Perfil_Comprador__c='Investimento',
                Procura_Tipologia__c='T3', Procura_Zonas__c='Matosinhos', Orcamento_Min__c=260000, Orcamento_Max__c=300000,
                Financiamento__c='Nao necessita',
                Notas_Preferencias__c='Compra para arrendar. So interessa rentabilidade acima de 5%.')
};

// ===== 3 · DOIS CONTRATOS NOVOS E OS RESPETIVOS IMOVEIS =====================
// Servem para demonstrar dois Record Types que ate agora nao tinham dados:
// Arrendamento e Venda de Terreno.
List<Contract> novosContratos = new List<Contract>{
    new Contract(AccountId=contas.get('vasconcelos').Id, Status='Draft', StartDate=HOJE.addDays(-80), ContractTerm=12,
                 Regime__c='Mediacao a Particular', Comissao__c=5, Exclusivo__c=false,
                 Localizacao__c='Porto', Description=MARCA+' CMI de arrendamento'),
    new Contract(AccountId=contas.get('ameal').Id,    Status='Draft', StartDate=HOJE.addDays(-45), ContractTerm=12,
                 Regime__c='Mediacao a Particular', Comissao__c=3, Exclusivo__c=true,
                 Localizacao__c='Maia', Description=MARCA+' CMI de terreno')
};
insert novosContratos;

List<Imovel__c> novosImoveis = new List<Imovel__c>{
    new Imovel__c(Contrato__c=novosContratos[0].Id, Name='Apartamento T2 - Rua de Costa Cabral, Porto',
                  Tipo_Imovel__c='Apartamento', Finalidade__c='Arrendamento', Estado_Comercial__c='Disponivel',
                  Preco__c=950, Area_m2__c=68, Tipologia__c='T2', Piso__c='3', Localizacao__c='Porto',
                  Data_Disponibilizacao__c=HOJE.addDays(-78)),
    new Imovel__c(Contrato__c=novosContratos[1].Id, Name='Terreno - Estrada da Circunvalacao, Maia',
                  Tipo_Imovel__c='Terreno', Finalidade__c='Venda', Estado_Comercial__c='Disponivel',
                  Preco__c=480000, Area_m2__c=3200, Localizacao__c='Maia',
                  Tipo_Solo__c='Urbanizavel', Area_Bruta_Construcao_m2__c=2400,
                  Data_Disponibilizacao__c=HOJE.addDays(-40))
};
insert novosImoveis;

// ===== 4 · IMOVEIS EXISTENTES PARA O PIPELINE ===============================
Map<String, Imovel__c> im = new Map<String, Imovel__c>();
for (Imovel__c i : [SELECT Id, Name, Preco__c FROM Imovel__c
                    WHERE Name IN ('Aurora - 3ºD','Aurora - 5ºB','Aurora - 6ºB','Aurora - 7ºC','Aurora - 4ºC','Aurora - 2ºD')]) {
    im.put(i.Name, i);
}

// ===== 5 · PIPELINE ABERTO ==================================================
// Desenhado para as dashboards: fases diferentes, dois negocios adormecidos,
// um ganho por fechar, um perdido com motivo, e quatro Record Types cobertos.
List<Opportunity> opps = new List<Opportunity>{
    new Opportunity(Name='Nuno Ferraz — Aurora 3ºD', RecordTypeId=rtOpp.get('Venda_Habitacao'),
        AccountId=contas.get('ferraz').Id, Imovel__c=im.get('Aurora - 3ºD').Id, Linha_Negocio__c='B2C',
        StageName='Interesse Registado', CloseDate=HOJE.addDays(78), Description=MARCA+' pipeline aberto'),

    new Opportunity(Name='Carla Peixoto — Aurora 5ºB', RecordTypeId=rtOpp.get('Venda_Habitacao'),
        AccountId=contas.get('peixoto').Id, Imovel__c=im.get('Aurora - 5ºB').Id, Linha_Negocio__c='B2C',
        StageName='Visita Realizada', CloseDate=HOJE.addDays(62), Description=MARCA+' pipeline aberto'),

    new Opportunity(Name='Ricardo Nobre — Aurora 6ºB', RecordTypeId=rtOpp.get('Venda_Habitacao'),
        AccountId=contas.get('nobre').Id, Imovel__c=im.get('Aurora - 6ºB').Id, Linha_Negocio__c='B2C',
        StageName='Proposta Apresentada', Amount=282000, CloseDate=HOJE.addDays(42), Description=MARCA+' pipeline aberto'),

    // ADORMECIDO — 26 dias sem atividade, em negociacao. E o caso que a gestao tem de ver.
    new Opportunity(Name='Sofia Almada — Aurora 7ºC', RecordTypeId=rtOpp.get('Venda_Habitacao'),
        AccountId=contas.get('almada').Id, Imovel__c=im.get('Aurora - 7ºC').Id, Linha_Negocio__c='B2C',
        StageName='Negociacao', Amount=520000, CloseDate=HOJE.addDays(32),
        NextStep='Confirmar se a proposta de 520k foi aceite pela construtora', Description=MARCA+' pipeline aberto - adormecido'),

    new Opportunity(Name='Bruno Casal — Aurora 4ºC', RecordTypeId=rtOpp.get('Venda_Habitacao'),
        AccountId=contas.get('casal').Id, Imovel__c=im.get('Aurora - 4ºC').Id, Linha_Negocio__c='B2C',
        StageName='CPCV Assinado', Amount=350000, CloseDate=HOJE.addDays(22), Description=MARCA+' pipeline aberto'),

    new Opportunity(Name='Marta Rios — T2 Costa Cabral', RecordTypeId=rtOpp.get('Arrendamento'),
        AccountId=contas.get('rios').Id, Imovel__c=novosImoveis[0].Id, Linha_Negocio__c='B2C',
        StageName='Proposta Apresentada', Amount=950, CloseDate=HOJE.addDays(17), Description=MARCA+' pipeline aberto'),

    // ADORMECIDO — 34 dias. Terreno, para exercitar a regra de viabilidade.
    new Opportunity(Name='Douro Vale — Terreno Circunvalacao', RecordTypeId=rtOpp.get('Venda_Terreno'),
        AccountId=contas.get('douro').Id, Imovel__c=novosImoveis[1].Id, Linha_Negocio__c='B2B',
        StageName='Avaliacao de Viabilidade', CloseDate=HOJE.addDays(108), Description=MARCA+' pipeline aberto - adormecido'),

    new Opportunity(Name='Angariacao — Herdeiros de Silva Matos', RecordTypeId=rtOpp.get('Angariacao'),
        AccountId=contas.get('herdeiros').Id, Linha_Negocio__c='B2C',
        StageName='Proposta de Mediacao', Amount=14500, CloseDate=HOJE.addDays(27), Description=MARCA+' pipeline de angariacao'),

    // PERDIDO com motivo — sem isto a metrica de perdas nao tem nada para mostrar
    new Opportunity(Name='Pedro Vilar — Aurora 2ºD', RecordTypeId=rtOpp.get('Venda_Habitacao'),
        AccountId=contas.get('vilar').Id, Imovel__c=im.get('Aurora - 2ºD').Id, Linha_Negocio__c='B2C',
        StageName='Perdido', Amount=183000, CloseDate=HOJE.addDays(-9),
        Motivo_Perda__c='Financiamento recusado', Description=MARCA+' negocio perdido')
};
insert opps;

// ===== 6 · ATIVIDADE ========================================================
// Sem isto, LastActivityDate fica nulo, Dias_Sem_Atividade nao calcula, as regras
// de avanco de fase bloqueiam tudo, e a vista "A Adormecer" aparece vazia.
Map<String, Integer> diasAtras = new Map<String, Integer>{
    'Nuno Ferraz — Aurora 3ºD'            => 2,
    'Carla Peixoto — Aurora 5ºB'          => 4,
    'Ricardo Nobre — Aurora 6ºB'          => 6,
    'Sofia Almada — Aurora 7ºC'           => 26,
    'Bruno Casal — Aurora 4ºC'            => 8,
    'Marta Rios — T2 Costa Cabral'        => 3,
    'Douro Vale — Terreno Circunvalacao'  => 34,
    'Angariacao — Herdeiros de Silva Matos' => 5,
    'Pedro Vilar — Aurora 2ºD'            => 15
};
Map<String, String> assunto = new Map<String, String>{
    'Nuno Ferraz — Aurora 3ºD'            => 'Chamada de primeiro contacto',
    'Carla Peixoto — Aurora 5ºB'          => 'Visita ao imovel',
    'Ricardo Nobre — Aurora 6ºB'          => 'Envio de proposta',
    'Sofia Almada — Aurora 7ºC'           => 'Reuniao de negociacao',
    'Bruno Casal — Aurora 4ºC'            => 'Assinatura do CPCV',
    'Marta Rios — T2 Costa Cabral'        => 'Visita ao apartamento',
    'Douro Vale — Terreno Circunvalacao'  => 'Envio do PIP e da certidao de teor',
    'Angariacao — Herdeiros de Silva Matos' => 'Apresentacao da proposta de mediacao',
    'Pedro Vilar — Aurora 2ºD'            => 'Comunicacao da recusa do banco'
};
Map<String, String> notas = new Map<String, String>{
    'Nuno Ferraz — Aurora 3ºD'            => 'Interessado no 3ºD. Vai confirmar com o banco antes de agendar visita.',
    'Carla Peixoto — Aurora 5ºB'          => 'Gostou da exposicao solar. Ficou de decidir com o marido ate ao fim da semana.',
    'Ricardo Nobre — Aurora 6ºB'          => 'Proposta de 282k enviada. Quer os valores de renda praticados no edificio.',
    'Sofia Almada — Aurora 7ºC'           => 'Contraproposta de 520k entregue a construtora. SEM RESPOSTA HA 26 DIAS.',
    'Bruno Casal — Aurora 4ºC'            => 'CPCV assinado, sinal de 35k pago. Escritura marcada para depois da entrega da obra.',
    'Marta Rios — T2 Costa Cabral'        => 'Gostou. Vai entregar comprovativos de rendimento e dados do fiador.',
    'Douro Vale — Terreno Circunvalacao'  => 'Documentacao entregue. Aguarda parecer do conselho. SEM CONTACTO HA 34 DIAS.',
    'Angariacao — Herdeiros de Silva Matos' => 'Tres herdeiros, dois ja concordam. O terceiro quer avaliacao independente.',
    'Pedro Vilar — Aurora 2ºD'            => 'Banco recusou por taxa de esforco. Recontactar dentro de 6 meses.'
};
List<Task> tarefas = new List<Task>();
for (Opportunity o : opps) {
    Task t = new Task(WhatId=o.Id, Subject=assunto.get(o.Name), Description=notas.get(o.Name),
                      Status='Completed', Priority='Normal', ActivityDate=HOJE.addDays(-diasAtras.get(o.Name)));
    tarefas.add(t);
}
// uma tarefa em aberto, para a lista de trabalho do consultor nao estar vazia
tarefas.add(new Task(WhatId=opps[3].Id, Subject='Ligar a construtora sobre a contraproposta da Sofia Almada',
                     Status='Not Started', Priority='High', ActivityDate=HOJE.addDays(1),
                     Description='Negocio parado ha 26 dias. Se nao houver resposta ate sexta, apresentar alternativa no 7ºB.'));
insert tarefas;

// ===== 7 · IMOVEIS RESERVADOS PELO PIPELINE =================================
// Escrito explicitamente para o estado ficar correto mesmo que os Flows ainda
// nao estejam na org. Se estiverem, escrevem o mesmo valor — nao ha conflito.
update new Imovel__c(Id=im.get('Aurora - 4ºC').Id, Estado_Comercial__c='Reservado');

// ===== 8 · LEADS POR CONTACTAR ==============================================
// Sem atividade, de proposito: alimentam a vista "Sem Primeiro Contacto".
insert new List<Lead>{
    new Lead(Website=MARCA_LD, FirstName='Vera',  LastName='Antunes', Company='Vera Antunes (Particular)',
             Email='vera.antunes@exemplo.pt', Phone='912000201', Status='Novo',
             LeadSource='Portal Imobiliario', RecordTypeId=rtLead.get('Compra'),
             Procura_Tipologia__c='T2', Procura_Zonas__c='Matosinhos', Orcamento_Min__c=160000, Orcamento_Max__c=210000,
             Financiamento__c='Em analise', Prazo_Decisao__c='3 a 6 meses', Description=MARCA+' lead por contactar'),
    new Lead(Website=MARCA_LD, FirstName='Hugo',  LastName='Bastos',  Company='Hugo Bastos (Particular)',
             Email='hugo.bastos@exemplo.pt', Phone='912000202', Status='Novo',
             LeadSource='Site', RecordTypeId=rtLead.get('Compra'),
             Procura_Tipologia__c='T3', Procura_Zonas__c='Foz, Boavista', Orcamento_Min__c=400000, Orcamento_Max__c=550000,
             Financiamento__c='Pre-aprovado', Prazo_Decisao__c='Menos de 3 meses', Description=MARCA+' lead por contactar'),
    new Lead(Website=MARCA_LD, FirstName='Celia', LastName='Moura',   Company='Celia Moura (Particular)',
             Email='celia.moura@exemplo.pt', Phone='912000203', Status='Novo',
             LeadSource='Referencia', RecordTypeId=rtLead.get('Arrendamento'),
             Procura_Tipologia__c='T1', Procura_Zonas__c='Porto', Orcamento_Max__c=800,
             Fiador__c='Tem fiador', Prazo_Decisao__c='Menos de 3 meses', Description=MARCA+' lead por contactar')
};

System.debug('Carga concluida: ' + opps.size() + ' negocios, ' + tarefas.size() + ' atividades, 3 leads, 2 contratos, 2 imoveis novos.');
