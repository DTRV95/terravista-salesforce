/**
 * Testes do matching. E a unica classe Apex do projeto com logica de negocio,
 * por isso e a unica que precisa mesmo de testes.
 *
 * Cada teste corresponde a uma decisao que a classe toma. Se um dia alguem
 * mudar a tolerancia do orcamento ou a forma de comparar zonas, e aqui que se
 * ve o que se partiu.
 */
@IsTest
private class MatchImoveisTest {

    private static Id rtPessoa {
        get {
            return [SELECT Id FROM RecordType
                    WHERE SobjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;
        }
    }

    private static Account criarComprador(String apelido, String tipologias, String zonas,
                                          Decimal minimo, Decimal maximo, String notas) {
        Account a = new Account(
            RecordTypeId = rtPessoa, FirstName = 'Teste', LastName = apelido,
            Procura_Tipologia__pc = tipologias, Procura_Zonas__pc = zonas,
            Orcamento_Min__pc = minimo, Orcamento_Max__pc = maximo,
            Notas_Preferencias__pc = notas);
        insert a;
        return a;
    }

    private static Imovel__c criarImovel(Id contratoId, String nome, String tipologia,
                                         String zona, Decimal preco) {
        return new Imovel__c(
            Contrato__c = contratoId, Name = nome, Tipo_Imovel__c = 'Apartamento',
            Finalidade__c = 'Venda', Estado_Comercial__c = 'Disponivel',
            Preco__c = preco, Area_m2__c = 100, Tipologia__c = tipologia,
            Localizacao__c = zona);
    }

    @TestSetup
    static void dados() {
        Account proprietario = new Account(RecordTypeId = rtPessoa,
            FirstName = 'Dono', LastName = 'Teste');
        insert proprietario;

        Contract c = new Contract(AccountId = proprietario.Id, Status = 'Draft',
            StartDate = Date.today(), ContractTerm = 12,
            Regime__c = 'Mediacao a Particular');
        insert c;

        insert new List<Imovel__c>{
            criarImovel(c.Id, 'Serve na cheia',        'T3', 'Matosinhos', 250000),
            criarImovel(c.Id, 'Serve esticando 4%',    'T3', 'Matosinhos', 260000),
            criarImovel(c.Id, 'Caro de mais',          'T3', 'Matosinhos', 400000),
            criarImovel(c.Id, 'Tipologia errada',      'T1', 'Matosinhos', 240000),
            criarImovel(c.Id, 'Zona errada',           'T3', 'Braga',      240000),
            criarImovel(c.Id, 'Barato de mais',        'T3', 'Matosinhos', 90000)
        };
    }

    @IsTest
    static void devolve_apenas_o_que_serve() {
        Account comprador = criarComprador('Serve', 'T3', 'Matosinhos', 150000, 250000,
            'Precisa de garagem.');

        MatchImoveis.Pedido p = new MatchImoveis.Pedido();
        p.clienteId = comprador.Id;

        Test.startTest();
        List<MatchImoveis.Resultado> r = MatchImoveis.encontrar(
            new List<MatchImoveis.Pedido>{ p });
        Test.stopTest();

        Set<String> nomes = new Set<String>();
        for (Imovel__c i : r[0].imoveis) nomes.add(i.Name);

        System.assertEquals(2, r[0].total, 'So dois imoveis cumprem os criterios');
        System.assert(nomes.contains('Serve na cheia'), 'O que cabe no orcamento tem de vir');
        System.assert(nomes.contains('Serve esticando 4%'),
            'A tolerancia de 5% deixa passar um imovel 4% acima do maximo');
        System.assert(!nomes.contains('Caro de mais'), 'Muito acima do orcamento fica fora');
        System.assert(!nomes.contains('Tipologia errada'), 'Tipologia diferente fica fora');
        System.assert(!nomes.contains('Zona errada'), 'Zona diferente fica fora');
        System.assert(!nomes.contains('Barato de mais'), 'Abaixo do minimo fica fora');
    }

    @IsTest
    static void ordena_do_mais_caro_para_o_mais_barato() {
        Account comprador = criarComprador('Ordem', 'T3', 'Matosinhos', 150000, 250000, null);
        MatchImoveis.Pedido p = new MatchImoveis.Pedido();
        p.clienteId = comprador.Id;

        List<MatchImoveis.Resultado> r = MatchImoveis.encontrar(
            new List<MatchImoveis.Pedido>{ p });

        System.assertEquals('Serve esticando 4%', r[0].imoveis[0].Name,
            'Dentro do orcamento, o melhor imovel que o cliente consegue pagar vem primeiro');
    }

    @IsTest
    static void zona_parcial_encontra_zona_completa() {
        // "Leca" tem de encontrar "Leca da Palmeira": os consultores nao escrevem
        // sempre o nome completo, e um matching que falha por isso e inutil.
        Contract c = [SELECT Id FROM Contract LIMIT 1];
        insert criarImovel(c.Id, 'Leca completa', 'T3', 'Leca da Palmeira', 240000);

        Account comprador = criarComprador('Zona', 'T3', 'Leca', 150000, 250000, null);
        MatchImoveis.Pedido p = new MatchImoveis.Pedido();
        p.clienteId = comprador.Id;

        List<MatchImoveis.Resultado> r = MatchImoveis.encontrar(
            new List<MatchImoveis.Pedido>{ p });

        System.assertEquals(1, r[0].total, 'A zona parcial tem de encontrar a completa');
    }

    @IsTest
    static void sem_criterios_nao_filtra_por_criterios_vazios() {
        Account comprador = criarComprador('Vazio', null, null, null, null, null);
        MatchImoveis.Pedido p = new MatchImoveis.Pedido();
        p.clienteId = comprador.Id;

        List<MatchImoveis.Resultado> r = MatchImoveis.encontrar(
            new List<MatchImoveis.Pedido>{ p });

        System.assertEquals(5, r[0].total, 'Sem criterios, devolve o maximo de 5');
        System.assertEquals('Sem notas registadas.', r[0].notasCliente);
    }

    @IsTest
    static void encontra_cliente_pelo_nome() {
        criarComprador('Nomeado', 'T3', 'Matosinhos', 150000, 250000, null);

        MatchImoveis.Pedido p = new MatchImoveis.Pedido();
        p.nomeCliente = 'Nomeado';

        List<MatchImoveis.Resultado> r = MatchImoveis.encontrar(
            new List<MatchImoveis.Pedido>{ p });

        System.assertEquals(2, r[0].total,
            'Encontrar pelo nome tem de dar o mesmo que encontrar pelo Id');
    }

    @IsTest
    static void nome_ambiguo_pergunta_em_vez_de_adivinhar() {
        // Dois clientes com o mesmo apelido: escolher um ao acaso daria uma
        // resposta confiante sobre a pessoa errada. Tem de perguntar.
        criarComprador('Ambiguo', 'T3', 'Matosinhos', 150000, 250000, null);
        criarComprador('Ambiguo', 'T2', 'Porto', 100000, 200000, null);

        MatchImoveis.Pedido p = new MatchImoveis.Pedido();
        p.nomeCliente = 'Ambiguo';

        List<MatchImoveis.Resultado> r = MatchImoveis.encontrar(
            new List<MatchImoveis.Pedido>{ p });

        System.assertEquals(0, r[0].total, 'Com ambiguidade nao devolve imoveis');
        System.assert(r[0].resumo.contains('mais do que um'),
            'Tem de dizer ao agente para perguntar qual dos clientes');
    }

    @IsTest
    static void nome_desconhecido_diz_que_nao_encontrou() {
        MatchImoveis.Pedido p = new MatchImoveis.Pedido();
        p.nomeCliente = 'Nao Existe Ninguem Assim';

        List<MatchImoveis.Resultado> r = MatchImoveis.encontrar(
            new List<MatchImoveis.Pedido>{ p });

        System.assertEquals(0, r[0].total);
        System.assert(r[0].resumo.contains('Nao encontrei'));
    }

    @IsTest
    static void o_resumo_leva_o_link_da_foto() {
        // O chat do Agentforce nao mostra imagens. Se o URL nao for no texto, o
        // modelo nao tem link nenhum para dar - e ai inventa um.
        Contract c = [SELECT Id FROM Contract LIMIT 1];
        Imovel__c com = criarImovel(c.Id, 'Com foto', 'T4+', 'Gaia', 200000);
        com.Foto_URL__c = 'https://exemplo.pt/foto.jpg';
        insert com;

        Account comprador = criarComprador('Foto', 'T4+', 'Gaia', 100000, 250000, null);
        MatchImoveis.Pedido p = new MatchImoveis.Pedido();
        p.clienteId = comprador.Id;

        List<MatchImoveis.Resultado> r = MatchImoveis.encontrar(
            new List<MatchImoveis.Pedido>{ p });

        System.assertEquals(1, r[0].total);
        System.assert(r[0].resumo.contains('foto: https://exemplo.pt/foto.jpg'),
            'O resumo tem de levar o URL da fotografia para o modelo o poder dar');
    }

    @IsTest
    static void cliente_inexistente_nao_rebenta() {
        MatchImoveis.Pedido p = new MatchImoveis.Pedido();
        p.clienteId = '001000000000000AAA';

        List<MatchImoveis.Resultado> r = MatchImoveis.encontrar(
            new List<MatchImoveis.Pedido>{ p });

        System.assertEquals(0, r[0].total);
        System.assert(r[0].resumo.contains('nao encontrado'));
    }
}
