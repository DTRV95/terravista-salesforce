/**
 * Accao de escrita do agente: criar a ficha de um cliente particular.
 *
 * TRES CLASSES E NAO UMA
 * Uma classe Apex so aceita UM metodo @InvocableMethod. As tres accoes de
 * escrita vivem por isso em tres classes, com a resposta e os helpers em comum
 * na AssistenteResposta e na AssistenteUtil.
 *
 * PORQUE E QUE ESTAS CLASSES SAO DIFERENTES DO MatchImoveis
 * O MatchImoveis le. Sugerir um imovel errado e embaracoso e desfaz-se com uma
 * frase. Estas escrevem, e um cliente duplicado nao se desfaz com um pedido de
 * desculpa.
 *
 * AS TRES REGRAS QUE GOVERNAM AS TRES ACCOES
 *
 * 1. NUNCA criar sem procurar primeiro. Se ja existir alguem parecido, pergunta.
 *    E o mesmo principio da ambiguidade no matching, mas aqui o erro fica na
 *    base de dados para sempre.
 *
 * 2. NUNCA inventar valores. O que o consultor nao disser fica em branco. Um
 *    campo vazio diz que ninguem perguntou; um campo adivinhado mente, e e
 *    indistinguivel de um valor que o cliente disse.
 *
 * 3. O agente NAO tem privilegios. Corre with sharing e as validation rules
 *    aplicam-se-lhe. Se o sistema recusa a um consultor, recusa-lhe a ele.
 */
public with sharing class AssistenteCriarCliente {

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

    @InvocableMethod(
        label='Criar cliente particular'
        description='Cria uma ficha de cliente particular. Antes de criar, procura por alguem com o mesmo apelido e avisa se encontrar.'
        category='Terravista')
    public static List<AssistenteResposta> executar(List<PedidoCliente> pedidos) {
        List<AssistenteResposta> saida = new List<AssistenteResposta>();
        for (PedidoCliente p : pedidos) saida.add(criarUm(p));
        return saida;
    }

    private static AssistenteResposta criarUm(PedidoCliente p) {
        AssistenteResposta r = new AssistenteResposta();
        r.sucesso = false;
        r.clientes = new List<Account>();

        if (String.isBlank(p.primeiroNome) || String.isBlank(p.apelido)) {
            r.mensagem = 'Falta o nome completo. Pergunta ao utilizador antes de criar.';
            return r;
        }

        // Regra 1: procurar antes de criar.
        List<Account> parecidos = AssistenteUtil.clientesPorNome(p.apelido);
        if (!parecidos.isEmpty()) {
            r.clientes = parecidos;
            r.mensagem = 'Ja existe ficha com esse apelido: ' + AssistenteUtil.nomesDe(parecidos)
                + '. Pergunta ao utilizador se e a mesma pessoa antes de criar outra.';
            return r;
        }

        Account novo = new Account(
            RecordTypeId = AssistenteUtil.idPessoa(),
            FirstName = p.primeiroNome.trim(),
            LastName  = p.apelido.trim());

        // Regra 2: so entra o que foi dito.
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
            // Regra 3: devolve a mensagem da propria regra, para o consultor
            // perceber o que faltou em vez de ouvir um erro generico.
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
}
