// Backfill dos campos obrigatorios criados depois dos registos existirem.
// Adicionar um campo obrigatorio com default NAO preenche registos antigos:
// o default so se aplica a registos novos criados pela interface.

// --- Contratos: regime inferido do nome do empreendimento ---
List<Contract> contratos = [SELECT Id, Nome_Empreendimento__c FROM Contract WHERE Regime__c = null];
for (Contract c : contratos) {
    c.Regime__c = String.isBlank(c.Nome_Empreendimento__c)
        ? 'Mediacao a Particular'
        : 'Comercializacao de Empreendimento';
}
update contratos;
System.debug('Contratos atualizados: ' + contratos.size());

// --- Imoveis: finalidade e data de disponibilizacao ---
List<Imovel__c> imoveis = [
    SELECT Id, Name, Tipologia__c, Estado_Comercial__c, Finalidade__c, Localizacao__c
    FROM Imovel__c
];
for (Imovel__c i : imoveis) {
    if (i.Finalidade__c == null) i.Finalidade__c = 'Venda';

    // So faz sentido datar o que esta disponivel
    if (i.Estado_Comercial__c == 'Disponivel') {
        if (i.Name.startsWith('Aurora')) {
            // Tipologias maiores foram libertadas depois do lancamento
            i.Data_Disponibilizacao__c = (i.Tipologia__c == 'T3' || i.Tipologia__c == 'T4+')
                ? Date.newInstance(2026, 7, 15)
                : Date.newInstance(2026, 5, 4);
        } else if (i.Localizacao__c != null && i.Localizacao__c.contains('Foz')) {
            i.Data_Disponibilizacao__c = Date.newInstance(2026, 6, 15);
        } else {
            i.Data_Disponibilizacao__c = Date.newInstance(2026, 7, 2);
        }
    }
}
update imoveis;
System.debug('Imoveis atualizados: ' + imoveis.size());
