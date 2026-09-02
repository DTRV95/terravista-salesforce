/*
 * Preenche Elevador__c e Foto_URL__c em toda a carteira.
 *   sf apex run -f scripts/apex/preencher_carteira.apex -o terravista
 *
 * PORQUE O ELEVADOR IMPORTA
 * Sem este campo, o agente afirmou que um predio tinha elevador porque o cliente
 * queria um. Um modelo preenche sempre uma lacuna com o que soa plausivel.
 * O T3 da Foz fica deliberadamente em 'Nao': e o unico imovel que serve ao Jorge
 * Teixeira em tipologia, zona e orcamento, e o unico que ele nao pode comprar.
 * Esse choque deixa de depender de o modelo adivinhar e passa a assentar num dado.
 *
 * AS FOTOS
 * Unsplash, livres de usar. So nos imoveis da demonstracao: um link partido a
 * frente do juri custa mais do que a foto vale. O terreno fica sem foto de
 * proposito - a unica que havia era de banco de imagens pago.
 */
final String FOTO_PREDIO   = 'https://images.unsplash.com/photo-1670589953882-b94c9cb380f5?q=80&w=1332&auto=format&fit=crop';
final String FOTO_MORADIA  = 'https://images.unsplash.com/photo-1580587771525-78b9dba3b914?q=80&w=1074&auto=format&fit=crop';
final String FOTO_INTERIOR = 'https://images.unsplash.com/photo-1745429523615-2a82c60bfc02?q=80&w=1074&auto=format&fit=crop';

List<Imovel__c> todos = [SELECT Id, Name, Tipo_Imovel__c, Localizacao__c,
                                Elevador__c, Foto_URL__c FROM Imovel__c];
for (Imovel__c i : todos) {
    // --- Elevador ---
    if (i.Tipo_Imovel__c == 'Moradia' || i.Tipo_Imovel__c == 'Terreno') {
        i.Elevador__c = 'Nao aplicavel';
    } else if (i.Name == 'Apartamento T3 - Rua do Molhe, Foz') {
        i.Elevador__c = 'Nao';
    } else {
        i.Elevador__c = 'Sim';
    }

    // --- Fotografia ---
    if (i.Name == 'Apartamento T3 - Rua do Molhe, Foz'
        || i.Name == 'Apartamento T2 - Rua de Costa Cabral, Porto') {
        i.Foto_URL__c = FOTO_INTERIOR;
    } else if (i.Tipo_Imovel__c == 'Moradia') {
        i.Foto_URL__c = FOTO_MORADIA;
    } else if (i.Tipo_Imovel__c == 'Fracao') {
        i.Foto_URL__c = FOTO_PREDIO;
    }
}
update todos;
System.debug('Carteira preenchida: ' + todos.size() + ' imoveis.');
