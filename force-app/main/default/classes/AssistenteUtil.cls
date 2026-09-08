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

    /**
     * Encontra clientes por nome, sem se deixar enganar por acentos.
     *
     * PORQUE E QUE NAO E UM LIKE
     * O LIKE do SOQL e sensivel a acentos, e nao ha forma de o mandar normalizar
     * o campo. Tirar o acento so ao termo procurado resolve metade: encontra
     * "Braganca" escrito com acento contra dados sem acento, mas nao encontra
     * dados COM acento - e desde que o agente cria fichas com o que o consultor
     * ditar, passa a haver acentos na base.
     *
     * Numa verificacao de duplicados, meia solucao e pior do que nenhuma: cria
     * a segunda ficha e ninguem repara.
     *
     * Por isso normaliza-se dos DOIS lados, em Apex. O preco e trazer os
     * clientes para memoria: 200 chegam para esta agencia e para a
     * demonstracao. Numa carteira maior, a resposta certa seria guardar o nome
     * ja normalizado num campo e procurar por ele - o SOQL nao normaliza, mas
     * nos podemos normalizar uma vez, no momento em que se escreve.
     */
    public static List<Account> clientesPorNome(String nome) {
        List<Account> encontrados = new List<Account>();
        if (String.isBlank(nome)) return encontrados;

        String alvo = MatchImoveis.semAcentos(nome.trim()).toLowerCase();
        for (Account a : [SELECT Id, Name, OwnerId, PersonContactId FROM Account
                          WHERE IsPersonAccount = true LIMIT 200]) {
            if (MatchImoveis.semAcentos(a.Name).toLowerCase().contains(alvo)) {
                encontrados.add(a);
                if (encontrados.size() == 5) break;
            }
        }
        return encontrados;
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
