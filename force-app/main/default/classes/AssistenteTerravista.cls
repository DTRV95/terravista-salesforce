/**
 * As acoes de ESCRITA do agente: criar clientes, marcar visitas, criar tarefas.
 *
 * PORQUE E QUE ESTA CLASSE E DIFERENTE DO MatchImoveis
 * O MatchImoveis le. Sugerir um imovel errado e embaracoso e desfaz-se com uma
 * frase. Esta classe escreve, e um cliente duplicado ou uma visita marcada no
 * registo errado nao se desfazem com um pedido de desculpa.
 *
 * AS TRES REGRAS QUE GOVERNAM TUDO O QUE ESTA AQUI
 *
 * 1. NUNCA criar sem procurar primeiro. Se ja existir alguem parecido, pergunta.
 *    E o mesmo principio da ambiguidade no matching: perguntar e sempre melhor
 *    do que adivinhar, e num registo novo o erro fica na base de dados para
 *    sempre.
 *
 * 2. NUNCA inventar valores. O que o consultor nao disser fica em branco. Um
 *    orcamento estimado por um modelo e indistinguivel de um orcamento dito
 *    pelo cliente, e ninguem volta atras para verificar.
 *
 * 3. O agente NAO tem privilegios. Isto corre com sharing e as validation rules
 *    aplicam-se-lhe como a qualquer pessoa. Se o sistema recusa a um consultor,
 *    recusa-lhe a ele - e essa e a resposta a pergunta "e se a IA fizer asneira".
 */
public with sharing class AssistenteTerravista {

    // ===================================================================
    // CRIAR CLIENTE
    // ===================================================================
    public class PedidoCliente {
        @InvocableVariable(label='Primeiro nome' required=true)
        public String primeiroNome;
        @InvocableVariable(label='Apelido' required=true)
        public String apelido;
        @InvocableVariable(label='Email')
        public String email;
        @InvocableVariable(label='Telemovel')
        public String telemovel;
        @InvocableVariable(label='Tipologias que procura' description='Separadas por ponto e virgula. Exemplo: T2;T3')
        public String tipologias;
        @InvocableVariable(label='Zonas que procura' description='Separadas por virgula. Exemplo: Matosinhos, Foz')
        public String zonas;
        @InvocableVariable(label='Orcamento minimo')
        public Decimal orcamentoMin;
        @InvocableVariable(label='Orcamento maximo')
        public Decimal orcamentoMax;
        @InvocableVariable(label='Notas' description='O que o cliente disse por palavras dele. Nao resumir nem interpretar.')
        public String notas;
    }

    public class Resposta {
        @InvocableVariable(label='Mensagem') @AuraEnabled public String mensagem;
        @InvocableVariable(label='Conseguiu') @AuraEnabled public Boolean sucesso;
        @InvocableVariable(label='Clientes') @AuraEnabled public List<Account> clientes;
        @InvocableVariable(label='Visitas') @AuraEnabled public List<Event> visitas;
        @InvocableVariable(label='Tarefas') @AuraEnabled public List<Task> tarefas;
    }

    @InvocableMethod(
        label='Criar cliente particular'
        description='Cria uma ficha de cliente particular. Antes de criar, procura por alguem com o mesmo nome e avisa se encontrar.'
        category='Terravista')
    public static List<Resposta> criarCliente(List<PedidoCliente> pedidos) {
        List<Resposta> saida = new List<Resposta>();
        for (PedidoCliente p : pedidos) saida.add(criarUm(p));
        return saida;
    }

    private static Resposta criarUm(PedidoCliente p) {
        Resposta r = new Resposta();
        r.sucesso = false;
        r.clientes = new List<Account>();

        if (String.isBlank(p.primeiroNome) || String.isBlank(p.apelido)) {
            r.mensagem = 'Falta o nome completo. Pergunta ao utilizador antes de criar.';
            return r;
        }

        // Regra 1: procurar antes de criar.
        String padrao = '%' + MatchImoveis.semAcentos(p.apelido.trim()) + '%';
        List<Account> parecidos = [
            SELECT Id, Name, PersonEmail FROM Account
            WHERE IsPersonAccount = true AND Name LIKE :padrao LIMIT 5];
        if (!parecidos.isEmpty()) {
            List<String> nomes = new List<String>();
            for (Account a : parecidos) nomes.add(a.Name);
            r.clientes = parecidos;
            r.mensagem = 'Ja existe ficha com esse apelido: ' + String.join(nomes, ', ')
                + '. Pergunta ao utilizador se e a mesma pessoa antes de criar outra.';
            return r;
        }

        Account novo = new Account(
            RecordTypeId = idPessoa(),
            FirstName = p.primeiroNome.trim(),
            LastName  = p.apelido.trim());

        // Regra 2: so entra o que foi dito. Um campo vazio e informacao - diz que
        // ninguem perguntou. Um campo preenchido por adivinhacao mente.
        if (String.isNotBlank(p.email))      novo.PersonEmail = p.email.trim();
        if (String.isNotBlank(p.telemovel))  novo.PersonMobilePhone = p.telemovel.trim();
        if (String.isNotBlank(p.tipologias)) novo.Procura_Tipologia__pc = p.tipologias.trim();
        if (String.isNotBlank(p.zonas))      novo.Procura_Zonas__pc = p.zonas.trim();
        if (String.isNotBlank(p.notas))      novo.Notas_Preferencias__pc = p.notas.trim();
        if (p.orcamentoMin != null)          novo.Orcamento_Min__pc = p.orcamentoMin;
        if (p.orcamentoMax != null)          novo.Orcamento_Max__pc = p.orcamentoMax;

        try {
            insert novo;
        } catch (DmlException e) {
            // Regra 3: as regras da org aplicam-se ao agente. A mensagem devolvida
            // e a da propria regra, para o consultor perceber o que faltou.
            r.mensagem = 'Nao foi possivel criar: ' + e.getDmlMessage(0);
            return r;
        }

        r.sucesso = true;
        r.clientes = [SELECT Id, Name, PersonEmail, PersonMobilePhone,
                             Procura_Tipologia__pc, Procura_Zonas__pc,
                             Orcamento_Min__pc, Orcamento_Max__pc
                      FROM Account WHERE Id = :novo.Id];
        r.mensagem = 'Ficha criada para ' + novo.FirstName + ' ' + novo.LastName + '.';
        return r;
    }

    // ===================================================================
    // MARCAR VISITA
    // ===================================================================
    public class PedidoVisita {
        @InvocableVariable(label='Nome do cliente' required=true)
        public String nomeCliente;
        @InvocableVariable(label='Nome do imovel' required=true
            description='Nome do imovel a visitar, como aparece na carteira.')
        public String nomeImovel;
        @InvocableVariable(label='Data e hora' required=true
            description='Quando e a visita. Se o utilizador nao disser a hora, pergunta - nao assumas.')
        public Datetime quando;
        @InvocableVariable(label='Duracao em minutos')
        public Integer duracao;
    }

    @InvocableMethod(
        label='Marcar visita a um imovel'
        description='Cria o evento da visita no calendario, ligado ao cliente e ao imovel. Usa quando alguem pedir para marcar, agendar ou combinar uma visita.'
        category='Terravista')
    public static List<Resposta> marcarVisita(List<PedidoVisita> pedidos) {
        List<Resposta> saida = new List<Resposta>();
        for (PedidoVisita p : pedidos) saida.add(marcarUma(p));
        return saida;
    }

    private static Resposta marcarUma(PedidoVisita p) {
        Resposta r = new Resposta();
        r.sucesso = false;
        r.visitas = new List<Event>();

        if (p.quando == null) {
            r.mensagem = 'Falta a data e a hora. Pergunta ao utilizador - nao inventes.';
            return r;
        }

        List<Account> contas = clientesPorNome(p.nomeCliente);
        if (contas.isEmpty()) {
            r.mensagem = 'Nao encontrei nenhum cliente com o nome "' + p.nomeCliente + '".';
            return r;
        }
        if (contas.size() > 1) {
            r.mensagem = 'Ha mais do que um cliente com esse nome: ' + nomesDe(contas)
                + '. Pergunta qual antes de marcar.';
            return r;
        }
        Account c = contas[0];

        List<Imovel__c> imoveis = imoveisPorNome(p.nomeImovel);
        if (imoveis.isEmpty()) {
            r.mensagem = 'Nao encontrei nenhum imovel com o nome "' + p.nomeImovel + '".';
            return r;
        }
        if (imoveis.size() > 1) {
            List<String> n = new List<String>();
            for (Imovel__c i : imoveis) n.add(i.Name);
            r.mensagem = 'Ha mais do que um imovel com esse nome: ' + String.join(n, ', ')
                + '. Pergunta qual.';
            return r;
        }
        Imovel__c im = imoveis[0];

        // O Evento liga-se ao NEGOCIO quando existe um em curso, e nao ao imovel.
        // E isso que faz o Flow "Carimbar Visita" preencher a Data da Visita, que
        // e o que a validation rule exige para avancar para "Visita Realizada".
        // Ligar ao imovel funcionaria na mesma como registo, mas nao desbloqueava
        // a fase - e a corrente ficava a meio.
        List<Opportunity> negocios = [
            SELECT Id FROM Opportunity
            WHERE AccountId = :c.Id AND Imovel__c = :im.Id AND IsClosed = false
            ORDER BY LastModifiedDate DESC LIMIT 1];

        Event visita = new Event(
            Subject = 'Visita — ' + im.Name,
            WhoId = c.PersonContactId,
            WhatId = negocios.isEmpty() ? im.Id : negocios[0].Id,
            StartDateTime = p.quando,
            EndDateTime = p.quando.addMinutes(p.duracao == null ? 45 : p.duracao),
            Description = 'Marcada pelo assistente a pedido do consultor.');

        try {
            insert visita;
        } catch (DmlException e) {
            r.mensagem = 'Nao foi possivel marcar: ' + e.getDmlMessage(0);
            return r;
        }

        r.sucesso = true;
        r.visitas = [SELECT Id, Subject, StartDateTime, EndDateTime, WhoId, WhatId
                     FROM Event WHERE Id = :visita.Id];
        r.mensagem = 'Visita marcada com ' + c.Name + ' ao ' + im.Name
            + ' em ' + p.quando.format('dd/MM/yyyy \'as\' HH:mm') + '.'
            + (negocios.isEmpty()
               ? ' Nao ha negocio em curso para este imovel - a visita ficou ligada ao imovel.'
               : '');
        return r;
    }

    // ===================================================================
    // CRIAR TAREFA
    // ===================================================================
    public class PedidoTarefa {
        @InvocableVariable(label='Nome do cliente' required=true)
        public String nomeCliente;
        @InvocableVariable(label='O que fazer' required=true
            description='Assunto da tarefa, curto. Exemplo: Ligar a confirmar a visita.')
        public String assunto;
        @InvocableVariable(label='Para quando' description='Data limite. Por omissao, hoje.')
        public Date prazo;
        @InvocableVariable(label='Urgente' description='Verdadeiro se o utilizador disser que e urgente ou prioritario.')
        public Boolean urgente;
    }

    @InvocableMethod(
        label='Criar tarefa para um cliente'
        description='Cria uma tarefa ligada a um cliente. Usa quando alguem pedir para lembrar, agendar um telefonema, ou registar algo a fazer.'
        category='Terravista')
    public static List<Resposta> criarTarefa(List<PedidoTarefa> pedidos) {
        List<Resposta> saida = new List<Resposta>();
        for (PedidoTarefa p : pedidos) saida.add(criarUma(p));
        return saida;
    }

    private static Resposta criarUma(PedidoTarefa p) {
        Resposta r = new Resposta();
        r.sucesso = false;
        r.tarefas = new List<Task>();

        if (String.isBlank(p.assunto)) {
            r.mensagem = 'Falta dizer o que ha a fazer.';
            return r;
        }

        List<Account> contas = clientesPorNome(p.nomeCliente);
        if (contas.isEmpty()) {
            r.mensagem = 'Nao encontrei nenhum cliente com o nome "' + p.nomeCliente + '".';
            return r;
        }
        if (contas.size() > 1) {
            r.mensagem = 'Ha mais do que um cliente com esse nome: ' + nomesDe(contas)
                + '. Pergunta qual.';
            return r;
        }
        Account c = contas[0];

        // Nasce ABERTA, sempre. Uma tarefa criada ja concluida diria que o
        // trabalho foi feito, e o trabalho ainda nao comecou - alem de disparar
        // os carimbos de latencia com uma data falsa.
        Task t = new Task(
            Subject = p.assunto.trim(),
            WhoId = c.PersonContactId,
            OwnerId = c.OwnerId,
            ActivityDate = (p.prazo == null) ? Date.today() : p.prazo,
            Status = 'Not Started',
            Priority = (p.urgente == true) ? 'High' : 'Normal');

        try {
            insert t;
        } catch (DmlException e) {
            r.mensagem = 'Nao foi possivel criar a tarefa: ' + e.getDmlMessage(0);
            return r;
        }

        r.sucesso = true;
        r.tarefas = [SELECT Id, Subject, ActivityDate, Status, Priority, WhoId
                     FROM Task WHERE Id = :t.Id];
        r.mensagem = 'Tarefa criada para ' + c.Name + ': ' + t.Subject + '.';
        return r;
    }

    // ===================================================================
    // O QUE E COMUM
    // ===================================================================
    private static Id idPessoa() {
        return [SELECT Id FROM RecordType
                WHERE SobjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;
    }

    /** Mesma resolucao por nome do matching, incluindo tirar acentos: o LIKE do
     *  SOQL e sensivel a eles e quem escreve portugues escreve com acentos. */
    private static List<Account> clientesPorNome(String nome) {
        if (String.isBlank(nome)) return new List<Account>();
        String padrao = '%' + MatchImoveis.semAcentos(nome.trim()) + '%';
        return [SELECT Id, Name, OwnerId, PersonContactId FROM Account
                WHERE IsPersonAccount = true AND Name LIKE :padrao LIMIT 5];
    }

    private static List<Imovel__c> imoveisPorNome(String nome) {
        if (String.isBlank(nome)) return new List<Imovel__c>();
        String padrao = '%' + MatchImoveis.semAcentos(nome.trim()) + '%';
        return [SELECT Id, Name FROM Imovel__c WHERE Name LIKE :padrao LIMIT 5];
    }

    private static String nomesDe(List<Account> contas) {
        List<String> n = new List<String>();
        for (Account a : contas) n.add(a.Name);
        return String.join(n, ', ');
    }
}
