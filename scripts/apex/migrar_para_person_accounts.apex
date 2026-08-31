/*
 * Migracao: agregados particulares -> Person Accounts
 * --------------------------------------------------------------------------
 * Correr com:  sf apex run -f scripts/apex/migrar_para_person_accounts.apex -o terravista
 *
 * PORQUE E UM TRANSPLANTE E NAO UMA CONVERSAO
 * A Salesforce NAO deixa converter uma conta de empresa em Person Account.
 * Tentar mudar so o RecordTypeId devolve INVALID_PERSON_ACCOUNT_OPERATION, e
 * mudar o RecordTypeId com qualquer outro campo devolve
 * "Cannot specify any additional fields when marrying or separating".
 * Logo: cria-se a pessoa nova, mudam-se os filhos para ela, apaga-se a antiga.
 *
 * SEGURANCA
 * Comeca em modo de teste: MIGRAR_TUDO = false processa APENAS a primeira conta
 * da lista, que nao tem negocios nem contactos. Confirma-se o resultado e so
 * depois se passa a true.
 */

Boolean MIGRAR_TUDO = false;   // <-- passar a true depois de validar o teste

Id rtPessoa = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND IsPersonType = true LIMIT 1].Id;

// Nome atual da conta -> nome proprio da pessoa.
// Varios nomes proprios sao recuperados do que a conta se chamava antes de a
// termos renomeado para "Familia X"; os restantes sao dados de demonstracao.
Map<String, String> primeiroNome = new Map<String, String>{
    'Família Lopes'          => 'Miguel',    // sem negocios - e a conta de teste
    'Família Nunes'          => 'Teresa',
    'Família Rocha'          => 'António',
    'Família Sousa'          => 'Joana',
    'Família Amaral'         => 'Ricardo',
    'Família Correia'        => 'Sandra',
    'Família Marques'        => 'Cláudia',
    'Família Moreira'        => 'Paulo',
    'Família Nogueira'       => 'Beatriz',
    'Família Pinto'          => 'Helena',
    'Família Salgado'        => 'Hugo',
    'Rui e Sofia Cardoso'    => 'Rui',
    'Marta e André Vieira'   => 'Marta',
    'Jorge e Filipa Teixeira'=> 'Jorge'
};
Map<String, String> apelido = new Map<String, String>{
    'Família Lopes'          => 'Lopes',
    'Família Nunes'          => 'Nunes',
    'Família Rocha'          => 'Rocha',
    'Família Sousa'          => 'Sousa',
    'Família Amaral'         => 'Amaral',
    'Família Correia'        => 'Correia',
    'Família Marques'        => 'Marques',
    'Família Moreira'        => 'Moreira',
    'Família Nogueira'       => 'Nogueira',
    'Família Pinto'          => 'Pinto',
    'Família Salgado'        => 'Salgado',
    'Rui e Sofia Cardoso'    => 'Cardoso',
    'Marta e André Vieira'   => 'Vieira',
    'Jorge e Filipa Teixeira'=> 'Teixeira'
};
// Casais: um Person Account representa UMA pessoa. O conjuge fica registado nas
// notas, porque perder essa informacao seria pior do que a guardar em texto.
Map<String, String> conjuge = new Map<String, String>{
    'Rui e Sofia Cardoso'    => 'Compra em conjunto com Sofia Cardoso (conjuge).',
    'Marta e André Vieira'   => 'Compra em conjunto com André Vieira (conjuge).',
    'Jorge e Filipa Teixeira'=> 'Compra em conjunto com Filipa Teixeira (conjuge).'
};

List<String> ordem = new List<String>{
    'Família Lopes', 'Família Nunes', 'Família Rocha', 'Família Sousa',
    'Família Amaral', 'Família Correia', 'Família Marques', 'Família Moreira',
    'Família Nogueira', 'Família Pinto', 'Família Salgado',
    'Rui e Sofia Cardoso', 'Marta e André Vieira', 'Jorge e Filipa Teixeira'
};
if (!MIGRAR_TUDO) ordem = new List<String>{ ordem[0] };

Map<Id, Account> antigas = new Map<Id, Account>(
    [SELECT Id, Name FROM Account WHERE Name IN :ordem AND IsPersonAccount = false]);
if (antigas.isEmpty()) { System.debug('Nada a migrar.'); return; }

// Contactos das contas antigas: e de la que vem o perfil de procura
Map<Id, Contact> contactoPorConta = new Map<Id, Contact>();
for (Contact c : [SELECT Id, AccountId, FirstName, LastName, Email, Phone,
                         Perfil_Comprador__c, Procura_Tipologia__c, Procura_Zonas__c,
                         Orcamento_Min__c, Orcamento_Max__c, Financiamento__c, Notas_Preferencias__c
                  FROM Contact WHERE AccountId IN :antigas.keySet()]) {
    contactoPorConta.put(c.AccountId, c);
}

// ===== 1 · Criar as Person Accounts =========================================
Map<String, Account> novas = new Map<String, Account>();
for (Account a : antigas.values()) {
    Contact c = contactoPorConta.get(a.Id);
    String notas = (c != null && c.Notas_Preferencias__c != null) ? c.Notas_Preferencias__c : '';
    if (conjuge.containsKey(a.Name)) {
        notas = (notas == '' ? '' : notas + ' ') + conjuge.get(a.Name);
    }
    novas.put(a.Name, new Account(
        RecordTypeId = rtPessoa,
        FirstName    = (c != null && c.FirstName != null) ? c.FirstName : primeiroNome.get(a.Name),
        LastName     = apelido.get(a.Name),
        PersonEmail  = (c != null) ? c.Email : null,
        PersonMobilePhone = (c != null) ? c.Phone : null,
        Perfil_Comprador__pc  = (c != null) ? c.Perfil_Comprador__c  : null,
        Procura_Tipologia__pc = (c != null) ? c.Procura_Tipologia__c : null,
        Procura_Zonas__pc     = (c != null) ? c.Procura_Zonas__c     : null,
        Orcamento_Min__pc     = (c != null) ? c.Orcamento_Min__c     : null,
        Orcamento_Max__pc     = (c != null) ? c.Orcamento_Max__c     : null,
        Financiamento__pc     = (c != null) ? c.Financiamento__c     : null,
        Notas_Preferencias__pc = (notas == '' ? null : notas)
    ));
}
insert novas.values();

// ===== 2 · Transplantar os filhos ===========================================
Map<Id, Id> antigaParaNova = new Map<Id, Id>();
for (Account a : antigas.values()) antigaParaNova.put(a.Id, novas.get(a.Name).Id);

List<Opportunity> opps = [SELECT Id, AccountId FROM Opportunity WHERE AccountId IN :antigas.keySet()];
for (Opportunity o : opps) o.AccountId = antigaParaNova.get(o.AccountId);
if (!opps.isEmpty()) update opps;

List<Contract> contratos = [SELECT Id, AccountId FROM Contract WHERE AccountId IN :antigas.keySet()];
for (Contract ct : contratos) ct.AccountId = antigaParaNova.get(ct.AccountId);
if (!contratos.isEmpty()) update contratos;

// ===== 3 · Apagar o que sobra ===============================================
// O contacto antigo desaparece: a Person Account JA E a pessoa. Manter os dois
// seria voltar exatamente ao problema que esta migracao existe para resolver.
if (!contactoPorConta.isEmpty()) delete contactoPorConta.values();
delete antigas.values();

System.debug('Migradas ' + novas.size() + ' contas · ' + opps.size() + ' negocios e '
             + contratos.size() + ' contratos transplantados.'
             + (MIGRAR_TUDO ? '' : '  [MODO DE TESTE - so a primeira conta]'));
