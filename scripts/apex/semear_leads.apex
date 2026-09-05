/*
 * SEMEAR OS LEADS - a segunda metade do semear_org.apex
 * ==========================================================================
 *   sf apex run -f scripts/apex/semear_leads.apex -o terravista
 *
 * Corre DEPOIS do semear_org.apex, que apaga os leads todos e cria as
 * campanhas e os utilizadores a que estes registos se ligam.
 *
 * PORQUE E QUE ESTA SEPARADO
 * O Apex anonimo nao aceita mais de 32.000 caracteres por execucao. Nao e uma
 * escolha de arquitetura: e um limite da plataforma, e o semear_org passou dele
 * quando ganhou a coorte de latencia.
 */

final Date HOJE = Date.today();

// Este script tem de poder correr sozinho, por isso reencontra tudo o que o
// semear_org deixou na org em vez de assumir que corre no mesmo contexto.
Database.delete([SELECT Id FROM CampaignMember], false);
Database.delete([SELECT Id FROM Lead], false);

Map<String, Id> u = new Map<String, Id>();
for (User x : [SELECT Id, LastName FROM User
               WHERE LastName IN ('Bettencourt','Andrade') AND IsActive = true]) {
    u.put(x.LastName, x.Id);
}
Id CARLA  = u.containsKey('Bettencourt') ? u.get('Bettencourt') : UserInfo.getUserId();
Id MIGUEL = u.containsKey('Andrade')     ? u.get('Andrade')     : UserInfo.getUserId();

Map<String, Id> rtL = new Map<String, Id>();
for (RecordType r : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Lead']) {
    rtL.put(r.DeveloperName, r.Id);
}

Map<String, Campaign> cmp = new Map<String, Campaign>();
for (Campaign c : [SELECT Id, Name FROM Campaign]) {
    if (c.Name.startsWith('Arrendamento')) cmp.put('matosinhos', c);
    else if (c.Name.startsWith('Captacao'))  cmp.put('particulares', c);
    else if (c.Name.startsWith('LinkedIn'))  cmp.put('linkedin', c);
}
if (cmp.size() < 3) {
    System.debug(LoggingLevel.ERROR,
        'Faltam campanhas. Corre o semear_org.apex primeiro.');
}

// nome|apelido|origem|recordType|status|tipologia|zonas|min|max|financiamento|prazo
List<String> lds = new List<String>{
 'Vera|Antunes|Portal Imobiliario|Compra|Novo|T2|Matosinhos|160000|210000|Em analise|3 a 6 meses',
 'Duarte|Machado|Site|Compra|Novo|T3|Foz, Boavista|400000|550000|Pre-aprovado|Menos de 3 meses',
 'Celia|Moura|Referencia|Arrendamento|Novo|T1|Porto|0|800||Menos de 3 meses',
 'Nelson|Faria|Portal Imobiliario|Compra|Em Contacto|T2|Matosinhos|180000|240000|Em analise|3 a 6 meses',
 'Patricia|Lima|Site|Compra|Em Contacto|T3|Matosinhos|250000|320000|Pre-aprovado|Menos de 3 meses',
 'Rodrigo|Seabra|Referencia|Compra|Qualificado|T4+|Foz|500000|700000|Nao necessita|Menos de 3 meses',
 'Carolina|Bento|Site|Arrendamento|Em Contacto|T2|Porto|0|1000||Menos de 3 meses',
 'Fabio|Marinho|Portal Imobiliario|Compra|Nao Qualificado|T3|Foz|180000|220000|Nao iniciado|Sem urgencia'
};
List<Lead> leads = new List<Lead>();
Integer t2 = 913000200;
for (String l : lds) {
    List<String> c = l.split('\\|', -1);
    t2++;
    Lead ld = new Lead(FirstName=c[0], LastName=c[1], Company=c[0] + ' ' + c[1] + ' (Particular)',
        Email=c[0].toLowerCase() + '.' + c[1].toLowerCase() + '@exemplo.pt', Phone=String.valueOf(t2),
        LeadSource=c[2], RecordTypeId=rtL.get(c[3]), Status=c[4],
        Procura_Tipologia__c=c[5], Procura_Zonas__c=c[6], Prazo_Decisao__c=c[10],
        OwnerId = (c[3] == 'Arrendamento') ? CARLA : CARLA);
    if (Decimal.valueOf(c[7]) > 0) ld.Orcamento_Min__c = Decimal.valueOf(c[7]);
    if (Decimal.valueOf(c[8]) > 0) ld.Orcamento_Max__c = Decimal.valueOf(c[8]);
    if (c[9] != '') ld.Financiamento__c = c[9];
    if (c[4] == 'Nao Qualificado') ld.Motivo_Nao_Qualificacao__c = 'Sem capacidade financeira';
    leads.add(ld);
}
// Angariacoes em curso
leads.add(new Lead(FirstName='Armando', LastName='Peixoto', Company='Armando Peixoto (Particular)',
    Email='armando.peixoto@exemplo.pt', Phone='913000301', LeadSource='Referencia',
    RecordTypeId=rtL.get('Angariacao'), Status='Em Contacto', OwnerId=CARLA,
    Imovel_Tipo__c='Apartamento', Imovel_Localizacao__c='Matosinhos', Imovel_Area_m2__c=95,
    Valor_Pretendido__c=230000, Motivo_Venda__c='Mudanca de casa'));
leads.add(new Lead(FirstName='Sonia', LastName='Barreto', Company='Promotora Barreto, Lda',
    Email='sonia@promotorabarreto.pt', Phone='229100700', LeadSource='Campanha',
    RecordTypeId=rtL.get('Angariacao_Empreendimento'), Status='Em Contacto', OwnerId=MIGUEL,
    Nome_Empreendimento__c='Jardins de Ramalde', Numero_Fracoes__c=18, Fase_Obra__c='Em construcao',
    Data_Conclusao_Prevista__c=HOJE.addMonths(9)));
insert leads;

// --- Coorte de latencia ---------------------------------------------------
// As duas metricas que sustentam a tese do projeto - tempo ate atribuir e tempo
// ate ao primeiro contacto - medem a partir da Data de Entrada. Sem ela os leads
// nao tem historia nenhuma para contar e a linha por semana sai vazia.
//
// Por isso cada lead traz a sua Data de Entrada, espalhada por 12 semanas. E um
// campo nosso, e nao o CreatedDate: escrever o CreatedDate exige uma permissao
// que so existe depois de se ligar uma preferencia em Setup, e uma metrica que
// depende de um interruptor e uma metrica que nao se pode demonstrar.
//
// A historia que os numeros contam e a do Case Study, e nao e favoravel: a
// agencia responde tarde. Os leads mais lentos sao os que se perdem, e perdem-se
// com o motivo "Demora no primeiro contacto" - o que faz a formula
// Tipo_de_Perda__c classifica-los como "Era viavel - perdemos".
//
// Um dashboard que so mostra o que corre bem nao serve para decidir nada.
String[] nomes = new String[]{
    'Ines|Ramalho','Tiago|Mendonca','Barbara|Quintas','Andre|Pontes',
    'Leonor|Sarmento','Bruno|Vilela','Matilde|Aguiar','Diogo|Rebelo',
    'Catarina|Frade','Simao|Peres','Mariana|Gouveia','Ricardo|Branco',
    'Alexandra|Lourenco','Vitor|Salgueiro','Ines|Camara','Nuno|Portela',
    'Sara|Vilar','Goncalo|Trindade','Rita|Esteves','Pedro|Cunha',
    'Clara|Antunes','Miguel|Ferreirinha','Joana|Prata','Luis|Botelho'
};
// Horas ate ao primeiro contacto, semana a semana (12 semanas atras -> a semana
// passada). O padrao e deliberado: mau no inicio, a melhorar, mas ainda longe da
// meta de 2 horas. Um -1 e um lead que nunca chegou a ser contactado.
Integer[] horasPorSemana = new Integer[]{ 26, 31, 18, 22, -1, 14, 9, 12, 5, 7, 3, 4 };

List<Lead> coorte = new List<Lead>();
Integer t3 = 913000400;
for (Integer i = 0; i < nomes.size(); i++) {
    List<String> n = nomes[i].split('\\|');
    Integer semana = 12 - Math.mod(i, 12);          // 12 semanas atras ate 1
    Integer horas = horasPorSemana[Math.mod(i, 12)];
    t3++;

    Datetime criado = Datetime.newInstance(HOJE.addDays(-7 * semana), Time.newInstance(9, 15, 0, 0));
    Lead ld = new Lead(
        FirstName = n[0], LastName = n[1],
        Company = n[0] + ' ' + n[1] + ' (Particular)',
        Email = n[0].toLowerCase() + '.' + n[1].toLowerCase() + '@exemplo.pt',
        Phone = String.valueOf(t3),
        LeadSource = (Math.mod(i, 3) == 0) ? 'Site'
                   : (Math.mod(i, 3) == 1) ? 'Portal Imobiliario' : 'Campanha',
        RecordTypeId = rtL.get('Compra'),
        Procura_Tipologia__c = (Math.mod(i, 2) == 0) ? 'T2' : 'T3',
        Procura_Zonas__c = (Math.mod(i, 2) == 0) ? 'Matosinhos' : 'Porto',
        Orcamento_Min__c = 150000, Orcamento_Max__c = 280000,
        Prazo_Decisao__c = 'Menos de 3 meses',
        OwnerId = CARLA,
        Data_Entrada__c = criado);

    // A atribuicao e sempre rapida: a Assignment Rule funciona. O problema nao
    // esta em distribuir, esta em ligar de volta - e e essa a distincao que o
    // dashboard torna visivel.
    ld.Data_Atribuicao__c = criado.addMinutes(2 + Math.mod(i, 4));

    if (horas < 0) {
        ld.Status = 'Nao Qualificado';
        ld.Motivo_Nao_Qualificacao__c = 'Sem resposta';
    } else {
        ld.Data_Primeiro_Contacto__c = criado.addMinutes(horas * 60);
        if (horas > 20) {
            ld.Status = 'Nao Qualificado';
            ld.Motivo_Nao_Qualificacao__c = 'Demora no primeiro contacto';
        } else if (horas > 10) {
            ld.Status = 'Em Contacto';
        } else {
            ld.Status = 'Qualificado';
        }
    }
    coorte.add(ld);
}
insert coorte;
leads.addAll(coorte);

// Ligar leads as campanhas: e isto que responde a pergunta da Ines
List<CampaignMember> cms = new List<CampaignMember>();
for (Lead l : leads) {
    Id cid = null;
    if (l.RecordTypeId == rtL.get('Angariacao_Empreendimento')) cid = cmp.get('linkedin').Id;
    else if (l.LeadSource == 'Site' || l.LeadSource == 'Portal Imobiliario') cid = cmp.get('particulares').Id;
    if (cid != null) cms.add(new CampaignMember(CampaignId=cid, LeadId=l.Id, Status='Sent'));
}
if (!cms.isEmpty()) Database.insert(cms, false);

// O resumo que aqui estava veio agarrado a divisao do ficheiro e falava de
// variaveis que ficaram no semear_org. Este so conta o que este script cria.
System.debug('=== LEADS SEMEADOS ===');
System.debug('Leads: ' + leads.size() + ' · Ligacoes a campanhas: ' + cms.size());
