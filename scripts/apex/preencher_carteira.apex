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
// URLs servidos pelo proprio Salesforce (Static Resource fotos_imoveis).
// Um URL externo depende da rede da sala e de um servico de terceiros: ja
// falhou duas vezes aqui, e um link partido a frente do juri custa mais do que
// a foto vale.
// O dominio vem da propria org em tempo de execucao. Escrito a mao, o script
// deixava de correr em qualquer outra org - e o projeto tem de poder ser
// reconstruido do zero.
// AS IMAGENS AINDA NAO EXISTEM.
// O Static Resource fotos_imoveis esta criado mas vazio - falta la largar os
// tres ficheiros. Enquanto isso, os URLs apontariam para 404 e o campo de
// formula mostraria o icone de imagem partida em 44 imoveis. Uma foto que nao
// carrega e pior do que nenhuma foto.
//
// Poe isto a true depois de largares predio.jpg, moradia.jpg e interior.jpg em
// force-app/main/default/staticresources/fotos_imoveis/ e fazeres deploy.
final Boolean HA_IMAGENS = false;

final String BASE = URL.getOrgDomainUrl().toExternalForm() + '/resource/fotos_imoveis/';
final String FOTO_PREDIO   = BASE + 'predio.jpg';
final String FOTO_MORADIA  = BASE + 'moradia.jpg';
final String FOTO_INTERIOR = BASE + 'interior.jpg';

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
        if (HA_IMAGENS) i.Foto_URL__c = FOTO_INTERIOR;
    } else if (i.Tipo_Imovel__c == 'Moradia') {
        if (HA_IMAGENS) i.Foto_URL__c = FOTO_MORADIA;
    } else if (i.Tipo_Imovel__c == 'Fracao') {
        if (HA_IMAGENS) i.Foto_URL__c = FOTO_PREDIO;
    }
}
update todos;
System.debug('Carteira preenchida: ' + todos.size() + ' imoveis.');
