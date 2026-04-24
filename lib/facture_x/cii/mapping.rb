module FactureX
  module CII
    module Mapping
      NS = {
        "rsm" => "urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100",
        "ram" => "urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100",
        "udt" => "urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100",
        "qdt" => "urn:un:unece:uncefact:data:standard:QualifiedDataType:100",
      }.freeze

      # Document context
      CONTEXT = "rsm:ExchangedDocumentContext"
      DOCUMENT = "rsm:ExchangedDocument"
      TRANSACTION = "rsm:SupplyChainTradeTransaction"

      # Invoice header (BG-0)
      INVOICE = {
        number:           "#{DOCUMENT}/ram:ID",
        issue_date:       "#{DOCUMENT}/ram:IssueDateTime/udt:DateTimeString",
        type_code:        "#{DOCUMENT}/ram:TypeCode",
        note:             "#{DOCUMENT}/ram:IncludedNote/ram:Content",
        customization_id: "#{CONTEXT}/ram:GuidelineSpecifiedDocumentContextParameter/ram:ID",
        profile_id:       "#{CONTEXT}/ram:BusinessProcessSpecifiedDocumentContextParameter/ram:ID",
      }.freeze

      # Delivery (BG-13)
      DELIVERY = "#{TRANSACTION}/ram:ApplicableHeaderTradeDelivery"
      DELIVERY_DATE = "ram:ActualDeliverySupplyChainEvent/ram:OccurrenceDateTime/udt:DateTimeString"

      # Settlement (contains currency, payment, tax, totals)
      SETTLEMENT = "#{TRANSACTION}/ram:ApplicableHeaderTradeSettlement"
      AGREEMENT = "#{TRANSACTION}/ram:ApplicableHeaderTradeAgreement"

      INVOICE_SETTLEMENT = {
        currency_code:  "#{SETTLEMENT}/ram:InvoiceCurrencyCode",
        buyer_reference: "#{AGREEMENT}/ram:BuyerReference",
      }.freeze

      # Seller (BG-4)
      SELLER = "#{AGREEMENT}/ram:SellerTradeParty"
      # Buyer (BG-7)
      BUYER = "#{AGREEMENT}/ram:BuyerTradeParty"

      # TradeParty fields
      PARTY = {
        name:                  "ram:Name",
        trading_name:          "ram:SpecifiedLegalOrganization/ram:TradingBusinessName",
        identifier:            "ram:ID",
        legal_registration_id: "ram:SpecifiedLegalOrganization/ram:ID",
        legal_form:            "ram:Description",
        vat_identifier:        "ram:SpecifiedTaxRegistration/ram:ID[@schemeID='VA']",
        electronic_address:    "ram:URIUniversalCommunication/ram:URIID",
      }.freeze

      # PostalAddress (BG-5 / BG-8)
      POSTAL_ADDRESS = "ram:PostalTradeAddress"
      ADDRESS = {
        street_name:            "ram:LineOne",
        additional_street_name: "ram:LineTwo",
        address_line_3:         "ram:LineThree",
        city_name:              "ram:CityName",
        postal_zone:            "ram:PostcodeCode",
        country_code:           "ram:CountryID",
        country_subdivision:    "ram:CountrySubDivisionName",
      }.freeze

      # Contact (BG-6 / BG-9)
      CONTACT = "ram:DefinedTradeContact"
      CONTACT_FIELDS = {
        name:      "ram:PersonName",
        telephone: "ram:TelephoneUniversalCommunication/ram:CompleteNumber",
        email:     "ram:EmailURIUniversalCommunication/ram:URIID",
      }.freeze

      # PaymentMeans (BG-16)
      PAYMENT_MEANS = "ram:SpecifiedTradeSettlementPaymentMeans"
      PAYMENT = {
        payment_means_code:          "ram:TypeCode",
        account_id:                  "ram:PayeePartyCreditorFinancialAccount/ram:IBANID",
        account_name:                "ram:PayeePartyCreditorFinancialAccount/ram:AccountName",
        payment_service_provider_id: "ram:PayeeSpecifiedCreditorFinancialInstitution/ram:BICID",
        card_account_id:             "ram:ApplicableTradeSettlementFinancialCard/ram:ID",
        card_holder_name:            "ram:ApplicableTradeSettlementFinancialCard/ram:CardholderName",
        debited_account_id:          "ram:PayerPartyDebtorFinancialAccount/ram:IBANID",
      }.freeze
      CREDITOR_REFERENCE_ID = "ram:CreditorReferenceID"
      PAYMENT_REFERENCE = "ram:PaymentReference"
      PAYMENT_TERMS_NOTE = "ram:SpecifiedTradePaymentTerms/ram:Description"
      PAYMENT_TERMS_DUE_DATE = "ram:SpecifiedTradePaymentTerms/ram:DueDateDateTime/udt:DateTimeString"
      PAYMENT_TERMS_MANDATE = "ram:SpecifiedTradePaymentTerms/ram:DirectDebitMandateID"

      # Invoice period (BG-14 / BG-26)
      BILLING_PERIOD = "ram:BillingSpecifiedPeriod"
      PERIOD_START = "ram:StartDateTime/udt:DateTimeString"
      PERIOD_END = "ram:EndDateTime/udt:DateTimeString"
      LINE_BILLING_PERIOD = "ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod"

      # Document references (BG-3, BT-11 to BT-14, BG-24)
      PURCHASE_ORDER_REF = "#{AGREEMENT}/ram:BuyerOrderReferencedDocument/ram:IssuerAssignedID"
      CONTRACT_REF = "#{AGREEMENT}/ram:ContractReferencedDocument/ram:IssuerAssignedID"
      PROJECT_REF = "#{AGREEMENT}/ram:SpecifiedProcuringProject/ram:ID"
      SALES_ORDER_REF = "#{AGREEMENT}/ram:SellerOrderReferencedDocument/ram:IssuerAssignedID"
      PRECEDING_INVOICE = "ram:InvoiceReferencedDocument"
      PRECEDING_INVOICE_ID = "ram:IssuerAssignedID"
      PRECEDING_INVOICE_DATE = "ram:FormattedIssueDateTime/qdt:DateTimeString"
      ADDITIONAL_DOC = "#{AGREEMENT}/ram:AdditionalReferencedDocument"
      ADDITIONAL_DOC_ID = "ram:IssuerAssignedID"
      ADDITIONAL_DOC_DESC = "ram:Name"
      ADDITIONAL_DOC_URI = "ram:URIID"
      ADDITIONAL_DOC_ATTACHMENT = "ram:AttachmentBinaryObject"

      # Payee (BG-10) and Seller Tax Representative (BG-11)
      PAYEE = "ram:PayeeTradeParty"
      TAX_REPRESENTATIVE = "#{AGREEMENT}/ram:SellerTaxRepresentativeTradeParty"

      # Deliver to (BG-13 / BG-15)
      SHIP_TO = "ram:ShipToTradeParty"
      SHIP_TO_NAME = "ram:Name"
      SHIP_TO_ID = "ram:ID"

      # Additional document-level fields
      TAX_CURRENCY_CODE = "ram:TaxCurrencyCode"
      BUYER_ACCOUNTING_REF = "ram:ReceivableSpecifiedTradeAccountingAccount/ram:ID"

      # TaxTotal (BG-23)
      TAX_SUBTOTAL = "ram:ApplicableTradeTax"
      TAX = {
        taxable_amount:        "ram:BasisAmount",
        tax_amount:            "ram:CalculatedAmount",
        category_code:         "ram:CategoryCode",
        percent:               "ram:RateApplicablePercent",
        exemption_reason:      "ram:ExemptionReason",
        exemption_reason_code: "ram:ExemptionReasonCode",
      }.freeze

      # LegalMonetaryTotal (BG-22)
      MONETARY_TOTAL = "ram:SpecifiedTradeSettlementHeaderMonetarySummation"
      TOTALS = {
        line_extension_amount:  "ram:LineTotalAmount",
        tax_exclusive_amount:   "ram:TaxBasisTotalAmount",
        tax_inclusive_amount:    "ram:GrandTotalAmount",
        prepaid_amount:          "ram:TotalPrepaidAmount",
        payable_rounding_amount: "ram:RoundingAmount",
        payable_amount:          "ram:DuePayableAmount",
        tax_total_amount:        "ram:TaxTotalAmount",
        allowance_total_amount:  "ram:AllowanceTotalAmount",
        charge_total_amount:     "ram:ChargeTotalAmount",
      }.freeze

      # AllowanceCharge (BG-20 / BG-21)
      ALLOWANCE_CHARGE = "ram:SpecifiedTradeAllowanceCharge"
      ALLOWANCE_CHARGE_FIELDS = {
        charge_indicator: "ram:ChargeIndicator/udt:Indicator",
        reason:           "ram:Reason",
        reason_code:      "ram:ReasonCode",
        amount:           "ram:ActualAmount",
        base_amount:      "ram:BasisAmount",
        multiplier_factor: "ram:CalculationPercent",
        tax_category_code: "ram:CategoryTradeTax/ram:CategoryCode",
        tax_percent:       "ram:CategoryTradeTax/ram:RateApplicablePercent",
      }.freeze

      # InvoiceLine (BG-25)
      INVOICE_LINE = "#{TRANSACTION}/ram:IncludedSupplyChainTradeLineItem"
      LINE = {
        id:                    "ram:AssociatedDocumentLineDocument/ram:LineID",
        note:                  "ram:AssociatedDocumentLineDocument/ram:IncludedNote/ram:Content",
        invoiced_quantity:     "ram:SpecifiedLineTradeDelivery/ram:BilledQuantity",
        unit_code:             "ram:SpecifiedLineTradeDelivery/ram:BilledQuantity/@unitCode",
        line_extension_amount: "ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeSettlementLineMonetarySummation/ram:LineTotalAmount",
      }.freeze

      # Item (BG-31)
      ITEM = "ram:SpecifiedTradeProduct"
      ITEM_FIELDS = {
        name:               "ram:Name",
        description:        "ram:Description",
        sellers_identifier: "ram:SellerAssignedID",
      }.freeze

      # Item tax (from line settlement, not from product)
      ITEM_TAX = "ram:SpecifiedLineTradeSettlement/ram:ApplicableTradeTax"
      ITEM_TAX_FIELDS = {
        tax_category: "ram:CategoryCode",
        tax_percent:  "ram:RateApplicablePercent",
      }.freeze

      # Line-level allowances/charges (BG-27/BG-28)
      LINE_ALLOWANCE_CHARGE = "ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge"

      # Line object identifier (BT-128)
      LINE_OBJECT_ID = "ram:SpecifiedLineTradeSettlement/ram:AdditionalReferencedDocument"
      LINE_OBJECT_ID_VALUE = "ram:IssuerAssignedID"
      LINE_OBJECT_ID_SCHEME = "ram:ReferenceTypeCode"

      # Line order reference (BT-132)
      LINE_ORDER_REF = "ram:SpecifiedLineTradeAgreement/ram:BuyerOrderReferencedDocument/ram:LineID"

      # Item additional fields
      ITEM_BUYERS_ID = "ram:BuyerAssignedID"
      ITEM_GLOBAL_ID = "ram:GlobalID"
      ITEM_CLASSIFICATION = "ram:DesignatedProductClassification/ram:ClassCode"
      ITEM_ORIGIN_COUNTRY = "ram:OriginTradeCountry/ram:ID"

      # Price (BG-29)
      PRICE = "ram:SpecifiedLineTradeAgreement/ram:NetPriceProductTradePrice"
      PRICE_FIELDS = {
        amount: "ram:ChargeAmount",
      }.freeze
    end
  end
end
