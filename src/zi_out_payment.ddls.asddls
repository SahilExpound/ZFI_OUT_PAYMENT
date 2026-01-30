@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view'
@Metadata.allowExtensions: true 
define root view entity zi_out_payment
as select  from I_AccountingDocumentJournal( P_Language: $session.system_language ) as a 
left outer join  ztb_out_payment as b on a.AccountingDocument = b.accountingdocument
{
    key a.AccountingDocument,
    key a.CompanyCode,
     key a.FiscalYear,
        b.base64,
        b.base64_3,
        b.m_ind
}
where a.AccountingDocumentItem = '001' 
and   a.AccountingDocumentType = 'DZ'
