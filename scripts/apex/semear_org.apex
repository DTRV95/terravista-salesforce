/*
 * SEMEAR A ORG - constroi o mundo Terravista do zero
 * ==========================================================================
 *   sf apex run -f scripts/apex/semear_org.apex -o terravista
 *
 * Apaga os dados de negocio e reconstroi tudo. E a fonte unica dos dados de
 * demonstracao: se a org rebentar, se precisares de uma org nova, ou se
 * estragares dados na vespera da apresentacao, um comando devolve tudo.
 *
 * PRE-REQUISITOS
 *   1. Deploy feito (roles, queue, campos de comissao)
 *   2. criar_utilizadores.apex ja correu (Carla e Miguel existem, e o
 *      administrador tem a flag Marketing User - sem ela nao ha DML em Campaign)
 *
 * ORDEM DE ELIMINACAO - NAO MEXER
 * Imovel__c esta em Master-Detail com Contract: apagar um contrato apaga as
 * fracoes todas. Por isso os negocios saem primeiro, depois os contratos (que
 * levam os imoveis atras), e as contas so no fim.
 *
 * Os contratos ficam todos em Draft de proposito: um contrato Activated NAO
 * se apaga, e isso partia a re-execucao deste script.
 */

final Date HOJE = Date.today();

// ===== 0 - LIMPAR ==========================================================
// allOrNone = false: ha registos de sistema que se recusam a sair (o Sample
// Account for Entitlements, por exemplo) e nao podem fazer falhar o resto.
Database.delete([SELECT Id FROM Task], false);
Database.delete([SELECT Id FROM Event], false);
Database.delete([SELECT Id FROM Opportunity], false);
Database.delete([SELECT Id FROM Case], false);
Database.delete([SELECT Id FROM Contract], false);
Database.delete([SELECT Id FROM Imovel__c], false);
Database.delete([SELECT Id FROM Lead], false);
Database.delete([SELECT Id FROM CampaignMember], false);
Database.delete([SELECT Id FROM Campaign], false);
Database.delete([SELECT Id FROM Contact WHERE Account.IsPersonAccount = false], false);
Database.delete([SELECT Id FROM Account], false);
System.debug('--- org limpa ---');

// ===== 1 - QUEM E QUEM =====================================================
Map<String, Id> u = new Map<String, Id>();
for (User x : [SELECT Id, LastName FROM User WHERE LastName IN ('Bettencourt','Andrade') AND IsActive = true]) {
    u.put(x.LastName, x.Id);
}
Id CARLA  = u.containsKey('Bettencourt') ? u.get('Bettencourt') : UserInfo.getUserId();
Id MIGUEL = u.containsKey('Andrade')     ? u.get('Andrade')     : UserInfo.getUserId();
if (!u.containsKey('Bettencourt') || !u.containsKey('Andrade')) {
    System.debug('AVISO: personas em falta. Corre criar_utilizadores.apex antes deste script.');
}

Id rtPessoa  = [SELECT Id FROM RecordType WHERE SobjectType='Account' AND IsPersonType = true LIMIT 1].Id;
Id rtEmpresa = [SELECT Id FROM RecordType WHERE SobjectType='Account' AND DeveloperName='Empresa' LIMIT 1].Id;
Map<String, Id> rtO = new Map<String, Id>();
Map<String, Id> rtL = new Map<String, Id>();
for (RecordType r : [SELECT Id, DeveloperName, SobjectType FROM RecordType WHERE SobjectType IN ('Opportunity','Lead')]) {
    if (r.SobjectType == 'Opportunity') rtO.put(r.DeveloperName, r.Id); else rtL.put(r.DeveloperName, r.Id);
}

// ===== 2 - CAMPANHAS =======================================================
// As tres que o case study nomeia. Sao elas que respondem a pergunta da Ines:
// "vale a pena manter o investimento no LinkedIn?"
Map<String, Campaign> cmp = new Map<String, Campaign>{
 'matosinhos' => new Campaign(Name='Arrendamento Matosinhos', Type='Advertisement', Status='Completed',
    StartDate=HOJE.addMonths(-11), EndDate=HOJE.addMonths(-9), BudgetedCost=1500, ActualCost=1420, IsActive=false,
    Description='Anuncio de arrendamento em Matosinhos. Publico: particulares.'),
 'particulares' => new Campaign(Name='Captacao de Compradores Particulares', Type='Advertisement', Status='In Progress',
    StartDate=HOJE.addMonths(-8), EndDate=HOJE.addMonths(1), BudgetedCost=6000, ActualCost=4850, IsActive=true,
    Description='Campanha continua de captacao de particulares interessados em compra.'),
 'linkedin' => new Campaign(Name='LinkedIn - Construtoras e Promotores', Type='Other', Status='In Progress',
    StartDate=HOJE.addMonths(-5), EndDate=HOJE.addMonths(1), BudgetedCost=3000, ActualCost=2600, IsActive=true,
    Description='Tentativa de chegar a construtoras. Publico completamente diferente do B2C.')
};
insert cmp.values();

// ===== 3 - EMPRESAS ========================================================
Map<String, Account> emp = new Map<String, Account>{
 'nortagua' => new Account(RecordTypeId=rtEmpresa, Name='Construtora Nortagua', Type='Partner', Phone='229100100',
    Description='Construtora do Edificio Aurora. Primeiro cliente B2B da Terravista.', OwnerId=MIGUEL),
 'edificios' => new Account(RecordTypeId=rtEmpresa, Name='Edificios do Norte, S.A.', Type='Prospect', Phone='229100200',
    Description='Chegou pela campanha do LinkedIn. Novo empreendimento em Gaia.', OwnerId=MIGUEL),
 'dourovale' => new Account(RecordTypeId=rtEmpresa, Name='Construtora Douro Vale, S.A.', Type='Prospect', Phone='229100300',
    Procura_Tipo_Solo__c='Urbanizavel', Procura_ABC_Minima_m2__c=2000, Procura_Zonas__c='Maia, Matosinhos, Valongo',
    Orcamento_Max__c=600000, Notas_Criterios__c='So avanca com PIP aprovado. Prefere lotes acima de 2000 m2 de ABC.',
    Description='Construtora compradora de terreno.', OwnerId=MIGUEL),
 'nobre' => new Account(RecordTypeId=rtEmpresa, Name='Nobre Investimentos, Unipessoal Lda', Phone='229100400',
    Orcamento_Max__c=900000, Procura_Zonas__c='Matosinhos, Porto',
    Notas_Criterios__c='Compra para arrendar. So interessa rentabilidade acima de 5%.',
    Description='Investidor institucional pequeno.', OwnerId=MIGUEL),
 'ameal' => new Account(RecordTypeId=rtEmpresa, Name='Quinta do Ameal, Lda', Phone='229100500',
    Description='Proprietaria do terreno da Maia.', OwnerId=MIGUEL),
 'herdeiros' => new Account(RecordTypeId=rtEmpresa, Name='Herdeiros de Silva Matos', Phone='229100600',
    Description='Heranca indivisa. Tres herdeiros, dois ja concordam.', OwnerId=CARLA)
};
insert emp.values();

insert new List<Contact>{
 new Contact(AccountId=emp.get('nortagua').Id,  FirstName='Alberto', LastName='Nortagua', Title='Director Comercial',
             Email='alberto@nortagua.pt', Phone='229100101'),
 new Contact(AccountId=emp.get('edificios').Id, FirstName='Rita', LastName='Ventura', Title='Administradora',
             Email='rita.ventura@edificiosdonorte.pt', Phone='229100201'),
 new Contact(AccountId=emp.get('dourovale').Id, FirstName='Alvaro', LastName='Sequeira', Title='Director de Expansao',
             Email='alvaro.sequeira@dourovale.pt', Phone='229100301',
             Notas_Preferencias__c='Decide com o conselho, reune a primeira segunda-feira do mes.'),
 new Contact(AccountId=emp.get('nobre').Id,     FirstName='Ricardo', LastName='Nobre', Title='Gerente',
             Email='ricardo.nobre@nobreinvest.pt', Phone='229100401')
};

// ===== 4 - PESSOAS =========================================================
// apelido|primeiro|tipologias|zonas|min|max|financiamento|perfil|notas
List<String> linhas = new List<String>{
 'Marques|Claudia|T2;T3|Matosinhos|180000|320000|Nao necessita|Investimento|Compra varias unidades no mesmo empreendimento. Decide depressa.',
 'Amaral|Ricardo|T3|Matosinhos, Leca da Palmeira|250000|300000|Pre-aprovado|Habitacao Propria|Dois filhos. Quer perto da escola basica de Leca.',
 'Correia|Sandra|T2|Matosinhos|170000|220000|Pre-aprovado|Habitacao Propria|Primeira casa. Precisa de garagem.',
 'Moreira|Paulo|T3|Matosinhos|230000|290000|Em analise|Habitacao Propria|Vem de Braga por mudanca de emprego.',
 'Nogueira|Beatriz|T2|Porto, Matosinhos|190000|250000|Pre-aprovado|Habitacao Propria|Divorcio recente. Quer resolver depressa.',
 'Pinto|Helena|T4+|Foz, Matosinhos|380000|560000|Pre-aprovado|Habitacao Propria|Vista mar e o unico ponto inegociavel.',
 'Salgado|Hugo|T2;T3|Matosinhos|250000|360000|Nao necessita|Investimento|Compra a pronto. Ja comprou duas vezes connosco.',
 'Cardoso|Rui|T3|Leca da Palmeira|260000|310000|Pre-aprovado|Habitacao Propria|Compra em conjunto com Sofia Cardoso (conjuge).',
 'Vieira|Marta|T2|Matosinhos|180000|300000|Em analise|Habitacao Propria|Compra em conjunto com Andre Vieira (conjuge).',
 'Teixeira|Jorge|T3|Foz|450000|520000|Pre-aprovado|Habitacao Propria|ELEVADOR E CONDICAO ABSOLUTA. Mae com mobilidade reduzida.',
 'Lopes|Miguel|T2|Porto, Matosinhos|160000|250000|Em analise|Habitacao Propria|Primeira casa. Orcamento apertado.',
 'Nunes|Teresa|T3|Matosinhos, Leca da Palmeira|270000|330000|Pre-aprovado|Habitacao Propria|Quer varanda ampla. Tem dois caes.',
 'Rocha|Antonio|T4+|Foz|480000|600000|Nao necessita|Habitacao Propria|Reformado. Compra a pronto, sem pressa nenhuma.',
 'Sousa|Joana|T1;T2|Porto, Matosinhos|140000|260000|Em analise|Investimento|Compra para arrendamento de curta duracao.',
 'Bastos|Hugo|T3|Foz, Boavista|400000|550000|Pre-aprovado|Habitacao Propria|Chegou pela campanha de particulares.',
 'Ferraz|Nuno|T2|Matosinhos|150000|210000|Em analise|Habitacao Propria|Nao quer r/c. Precisa de garagem.',
 'Almada|Sofia|T4+|Foz, Matosinhos|450000|560000|Pre-aprovado|Habitacao Propria|Vem de Lisboa. Quer vista mar.',
 'Rios|Marta|T2|Porto|0|1100||Habitacao Propria|Arrendamento. Tem fiador. Contrato minimo de 2 anos.',
 'Vasconcelos|Isabel|T2|Porto|0|0||Habitacao Propria|Proprietaria. Herdou o T2 e prefere arrendar a vender.',
 'Tavares|Fernando|T3|Foz|0|0||Habitacao Propria|Proprietario. Emigrou e quer vender o apartamento da Foz.',
 'Guerra|Alice|T3|Leca da Palmeira|0|0||Habitacao Propria|Proprietaria. Vende a moradia por mudanca para lar.'
};
Map<String, Account> pa = new Map<String, Account>();
Integer tel = 912000100;
for (String l : linhas) {
    List<String> c = l.split('\\|', -1);
    tel++;
    Account a = new Account(RecordTypeId=rtPessoa, FirstName=c[1], LastName=c[0],
        PersonEmail = c[1].toLowerCase() + '.' + c[0].toLowerCase() + '@exemplo.pt',
        PersonMobilePhone = String.valueOf(tel),
        Procura_Tipologia__pc = c[2], Procura_Zonas__pc = c[3],
        Perfil_Comprador__pc = c[7], Notas_Preferencias__pc = c[8], OwnerId = CARLA);
    if (Decimal.valueOf(c[4]) > 0) a.Orcamento_Min__pc = Decimal.valueOf(c[4]);
    if (Decimal.valueOf(c[5]) > 0) a.Orcamento_Max__pc = Decimal.valueOf(c[5]);
    if (c[6] != '') a.Financiamento__pc = c[6];
    pa.put(c[0], a);
}
insert pa.values();

// ===== 5 - CONTRATOS =======================================================
// Um CMI e sempre entre a Terravista e UM proprietario. Por isso cada imovel
// disperso tem o seu contrato, e nao um contrato coletivo que nao existiria.
Map<String, Contract> ct = new Map<String, Contract>{
 'aurora' => new Contract(OwnerId=MIGUEL, AccountId=emp.get('nortagua').Id, Status='Draft', StartDate=HOJE.addMonths(-13), ContractTerm=24,
    Regime__c='Comercializacao de Empreendimento', Comissao__c=4.5, Exclusivo__c=true,
    Nome_Empreendimento__c='Edificio Aurora', Localizacao__c='Matosinhos',
    Description='32 fracoes. O contrato que sustenta a maior parte da faturacao.'),
 'gaia' => new Contract(OwnerId=MIGUEL, AccountId=emp.get('edificios').Id, Status='Draft', StartDate=HOJE.addMonths(-2), ContractTerm=24,
    Regime__c='Comercializacao de Empreendimento', Comissao__c=4, Exclusivo__c=false,
    Nome_Empreendimento__c='Varanda do Douro', Localizacao__c='Vila Nova de Gaia',
    Description='8 fracoes. Contrato ganho pela campanha do LinkedIn.'),
 'britocapelo' => new Contract(OwnerId=CARLA, AccountId=emp.get('herdeiros').Id, Status='Draft', StartDate=HOJE.addMonths(-7), ContractTerm=12,
    Regime__c='Mediacao a Particular', Comissao__c=5, Exclusivo__c=true, Localizacao__c='Matosinhos',
    Description='Moradia da heranca.'),
 'molhe' => new Contract(OwnerId=CARLA, AccountId=pa.get('Tavares').Id, Status='Draft', StartDate=HOJE.addMonths(-6), ContractTerm=12,
    Regime__c='Mediacao a Particular', Comissao__c=5, Exclusivo__c=false, Localizacao__c='Foz',
    Description='Proprietario emigrado.'),
 'hintze' => new Contract(OwnerId=MIGUEL, AccountId=pa.get('Guerra').Id, Status='Draft', StartDate=HOJE.addMonths(-9), ContractTerm=12,
    Regime__c='Mediacao a Particular', Comissao__c=5, Exclusivo__c=true, Localizacao__c='Leca da Palmeira',
    Description='Venda por mudanca para lar.'),
 'costacabral' => new Contract(OwnerId=CARLA, AccountId=pa.get('Vasconcelos').Id, Status='Draft', StartDate=HOJE.addDays(-80), ContractTerm=12,
    Regime__c='Mediacao a Particular', Comissao__c=5, Exclusivo__c=false, Localizacao__c='Porto',
    Description='CMI de arrendamento.'),
 'maia' => new Contract(OwnerId=MIGUEL, AccountId=emp.get('ameal').Id, Status='Draft', StartDate=HOJE.addDays(-45), ContractTerm=12,
    Regime__c='Mediacao a Particular', Comissao__c=3, Exclusivo__c=true, Localizacao__c='Maia',
    Description='Terreno urbanizavel.')
};
insert ct.values();

// ===== 6 - IMOVEIS =========================================================
List<Imovel__c> imv = new List<Imovel__c>();
List<String> pisos = new List<String>{'R/C','1','2','3','4','5','6','7'};
List<String> letras = new List<String>{'A','B','C','D'};
Map<String, String> tipoPorLetra = new Map<String, String>{'A'=>'T3','B'=>'T2','C'=>'T3','D'=>'T2'};

// Edificio Aurora - 32 fracoes. Preco sobe com o piso.
for (Integer i = 0; i < pisos.size(); i++) {
    for (String let : letras) {
        Decimal base = (tipoPorLetra.get(let) == 'T3') ? 245000 : 185000;
        imv.add(new Imovel__c(Contrato__c=ct.get('aurora').Id,
            Name='Aurora - ' + pisos[i] + (pisos[i] == 'R/C' ? ' ' : 'º') + let,
            Tipo_Imovel__c='Fracao', Finalidade__c='Venda', Estado_Comercial__c='Disponivel',
            Preco__c = base + (i * 9000), Area_m2__c = (tipoPorLetra.get(let) == 'T3') ? 118 : 92,
            Tipologia__c = tipoPorLetra.get(let), Piso__c = pisos[i], Localizacao__c='Matosinhos',
            Data_Disponibilizacao__c = HOJE.addMonths(-13)));
    }
}
// Varanda do Douro - 8 fracoes novas, ainda todas disponiveis
for (Integer i = 0; i < 4; i++) {
    for (String let : new List<String>{'A','B'}) {
        imv.add(new Imovel__c(Contrato__c=ct.get('gaia').Id,
            Name='Varanda do Douro - ' + String.valueOf(i+1) + 'º' + let,
            Tipo_Imovel__c='Fracao', Finalidade__c='Venda', Estado_Comercial__c='Disponivel',
            Preco__c = 268000 + (i * 12000) + (let == 'A' ? 15000 : 0), Area_m2__c = (let == 'A' ? 124 : 98),
            Tipologia__c = (let == 'A' ? 'T3' : 'T2'), Piso__c = String.valueOf(i+1),
            Localizacao__c='Vila Nova de Gaia', Data_Disponibilizacao__c = HOJE.addMonths(-2)));
    }
}
// Imoveis dispersos
imv.add(new Imovel__c(Contrato__c=ct.get('britocapelo').Id, Name='Moradia T4 - Rua Brito Capelo, Matosinhos',
    Tipo_Imovel__c='Moradia', Finalidade__c='Venda', Estado_Comercial__c='Disponivel', Preco__c=395000,
    Area_m2__c=210, Tipologia__c='T4+', Localizacao__c='Matosinhos', Data_Disponibilizacao__c=HOJE.addMonths(-7)));
imv.add(new Imovel__c(Contrato__c=ct.get('molhe').Id, Name='Apartamento T3 - Rua do Molhe, Foz',
    Tipo_Imovel__c='Apartamento', Finalidade__c='Venda', Estado_Comercial__c='Disponivel', Preco__c=495000,
    Area_m2__c=132, Tipologia__c='T3', Piso__c='2', Localizacao__c='Foz', Data_Disponibilizacao__c=HOJE.addMonths(-6)));
imv.add(new Imovel__c(Contrato__c=ct.get('hintze').Id, Name='Moradia T3 - Rua Hintze Ribeiro, Leca',
    Tipo_Imovel__c='Moradia', Finalidade__c='Venda', Estado_Comercial__c='Disponivel', Preco__c=312000,
    Area_m2__c=165, Tipologia__c='T3', Localizacao__c='Leca da Palmeira', Data_Disponibilizacao__c=HOJE.addMonths(-9)));
imv.add(new Imovel__c(Contrato__c=ct.get('costacabral').Id, Name='Apartamento T2 - Rua de Costa Cabral, Porto',
    Tipo_Imovel__c='Apartamento', Finalidade__c='Arrendamento', Estado_Comercial__c='Disponivel', Preco__c=950,
    Area_m2__c=68, Tipologia__c='T2', Piso__c='3', Localizacao__c='Porto', Data_Disponibilizacao__c=HOJE.addDays(-78)));
imv.add(new Imovel__c(Contrato__c=ct.get('maia').Id, Name='Terreno - Estrada da Circunvalacao, Maia',
    Tipo_Imovel__c='Terreno', Finalidade__c='Venda', Estado_Comercial__c='Disponivel', Preco__c=480000,
    Area_m2__c=3200, Localizacao__c='Maia', Tipo_Solo__c='Urbanizavel', Area_Bruta_Construcao_m2__c=2400,
    Data_Disponibilizacao__c=HOJE.addDays(-45)));
insert imv;

// O angariador de um imovel e o dono do CMI que o trouxe para a carteira.
// O contrato 'hintze' e de proposito do Miguel enquanto a venda e da Carla:
// e o caso que prova que a comissao se divide entre duas pessoas.
Map<Id, Id> donoContrato = new Map<Id, Id>();
for (Contract c : ct.values()) donoContrato.put(c.Id, c.OwnerId);
Map<Id, Id> angariadorPorImovel = new Map<Id, Id>();
for (Imovel__c x : imv) angariadorPorImovel.put(x.Id, donoContrato.get(x.Contrato__c));

Map<String, Imovel__c> im = new Map<String, Imovel__c>();
for (Imovel__c x : imv) im.put(x.Name, x);
System.debug('Imoveis: ' + imv.size());

// ===== 7 - NEGOCIOS ========================================================
// A forma dos numeros e deliberada: um pico no inverno, uma quebra na primavera
// e agosto praticamente morto. A pergunta da Rita - "esta a crescer ou a
// estagnar?" - so tem graca se houver algo para interpretar.
// fracao|comprador|mesesAtras|valor
List<String> vendasAurora = new List<String>{
 'Aurora - R/C A|Marques|12|238000',  'Aurora - R/C B|Correia|11|196000',
 'Aurora - 1ºA|Amaral|11|254000',     'Aurora - 1ºB|Marques|10|194000',
 'Aurora - 2ºA|Moreira|10|263000',    'Aurora - 2ºC|Nogueira|9|261000',
 'Aurora - 3ºA|Salgado|8|272000',     'Aurora - 3ºC|Cardoso|8|270000',
 'Aurora - 4ºA|Vieira|7|281000',      'Aurora - 4ºD|Marques|6|221000',
 'Aurora - R/C D|Lopes|5|185000',     'Aurora - 5ºC|Nunes|4|290000',
 'Aurora - 1ºD|Sousa|3|194000',       'Aurora - 6ºA|Rocha|2|299000',
 'Aurora - 2ºD|Salgado|2|203000',     'Aurora - 7ºA|Pinto|1|308000'
};
List<Opportunity> ops = new List<Opportunity>();
for (String v : vendasAurora) {
    List<String> c = v.split('\\|');
    ops.add(new Opportunity(Name = c[1] + ' - ' + c[0], RecordTypeId = rtO.get('Venda_Habitacao'),
        AccountId = pa.get(c[1]).Id, Imovel__c = im.get(c[0]).Id, Linha_Negocio__c = 'B2C',
        StageName = 'Escritura Realizada', Amount = Decimal.valueOf(c[3]),
        CloseDate = HOJE.addMonths(-Integer.valueOf(c[2])), OwnerId = MIGUEL,
        CampaignId = cmp.get('particulares').Id));
}
// Vendas B2C da Carla, nos imoveis dispersos
ops.add(new Opportunity(Name='Pinto - Moradia Brito Capelo', RecordTypeId=rtO.get('Venda_Habitacao'),
    AccountId=pa.get('Pinto').Id, Imovel__c=im.get('Moradia T4 - Rua Brito Capelo, Matosinhos').Id,
    Linha_Negocio__c='B2C', StageName='Escritura Realizada', Amount=388000, CloseDate=HOJE.addMonths(-3), OwnerId=CARLA));
ops.add(new Opportunity(Name='Nunes - Moradia Hintze Ribeiro', RecordTypeId=rtO.get('Venda_Habitacao'),
    AccountId=pa.get('Nunes').Id, Imovel__c=im.get('Moradia T3 - Rua Hintze Ribeiro, Leca').Id,
    Linha_Negocio__c='B2C', StageName='Escritura Realizada', Amount=305000, CloseDate=HOJE.addMonths(-5), OwnerId=CARLA));
// Pipeline aberto
ops.add(new Opportunity(Name='Teixeira - T3 Rua do Molhe', RecordTypeId=rtO.get('Venda_Habitacao'),
    AccountId=pa.get('Teixeira').Id, Imovel__c=im.get('Apartamento T3 - Rua do Molhe, Foz').Id,
    Linha_Negocio__c='B2C', StageName='Visita Realizada', CloseDate=HOJE.addDays(75), OwnerId=CARLA,
    CampaignId=cmp.get('particulares').Id));
ops.add(new Opportunity(Name='Almada - Aurora 7ºC', RecordTypeId=rtO.get('Venda_Habitacao'),
    AccountId=pa.get('Almada').Id, Imovel__c=im.get('Aurora - 7ºC').Id, Linha_Negocio__c='B2C',
    StageName='Negociacao', Amount=320000, CloseDate=HOJE.addDays(32), OwnerId=MIGUEL,
    NextStep='Confirmar se a contraproposta foi aceite pela construtora'));
ops.add(new Opportunity(Name='Bastos - Aurora 6ºB', RecordTypeId=rtO.get('Venda_Habitacao'),
    AccountId=pa.get('Bastos').Id, Imovel__c=im.get('Aurora - 6ºB').Id, Linha_Negocio__c='B2C',
    StageName='Proposta Apresentada', Amount=238000, CloseDate=HOJE.addDays(42), OwnerId=MIGUEL,
    CampaignId=cmp.get('particulares').Id));
ops.add(new Opportunity(Name='Ferraz - Aurora 3ºD', RecordTypeId=rtO.get('Venda_Habitacao'),
    AccountId=pa.get('Ferraz').Id, Imovel__c=im.get('Aurora - 3ºD').Id, Linha_Negocio__c='B2C',
    StageName='Interesse Registado', CloseDate=HOJE.addDays(78), OwnerId=MIGUEL));
ops.add(new Opportunity(Name='Salgado - Aurora 5ºA', RecordTypeId=rtO.get('Venda_Habitacao'),
    AccountId=pa.get('Salgado').Id, Imovel__c=im.get('Aurora - 5ºA').Id, Linha_Negocio__c='B2C',
    StageName='CPCV Assinado', Amount=286000, CloseDate=HOJE.addDays(22), OwnerId=MIGUEL));
ops.add(new Opportunity(Name='Nobre Investimentos - Varanda do Douro 1ºA', RecordTypeId=rtO.get('Venda_Habitacao'),
    AccountId=emp.get('nobre').Id, Imovel__c=im.get('Varanda do Douro - 1ºA').Id, Linha_Negocio__c='B2B',
    StageName='Proposta Apresentada', Amount=275000, CloseDate=HOJE.addDays(38), OwnerId=MIGUEL));
ops.add(new Opportunity(Name='Rios - Arrendamento T2 Costa Cabral', RecordTypeId=rtO.get('Arrendamento'),
    AccountId=pa.get('Rios').Id, Imovel__c=im.get('Apartamento T2 - Rua de Costa Cabral, Porto').Id,
    Linha_Negocio__c='B2C', StageName='Proposta Apresentada', Amount=950, CloseDate=HOJE.addDays(17), OwnerId=CARLA,
    CampaignId=cmp.get('matosinhos').Id));
ops.add(new Opportunity(Name='Douro Vale - Terreno Circunvalacao', RecordTypeId=rtO.get('Venda_Terreno'),
    AccountId=emp.get('dourovale').Id, Imovel__c=im.get('Terreno - Estrada da Circunvalacao, Maia').Id,
    Linha_Negocio__c='B2B', StageName='Avaliacao de Viabilidade', CloseDate=HOJE.addDays(108), OwnerId=MIGUEL,
    CampaignId=cmp.get('linkedin').Id));
// Angariacoes
ops.add(new Opportunity(Name='Angariacao - Edificios do Norte (Varanda do Douro)', RecordTypeId=rtO.get('Angariacao'),
    AccountId=emp.get('edificios').Id, Linha_Negocio__c='B2B', StageName='Contrato Assinado', Amount=86000,
    CloseDate=HOJE.addMonths(-2), OwnerId=MIGUEL, CampaignId=cmp.get('linkedin').Id));
ops.add(new Opportunity(Name='Angariacao - Heranca Silva Matos', RecordTypeId=rtO.get('Angariacao'),
    AccountId=emp.get('herdeiros').Id, Linha_Negocio__c='B2C', StageName='Proposta de Mediacao', Amount=14500,
    CloseDate=HOJE.addDays(27), OwnerId=CARLA));
// Perdidos - sem estes a metrica de perdas nao existe
ops.add(new Opportunity(Name='Lopes - Aurora 2ºB', RecordTypeId=rtO.get('Venda_Habitacao'),
    AccountId=pa.get('Lopes').Id, Imovel__c=im.get('Aurora - 2ºB').Id, Linha_Negocio__c='B2C',
    StageName='Perdido', Amount=203000, CloseDate=HOJE.addDays(-40), OwnerId=MIGUEL,
    Motivo_Perda__c='Financiamento recusado'));
ops.add(new Opportunity(Name='Sousa - Aurora 4ºB', RecordTypeId=rtO.get('Venda_Habitacao'),
    AccountId=pa.get('Sousa').Id, Imovel__c=im.get('Aurora - 4ºB').Id, Linha_Negocio__c='B2C',
    StageName='Perdido', Amount=221000, CloseDate=HOJE.addDays(-70), OwnerId=MIGUEL,
    Motivo_Perda__c='Concorrencia'));
ops.add(new Opportunity(Name='Rocha - T3 Rua do Molhe', RecordTypeId=rtO.get('Venda_Habitacao'),
    AccountId=pa.get('Rocha').Id, Imovel__c=im.get('Apartamento T3 - Rua do Molhe, Foz').Id,
    Linha_Negocio__c='B2C', StageName='Perdido', Amount=470000, CloseDate=HOJE.addDays(-25), OwnerId=CARLA,
    Motivo_Perda__c='Preco'));
for (Opportunity o : ops) {
    if (o.Imovel__c != null) o.Angariador__c = angariadorPorImovel.get(o.Imovel__c);
}
insert ops;
System.debug('Negocios: ' + ops.size());

// ===== 8 - ESTADO DOS IMOVEIS ==============================================
// Escrito explicitamente para o estado ficar certo mesmo que os Flows estejam
// desligados. Se estiverem ligados, escrevem o mesmo valor - nao ha conflito.
List<Imovel__c> est = new List<Imovel__c>();
for (String v : vendasAurora) est.add(new Imovel__c(Id=im.get(v.split('\\|')[0]).Id, Estado_Comercial__c='Vendido'));
est.add(new Imovel__c(Id=im.get('Moradia T4 - Rua Brito Capelo, Matosinhos').Id, Estado_Comercial__c='Vendido'));
est.add(new Imovel__c(Id=im.get('Moradia T3 - Rua Hintze Ribeiro, Leca').Id, Estado_Comercial__c='Vendido'));
est.add(new Imovel__c(Id=im.get('Aurora - 5ºA').Id, Estado_Comercial__c='Reservado'));
update est;

// ===== 9 - ATIVIDADE =======================================================
// Sem isto o LastActivityDate fica nulo, as regras de avanco bloqueiam tudo e
// a vista "A Adormecer" aparece vazia.
// nomeNegocio|diasAtras|assunto|nota
List<String> ativ = new List<String>{
 'Teixeira - T3 Rua do Molhe|31|Visita ao apartamento|Gostou muito da luz e da zona. MAS O PREDIO NAO TEM ELEVADOR e a mae dele tem mobilidade reduzida. Disse que sem isso nao avanca.',
 'Almada - Aurora 7ºC|26|Reuniao de negociacao|Contraproposta de 320k entregue a construtora. SEM RESPOSTA HA 26 DIAS.',
 'Bastos - Aurora 6ºB|6|Envio de proposta|Proposta enviada. Quer saber os valores de renda praticados no edificio.',
 'Ferraz - Aurora 3ºD|2|Chamada de primeiro contacto|Interessado. Vai confirmar com o banco antes de agendar visita.',
 'Salgado - Aurora 5ºA|8|Assinatura do CPCV|CPCV assinado, sinal pago. Escritura depende da entrega da obra.',
 'Nobre Investimentos - Varanda do Douro 1ºA|9|Apresentacao do empreendimento|Interessado em duas fracoes se a rentabilidade der acima de 5%.',
 'Rios - Arrendamento T2 Costa Cabral|3|Visita ao apartamento|Gostou. Vai entregar comprovativos e dados do fiador.',
 'Douro Vale - Terreno Circunvalacao|34|Envio do PIP e certidao de teor|Documentacao entregue. Aguarda parecer do conselho. SEM CONTACTO HA 34 DIAS.',
 'Angariacao - Heranca Silva Matos|5|Apresentacao da proposta de mediacao|Tres herdeiros, dois concordam. O terceiro quer avaliacao independente.',
 'Lopes - Aurora 2ºB|45|Comunicacao da recusa do banco|Taxa de esforco acima do limite. Recontactar dentro de 6 meses.',
 'Sousa - Aurora 4ºB|75|Cliente informou que comprou noutra agencia|Perdemos por falta de segundo contacto a tempo.',
 'Rocha - T3 Rua do Molhe|28|Proposta recusada pelo proprietario|Cliente ofereceu 470k, proprietario nao desce de 495k.'
};
Map<String, Id> idPorNome = new Map<String, Id>();
for (Opportunity o : ops) idPorNome.put(o.Name, o.Id);
List<Task> tks = new List<Task>();
for (String a : ativ) {
    List<String> c = a.split('\\|');
    if (!idPorNome.containsKey(c[0])) continue;
    tks.add(new Task(WhatId=idPorNome.get(c[0]), Subject=c[2], Description=c[3], Status='Completed',
        Priority='Normal', ActivityDate=HOJE.addDays(-Integer.valueOf(c[1]))));
}
// Uma tarefa em aberto: a lista de trabalho do consultor nao pode estar vazia
tks.add(new Task(WhatId=idPorNome.get('Almada - Aurora 7ºC'), OwnerId=MIGUEL,
    Subject='Ligar a construtora sobre a contraproposta da Sofia Almada', Status='Not Started', Priority='High',
    ActivityDate=HOJE.addDays(1),
    Description='Negocio parado ha 26 dias. Se nao houver resposta ate sexta, apresentar o 7ºB como alternativa.'));
tks.add(new Task(WhatId=idPorNome.get('Teixeira - T3 Rua do Molhe'), OwnerId=CARLA,
    Subject='Procurar T3 na Foz COM ELEVADOR para o Jorge Teixeira', Status='Not Started', Priority='High',
    ActivityDate=HOJE.addDays(2),
    Description='Nao voltar a mostrar nada sem elevador. Ja recusou por esse motivo.'));
insert tks;

// ===== 10 - LEADS ==========================================================
// nome|apelido|origem|recordType|status|tipologia|zonas|min|max|financiamento|prazo
List<String> lds = new List<String>{
 'Vera|Antunes|Portal Imobiliario|Compra|Novo|T2|Matosinhos|160000|210000|Em analise|3 a 6 meses',
 'Duarte|Machado|Site|Compra|Novo|T3|Foz, Boavista|400000|550000|Pre-aprovado|Menos de 3 meses',
 'Celia|Moura|Referencia|Arrendamento|Novo|T1|Porto|0|800||Menos de 3 meses',
 'Nelson|Faria|Portal Imobiliario|Compra|Em Contacto|T2|Matosinhos|180000|240000|Em analise|3 a 6 meses',
 'Patricia|Lima|Site|Compra|Em Contacto|T3|Matosinhos|250000|320000|Pre-aprovado|Menos de 3 meses',
 'Rodrigo|Seabra|Referencia|Compra|Qualificado|T4+|Foz|500000|700000|Nao necessita|Menos de 3 meses',
 'Carolina|Bento|Site|Arrendamento|Em Contacto|T2|Porto|0|1000||Menos de 3 meses',
 'Fabio|Marinho|Portal Imobiliario|Compra|Nao Qualificado|T3|Foz|180000|220000|Nao iniciado|Sem urgencia'
};
List<Lead> leads = new List<Lead>();
Integer t2 = 913000200;
for (String l : lds) {
    List<String> c = l.split('\\|', -1);
    t2++;
    Lead ld = new Lead(FirstName=c[0], LastName=c[1], Company=c[0] + ' ' + c[1] + ' (Particular)',
        Email=c[0].toLowerCase() + '.' + c[1].toLowerCase() + '@exemplo.pt', Phone=String.valueOf(t2),
        LeadSource=c[2], RecordTypeId=rtL.get(c[3]), Status=c[4],
        Procura_Tipologia__c=c[5], Procura_Zonas__c=c[6], Prazo_Decisao__c=c[10],
        OwnerId = (c[3] == 'Arrendamento') ? CARLA : CARLA);
    if (Decimal.valueOf(c[7]) > 0) ld.Orcamento_Min__c = Decimal.valueOf(c[7]);
    if (Decimal.valueOf(c[8]) > 0) ld.Orcamento_Max__c = Decimal.valueOf(c[8]);
    if (c[9] != '') ld.Financiamento__c = c[9];
    if (c[4] == 'Nao Qualificado') ld.Motivo_Nao_Qualificacao__c = 'Sem capacidade financeira';
    leads.add(ld);
}
// Angariacoes em curso
leads.add(new Lead(FirstName='Armando', LastName='Peixoto', Company='Armando Peixoto (Particular)',
    Email='armando.peixoto@exemplo.pt', Phone='913000301', LeadSource='Referencia',
    RecordTypeId=rtL.get('Angariacao'), Status='Em Contacto', OwnerId=CARLA,
    Imovel_Tipo__c='Apartamento', Imovel_Localizacao__c='Matosinhos', Imovel_Area_m2__c=95,
    Valor_Pretendido__c=230000, Motivo_Venda__c='Mudanca de casa'));
leads.add(new Lead(FirstName='Sonia', LastName='Barreto', Company='Promotora Barreto, Lda',
    Email='sonia@promotorabarreto.pt', Phone='229100700', LeadSource='Campanha',
    RecordTypeId=rtL.get('Angariacao_Empreendimento'), Status='Em Contacto', OwnerId=MIGUEL,
    Nome_Empreendimento__c='Jardins de Ramalde', Numero_Fracoes__c=18, Fase_Obra__c='Em construcao',
    Data_Conclusao_Prevista__c=HOJE.addMonths(9)));
insert leads;

// --- Coorte de latencia ---------------------------------------------------
// As duas metricas que sustentam a tese do projeto - tempo ate atribuir e tempo
// ate ao primeiro contacto - medem a partir da Data de Entrada. Sem ela os leads
// nao tem historia nenhuma para contar e a linha por semana sai vazia.
//
// Por isso cada lead traz a sua Data de Entrada, espalhada por 12 semanas. E um
// campo nosso, e nao o CreatedDate: escrever o CreatedDate exige uma permissao
// que so existe depois de se ligar uma preferencia em Setup, e uma metrica que
// depende de um interruptor e uma metrica que nao se pode demonstrar.
//
// A historia que os numeros contam e a do Case Study, e nao e favoravel: a
// agencia responde tarde. Os leads mais lentos sao os que se perdem, e perdem-se
// com o motivo "Demora no primeiro contacto" - o que faz a formula
// Tipo_de_Perda__c classifica-los como "Era viavel - perdemos".
//
// Um dashboard que so mostra o que corre bem nao serve para decidir nada.
String[] nomes = new String[]{
    'Ines|Ramalho','Tiago|Mendonca','Barbara|Quintas','Andre|Pontes',
    'Leonor|Sarmento','Bruno|Vilela','Matilde|Aguiar','Diogo|Rebelo',
    'Catarina|Frade','Simao|Peres','Mariana|Gouveia','Ricardo|Branco',
    'Alexandra|Lourenco','Vitor|Salgueiro','Ines|Camara','Nuno|Portela',
    'Sara|Vilar','Goncalo|Trindade','Rita|Esteves','Pedro|Cunha',
    'Clara|Antunes','Miguel|Ferreirinha','Joana|Prata','Luis|Botelho'
};
// Horas ate ao primeiro contacto, semana a semana (12 semanas atras -> a semana
// passada). O padrao e deliberado: mau no inicio, a melhorar, mas ainda longe da
// meta de 2 horas. Um -1 e um lead que nunca chegou a ser contactado.
Integer[] horasPorSemana = new Integer[]{ 26, 31, 18, 22, -1, 14, 9, 12, 5, 7, 3, 4 };

List<Lead> coorte = new List<Lead>();
Integer t3 = 913000400;
for (Integer i = 0; i < nomes.size(); i++) {
    List<String> n = nomes[i].split('\\|');
    Integer semana = 12 - Math.mod(i, 12);          // 12 semanas atras ate 1
    Integer horas = horasPorSemana[Math.mod(i, 12)];
    t3++;

    Datetime criado = Datetime.newInstance(HOJE.addDays(-7 * semana), Time.newInstance(9, 15, 0, 0));
    Lead ld = new Lead(
        FirstName = n[0], LastName = n[1],
        Company = n[0] + ' ' + n[1] + ' (Particular)',
        Email = n[0].toLowerCase() + '.' + n[1].toLowerCase() + '@exemplo.pt',
        Phone = String.valueOf(t3),
        LeadSource = (Math.mod(i, 3) == 0) ? 'Site'
                   : (Math.mod(i, 3) == 1) ? 'Portal Imobiliario' : 'Campanha',
        RecordTypeId = rtL.get('Compra'),
        Procura_Tipologia__c = (Math.mod(i, 2) == 0) ? 'T2' : 'T3',
        Procura_Zonas__c = (Math.mod(i, 2) == 0) ? 'Matosinhos' : 'Porto',
        Orcamento_Min__c = 150000, Orcamento_Max__c = 280000,
        Prazo_Decisao__c = 'Menos de 3 meses',
        OwnerId = CARLA,
        Data_Entrada__c = criado);

    // A atribuicao e sempre rapida: a Assignment Rule funciona. O problema nao
    // esta em distribuir, esta em ligar de volta - e e essa a distincao que o
    // dashboard torna visivel.
    ld.Data_Atribuicao__c = criado.addMinutes(2 + Math.mod(i, 4));

    if (horas < 0) {
        ld.Status = 'Nao Qualificado';
        ld.Motivo_Nao_Qualificacao__c = 'Sem resposta';
    } else {
        ld.Data_Primeiro_Contacto__c = criado.addMinutes(horas * 60);
        if (horas > 20) {
            ld.Status = 'Nao Qualificado';
            ld.Motivo_Nao_Qualificacao__c = 'Demora no primeiro contacto';
        } else if (horas > 10) {
            ld.Status = 'Em Contacto';
        } else {
            ld.Status = 'Qualificado';
        }
    }
    coorte.add(ld);
}
insert coorte;
leads.addAll(coorte);

// Ligar leads as campanhas: e isto que responde a pergunta da Ines
List<CampaignMember> cms = new List<CampaignMember>();
for (Lead l : leads) {
    Id cid = null;
    if (l.RecordTypeId == rtL.get('Angariacao_Empreendimento')) cid = cmp.get('linkedin').Id;
    else if (l.LeadSource == 'Site' || l.LeadSource == 'Portal Imobiliario') cid = cmp.get('particulares').Id;
    if (cid != null) cms.add(new CampaignMember(CampaignId=cid, LeadId=l.Id, Status='Sent'));
}
if (!cms.isEmpty()) Database.insert(cms, false);

System.debug('=== SEMEADO ===');
System.debug('Empresas: ' + emp.size() + ' · Pessoas: ' + pa.size() + ' · Contratos: ' + ct.size());
System.debug('Imoveis: ' + imv.size() + ' · Negocios: ' + ops.size() + ' · Atividades: ' + tks.size() + ' · Leads: ' + leads.size());
