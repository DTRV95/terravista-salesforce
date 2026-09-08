/**
 * A resposta das tres accoes de escrita do agente.
 *
 * Esta partilhada porque as tres devolvem a mesma coisa: o que aconteceu, se
 * correu bem, e o registo criado - para o chat o mostrar como cartao clicavel.
 * Tres copias divergiam no dia em que uma delas ganhasse um campo novo.
 */
public class AssistenteResposta {
    @InvocableVariable(label='Mensagem') @AuraEnabled public String mensagem;
    @InvocableVariable(label='Conseguiu') @AuraEnabled public Boolean sucesso;
    @InvocableVariable(label='Clientes') @AuraEnabled public List<Account> clientes;
    @InvocableVariable(label='Visitas') @AuraEnabled public List<Event> visitas;
    @InvocableVariable(label='Tarefas') @AuraEnabled public List<Task> tarefas;
}
