/**
 * Accao de escrita do agente: marcar a visita a um imovel.
 * As tres regras que a governam estao na AssistenteCriarCliente.
 */
public with sharing class AssistenteMarcarVisita {

    public class PedidoVisita {
        @InvocableVariable(label='Nome do cliente ou lead' required=true
            description='Nome da pessoa, seja ela cliente ou lead por qualificar.')
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

        List<AssistenteUtil.Pessoa> pessoas = AssistenteUtil.pessoasPorNome(p.nomeCliente);
        if (pessoas.isEmpty()) {
            r.mensagem = 'Nao encontrei nenhum cliente nem lead com o nome "' + p.nomeCliente + '".';
            return r;
        }
        if (pessoas.size() > 1) {
            r.mensagem = 'Ha mais do que uma pessoa com esse nome: ' + AssistenteUtil.etiquetasDe(pessoas)
                + '. Pergunta qual antes de marcar.';
            return r;
        }
        AssistenteUtil.Pessoa quem = pessoas[0];

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
        //
        // NUMA LEAD NAO HA ESCOLHA A FAZER. A plataforma recusa um Evento que
        // tenha ao mesmo tempo WhoId de Lead e WhatId: uma lead ainda nao esta
        // ligada a negocio nenhum. O WhatId fica nulo, e e o mesmo Flow que
        // carimba - pelo lado da Lead, na Data da Visita Agendada.
        //
        // O QUE MUDOU COM O Imovel_Interesse__c
        // O Evento deixou de apontar para o negocio e passa a apontar para a
        // LINHA DE INTERESSE daquele imovel naquele negocio. Sem isso, mostrar
        // tres imoveis ao mesmo cliente escrevia tres vezes no mesmo
        // Opportunity.Data_Visita__c e sobrava a ultima: o negocio sabia que
        // houve visita, mas nao a que imovel.
        //
        // O carimbo nao se perde - o Flow "Carimbar Visita" passou a dar o
        // salto WhatId -> linha de interesse -> negocio.
        Id alvo = null;
        Boolean temNegocio = false;
        if (!quem.eLead()) {
            List<Opportunity> negocios = [
                SELECT Id FROM Opportunity
                WHERE AccountId = :quem.registoId AND IsClosed = false
                ORDER BY LastModifiedDate DESC LIMIT 1];
            temNegocio = !negocios.isEmpty();
            if (temNegocio) {
                try {
                    alvo = linhaDeInteresse(negocios[0].Id, im.Id);
                } catch (DmlException e) {
                    r.mensagem = 'Nao foi possivel registar o interesse neste imovel: '
                        + e.getDmlMessage(0);
                    return r;
                }
            } else {
                alvo = im.Id;
            }
        }

        Event visita = new Event(
            Subject = 'Visita — ' + im.Name,
            WhoId = quem.whoId,
            WhatId = alvo,
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
        r.mensagem = 'Visita marcada com ' + quem.etiqueta() + ' ao ' + im.Name
            + ' em ' + p.quando.format('dd/MM/yyyy \'as\' HH:mm') + '.'
            + (quem.eLead()
               ? ' E uma lead, por isso a visita ficou ligada a ela e nao a um negocio.'
               : (temNegocio
                  ? ' Ficou registada na lista de imoveis de interesse do negocio.'
                  : ' Nao ha negocio em curso com este cliente - a visita ficou ligada ao imovel.'));
        return r;
    }

    /**
     * A linha de interesse daquele imovel naquele negocio, criada se ainda nao
     * existir. UMA linha por imovel, nunca uma por visita: o estado ("Recusado",
     * "Proposta feita") tem de ter uma verdade unica. As varias visitas ao mesmo
     * imovel sao os Eventos pendurados nesta linha.
     */
    private static Id linhaDeInteresse(Id negocioId, Id imovelId) {
        List<Imovel_Interesse__c> linhas = [
            SELECT Id, Estado__c FROM Imovel_Interesse__c
            WHERE Oportunidade__c = :negocioId AND Imovel__c = :imovelId LIMIT 1];

        if (linhas.isEmpty()) {
            Imovel_Interesse__c nova = new Imovel_Interesse__c(
                Oportunidade__c = negocioId,
                Imovel__c = imovelId,
                Estado__c = 'Visitado');
            insert nova;
            return nova.Id;
        }

        // So se promove a partir de "Sugerido". Escrever "Visitado" por cima de
        // "Recusado" apagava a conclusao com o meio do caminho: uma segunda
        // visita a um imovel recusado nao o torna menos recusado.
        Imovel_Interesse__c linha = linhas[0];
        if (linha.Estado__c == 'Sugerido') {
            linha.Estado__c = 'Visitado';
            update linha;
        }
        return linha.Id;
    }
}
