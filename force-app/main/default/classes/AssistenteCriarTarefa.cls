/**
 * Accao de escrita do agente: criar uma tarefa para um cliente.
 * As tres regras que a governam estao na AssistenteCriarCliente.
 */
public with sharing class AssistenteCriarTarefa {

    public class PedidoTarefa {
        @InvocableVariable(label='Nome do cliente ou lead' required=true
            description='Nome da pessoa, seja ela cliente ou lead por qualificar.')
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
    public static List<AssistenteResposta> executar(List<PedidoTarefa> pedidos) {
        List<AssistenteResposta> saida = new List<AssistenteResposta>();
        for (PedidoTarefa p : pedidos) saida.add(criarUma(p));
        return saida;
    }

    private static AssistenteResposta criarUma(PedidoTarefa p) {
        AssistenteResposta r = new AssistenteResposta();
        r.sucesso = false;
        r.tarefas = new List<Task>();

        if (String.isBlank(p.assunto)) {
            r.mensagem = 'Falta dizer o que ha a fazer.';
            return r;
        }

        List<AssistenteUtil.Pessoa> pessoas = AssistenteUtil.pessoasPorNome(p.nomeCliente);
        if (pessoas.isEmpty()) {
            r.mensagem = 'Nao encontrei nenhum cliente nem lead com o nome "' + p.nomeCliente + '".';
            return r;
        }
        if (pessoas.size() > 1) {
            r.mensagem = 'Ha mais do que uma pessoa com esse nome: ' + AssistenteUtil.etiquetasDe(pessoas)
                + '. Pergunta qual.';
            return r;
        }
        AssistenteUtil.Pessoa quem = pessoas[0];

        // Nasce ABERTA, sempre. Uma tarefa criada ja concluida diria que o
        // trabalho foi feito quando ainda nem comecou, e dispararia os carimbos
        // de latencia com uma data falsa.
        //
        // O WhoId aponta para a Lead ou para o Contacto escondido da Person
        // Account, conforme o caso - e e o mesmo campo, por isso o Flow que
        // carimba o primeiro contacto continua a ver a tarefa nos dois cenarios.
        Task t = new Task(
            Subject = p.assunto.trim(),
            WhoId = quem.whoId,
            OwnerId = quem.ownerId,
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
        r.mensagem = 'Tarefa criada para ' + quem.etiqueta() + ': ' + t.Subject + '.';
        return r;
    }
}
