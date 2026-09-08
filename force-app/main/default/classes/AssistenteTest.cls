/**
 * Testes das accoes de escrita do agente.
 *
 * Cada teste corresponde a uma das tres regras que governam a classe. Numa
 * classe que le, um teste em falta da uma resposta errada; numa classe que
 * escreve, da um registo errado que fica na base de dados.
 */
@IsTest
private class AssistenteTest {

    private static Id rtPessoa {
        get {
            return [SELECT Id FROM RecordType
                    WHERE SobjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;
        }
    }

    @TestSetup
    static void dados() {
        Account dono = new Account(RecordTypeId = rtPessoa,
            FirstName = 'Dono', LastName = 'Teste');
        insert dono;

        Contract c = new Contract(AccountId = dono.Id, Status = 'Draft',
            StartDate = Date.today(), ContractTerm = 12,
            Regime__c = 'Mediacao a Particular', Comissao__c = 0.05);
        insert c;

        insert new Imovel__c(
            Contrato__c = c.Id, Name = 'Apartamento de Teste', Tipo_Imovel__c = 'Apartamento',
            Finalidade__c = 'Venda', Estado_Comercial__c = 'Disponivel',
            Preco__c = 200000, Area_m2__c = 90, Tipologia__c = 'T2',
            Localizacao__c = 'Matosinhos');
    }

    private static AssistenteCriarCliente.PedidoCliente pedidoBase() {
        AssistenteCriarCliente.PedidoCliente p = new AssistenteCriarCliente.PedidoCliente();
        p.primeiroNome = 'Mariana';
        p.apelido = 'Bragança';
        return p;
    }

    // --- Regra 1: procurar antes de criar -------------------------------
    @IsTest
    static void cria_quando_nao_ha_ninguem_parecido() {
        Test.startTest();
        List<AssistenteResposta> r =
            AssistenteCriarCliente.executar(new List<AssistenteCriarCliente.PedidoCliente>{ pedidoBase() });
        Test.stopTest();

        System.assertEquals(true, r[0].sucesso);
        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE LastName = 'Bragança']);
    }

    @IsTest
    static void nao_duplica_quando_ja_existe_o_apelido() {
        insert new Account(RecordTypeId = rtPessoa, FirstName = 'Joana', LastName = 'Bragança');

        List<AssistenteResposta> r =
            AssistenteCriarCliente.executar(new List<AssistenteCriarCliente.PedidoCliente>{ pedidoBase() });

        System.assertEquals(false, r[0].sucesso, 'Nao pode criar sem perguntar');
        System.assert(r[0].mensagem.contains('Ja existe'),
            'Tem de mandar o agente perguntar se e a mesma pessoa');
        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE LastName = 'Bragança'],
            'Continua a haver so uma ficha');
    }

    // --- Regra 2: nao inventar ------------------------------------------
    @IsTest
    static void o_que_nao_foi_dito_fica_em_branco() {
        AssistenteCriarCliente.executar(new List<AssistenteCriarCliente.PedidoCliente>{ pedidoBase() });

        Account a = [SELECT Orcamento_Max__pc, Procura_Zonas__pc, PersonEmail
                     FROM Account WHERE LastName = 'Bragança'];
        System.assertEquals(null, a.Orcamento_Max__pc, 'Ninguem disse o orcamento');
        System.assertEquals(null, a.Procura_Zonas__pc, 'Ninguem disse as zonas');
        System.assertEquals(null, a.PersonEmail, 'Ninguem deu o email');
    }

    @IsTest
    static void sem_nome_completo_nao_cria() {
        AssistenteCriarCliente.PedidoCliente p = new AssistenteCriarCliente.PedidoCliente();
        p.primeiroNome = 'So o primeiro';

        List<AssistenteResposta> r =
            AssistenteCriarCliente.executar(new List<AssistenteCriarCliente.PedidoCliente>{ p });

        System.assertEquals(false, r[0].sucesso);
        System.assert(r[0].mensagem.contains('nome completo'));
    }

    // --- Marcar visita ---------------------------------------------------
    @IsTest
    static void marca_a_visita_e_liga_ao_negocio_em_curso() {
        Account cliente = new Account(RecordTypeId = rtPessoa,
            FirstName = 'Jorge', LastName = 'Visitante');
        insert cliente;
        Imovel__c im = [SELECT Id FROM Imovel__c LIMIT 1];

        Opportunity o = new Opportunity(Name = 'Negocio de teste', AccountId = cliente.Id,
            Imovel__c = im.Id, StageName = 'Interesse Registado',
            CloseDate = Date.today().addDays(30));
        insert o;

        AssistenteMarcarVisita.PedidoVisita p = new AssistenteMarcarVisita.PedidoVisita();
        p.nomeCliente = 'Visitante';
        p.nomeImovel = 'Apartamento de Teste';
        p.quando = Datetime.now().addDays(3);

        Test.startTest();
        List<AssistenteResposta> r =
            AssistenteMarcarVisita.executar(new List<AssistenteMarcarVisita.PedidoVisita>{ p });
        Test.stopTest();

        System.assertEquals(true, r[0].sucesso);
        Event e = [SELECT WhatId, WhoId, EndDateTime, StartDateTime FROM Event LIMIT 1];
        System.assertEquals(o.Id, e.WhatId,
            'Tem de ligar ao negocio: e isso que faz o Flow carimbar a Data da Visita');
        System.assertEquals(45, (e.EndDateTime.getTime() - e.StartDateTime.getTime()) / 60000,
            'Sem duracao dita, 45 minutos');
    }

    @IsTest
    static void sem_data_pergunta_em_vez_de_assumir() {
        AssistenteMarcarVisita.PedidoVisita p = new AssistenteMarcarVisita.PedidoVisita();
        p.nomeCliente = 'Dono';
        p.nomeImovel = 'Apartamento de Teste';

        List<AssistenteResposta> r =
            AssistenteMarcarVisita.executar(new List<AssistenteMarcarVisita.PedidoVisita>{ p });

        System.assertEquals(false, r[0].sucesso);
        System.assert(r[0].mensagem.contains('nao inventes'));
        System.assertEquals(0, [SELECT COUNT() FROM Event]);
    }

    @IsTest
    static void imovel_desconhecido_nao_marca_nada() {
        AssistenteMarcarVisita.PedidoVisita p = new AssistenteMarcarVisita.PedidoVisita();
        p.nomeCliente = 'Dono';
        p.nomeImovel = 'Palacio Que Nao Existe';
        p.quando = Datetime.now().addDays(1);

        List<AssistenteResposta> r =
            AssistenteMarcarVisita.executar(new List<AssistenteMarcarVisita.PedidoVisita>{ p });

        System.assertEquals(false, r[0].sucesso);
        System.assertEquals(0, [SELECT COUNT() FROM Event]);
    }

    // --- Criar tarefa ----------------------------------------------------
    @IsTest
    static void a_tarefa_nasce_aberta() {
        AssistenteCriarTarefa.PedidoTarefa p = new AssistenteCriarTarefa.PedidoTarefa();
        p.nomeCliente = 'Dono';
        p.assunto = 'Ligar a confirmar';
        p.urgente = true;

        Test.startTest();
        List<AssistenteResposta> r =
            AssistenteCriarTarefa.executar(new List<AssistenteCriarTarefa.PedidoTarefa>{ p });
        Test.stopTest();

        System.assertEquals(true, r[0].sucesso);
        Task t = [SELECT Status, Priority, ActivityDate FROM Task LIMIT 1];
        System.assertEquals('Not Started', t.Status,
            'Uma tarefa criada ja concluida dizia que o trabalho estava feito');
        System.assertEquals('High', t.Priority);
        System.assertEquals(Date.today(), t.ActivityDate, 'Sem prazo dito, e para hoje');
    }

    @IsTest
    static void cliente_ambiguo_pergunta_qual() {
        insert new List<Account>{
            new Account(RecordTypeId = rtPessoa, FirstName = 'Ana',  LastName = 'Ambigua'),
            new Account(RecordTypeId = rtPessoa, FirstName = 'Rita', LastName = 'Ambigua')
        };

        AssistenteCriarTarefa.PedidoTarefa p = new AssistenteCriarTarefa.PedidoTarefa();
        p.nomeCliente = 'Ambigua';
        p.assunto = 'Ligar';

        List<AssistenteResposta> r =
            AssistenteCriarTarefa.executar(new List<AssistenteCriarTarefa.PedidoTarefa>{ p });

        System.assertEquals(false, r[0].sucesso);
        System.assert(r[0].mensagem.contains('mais do que um'));
        System.assertEquals(0, [SELECT COUNT() FROM Task]);
    }
}
