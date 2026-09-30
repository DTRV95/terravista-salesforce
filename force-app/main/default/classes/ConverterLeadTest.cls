/**
 * Testes da accao de conversao.
 *
 * Os quatro casos sao os quatro caminhos em que ela NAO converte, mais o que
 * converte. Numa operacao irreversivel, os caminhos de recusa valem mais do
 * que o de sucesso: e neles que se decide se o Flow rebenta ou se explica.
 */
@IsTest
private class ConverterLeadTest {

    private static Lead leadPronta(String primeiro, String apelido) {
        // Company em branco: numa org com Person Accounts, e isso que faz a
        // conversao criar uma pessoa e nao uma empresa.
        // Os dois campos vao preenchidos a nascenca porque as validation rules
        // usam ISCHANGED(Status) - num insert nao disparam, e assim o teste nao
        // depende da ordem por que se escrevem.
        Lead l = new Lead(
            FirstName = primeiro, LastName = apelido,
            Status = 'Visita Agendada',
            Data_Primeiro_Contacto__c = Datetime.now().addHours(-3),
            Data_Visita_Agendada__c = Datetime.now().addDays(2));
        insert l;
        return l;
    }

    private static ConverterLead.Pedido pedido(String id, String nome) {
        ConverterLead.Pedido p = new ConverterLead.Pedido();
        p.leadId = id;
        p.nomeNegocio = nome;
        return p;
    }

    @IsTest
    static void converte_e_devolve_o_negocio_criado() {
        Lead l = leadPronta('Vera', 'Antunes');

        Test.startTest();
        List<ConverterLead.Resultado> r = ConverterLead.executar(
            new List<ConverterLead.Pedido>{ pedido(l.Id, 'Vera Antunes — T3 Foz') });
        Test.stopTest();

        System.assertEquals(true, r[0].sucesso, r[0].mensagem);
        System.assertNotEquals(null, r[0].negocioId, 'Tem de criar negocio');
        System.assertNotEquals(null, r[0].clienteId);
        System.assertEquals(true, [SELECT IsConverted FROM Lead WHERE Id = :l.Id].IsConverted);
        System.assertEquals('Vera Antunes — T3 Foz',
            [SELECT Name FROM Opportunity WHERE Id = :r[0].negocioId].Name,
            'O nome dado tem de chegar ao negocio');
    }

    @IsTest
    static void lead_ja_convertida_explica_em_vez_de_rebentar() {
        Lead l = leadPronta('Joao', 'Repetido');
        ConverterLead.executar(new List<ConverterLead.Pedido>{ pedido(l.Id, null) });

        Test.startTest();
        List<ConverterLead.Resultado> r = ConverterLead.executar(
            new List<ConverterLead.Pedido>{ pedido(l.Id, null) });
        Test.stopTest();

        System.assertEquals(false, r[0].sucesso);
        System.assert(r[0].mensagem.contains('ja estava convertida'),
            'Uma segunda conversao nao pode rebentar o Flow: ' + r[0].mensagem);
    }

    @IsTest
    static void sem_id_nao_faz_nada_e_diz_porque() {
        List<ConverterLead.Resultado> r = ConverterLead.executar(
            new List<ConverterLead.Pedido>{ pedido(null, null) });

        System.assertEquals(false, r[0].sucesso);
        System.assert(r[0].mensagem.contains('Falta o Id'));
    }

    @IsTest
    static void id_que_nao_e_id_nao_rebenta() {
        List<ConverterLead.Resultado> r = ConverterLead.executar(
            new List<ConverterLead.Pedido>{ pedido('isto nao e um id', null) });

        System.assertEquals(false, r[0].sucesso);
        System.assert(r[0].mensagem.contains('nao e um Id valido'), r[0].mensagem);
    }

    @IsTest
    static void id_valido_de_lead_que_nao_existe() {
        Lead l = leadPronta('Apagada', 'Silva');
        Id perdido = l.Id;
        delete l;

        List<ConverterLead.Resultado> r = ConverterLead.executar(
            new List<ConverterLead.Pedido>{ pedido(perdido, null) });

        System.assertEquals(false, r[0].sucesso);
        System.assert(r[0].mensagem.contains('Nao encontrei'), r[0].mensagem);
    }
}
