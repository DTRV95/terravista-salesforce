import { LightningElement, api } from 'lwc';

/**
 * Desenha os imoveis sugeridos DENTRO da conversa do Agentforce, com fotografia.
 *
 * Sem isto o chat mostra texto e cartoes de registo - nunca uma imagem. Esta e
 * a unica maneira suportada de por a fotografia na conversa, e por isso e a
 * unica parte do projeto que exige um LWC em vez de configuracao.
 *
 * POR CONFIRMAR: o nome da propriedade que recebe o output da accao. A
 * documentacao oficial esteve em baixo (503) quando isto foi escrito, por isso
 * o componente aceita as formas mais provaveis em vez de apostar numa so - um
 * componente que rebenta em silencio no meio de uma demonstracao e pior do que
 * um componente feio.
 */
export default class ImoveisSugeridos extends LightningElement {
    _valor;

    @api
    get value() { return this._valor; }
    set value(v) { this._valor = v; }

    // Alternativa provavel, caso a plataforma injete o output com outro nome.
    @api
    get output() { return this._valor; }
    set output(v) { this._valor = v; }

    get dados() {
        const v = this._valor;
        if (!v) return {};
        return typeof v === 'string' ? JSON.parse(v) : v;
    }

    get cartoes() {
        const imoveis = this.dados.imoveis || [];
        return imoveis.map((i) => ({
            id: i.Id,
            nome: i.Name,
            foto: i.Foto_URL__c,
            link: '/lightning/r/Imovel__c/' + i.Id + '/view',
            detalhe: [
                i.Tipologia__c,
                i.Localizacao__c,
                i.Area_m2__c ? i.Area_m2__c + ' m2' : null,
                i.Elevador__c ? 'elevador: ' + i.Elevador__c : null
            ].filter(Boolean).join(' · '),
            preco: i.Preco__c == null
                ? ''
                : new Intl.NumberFormat('pt-PT', {
                    style: 'currency', currency: 'EUR', maximumFractionDigits: 0
                  }).format(i.Preco__c)
        }));
    }

    get temImoveis() { return this.cartoes.length > 0; }
}
