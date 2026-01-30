CLASS zcl_out_payment DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS get_pdf_64
      IMPORTING
                VALUE(io_accountingdoc) TYPE i_accountingdocumentjournal-AccountingDocument    "<-write your input name and type
      RETURNING VALUE(pdf_64)           TYPE string..

  PRIVATE SECTION.

    METHODS build_xml
      IMPORTING
        VALUE(io_accountingdoc) TYPE  i_accountingdocumentjournal-AccountingDocument  "<-write your input name and type
      RETURNING
        VALUE(rv_xml)           TYPE string.
ENDCLASS.



CLASS zcl_out_payment IMPLEMENTATION.


  METHOD get_pdf_64.

    DATA(lv_xml) = build_xml(
                      io_accountingdoc = io_accountingdoc ). " <- input param

    IF lv_xml IS INITIAL.
      RETURN.
    ENDIF.

    CALL METHOD zadobe_call=>format_xml
      EXPORTING
        xmldata    = lv_xml
      IMPORTING
        result_xml = lv_xml.

    CALL METHOD zadobe_call=>getpdf
      EXPORTING
        template = 'zfi_out_payment/zfi_out_payment'
        xmldata  = lv_xml
      RECEIVING
        result   = DATA(lv_result).

    IF lv_result IS NOT INITIAL.
      pdf_64 = lv_result.
    ENDIF.

  ENDMETHOD. " get_pdf_64


  METHOD build_xml.

    " local variables
    DATA: lv_company_add       TYPE i_companycode-AddressID,
          lv_doc_no            TYPE i_accountingdocumentjournal-AccountingDocument,
          lv_doc_date          TYPE string,
          lv_cust_name         TYPE i_businesspartner-BusinessPartnerName,
          lv_comp_city         TYPE i_companycode-CityName,
          lv_comp_country      TYPE i_companycode-Country,
          lv_comp_addr         TYPE i_companycode-AddressID,
          lv_comp_name         TYPE i_companycode-CompanyCodeName,
          lv_payment_date      TYPE string,
          lv_amount            TYPE I_journalentryitem-AmountInCompanyCodeCurrency,
          lv_bank              TYPE i_bank_2-BankName,
          lv_bank_acc          TYPE  i_housebank-BankInternalID,
          lv_comp_addr1        TYPE string,
          lv_comp_addr2        TYPE string,
          lv_cust_cityname     TYPE string,
          lv_cust_cityfull     TYPE string,
          lv_cust_districtfull TYPE string,
          lv_cust_postalcode   TYPE string,
          lv_cust_street       TYPE string,
          lv_cust_streetname   TYPE string,
          lv_comp_addr_2       TYPE string,
          lv_reference         TYPE string,
          lv_remark            TYPE string,
          lv_contact           TYPE string.

    " fetch main accounting document row(s)
    SELECT *
      FROM i_accountingdocumentjournal
      WHERE AccountingDocument = @io_accountingdoc
      INTO TABLE @DATA(it_acc_doc).

    DATA(lt_accounting2) = it_acc_doc[].
    DELETE lt_accounting2 WHERE HouseBank IS INITIAL .
    DELETE it_acc_doc WHERE Customer IS INITIAL AND supplier IS INITIAL.
    READ TABLE lt_accounting2 INTO DATA(lwa_accounting2) INDEX 1.
    IF it_acc_doc IS NOT INITIAL.

      " get related companycode rows
      SELECT *
        FROM i_companycode
        FOR ALL ENTRIES IN @it_acc_doc
        WHERE CompanyCode = @it_acc_doc-CompanyCode
        INTO TABLE @DATA(it_comp_det).

      READ TABLE it_acc_doc INTO DATA(wa_doc) INDEX 1.
      IF sy-subrc = 0.

        CASE wa_doc-AccountingDocumentType.
          WHEN 'DZ'.  " Customer document
            " Fetch CUSTOMER data
            SELECT *
              FROM i_customer
              FOR ALL ENTRIES IN @it_acc_doc
              WHERE Customer = @it_acc_doc-Customer
              INTO TABLE @DATA(it_customer).

            " Fetch business partner details for customers
            IF it_customer IS NOT INITIAL.
              READ TABLE it_customer INTO DATA(wa_customer) INDEX 1.
              SELECT *
                FROM i_businesspartner
                FOR ALL ENTRIES IN @it_customer
                WHERE BusinessPartner = @it_customer-Customer
                INTO TABLE @DATA(it_bp_customer).

              " Fetch customer addresses
              SELECT *
                FROM i_address_2
                WITH PRIVILEGED ACCESS
                FOR ALL ENTRIES IN @it_customer
                WHERE AddressID = @it_customer-AddressID
                INTO TABLE @DATA(it_cust_addr).

              SELECT * FROM I_AddressEmailAddress_2
               WITH PRIVILEGED ACCESS
               FOR ALL ENTRIES IN @it_cust_addr
               WHERE addressid = @it_cust_addr-AddressID
               INTO TABLE @DATA(it_custemail).
            ENDIF.

            LOOP AT it_cust_addr INTO DATA(wa_cust_addr).
              lv_cust_cityfull = |{ wa_cust_addr-CityName } - { wa_cust_addr-CityNumber }|.
              lv_cust_cityname = wa_cust_addr-CityName.
              lv_cust_districtfull = |{ wa_cust_addr-DistrictName } - { wa_cust_addr-DistrictNumber }|.
              lv_cust_postalcode = wa_cust_addr-DistrictNumber.
              lv_cust_street = wa_cust_addr-Street.
              lv_cust_streetname = wa_cust_addr-StreetName.
              lv_cust_name = wa_customer-CustomerName .
            ENDLOOP.

            READ TABLE it_custemail INTO DATA(wa_custemail) INDEX 1.
            CONCATENATE wa_customer-TelephoneNumber1 '\' 'Email :' wa_custemail-EmailAddress INTO lv_contact .

          WHEN 'KZ'.  " Vendor document
            " Fetch VENDOR data
            SELECT *
              FROM i_supplier
              FOR ALL ENTRIES IN @it_acc_doc
              WHERE Supplier = @it_acc_doc-Supplier
              INTO TABLE @DATA(it_vendor).

            " Fetch business partner details for vendors
            IF it_vendor IS NOT INITIAL.
              READ TABLE it_vendor INTO DATA(wa_vendor) INDEX 1.
              SELECT *
                FROM i_businesspartner
                FOR ALL ENTRIES IN @it_vendor
                WHERE BusinessPartner = @it_vendor-Supplier
                INTO TABLE @DATA(it_bp_vendor).

              " Fetch vendor addresses
              SELECT *
                FROM i_address_2
                WITH PRIVILEGED ACCESS
                FOR ALL ENTRIES IN @it_vendor
                WHERE AddressID = @it_vendor-AddressID
                INTO TABLE @DATA(it_vend_addr).

              SELECT * FROM I_AddressEmailAddress_2
                 WITH PRIVILEGED ACCESS
                 FOR ALL ENTRIES IN @it_cust_addr
                 WHERE addressid = @it_cust_addr-AddressID
                 INTO TABLE @DATA(it_vendemail).

            ENDIF.

            LOOP AT it_vend_addr INTO DATA(wa_vend_addr).
              lv_cust_cityfull = |{ wa_vend_addr-CityName } - { wa_vend_addr-CityNumber }|.
              lv_cust_cityname = wa_vend_addr-CityName.
              lv_cust_districtfull = |{ wa_vend_addr-DistrictName } - { wa_vend_addr-DistrictNumber }|.
              lv_cust_postalcode = wa_vend_addr-DistrictNumber.
              lv_cust_street = wa_vend_addr-Street.
              lv_cust_streetname = wa_vend_addr-StreetName.
              lv_cust_name = wa_vendor-SupplierFullName .
            ENDLOOP.

            READ TABLE it_vendemail INTO DATA(wa_email) INDEX 1.
            CONCATENATE wa_vendor-PhoneNumber1 '\' 'Email :' wa_email-EmailAddress INTO lv_contact .

        ENDCASE.
      ENDIF.

      " business partner rows
      SELECT *
        FROM i_businesspartner
        FOR ALL ENTRIES IN @it_acc_doc
        WHERE BusinessPartner = @it_acc_doc-Customer
        INTO TABLE @DATA(it_bus_part).


      " housebank rows
      SELECT *
        FROM i_housebank
*        FOR ALL ENTRIES IN @it_acc_doc
        WHERE HouseBank = @lwa_accounting2-HouseBank
        INTO TABLE @DATA(it_bank).

      " journal entry rows (note: use INTO TABLE for many rows)
      SELECT *
        FROM i_journalentry
        FOR ALL ENTRIES IN @it_acc_doc
        WHERE AccountingDocument = @it_acc_doc-AccountingDocument
        INTO TABLE @DATA(it_journal).

      SELECT * FROM i_journalentryitem
         FOR ALL ENTRIES IN @it_acc_doc
         WHERE AccountingDocument = @it_acc_doc-AccountingDocument
           AND CompanyCode = @it_acc_doc-CompanyCode
           AND FiscalYear = @it_acc_doc-FiscalYear
         INTO TABLE @DATA(it_journal1).


      " if we have banks, fetch bank names
      IF it_bank IS NOT INITIAL.
        SELECT *
          FROM i_bank_2
          WITH PRIVILEGED ACCESS
          FOR ALL ENTRIES IN @it_bank
          WHERE BankInternalID = @it_bank-BankInternalID
          INTO TABLE @DATA(it_bank_name).
      ENDIF.


      IF it_comp_det IS NOT INITIAL.

        SELECT *
          FROM i_address_2
            WITH PRIVILEGED ACCESS
          FOR ALL ENTRIES IN @it_comp_det
          WHERE AddressID = @it_comp_det-AddressID
          INTO TABLE @DATA(i_comp_addr).

      ENDIF.



    ENDIF. " it_acc_doc IS NOT INITIAL

    LOOP AT it_acc_doc INTO DATA(wa_data).
      lv_doc_no = wa_data-AccountingDocument.
      lv_doc_date = |{ wa_data-DocumentDate+6(2) }.{ wa_data-DocumentDate+4(2) }.{ wa_data-DocumentDate+0(4) }|.
      lv_payment_date = |{ wa_data-PostingDate+6(2) }.{ wa_data-PostingDate+4(2) }.{ wa_data-PostingDate+0(4) }|.
*      lv_payment_date = wa_data-PostingDate.
*      lv_amount = wa_data-

      READ TABLE it_comp_det INTO DATA(wa_comp) WITH KEY CompanyCode = wa_data-CompanyCode.
      IF sy-subrc = 0.
        lv_comp_name = wa_comp-CompanyCodeName.
*    lv_comp_addr = wa_comp-AddressID.
        lv_comp_city = wa_comp-CityName.
*        lv_comp_country = wa_comp-Country.

      ENDIF.


      READ TABLE i_comp_addr INTO DATA(wa_comp_addr) WITH KEY AddressID = wa_comp-AddressID.
      IF sy-subrc = 0.
        lv_comp_addr1 = wa_comp_addr-StreetName+35.
        lv_comp_addr2 = wa_comp_addr-StreetName+0(35).
        SELECT SINGLE * FROM i_countrytext
              WHERE country = @wa_comp_addr-country
              AND language = @sy-langu
              INTO @DATA(wa_country_cust).

        SELECT SINGLE * FROM i_regiontext
           WHERE country = @wa_comp_addr-country
           AND region = @wa_comp_addr-region
           AND language = @sy-langu
           INTO @DATA(wa_region_cust).

        CONCATENATE wa_region_cust-RegionName '-' wa_country_cust-CountryName INTO lv_comp_country .

        READ TABLE it_journal1 INTO DATA(wa_amt) WITH KEY accountingdocument = wa_data-AccountingDocument.
        IF sy-subrc = 0.
          lv_amount = wa_amt-AmountInCompanyCodeCurrency.
          IF lv_amount LT 0 .
            lv_amount = lv_amount * -1 .
          ENDIF.
          lv_remark = wa_amt-ReferenceDocument .
        ENDIF.

        READ TABLE it_bank INTO DATA(wa_bank)
          WITH KEY HouseBank = wa_data-HouseBank
                   CompanyCode = wa_data-CompanyCode.

        IF sy-subrc = 0.
          lv_bank_acc = wa_bank-BankInternalID.

          " Then read bank name using BankInternalID from house bank
          READ TABLE it_bank_name INTO DATA(wa_bank_name)
            WITH KEY BankInternalID = wa_bank-BankInternalID.

          IF sy-subrc = 0.
            lv_bank = wa_bank_name-BankName.
          ENDIF.

        ENDIF.
      ENDIF.

      IF wa_data-AccountingDocumentHeaderText IS NOT INITIAL.
        lv_reference = wa_data-AccountingDocumentHeaderText.
      ELSE.
        lv_reference = lwa_accounting2-AccountingDocumentHeaderText .
      ENDIF.
    ENDLOOP.

    CONCATENATE lv_comp_name lv_comp_addr2 ',' lv_comp_city ','  lv_comp_country INTO lv_comp_addr_2 .
    " Header part (static template from your original)
    DATA(lv_header) =
     |<form1>| &&
     |   <fullpage>| &&
     |      <main>| &&
     |         <company_details>| &&
     |            <company_address>| &&
     |               <company_name>{ lv_comp_name }</company_name>| &&
     |               <phone></phone>| &&
     |               <region>{ lv_comp_country }</region>| &&
     |               <addr2>{ lv_comp_addr2 }lv_</addr2>| &&
     |               <state>{ lv_comp_city }</state>| &&
     |               <email></email>| &&
     |               <addr1>{ lv_comp_addr1 }</addr1>| &&
     |            </company_address>| &&
     |            <company_name>{ lv_comp_name }</company_name>| &&
     |         </company_details>| &&
     |         <payment_voucher_detail>| &&
     |            <Voucher_detail>| &&
     |               <doc_num>{ lv_doc_no }</doc_num>| &&
     |               <doc_date>{ lv_doc_date }</doc_date>| &&
     |               <project></project>| &&
     |            </Voucher_detail>| &&
     |            <Voucher_name>| &&
     |               <state>{ lv_cust_districtfull }</state>| &&
     |               <cust_addr2>{ lv_cust_street }</cust_addr2>| &&
     |               <cust_addr1>{ lv_cust_streetname }</cust_addr1>| &&
     |               <region>{ lv_cust_cityfull }</region>| &&
     |               <cont_person>{ lv_contact }</cont_person>| &&
     |               <cust_name>{ lv_cust_name }</cust_name>| &&
     |            </Voucher_name>| &&
     |         </payment_voucher_detail>| &&
     |         <payment_details>| &&
     |            <payment_header>| &&
     |               <Payment_body>| &&
     |                  <bank_name>{ lv_bank }</bank_name>| &&
     |                  <refernce>{ lv_reference }</refernce>| &&
     |                  <date>{ lv_doc_date }</date>| &&
     |                  <remarks>{ lv_remark }</remarks>| &&
     |               </Payment_body>| &&
     |               <payment_amount>{ lv_amount }</payment_amount>| &&
     |            </payment_header>| .  " <-- end of lv_header assignment

    " initialize lv_items (empty string)
    DATA(lv_items) = ''.

    DATA(lv_footer) =
     |            <payment_footer>| &&
     |               <for_comp_name>{ lv_comp_name }</for_comp_name>| &&
     |            </payment_footer>| &&
     |         </payment_details>| &&
     |         <page_footer/>| &&
     |      </main>| &&
     |      <BRANCH></BRANCH>| &&
     |      <office>{ lv_comp_addr_2 }</office>| &&
     |   </fullpage>| &&
     |</form1>|.

    " assemble final xml
    rv_xml = |{ lv_header }{ lv_items }{ lv_footer }|.

  ENDMETHOD. " build_xml
ENDCLASS.
