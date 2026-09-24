// ============================================================
// notas_das_leads.apex
//
// Preenche Notas_Preferencias__c nas leads do lado comprador.
// Antes disto, 33 das 34 leads tinham o campo vazio e a unica
// preenchida dizia "Apartamento T2" - que so repete a tipologia.
//
// PORQUE E QUE ISTO IMPORTA
// A regra da condicao absoluta - recusar um imovel que passa em
// todos os filtros duros porque o cliente disse que alguma coisa
// e inegociavel - le-se DESTE campo. Com o campo vazio, a regra
// existe e nunca dispara: o agente limita-se a listar.
// O silencio nos dados e o que convida um modelo a inventar.
//
// As leads de ANGARIACAO ficam de fora: quem angaria tem imovel
// para vender, nao anda a procura de um.
//
// Chaveado por nome e nao por Id: o semear_leads.apex recria as
// leads e os Ids mudam. Correr as vezes que for preciso.
// ============================================================

Map<String, String> notas = new Map<String, String>{

// --- Arrendamento -------------------------------------------
'Carolina Bento' =>
  'Muda-se do Algarve por trabalho. Precisa de entrar ate ao fim do mes: '
+ 'a data e mais importante do que o estado do apartamento. Aceita sem mobilia.',

'Celia Moura' =>
  'Estudante de medicina, primeiro arrendamento. O fiador e o pai, que vive em '
+ 'Braganca e so consegue vir assinar aos sabados. Quer perto do Hospital de '
+ 'Sao Joao ou com metro directo.',

// --- Compra: condicoes absolutas -----------------------------
'Duarte Machado' =>
  'GARAGEM FECHADA E CONDICAO ABSOLUTA. Tem dois carros classicos e nao os '
+ 'deixa na rua - ja recusou dois imoveis por causa disto. Prefere Foz, aceita '
+ 'Boavista se a garagem for boa. Nao tem pressa nenhuma.',

'Rodrigo Seabra' =>
  'NAO VE NADA SEM VISTA MAR. Vem de Lisboa, vende um T4 em Alges e compra a '
+ 'pronto. Quatro quartos porque tem tres filhos. Disse que prefere pagar mais '
+ 'e esperar do que aceitar vista interior.',

'Patricia Lima' =>
  'RES-DO-CHAO ESTA FORA DE QUESTAO. Foi assaltada no andar terreo da casa '
+ 'anterior. Quer andar alto, e se houver elevador melhor. Decide depressa '
+ 'quando gosta.',

// --- Compra: contexto que muda a abordagem -------------------
'Nelson Faria' =>
  'Primeira casa, casal novo. Orcamento apertado e sem folga nenhuma: o banco '
+ 'aprovou 240 mil e nao ha mais. Nao mostrar nada acima disso, ja se '
+ 'desiludiram uma vez.',

'Matilde Aguiar' =>
  'Compra com a irma, as duas em conjunto. As decisoes demoram porque tem de '
+ 'haver acordo das duas - marcar visitas em que ambas possam vir.',

'Clara Antunes' =>
  'Investidora. Compra para arrendar a estudantes, por isso interessa-lhe a '
+ 'proximidade a faculdade e o numero de quartos, nao o acabamento. Aceita '
+ 'imovel para obras se o preco refletir.',

'Vera Antunes' =>
  'Tem um cao de grande porte. Precisa de condominio que aceite animais ou de '
+ 'espaco exterior - nao e condicao absoluta, mas ja recusou por causa disso.',

'Luis Botelho' =>
  'Divorcio a decorrer. Quer resolver depressa e nao quer voltar a zona onde '
+ 'vivia. Evitar Bonfim e Campanha.',

'Ricardo Branco' =>
  'Trabalha em turnos no hospital. So consegue visitar de manha cedo ou depois '
+ 'das 21h. Nao gosta que lhe liguem a meio da tarde.',

'Ines Camara' =>
  'Vem de Lisboa por transferencia de emprego. Nao conhece o Porto nenhum - '
+ 'precisa que lhe expliquem as zonas, nao so que lhe mostrem casas.',

'Pedro Cunha' =>
  'Ja comprou duas vezes connosco. Sabe exactamente o que quer e nao perde '
+ 'tempo. Se o imovel servir, faz proposta na mesma semana.',

'Rita Esteves' =>
  'Casal com bebe de meses. Quer sossego e perto de creche. Nao aceita imovel '
+ 'que precise de obras - nao ha tempo nem cabeca para isso agora.',

'Miguel Ferreirinha' =>
  'Emigrante em Franca, vem a Portugal de dois em dois meses. Visitas tem de '
+ 'ser concentradas nesses dias, ou por videochamada.',

'Catarina Frade' =>
  'Chegou pela campanha de particulares. Primeira vez que compra sozinha e '
+ 'esta insegura com o processo - explicar cada passo antes de avancar.',

'Mariana Gouveia' =>
  'Quer varanda ampla, e o ponto que mais repete. Cozinha equipada tambem '
+ 'pesa. Aceita andar sem elevador ate ao segundo piso.',

'Simao Peres' =>
  'Compra a pronto, sem credito. Isso da margem para negociar o preco em baixa '
+ 'com o proprietario - usar isso na proposta.',

'Joana Prata' =>
  'Compra para arrendamento de curta duracao. Interessa-lhe licenca de '
+ 'alojamento local ou a possibilidade de a obter. Perguntar sempre ao '
+ 'proprietario antes de mostrar.',

'Barbara Quintas' =>
  'Mae idosa vai viver com o casal. Precisa de tres quartos ou de um espaco '
+ 'que de para adaptar. Elevador pesa muito, mas nao e condicao absoluta se '
+ 'for primeiro andar.',

'Diogo Rebelo' =>
  'Arquitecto. Repara em tudo e nao se deixa impressionar por acabamentos - '
+ 'quer plantas, orientacao solar e area util real, nao area bruta.',

'Goncalo Trindade' =>
  'Anda a ver ha mais de um ano e nunca decide. Mostrar poucos imoveis e bons, '
+ 'nao listas grandes - com opcoes a mais fica paralisado.',

'Bruno Vilela' =>
  'Trabalha em Matosinhos e nao quer mais de 20 minutos de casa ao emprego. '
+ 'Prefere Porto, mas so a zona norte.',

// --- Nao qualificados: a nota explica porque nao avancou ------
'Fabio Marinho' =>
  'Quer T3 na Foz com 220 mil de tecto. Nao existe nada nesse intervalo na '
+ 'Foz, e ele nao aceita mudar de zona nem subir o orcamento. Nao qualificado '
+ 'por desajuste entre expectativa e mercado, nao por falta de interesse.',

'Alexandra Lourenco' =>
  'Credito recusado por dois bancos. Sem financiamento nao ha negocio '
+ 'possivel - voltar a contactar daqui a seis meses.',

'Tiago Mendonca' =>
  'Nunca atendeu nenhuma das quatro chamadas nem respondeu a email. Sem '
+ 'contacto nao ha qualificacao possivel.',

'Andre Pontes' =>
  'Estava so a sondar precos para avaliar a casa dele, nao para comprar. '
+ 'Passar para angariacao se voltar a contactar.',

'Nuno Portela' =>
  'Ja comprou com outra agencia entretanto. Nao qualificado por ter '
+ 'concretizado fora.',

'Ines Ramalho' =>
  'Procura T2 em Matosinhos abaixo de 150 mil, o que nao existe na zona. '
+ 'Recusou ver Leca e Sao Mamede. Expectativa desalinhada com o mercado.',

'Vitor Salgueiro' =>
  'Disse que so avanca depois de vender a casa atual, que ainda nem poz a '
+ 'venda. Sem prazo nenhum - retomar quando houver.',

'Leonor Sarmento' =>
  'Mudou-se para Lisboa entretanto. Ja nao procura no Porto.',

'Sara Vilar' =>
  'Contacto duplicado: e a mesma pessoa que a Ines Ramalho, com email '
+ 'diferente. Marcar como duplicado em vez de trabalhar as duas.'
};

// ------------------------------------------------------------
List<Lead> aGravar = new List<Lead>();
Set<String> naoEncontradas = new Set<String>(notas.keySet());

for (Lead l : [SELECT Id, FirstName, LastName, Notas_Preferencias__c
               FROM Lead WHERE IsConverted = false]) {
    String chave = l.FirstName + ' ' + l.LastName;
    if (!notas.containsKey(chave)) continue;
    naoEncontradas.remove(chave);
    l.Notas_Preferencias__c = notas.get(chave);
    aGravar.add(l);
}

update aGravar;

System.debug(LoggingLevel.ERROR, '=== NOTAS DAS LEADS ===');
System.debug(LoggingLevel.ERROR, 'Gravadas: ' + aGravar.size() + ' de ' + notas.size());
if (!naoEncontradas.isEmpty()) {
    System.debug(LoggingLevel.ERROR, 'NAO ENCONTRADAS NA ORG (nome mudou?): '
        + String.join(new List<String>(naoEncontradas), ', '));
}
// Notas_Preferencias__c e LongTextArea e NAO pode ser filtrado num WHERE: a
// plataforma recusa a query e a classe nem compila - o script inteiro nao
// corre e nao grava nada. Conta-se em memoria sobre as leads em aberto.
Integer semNotas = 0;
for (Lead l : [SELECT Notas_Preferencias__c FROM Lead WHERE IsConverted = false]) {
    if (String.isBlank(l.Notas_Preferencias__c)) semNotas++;
}
System.debug(LoggingLevel.ERROR, 'Leads ainda sem notas: ' + semNotas
    + ' (esperado 2: as duas de angariacao)');
