/**
 * DIAGNOSTICO: porque e que a lead nao converteu.
 *
 * O ConverterLead nunca lanca excepcoes - devolve sucesso falso e uma mensagem.
 * Isso impede o Flow de rebentar, mas tambem faz com que uma falha nao deixe
 * rasto: nem erro, nem email, nem nada. Este script chama a accao a mao e
 * imprime o que o Flow engoliu.
 *
 * Se a conversao correr bem, a lead FICA CONVERTIDA - o script nao e um ensaio.
 */
List<Lead> candidatas = [
    SELECT Id, Name, Status, Company, Imovel_Pretendido__c,
           Data_Primeiro_Contacto__c, Data_Visita_Agendada__c
    FROM Lead
    WHERE IsConverted = false AND Status = 'Visita Agendada'
    ORDER BY LastModifiedDate DESC
    LIMIT 1];

if (candidatas.isEmpty()) {
    System.debug('Nao ha nenhuma lead por converter em "Visita Agendada".');
} else {
    Lead l = candidatas[0];
    System.debug('=== LEAD ===');
    System.debug('Nome: ' + l.Name);
    System.debug('Company: ' + (l.Company == null ? '(em branco - bom, da Person Account)' : l.Company));
    System.debug('1o contacto: ' + l.Data_Primeiro_Contacto__c);
    System.debug('Visita agendada: ' + l.Data_Visita_Agendada__c);
    System.debug('Imovel pretendido: ' + l.Imovel_Pretendido__c);

    ConverterLead.Pedido p = new ConverterLead.Pedido();
    p.leadId = l.Id;
    p.nomeNegocio = l.Name;

    List<ConverterLead.Resultado> r =
        ConverterLead.executar(new List<ConverterLead.Pedido>{ p });

    System.debug('=== RESULTADO ===');
    System.debug('Conseguiu: ' + r[0].sucesso);
    System.debug('Mensagem: ' + r[0].mensagem);
    System.debug('Cliente: ' + r[0].clienteId);
    System.debug('Negocio: ' + r[0].negocioId);
}
