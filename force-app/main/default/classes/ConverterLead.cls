/**
 * A accao "Converter Lead" que o Flow Builder desta org nao tem.
 *
 * PORQUE E QUE ISTO E APEX E NAO CONFIGURACAO
 * A accao standard de conversao nao esta disponivel no Flow Builder aqui.
 * Escreve-se a que falta, e fica com a forma de uma accao qualquer: entra um
 * Id, sai um resultado. O Flow nao sabe que por baixo e Apex.
 *
 * O QUE ESTA CLASSE NAO FAZ, DE PROPOSITO
 * Nao decide QUANDO converter. Essa decisao e do Flow, e o criterio e de
 * negocio: converte-se quando a visita esta agendada, porque uma visita
 * marcada e um facto verificavel e "qualificado" e um juizo que varia de
 * consultor para consultor.
 *
 * A CONVERSAO NAO SE DESFAZ
 * Por isso esta classe nunca lanca excepcoes para o Flow: devolve sucesso
 * falso e uma mensagem. Um Flow que rebenta a meio deixa a lead num estado
 * que ninguem percebe; um Flow que recebe "nao deu, e porque" pode decidir.
 */
public with sharing class ConverterLead {

    public class Pedido {
        @InvocableVariable(label='Id da lead' required=true)
        public String leadId;
        @InvocableVariable(label='Nome do negocio'
            description='Opcional. Sem ele, o Salesforce usa o nome da lead.')
        public String nomeNegocio;
    }

    public class Resultado {
        @InvocableVariable(label='Conseguiu') public Boolean sucesso;
        @InvocableVariable(label='Mensagem') public String mensagem;
        @InvocableVariable(label='Id do negocio') public String negocioId;
        @InvocableVariable(label='Id do cliente') public String clienteId;
    }

    @InvocableMethod(
        label='Converter lead'
        description='Converte a lead em cliente e negocio. Usa quando a visita fica agendada.'
        category='Terravista')
    public static List<Resultado> executar(List<Pedido> pedidos) {

        List<Resultado> saida = new List<Resultado>();
        for (Integer i = 0; i < pedidos.size(); i++) {
            Resultado r = new Resultado();
            r.sucesso = false;
            saida.add(r);
        }

        // O estado de conversao nao se escreve a mao: pergunta-se a org qual e.
        // Fixar "Convertido" no codigo partia-se no dia em que alguem lhe
        // mudasse o nome, e partia-se em silencio.
        List<LeadStatus> convertido = [SELECT MasterLabel FROM LeadStatus
                                       WHERE IsConverted = true LIMIT 1];
        if (convertido.isEmpty()) {
            for (Resultado r : saida) {
                r.mensagem = 'Esta org nao tem nenhum estado de lead marcado como convertido.';
            }
            return saida;
        }

        Set<Id> ids = new Set<Id>();
        for (Pedido p : pedidos) {
            if (String.isNotBlank(p.leadId)) {
                try { ids.add(Id.valueOf(p.leadId)); } catch (Exception e) { /* tratado abaixo */ }
            }
        }
        Map<Id, Lead> leads = ids.isEmpty()
            ? new Map<Id, Lead>()
            : new Map<Id, Lead>([SELECT Id, Name, IsConverted FROM Lead WHERE Id IN :ids]);

        List<Database.LeadConvert> aConverter = new List<Database.LeadConvert>();
        List<Integer> deQuem = new List<Integer>();

        for (Integer i = 0; i < pedidos.size(); i++) {
            Pedido p = pedidos[i];
            Resultado r = saida[i];

            if (String.isBlank(p.leadId)) {
                r.mensagem = 'Falta o Id da lead.';
                continue;
            }
            Id leadId;
            try {
                leadId = Id.valueOf(p.leadId);
            } catch (Exception e) {
                r.mensagem = 'O Id "' + p.leadId + '" nao e um Id valido.';
                continue;
            }
            Lead l = leads.get(leadId);
            if (l == null) {
                r.mensagem = 'Nao encontrei nenhuma lead com esse Id.';
                continue;
            }
            if (l.IsConverted) {
                r.mensagem = 'A lead ' + l.Name + ' ja estava convertida. Nada a fazer.';
                continue;
            }

            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(l.Id);
            lc.setConvertedStatus(convertido[0].MasterLabel);
            lc.setDoNotCreateOpportunity(false);
            if (String.isNotBlank(p.nomeNegocio)) {
                lc.setOpportunityName(p.nomeNegocio.trim());
            }
            aConverter.add(lc);
            deQuem.add(i);
        }

        if (aConverter.isEmpty()) return saida;

        // allOrNone a false: uma lead que falhe nao arrasta as outras, e a
        // razao da falha chega ao Flow em vez de rebentar a transaccao.
        List<Database.LeadConvertResult> resultados =
            Database.convertLead(aConverter, false);

        for (Integer j = 0; j < resultados.size(); j++) {
            Resultado r = saida[deQuem[j]];
            Database.LeadConvertResult lcr = resultados[j];
            if (lcr.isSuccess()) {
                r.sucesso = true;
                r.clienteId = lcr.getAccountId();
                r.negocioId = lcr.getOpportunityId();
                r.mensagem = 'Lead convertida.';
            } else {
                r.mensagem = 'Nao foi possivel converter: ' + lcr.getErrors()[0].getMessage();
            }
        }
        return saida;
    }
}
