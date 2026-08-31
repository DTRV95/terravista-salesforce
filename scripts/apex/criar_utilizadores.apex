/*
 * Cria os utilizadores das personas e liga a hierarquia de roles.
 * --------------------------------------------------------------------------
 * Correr DEPOIS do deploy das roles:
 *   sf apex run -f scripts/apex/criar_utilizadores.apex -o terravista
 *
 * E re-executavel: se o utilizador ja existir, e ignorado.
 *
 * PORQUE SO DOIS UTILIZADORES PARA SEIS PERSONAS
 * Ha duas licencas livres. Sao gastas em quem PRECISA de ser dono de registos:
 * a Carla (B2C) e o Miguel (B2B) - sem donos diferentes, o grafico de comissoes
 * tem uma barra so. As restantes personas existem no modelo de seguranca:
 * a Direcao e o utilizador do administrador no topo da hierarquia, o Apoio ao
 * Cliente e uma Queue, e Marketing e Recrutamento sao roles.
 * Os departamentos vivem no modelo de seguranca, nao no numero de cadeiras.
 */

final String EMAIL_DONO = 'davidvilaverde@hotmail.com';  // recebe as ativacoes

Id perfilPadrao = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id;
Map<String, Id> roles = new Map<String, Id>();
for (UserRole r : [SELECT Id, DeveloperName FROM UserRole]) roles.put(r.DeveloperName, r.Id);

// ===== 1 · A Direcao e quem ja ca esta =====================================
User admin = [SELECT Id, UserRoleId FROM User WHERE Id = :UserInfo.getUserId()];
if (admin.UserRoleId == null && roles.containsKey('Direcao')) {
    admin.UserRoleId = roles.get('Direcao');
    update admin;
    System.debug('Administrador colocado na role Direcao.');
}

// ===== 2 · Os dois consultores =============================================
List<User> aCriar = new List<User>();
Map<String, String> jaExiste = new Map<String, String>();
for (User u : [SELECT Username FROM User]) jaExiste.put(u.Username.toLowerCase(), u.Username);

// Percentagens diferentes de proposito: o B2C leva uma quota maior por negocio,
// o B2B compensa em volume. E o que torna o grafico de comissoes interessante
// em vez de previsivel.
List<Map<String, Object>> pessoas = new List<Map<String, Object>>{
    new Map<String, Object>{
        'first' => 'Carla', 'last' => 'Bettencourt', 'alias' => 'cbett',
        'user'  => 'carla.bettencourt@terravista-demo-2026.pt',
        'role'  => 'Comercial_B2C', 'pct' => 40
    },
    new Map<String, Object>{
        'first' => 'Miguel', 'last' => 'Andrade', 'alias' => 'mandrade',
        'user'  => 'miguel.andrade@terravista-demo-2026.pt',
        'role'  => 'Comercial_B2B', 'pct' => 30
    }
};

for (Map<String, Object> p : pessoas) {
    String un = (String) p.get('user');
    if (jaExiste.containsKey(un.toLowerCase())) { System.debug('Ja existe: ' + un); continue; }
    aCriar.add(new User(
        FirstName = (String) p.get('first'),
        LastName  = (String) p.get('last'),
        Alias     = ((String) p.get('alias')).left(8),
        Username  = un,
        Email     = EMAIL_DONO,
        ProfileId = perfilPadrao,
        UserRoleId = roles.get((String) p.get('role')),
        Percentagem_Comissao__c = (Integer) p.get('pct'),
        TimeZoneSidKey   = 'Europe/Lisbon',
        LocaleSidKey     = 'pt_PT',
        EmailEncodingKey = 'UTF-8',
        LanguageLocaleKey = 'pt_BR'
    ));
}
if (!aCriar.isEmpty()) insert aCriar;

// ===== 3 · Dar-lhes acesso ao modelo Terravista ============================
Id ps = [SELECT Id FROM PermissionSet WHERE Name = 'Terravista_Acesso_Base' LIMIT 1].Id;
Set<Id> jaTem = new Set<Id>();
for (PermissionSetAssignment a : [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId = :ps]) {
    jaTem.add(a.AssigneeId);
}
List<PermissionSetAssignment> atribuir = new List<PermissionSetAssignment>();
for (User u : aCriar) if (!jaTem.contains(u.Id)) atribuir.add(new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps));
if (!atribuir.isEmpty()) insert atribuir;

// ===== 4 · A Direcao tambem tem quota, para a margem fazer sentido =========
User rita = [SELECT Id, Percentagem_Comissao__c FROM User WHERE Id = :UserInfo.getUserId()];
if (rita.Percentagem_Comissao__c == null) { rita.Percentagem_Comissao__c = 0; update rita; }

System.debug('Criados ' + aCriar.size() + ' utilizadores · ' + atribuir.size() + ' permission sets atribuidos.');
