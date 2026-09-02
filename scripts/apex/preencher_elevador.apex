/*
 * Preenche o Elevador__c em toda a carteira.
 *   sf apex run -f scripts/apex/preencher_elevador.apex -o terravista
 *
 * PORQUE ISTO IMPORTA
 * Sem este campo, o agente afirmou que um predio tinha elevador porque o cliente
 * queria um. Um modelo preenche sempre uma lacuna com o que soa plausivel.
 * O T3 da Foz fica deliberadamente em 'Nao': e o unico imovel que serve ao Jorge
 * Teixeira nos numeros todos, e o unico que ele nao pode comprar. E esse choque
 * que faz a demonstracao valer alguma coisa - deixa de depender de o modelo
 * adivinhar e passa a assentar num dado.
 */
List<Imovel__c> todos = [SELECT Id, Name, Tipo_Imovel__c, Elevador__c FROM Imovel__c];
for (Imovel__c i : todos) {
    if (i.Tipo_Imovel__c == 'Moradia' || i.Tipo_Imovel__c == 'Terreno') {
        i.Elevador__c = 'Nao aplicavel';
    } else if (i.Name == 'Apartamento T3 - Rua do Molhe, Foz') {
        i.Elevador__c = 'Nao';
    } else {
        i.Elevador__c = 'Sim';
    }
}
update todos;
System.debug('Elevador preenchido em ' + todos.size() + ' imoveis.');
