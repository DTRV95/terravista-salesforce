/**
 * POR O Company EM BRANCO NAS LEADS DE PARTICULAR
 *
 * Numa org com Person Accounts activas, a conversao de uma Lead decide-se por
 * UM campo: se o Company estiver em branco nasce uma Person Account; se
 * estiver preenchido nasce uma Account de empresa com um Contact dentro. Nao
 * ha caixa para escolher.
 *
 * Todas as leads de particular desta org tinham Company preenchido com
 * "<Nome> (Particular)". Converte-las criava empresas chamadas "Miguel
 * Ferreirinha (Particular)" - e o cliente desaparecia do sistema, porque o
 * MatchImoveis e o AssistenteUtil filtram por IsPersonAccount = true e os
 * campos de perfil (Procura_Zonas__pc, Orcamento_Max__pc) so existem em
 * Person Accounts.
 *
 * O criterio e o proprio marcador "(Particular)", e nao o record type: e mais
 * preciso, e deixa de fora a Promotora Barreto, que e mesmo uma empresa.
 */
List<Lead> particulares = [
    SELECT Id, Name, Company
    FROM Lead
    WHERE IsConverted = false AND Company LIKE '%(Particular)'];

System.debug('Leads de particular encontradas: ' + particulares.size());

for (Lead l : particulares) {
    l.Company = null;
}

if (particulares.isEmpty()) {
    System.debug('Nada a fazer.');
} else {
    Database.SaveResult[] r = Database.update(particulares, false);
    Integer ok = 0;
    for (Integer i = 0; i < r.size(); i++) {
        if (r[i].isSuccess()) {
            ok++;
        } else {
            System.debug('FALHOU ' + particulares[i].Name + ': ' + r[i].getErrors()[0].getMessage());
        }
    }
    System.debug('Company limpo em ' + ok + ' de ' + particulares.size() + ' leads.');
    System.debug('A Promotora Barreto e as outras empresas ficam como estavam.');
}

// Confirmacao: quem ainda tem Company preenchido deve ser SO empresa a serio.
for (Lead l : [SELECT Name, Company FROM Lead WHERE IsConverted = false AND Company != null]) {
    System.debug('Continua com Company (tem de ser empresa): ' + l.Name + ' -> ' + l.Company);
}
