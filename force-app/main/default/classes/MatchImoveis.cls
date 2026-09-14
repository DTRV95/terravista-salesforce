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
 * LEAD E PERSON ACCOUNT, NAO SO PERSON ACCOUNT
 * Um perfil de procura existe dos dois lados: a Lead tem exactamente os mesmos
 * sete campos que o Contact (Procura_Tipologia, Procura_Zonas, Orcamento_Min,
 * Orcamento_Max, Notas_Preferencias, Perfil_Comprador, Financiamento).
 * Procurar so em Person Accounts deixava de fora quem esta em "Visita
 * Agendada" - precisamente o estado em que saber que imovel mostrar e mais
 * urgente. Por isso a classe trabalha sobre um Perfil, e e o SOQL que decide
 * de que objecto o enche.
 *
 * PORQUE E APEX E NAO UM FLOW
 * O projeto usa configuracao antes de codigo, e esta e a unica excecao com
 * logica de negocio. A razao e concreta: o perfil de procura vive em campos de
 * texto - Procura_Tipologia e um multi-select separado por ponto e virgula,
 * Procura_Zonas e texto livre separado por virgulas. Um Flow nao parte
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
    private static final Integer LIMITE_HOMONIMOS = 5;
    private static final Integer LIMITE_VARRIMENTO = 200;

    public class Pedido {
        @InvocableVariable(label='Id do Cliente ou da Lead' description='Id da Person Account ou da Lead. Usa este quando estas na pagina do registo. Se so souberes o nome, deixa vazio e preenche o Nome.')
        public Id clienteId;

        @InvocableVariable(label='Nome do Cliente ou da Lead' description='Nome ou apelido, para quando nao se tem o Id. Procura em clientes e em leads. Exemplo: Jorge Teixeira, ou apenas Teixeira.')
        public String nomeCliente;

        @InvocableVariable(label='Finalidade' description='Venda ou Arrendamento. Por omissao, Venda')
        public String finalidade;
    }

    /**
     * O @AuraEnabled em cada campo nao e decoracao: e o que permite desenhar a
     * resposta no chat com um LWC nosso. A camada que liga uma accao a um custom
     * Lightning type le a classe a procura de @AuraEnabled - com so
     * @InvocableVariable, o output nao chega ao componente e nao ha maneira de
     * mostrar a fotografia dentro da conversa.
     */
    public class Resultado {
        @InvocableVariable(label='Imóveis') @AuraEnabled public List<Imovel__c> imoveis;
        @InvocableVariable(label='Resumo para o modelo') @AuraEnabled public String resumo;
        @InvocableVariable(label='Notas do cliente') @AuraEnabled public String notasCliente;
        @InvocableVariable(label='Total encontrado') @AuraEnabled public Integer total;
    }

    /**
     * Um perfil de procura, venha ele de uma Person Account ou de uma Lead.
     * Existe para que o filtro seja escrito uma vez so: duas copias da mesma
     * regra divergem no dia em que uma delas for corrigida.
     */
    private class Perfil {
        Id registoId;
        String nome;
        String origem;      // 'Cliente' ou 'Lead' - vai para o resumo
        String tipologias;
        String zonas;
        Decimal orcMin;
        Decimal orcMax;
        String notas;
    }

    @InvocableMethod(
        label='Encontrar imóveis para um cliente'
        description='Filtra a carteira disponivel pelos criterios de procura de um cliente ou de uma lead e devolve os imoveis reais que servem.'
        category='Terravista')
    public static List<Resultado> encontrar(List<Pedido> pedidos) {
        List<Resultado> saida = new List<Resultado>();
        for (Pedido p : pedidos) saida.add(paraUmPerfil(p));
        return saida;
    }

    private static Resultado paraUmPerfil(Pedido p) {
        Resultado r = new Resultado();
        r.imoveis = new List<Imovel__c>();
        r.total = 0;

        List<Perfil> perfis = resolverPerfis(p);
        if (perfis.isEmpty()) {
            r.resumo = String.isBlank(p.nomeCliente)
                ? 'Cliente nao encontrado.'
                : 'Nao encontrei nenhum cliente nem nenhuma lead com o nome "'
                  + p.nomeCliente + '".';
            return r;
        }
        if (perfis.size() > 1) {
            // Ambiguidade resolve-se PERGUNTANDO, nunca adivinhando. Escolher um
            // ao acaso daria uma resposta confiante sobre o cliente errado.
            // A origem vai no nome porque a mesma pessoa pode existir como lead
            // por qualificar e como cliente ja qualificado - e nesse caso o
            // consultor tem mesmo de ser ele a dizer qual e que interessa.
            List<String> nomes = new List<String>();
            for (Perfil pf : perfis) nomes.add(pf.nome + ' (' + pf.origem + ')');
            r.resumo = 'Ha mais do que um registo com esse nome: ' + String.join(nomes, ', ')
                     + '. Pergunta ao utilizador qual deles.';
            return r;
        }
        Perfil pf = perfis[0];
        r.notasCliente = String.isBlank(pf.notas) ? 'Sem notas registadas.' : pf.notas;

        String finalidade = String.isBlank(p.finalidade) ? 'Venda' : p.finalidade;
        Decimal minimo = (pf.orcMin == null) ? 0 : pf.orcMin;
        Decimal orcamentoMax = (pf.orcMax == null) ? null : pf.orcMax * TOLERANCIA_ORCAMENTO;

        Set<String> tipologias = separar(pf.tipologias, ';');
        Set<String> zonas = separar(pf.zonas, ',');

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
            linhas.add(descrever(i, pf));
            if (r.imoveis.size() == LIMITE_RESULTADOS) break;
        }

        r.total = r.imoveis.size();
        // A origem vai sempre no resumo, mesmo quando nao ha ambiguidade: o
        // consultor precisa de saber se esta a falar de um cliente qualificado
        // ou de alguem que ainda e uma lead, porque o passo seguinte nao e o
        // mesmo nos dois casos.
        String cabecalho = pf.origem + ': ' + pf.nome;
        r.resumo = (r.total == 0)
            ? cabecalho + '. Nenhum imovel disponivel corresponde aos criterios.'
            : cabecalho + '\n' + String.join(linhas, '\n');
        return r;
    }

    /** Encontra o perfil por Id ou por nome, em Person Accounts e em Leads.
     *  E SOQL que resolve o nome, nunca o modelo: pedir a um modelo o Id de um
     *  registo e pedir-lhe que o invente. */
    private static List<Perfil> resolverPerfis(Pedido p) {
        if (p.clienteId != null) {
            // O Id pode vir do contexto da pagina, nao do utilizador. Numa
            // pagina que nao seja de uma Account nem de uma Lead vem o Id desse
            // outro registo - e a query devolvia zero, que se le como "esta
            // pessoa nao existe". Validar o prefixo antes de confiar nele, e
            // cair para o nome quando nao serve.
            String prefixo = String.valueOf(p.clienteId).substring(0, 3);
            if (prefixo == '001') {
                List<Perfil> achados = dePersonAccounts(
                    [SELECT Id, Name, Procura_Tipologia__pc, Procura_Zonas__pc,
                            Orcamento_Min__pc, Orcamento_Max__pc, Notas_Preferencias__pc
                     FROM Account WHERE Id = :p.clienteId LIMIT 1]);
                if (!achados.isEmpty()) return achados;
            } else if (prefixo == '00Q') {
                List<Perfil> achados = deLeads(
                    [SELECT Id, Name, Procura_Tipologia__c, Procura_Zonas__c,
                            Orcamento_Min__c, Orcamento_Max__c, Notas_Preferencias__c
                     FROM Lead WHERE Id = :p.clienteId AND IsConverted = false LIMIT 1]);
                if (!achados.isEmpty()) return achados;
            }
        }
        if (String.isBlank(p.nomeCliente)) return new List<Perfil>();

        // Normaliza os DOIS lados. Tirar o acento so ao termo procurado resolvia
        // metade: encontrava dados sem acento, nao encontrava dados com acento.
        // Desde que o agente cria fichas com o que o consultor ditar, ha acentos
        // na base - e um cliente que existe e nao e encontrado le-se como um
        // cliente que nao existe.
        String alvo = semAcentos(p.nomeCliente.trim()).toLowerCase();
        List<Perfil> encontrados = new List<Perfil>();

        for (Perfil pf : dePersonAccounts(
                [SELECT Id, Name, Procura_Tipologia__pc, Procura_Zonas__pc,
                        Orcamento_Min__pc, Orcamento_Max__pc, Notas_Preferencias__pc
                 FROM Account WHERE IsPersonAccount = true LIMIT :LIMITE_VARRIMENTO])) {
            if (semAcentos(pf.nome).toLowerCase().contains(alvo)) encontrados.add(pf);
            if (encontrados.size() == LIMITE_HOMONIMOS) return encontrados;
        }

        // IsConverted = false nao e detalhe: uma lead convertida deu origem a
        // uma Person Account com o mesmo nome. Sem este filtro, a mesma pessoa
        // aparecia duas vezes e a classe perguntava qual das duas - uma
        // ambiguidade inventada por nos, sobre um registo que ja nao se usa.
        for (Perfil pf : deLeads(
                [SELECT Id, Name, Procura_Tipologia__c, Procura_Zonas__c,
                        Orcamento_Min__c, Orcamento_Max__c, Notas_Preferencias__c
                 FROM Lead WHERE IsConverted = false LIMIT :LIMITE_VARRIMENTO])) {
            if (semAcentos(pf.nome).toLowerCase().contains(alvo)) encontrados.add(pf);
            if (encontrados.size() == LIMITE_HOMONIMOS) break;
        }
        return encontrados;
    }

    private static List<Perfil> dePersonAccounts(List<Account> contas) {
        List<Perfil> fora = new List<Perfil>();
        for (Account a : contas) {
            Perfil pf = new Perfil();
            pf.registoId  = a.Id;
            pf.nome       = a.Name;
            pf.origem     = 'Cliente';
            pf.tipologias = a.Procura_Tipologia__pc;
            pf.zonas      = a.Procura_Zonas__pc;
            pf.orcMin     = a.Orcamento_Min__pc;
            pf.orcMax     = a.Orcamento_Max__pc;
            pf.notas      = a.Notas_Preferencias__pc;
            fora.add(pf);
        }
        return fora;
    }

    private static List<Perfil> deLeads(List<Lead> leads) {
        List<Perfil> fora = new List<Perfil>();
        for (Lead l : leads) {
            Perfil pf = new Perfil();
            pf.registoId  = l.Id;
            pf.nome       = l.Name;
            pf.origem     = 'Lead';
            pf.tipologias = l.Procura_Tipologia__c;
            pf.zonas      = l.Procura_Zonas__c;
            pf.orcMin     = l.Orcamento_Min__c;
            pf.orcMax     = l.Orcamento_Max__c;
            pf.notas      = l.Notas_Preferencias__c;
            fora.add(pf);
        }
        return fora;
    }

    /** O LIKE do SOQL e sensivel a acentos: '%Claudia%' encontra a Claudia
     *  Marques, '%Claudia%' com acento agudo nao encontra nada. Quem escreve
     *  portugues a serio escreve com acentos, e o agente passa a pergunta tal e
     *  qual - por isso normalizamos os dois lados em Apex, ja que o SOQL nao
     *  normaliza o campo.
     *
     *  Publico porque as accoes de escrita precisam da mesma normalizacao: duas
     *  copias da mesma regra divergem no dia em que uma delas for corrigida. */
    public static String semAcentos(String texto) {
        final String acentuadas = 'áàâãäéèêë'
            + 'íìîïóòôõö'
            + 'úùûüç';
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
    private static String descrever(Imovel__c i, Perfil pf) {
        String s = '- ' + i.Name + ' | ' + i.Tipologia__c + ' | ' + i.Localizacao__c
                 + ' | ' + i.Area_m2__c + ' m2 | ' + i.Preco__c + ' EUR';
        if (String.isNotBlank(i.Piso__c)) s += ' | piso ' + i.Piso__c;
        // Dito sempre, mesmo quando e 'Por confirmar': o silencio e o que convida
        // o modelo a inventar.
        s += ' | elevador: ' + (String.isBlank(i.Elevador__c) ? 'por confirmar' : i.Elevador__c);
        if (i.Contrato__r != null && String.isNotBlank(i.Contrato__r.Nome_Empreendimento__c)) {
            s += ' | empreendimento ' + i.Contrato__r.Nome_Empreendimento__c;
        }
        if (pf.orcMax != null && i.Preco__c > pf.orcMax) {
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
