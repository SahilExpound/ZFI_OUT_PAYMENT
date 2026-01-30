@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
@UI: {
    headerInfo: {
        typeName: 'Accounting Document',
        typeNamePlural: 'Accounting Document'
    },
    presentationVariant: [
        {
            sortOrder: [
                {
                    by: 'AccountingDocument',
                    direction: #DESC
                }
            ]
        }
    ]
}

define root view entity ZC_OUT_PAYMENT
provider contract transactional_query
  as projection on zi_out_payment
{

    
      @UI.facet: [{ id : 'AccountingDoc',
        purpose: #STANDARD,
        type: #IDENTIFICATION_REFERENCE,
        label: 'Out Payment',
         position: 10 }]


      @UI.lineItem:       [{ position: 10, label: 'AccountingDocument' },{ type: #FOR_ACTION , dataAction: 'ZPRINT', label: 'Generate Print'}]
      @UI.identification: [{ position: 10, label: 'AccountingDocument' }]
      @UI.selectionField: [{ position: 10 }]
  key AccountingDocument,
   @UI.lineItem:       [{ position: 20, label: 'CompanyCode' }]
      @UI.identification: [{ position: 20, label: 'CompanyCode' }]
  key CompanyCode,
    @UI.lineItem:       [{ position: 30, label: 'FiscalYear' }]
      @UI.identification: [{ position: 30, label: 'FiscalYear' }]
   key FiscalYear,
      base64,
      base64_3,
      m_ind
}
