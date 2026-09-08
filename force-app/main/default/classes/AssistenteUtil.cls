/**
 * O que as tres accoes de escrita partilham.
 *
 * Corre with sharing, como as classes que a chamam: uma classe de apoio sem
 * sharing seria uma porta lateral para o agente ver registos que o consultor
 * nao ve, e a regra e que o agente nao tem privilegios.
 */
public with sharing class AssistenteUtil {

    public static Id idPessoa() {
        return [SELECT Id FROM RecordType
                WHERE SobjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;
    }

    /** Mesma resolucao por nome do matching, incluindo tirar acentos: o LIKE do
     *  SOQL e sensivel a eles e quem escreve portugues escreve com acentos. */
    public static List<Account> clientesPorNome(String nome) {
        if (String.isBlank(nome)) return new List<Account>();
        String padrao = '%' + MatchImoveis.semAcentos(nome.trim()) + '%';
        return [SELECT Id, Name, OwnerId, PersonContactId FROM Account
                WHERE IsPersonAccount = true AND Name LIKE :padrao LIMIT 5];
    }

    public static List<Imovel__c> imoveisPorNome(String nome) {
        if (String.isBlank(nome)) return new List<Imovel__c>();
        String padrao = '%' + MatchImoveis.semAcentos(nome.trim()) + '%';
        return [SELECT Id, Name FROM Imovel__c WHERE Name LIKE :padrao LIMIT 5];
    }

    public static String nomesDe(List<Account> contas) {
        List<String> n = new List<String>();
        for (Account a : contas) n.add(a.Name);
        return String.join(n, ', ');
    }
}
