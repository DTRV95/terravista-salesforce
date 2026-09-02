/**
 * Encontra os imoveis da carteira que servem a um cliente.
 *
 * DIVISAO DE TRABALHO
 * Esta classe faz a parte determinista: filtra a carteira pelos criterios duros
 * e devolve registos REAIS. Nao ordena por "qualidade" nem interpreta nada.
 *
 * A parte de julgar - ler as notas em texto livre e perceber que "elevador e
 * condicao absoluta" elimina um imovel que passa em todos os filtros - fica
 * para o Prompt Template que consome este resultado.
 *
 * O SOQL encontra. O modelo julga e explica.
 * Um modelo de linguagem a quem se pede para encontrar registos inventa
 * registos, e um imovel inventado a frente de um cliente e o fim da confianca
 * no sistema.
 *
 * PORQUE E APEX E NAO UM FLOW
 * O projeto usa configuracao antes de codigo, e esta e a unica excecao com
 * logica de negocio. A razao e concreta: o perfil de procura vive em campos de
 * texto - Procura_Tipologia__pc e um multi-select separado por ponto e virgula,
 * Procura_Zonas__pc e texto livre separado por virgulas. Um Flow nao parte
 * strings. Forcar isso em Flow daria um matching pior e ilegivel.
 * Como Invocable, serve na mesma um Flow, um Prompt Template ou uma Agent Action.
 */
public with sharing class MatchImoveis {

    // Compradores esticam o orcamento. 5% e o que a experiencia do sector diz
    // que se estica sem deixar de ser um negocio possivel.
    private static final Decimal TOLERANCIA_ORCAMENTO = 1.05;
    // ATENCAO: os identificadores em Apex NAO distinguem maiusculas de
    // minusculas. Uma constante MAXIMO e uma variavel local maximo sao o MESMO
    // nome para o compilador, e o local ganha dentro do metodo - sem erro nem
    // aviso. Foi esse o bug: a comparacao do limite de resultados passou a usar
    // o orcamento do cliente. Por isso os nomes sao deliberadamente distintos.
    private static final Integer LIMITE_RESULTADOS = 5;

    public class Pedido {
        @InvocableVariable(label='Id do Cliente' description='Id da conta do cliente. Usa este quando estas na pagina de um cliente. Se so souberes o nome, deixa vazio e preenche o Nome do Cliente.')
        public Id clienteId;

        @InvocableVariable(label='Nome do Cliente' description='Nome ou apelido do cliente, para quando nao se tem o Id. Exemplo: Jorge Teixeira, ou apenas Teixeira.')
        public String nomeCliente;

        @InvocableVariable(label='Finalidade' description='Venda ou Arrendamento. Por omissao, Venda')
        public String finalidade;
    }

    public class Resultado {
        @InvocableVariable(label='Imóveis') public List<Imovel__c> imoveis;
        @InvocableVariable(label='Resumo para o modelo') public String resumo;
        @InvocableVariable(label='Notas do cliente') public String notasCliente;
        @InvocableVariable(label='Total encontrado') public Integer total;
    }

    @InvocableMethod(
        label='Encontrar imóveis para um cliente'
        description='Filtra a carteira disponivel pelos criterios de procura do cliente e devolve os imoveis reais que servem.'
        category='Terravista')
    public static List<Resultado> encontrar(List<Pedido> pedidos) {
        List<Resultado> saida = new List<Resultado>();
        for (Pedido p : pedidos) saida.add(paraUmCliente(p));
        return saida;
    }

    private static Resultado paraUmCliente(Pedido p) {
        Resultado r = new Resultado();
        r.imoveis = new List<Imovel__c>();
        r.total = 0;

        List<Account> contas = resolverCliente(p);
        if (contas.isEmpty()) {
            r.resumo = String.isBlank(p.nomeCliente)
                ? 'Cliente nao encontrado.'
                : 'Nao encontrei nenhum cliente com o nome "' + p.nomeCliente + '".';
            return r;
        }
        if (contas.size() > 1) {
            // Ambiguidade resolve-se PERGUNTANDO, nunca adivinhando. Escolher um
            // ao acaso daria uma resposta confiante sobre o cliente errado.
            List<String> nomes = new List<String>();
            for (Account a : contas) nomes.add(a.Name);
            r.resumo = 'Ha mais do que um cliente com esse nome: ' + String.join(nomes, ', ')
                     + '. Pergunta ao utilizador qual deles.';
            return r;
        }
        Account c = contas[0];
        r.notasCliente = String.isBlank(c.Notas_Preferencias__pc)
            ? 'Sem notas registadas.' : c.Notas_Preferencias__pc;

        String finalidade = String.isBlank(p.finalidade) ? 'Venda' : p.finalidade;
        Decimal minimo = (c.Orcamento_Min__pc == null) ? 0 : c.Orcamento_Min__pc;
        Decimal orcamentoMax = (c.Orcamento_Max__pc == null) ? null
                                                       : c.Orcamento_Max__pc * TOLERANCIA_ORCAMENTO;

        Set<String> tipologias = separar(c.Procura_Tipologia__pc, ';');
        Set<String> zonas = separar(c.Procura_Zonas__pc, ',');

        // Ordena por preco decrescente: dentro do orcamento, o melhor imovel que
        // o cliente consegue pagar. E uma ordem defensavel por omissao - quem a
        // corrige com base nas notas e o modelo, que e quem as sabe ler.
        List<Imovel__c> candidatos = [
            SELECT Id, Name, Tipologia__c, Piso__c, Localizacao__c, Preco__c, Area_m2__c,
                   Tipo_Imovel__c, Dias_Disponivel__c, Elevador__c, Foto_URL__c,
                   Contrato__r.Nome_Empreendimento__c
            FROM Imovel__c
            WHERE Estado_Comercial__c = 'Disponivel'
              AND Finalidade__c = :finalidade
              AND Preco__c >= :minimo
            ORDER BY Preco__c DESC];

        List<String> linhas = new List<String>();
        for (Imovel__c i : candidatos) {
            if (orcamentoMax != null && i.Preco__c > orcamentoMax) continue;
            if (!tipologias.isEmpty() && !tipologias.contains(i.Tipologia__c)) continue;
            if (!zonas.isEmpty() && !zonaServe(i.Localizacao__c, zonas)) continue;

            r.imoveis.add(i);
            linhas.add(descrever(i, c));
            if (r.imoveis.size() == LIMITE_RESULTADOS) break;
        }

        r.total = r.imoveis.size();
        r.resumo = (r.total == 0)
            ? 'Nenhum imovel disponivel corresponde aos criterios de ' + c.Name + '.'
            : String.join(linhas, '\n');
        return r;
    }

    /** Encontra o cliente por Id ou por nome. E SOQL que resolve o nome, nunca o
     *  modelo: pedir a um modelo o Id de um registo e pedir-lhe que o invente. */
    private static List<Account> resolverCliente(Pedido p) {
        if (p.clienteId != null) {
            return [SELECT Id, Name, Procura_Tipologia__pc, Procura_Zonas__pc,
                           Orcamento_Min__pc, Orcamento_Max__pc, Notas_Preferencias__pc,
                           Perfil_Comprador__pc
                    FROM Account WHERE Id = :p.clienteId LIMIT 1];
        }
        if (String.isBlank(p.nomeCliente)) return new List<Account>();
        String padrao = '%' + semAcentos(p.nomeCliente.trim()) + '%';
        return [SELECT Id, Name, Procura_Tipologia__pc, Procura_Zonas__pc,
                       Orcamento_Min__pc, Orcamento_Max__pc, Notas_Preferencias__pc,
                       Perfil_Comprador__pc
                FROM Account WHERE Name LIKE :padrao LIMIT 5];
    }

    /** O LIKE do SOQL e sensivel a acentos: '%Claudia%' encontra a Claudia
     *  Marques, '%Claudia%' com acento agudo nao encontra nada. Quem escreve
     *  portugues a serio escreve com acentos, e o agente passa a pergunta tal e
     *  qual - por isso e aqui que se tira o acento, antes de ir para o SOQL.
     *
     *  Funciona porque os nomes na base estao sem acentos. Se um dia passarem a
     *  ter, isto deixa de chegar: seria preciso normalizar os dois lados, e o
     *  SOQL nao normaliza o campo. */
    private static String semAcentos(String texto) {
        final String acentuadas = '\u00E1\u00E0\u00E2\u00E3\u00E4\u00E9\u00E8\u00EA\u00EB'
            + '\u00ED\u00EC\u00EE\u00EF\u00F3\u00F2\u00F4\u00F5\u00F6'
            + '\u00FA\u00F9\u00FB\u00FC\u00E7';
        final String simples = 'aaaaaeeeeiiiiooooouuuuc';
        String r = texto;
        for (Integer i = 0; i < acentuadas.length(); i++) {
            String a = acentuadas.substring(i, i + 1);
            String b = simples.substring(i, i + 1);
            r = r.replace(a, b).replace(a.toUpperCase(), b.toUpperCase());
        }
        return r;
    }

    /** Um imovel serve a zona se o texto de uma das zonas procuradas aparecer
     *  na localizacao, ou o contrario. "Leca" encontra "Leca da Palmeira". */
    private static Boolean zonaServe(String localizacao, Set<String> zonas) {
        if (String.isBlank(localizacao)) return false;
        String loc = localizacao.toLowerCase();
        for (String z : zonas) {
            if (loc.contains(z) || z.contains(loc)) return true;
        }
        return false;
    }

    private static Set<String> separar(String texto, String separador) {
        Set<String> partes = new Set<String>();
        if (String.isBlank(texto)) return partes;
        for (String s : texto.split(separador)) {
            String limpo = s.trim();
            if (limpo != '') partes.add(separador == ',' ? limpo.toLowerCase() : limpo);
        }
        return partes;
    }

    /** Linha legivel por uma pessoa e utilizavel por um modelo. Inclui o que o
     *  modelo precisa para julgar: preco face ao orcamento e ha quanto tempo
     *  esta parado - um imovel parado ha muito negoceia-se melhor. */
    private static String descrever(Imovel__c i, Account c) {
        String s = '- ' + i.Name + ' | ' + i.Tipologia__c + ' | ' + i.Localizacao__c
                 + ' | ' + i.Area_m2__c + ' m2 | ' + i.Preco__c + ' EUR';
        if (String.isNotBlank(i.Piso__c)) s += ' | piso ' + i.Piso__c;
        // Dito sempre, mesmo quando e 'Por confirmar': o silencio e o que convida
        // o modelo a inventar.
        s += ' | elevador: ' + (String.isBlank(i.Elevador__c) ? 'por confirmar' : i.Elevador__c);
        if (i.Contrato__r != null && String.isNotBlank(i.Contrato__r.Nome_Empreendimento__c)) {
            s += ' | empreendimento ' + i.Contrato__r.Nome_Empreendimento__c;
        }
        if (c.Orcamento_Max__pc != null && i.Preco__c > c.Orcamento_Max__pc) {
            s += ' | ACIMA do orcamento maximo';
        }
        if (i.Dias_Disponivel__c != null && i.Dias_Disponivel__c > 60) {
            s += ' | parado ha ' + i.Dias_Disponivel__c.intValue() + ' dias';
        }
        // O URL vai literal para o resumo porque o chat do Agentforce NAO mostra
        // imagens - mostra texto. Sem isto o modelo nao tem link nenhum para dar,
        // e um modelo sem link inventa um. Vai por ultimo para nao empurrar os
        // dados que interessam ao julgamento para o fim da linha.
        if (String.isNotBlank(i.Foto_URL__c)) s += ' | foto: ' + i.Foto_URL__c;
        return s;
    }
}
