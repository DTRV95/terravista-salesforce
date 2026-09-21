/**
 * O que as tres accoes de escrita partilham.
 *
 * Corre with sharing, como as classes que a chamam: uma classe de apoio sem
 * sharing seria uma porta lateral para o agente ver registos que o consultor
 * nao ve, e a regra e que o agente nao tem privilegios.
 */
public with sharing class AssistenteUtil {

    /**
     * Uma pessoa com quem se pode marcar uma visita ou criar uma tarefa.
     *
     * PORQUE E QUE ISTO EXISTE
     * Na Terravista, a mesma pessoa pode estar em dois sitios conforme a fase:
     * Lead enquanto e um contacto por qualificar, Person Account depois de ser
     * cliente. Quem marca a visita nao quer saber disso - quer marcar com a
     * Vera Antunes.
     *
     * Sem esta abstraccao, as accoes de escrita so viam Person Accounts, e a
     * resposta a "marca visita com a Vera Antunes" era que a Vera nao existe.
     * Existia. Era uma Lead. O MatchImoveis ja tinha aprendido isto com a
     * classe Perfil; as accoes de escrita ficaram para tras.
     */
    public class Pessoa {
        public Id registoId;    // o Id da Lead ou da Account
        public Id whoId;        // o que vai para WhoId: Lead.Id ou PersonContactId
        public Id ownerId;
        public String nome;
        public String origem;   // 'Cliente' ou 'Lead'

        public Boolean eLead() { return origem == 'Lead'; }
        public String etiqueta() { return nome + ' (' + origem + ')'; }
    }

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

    /**
     * Procura em Leads por qualificar, com a mesma normalizacao dos dois lados.
     *
     * IsConverted = false NAO E DETALHE
     * Uma lead convertida deixa atras de si a Person Account com o mesmo nome.
     * Sem este filtro, a mesma pessoa aparecia duas vezes e o agente perguntava
     * qual das duas era - uma ambiguidade que nao existe no negocio e que
     * seriamos nos a inventar.
     */
    public static List<Lead> leadsPorNome(String nome) {
        List<Lead> encontrados = new List<Lead>();
        if (String.isBlank(nome)) return encontrados;

        String alvo = MatchImoveis.semAcentos(nome.trim()).toLowerCase();
        for (Lead l : [SELECT Id, Name, OwnerId FROM Lead
                       WHERE IsConverted = false LIMIT 200]) {
            if (MatchImoveis.semAcentos(l.Name).toLowerCase().contains(alvo)) {
                encontrados.add(l);
                if (encontrados.size() == 5) break;
            }
        }
        return encontrados;
    }

    /**
     * Os dois universos juntos, que e como o consultor pensa quando pede para
     * marcar uma visita: pelo nome, sem saber em que objecto a pessoa esta.
     *
     * Os clientes vem primeiro de proposito. Se houver homonimos nos dois
     * lados, a lista devolvida tem mais do que um e quem chama pergunta qual -
     * e a pergunta traz a origem no nome, para a resposta ser possivel.
     */
    public static List<Pessoa> pessoasPorNome(String nome) {
        List<Pessoa> encontrados = new List<Pessoa>();
        if (String.isBlank(nome)) return encontrados;

        for (Account a : clientesPorNome(nome)) {
            Pessoa p = new Pessoa();
            p.registoId = a.Id;
            p.whoId     = a.PersonContactId;
            p.ownerId   = a.OwnerId;
            p.nome      = a.Name;
            p.origem    = 'Cliente';
            encontrados.add(p);
        }
        for (Lead l : leadsPorNome(nome)) {
            Pessoa p = new Pessoa();
            p.registoId = l.Id;
            p.whoId     = l.Id;
            p.ownerId   = l.OwnerId;
            p.nome      = l.Name;
            p.origem    = 'Lead';
            encontrados.add(p);
        }
        return encontrados;
    }

    /**
     * Mesma normalizacao dos dois lados que a clientesPorNome, e pela mesma
     * razao: o LIKE do SOQL e sensivel a acentos, e o nome do imovel chega
     * aqui tal como o consultor o disser.
     */
    public static List<Imovel__c> imoveisPorNome(String nome) {
        List<Imovel__c> encontrados = new List<Imovel__c>();
        if (String.isBlank(nome)) return encontrados;

        String alvo = MatchImoveis.semAcentos(nome.trim()).toLowerCase();
        for (Imovel__c i : [SELECT Id, Name FROM Imovel__c LIMIT 200]) {
            if (MatchImoveis.semAcentos(i.Name).toLowerCase().contains(alvo)) {
                encontrados.add(i);
                if (encontrados.size() == 5) break;
            }
        }
        return encontrados;
    }

    public static String nomesDe(List<Account> contas) {
        List<String> n = new List<String>();
        for (Account a : contas) n.add(a.Name);
        return String.join(n, ', ');
    }

    /**
     * A origem vai no nome. "Ha mais do que uma Vera Antunes" e uma pergunta
     * sem resposta possivel; "a cliente Vera Antunes ou a lead Vera Antunes"
     * responde-se.
     */
    public static String etiquetasDe(List<Pessoa> pessoas) {
        List<String> n = new List<String>();
        for (Pessoa p : pessoas) n.add(p.etiqueta());
        return String.join(n, ', ');
    }
}
