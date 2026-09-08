/**
 * Accao de escrita do agente: marcar a visita a um imovel.
 * As tres regras que a governam estao na AssistenteCriarCliente.
 */
public with sharing class AssistenteMarcarVisita {

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
        description='Cria o evento da visita no calendario, ligado ao cliente e ao negocio. Usa quando alguem pedir para marcar, agendar ou combinar uma visita.'
        category='Terravista')
    public static List<AssistenteResposta> executar(List<PedidoVisita> pedidos) {
        List<AssistenteResposta> saida = new List<AssistenteResposta>();
        for (PedidoVisita p : pedidos) saida.add(marcarUma(p));
        return saida;
    }

    private static AssistenteResposta marcarUma(PedidoVisita p) {
        AssistenteResposta r = new AssistenteResposta();
        r.sucesso = false;
        r.visitas = new List<Event>();

        if (p.quando == null) {
            r.mensagem = 'Falta a data e a hora. Pergunta ao utilizador - nao inventes.';
            return r;
        }

        List<Account> contas = AssistenteUtil.clientesPorNome(p.nomeCliente);
        if (contas.isEmpty()) {
            r.mensagem = 'Nao encontrei nenhum cliente com o nome "' + p.nomeCliente + '".';
            return r;
        }
        if (contas.size() > 1) {
            r.mensagem = 'Ha mais do que um cliente com esse nome: ' + AssistenteUtil.nomesDe(contas)
                + '. Pergunta qual antes de marcar.';
            return r;
        }
        Account c = contas[0];

        List<Imovel__c> imoveis = AssistenteUtil.imoveisPorNome(p.nomeImovel);
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
        // Ligar ao imovel registava a visita na mesma, mas nao desbloqueava a
        // fase - e a corrente ficava a meio.
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
}
