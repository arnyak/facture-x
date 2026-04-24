module FactureX
  module UBL
    module Mapping
      NS = {
        "ubl" => "urn:oasis:names:specification:ubl:schema:xsd:Invoice-2",
        "cac" => "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2",
        "cbc" => "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      }.freeze

      CN_NS = {
        "cn" => "urn:oasis:names:specification:ubl:schema:xsd:CreditNote-2",
        "cac" => "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-2",
        "cbc" => "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2",
      }.freeze

      # Invoice (BG-0)
      INVOICE = {
        number:             "cbc:ID",
        issue_date:         "cbc:IssueDate",
        due_date:           "cbc:DueDate",
        type_code:          "cbc:InvoiceTypeCode",
        currency_code:      "cbc:DocumentCurrencyCode",
        buyer_reference:    "cbc:BuyerReference",
        customization_id:   "cbc:CustomizationID",
        profile_id:         "cbc:ProfileID",
        note:               "cbc:Note",
      }.freeze

      # Delivery (BG-13)
      DELIVERY = "cac:Delivery"
      DELIVERY_DATE = "cbc:ActualDeliveryDate"

      # Seller (BG-4)
      SELLER = "cac:AccountingSupplierParty/cac:Party"
      # Buyer (BG-7)
      BUYER = "cac:AccountingCustomerParty/cac:Party"

      # TradeParty fields
      PARTY = {
        name:                    "cac:PartyLegalEntity/cbc:RegistrationName",
        trading_name:            "cac:PartyName/cbc:Name",
        identifier:              "cac:PartyIdentification/cbc:ID",
        legal_registration_id:   "cac:PartyLegalEntity/cbc:CompanyID",
        legal_form:              "cac:PartyLegalEntity/cbc:CompanyLegalForm",
        vat_identifier:          "cac:PartyTaxScheme[cac:TaxScheme/cbc:ID='VAT']/cbc:CompanyID",
        electronic_address:      "cbc:EndpointID",
      }.freeze

      # PostalAddress (BG-5 / BG-8)
      POSTAL_ADDRESS = "cac:PostalAddress"
      ADDRESS = {
        street_name:            "cbc:StreetName",
        additional_street_name: "cbc:AdditionalStreetName",
        address_line_3:         "cac:AddressLine/cbc:Line",
        city_name:              "cbc:CityName",
        postal_zone:            "cbc:PostalZone",
        country_code:           "cac:Country/cbc:IdentificationCode",
        country_subdivision:    "cbc:CountrySubentity",
      }.freeze

      # Contact (BG-6 / BG-9)
      CONTACT = "cac:Contact"
      CONTACT_FIELDS = {
        name:      "cbc:Name",
        telephone: "cbc:Telephone",
        email:     "cbc:ElectronicMail",
      }.freeze

      # PaymentMeans (BG-16)
      PAYMENT_MEANS = "cac:PaymentMeans"
      PAYMENT = {
        payment_means_code:          "cbc:PaymentMeansCode",
        payment_id:                  "cbc:PaymentID",
        account_id:                  "cac:PayeeFinancialAccount/cbc:ID",
        account_name:                "cac:PayeeFinancialAccount/cbc:Name",
        payment_service_provider_id: "cac:PayeeFinancialAccount/cac:FinancialInstitutionBranch/cbc:ID",
        card_account_id:             "cac:CardAccount/cbc:PrimaryAccountNumberID",
        card_network_id:             "cac:CardAccount/cbc:NetworkID",
        card_holder_name:            "cac:CardAccount/cbc:HolderName",
        mandate_reference:           "cac:PaymentMandate/cbc:ID",
        debited_account_id:          "cac:PaymentMandate/cac:PayerFinancialAccount/cbc:ID",
      }.freeze
      PAYMENT_TERMS_NOTE = "cac:PaymentTerms/cbc:Note"

      # Invoice period (BG-14 / BG-26)
      INVOICE_PERIOD = "cac:InvoicePeriod"
      PERIOD_START = "cbc:StartDate"
      PERIOD_END = "cbc:EndDate"

      # Document references (BG-3, BT-11 to BT-14, BG-24)
      ORDER_REFERENCE = "cac:OrderReference"
      PURCHASE_ORDER_REF = "cac:OrderReference/cbc:ID"
      SALES_ORDER_REF = "cac:OrderReference/cbc:SalesOrderID"
      CONTRACT_REF = "cac:ContractDocumentReference/cbc:ID"
      PROJECT_REF = "cac:ProjectReference/cbc:ID"
      PRECEDING_INVOICE_REF = "cac:BillingReference/cac:InvoiceDocumentReference"
      PRECEDING_INVOICE_REF_ID = "cbc:ID"
      PRECEDING_INVOICE_REF_DATE = "cbc:IssueDate"
      ADDITIONAL_DOC_REF = "cac:AdditionalDocumentReference"
      ADDITIONAL_DOC_REF_ID = "cbc:ID"
      ADDITIONAL_DOC_REF_DESC = "cbc:DocumentDescription"
      ADDITIONAL_DOC_REF_URI = "cac:Attachment/cac:ExternalReference/cbc:URI"
      ADDITIONAL_DOC_REF_ATTACHMENT = "cac:Attachment/cbc:EmbeddedDocumentBinaryObject"

      # Payee (BG-10) and Seller Tax Representative (BG-11)
      PAYEE_PARTY = "cac:PayeeParty"
      TAX_REPRESENTATIVE_PARTY = "cac:TaxRepresentativeParty"

      # Deliver to (BG-13 / BG-15)
      DELIVERY_LOCATION = "cac:DeliveryLocation"
      DELIVERY_PARTY = "cac:DeliveryParty"
      DELIVERY_LOCATION_ID = "cbc:ID"
      DELIVERY_PARTY_NAME = "cac:PartyName/cbc:Name"
      DELIVERY_ADDRESS = "cac:Address"

      # Additional document-level fields
      TAX_CURRENCY_CODE = "cbc:TaxCurrencyCode"
      BUYER_ACCOUNTING_REF = "cbc:AccountingCost"

      # TaxTotal (BG-23)
      TAX_TOTAL = "cac:TaxTotal"
      TAX_SUBTOTAL = "cac:TaxSubtotal"
      TAX = {
        taxable_amount:        "cbc:TaxableAmount",
        tax_amount:            "cbc:TaxAmount",
        category_code:         "cac:TaxCategory/cbc:ID",
        percent:               "cac:TaxCategory/cbc:Percent",
        exemption_reason:      "cac:TaxCategory/cbc:TaxExemptionReason",
        exemption_reason_code: "cac:TaxCategory/cbc:TaxExemptionReasonCode",
      }.freeze

      # LegalMonetaryTotal (BG-22)
      MONETARY_TOTAL = "cac:LegalMonetaryTotal"
      TOTALS = {
        line_extension_amount:  "cbc:LineExtensionAmount",
        tax_exclusive_amount:   "cbc:TaxExclusiveAmount",
        tax_inclusive_amount:    "cbc:TaxInclusiveAmount",
        prepaid_amount:          "cbc:PrepaidAmount",
        payable_rounding_amount: "cbc:PayableRoundingAmount",
        allowance_total_amount:  "cbc:AllowanceTotalAmount",
        charge_total_amount:     "cbc:ChargeTotalAmount",
        payable_amount:          "cbc:PayableAmount",
      }.freeze

      # AllowanceCharge (BG-20 / BG-21)
      ALLOWANCE_CHARGE = "cac:AllowanceCharge"
      ALLOWANCE_CHARGE_FIELDS = {
        charge_indicator: "cbc:ChargeIndicator",
        reason:           "cbc:AllowanceChargeReason",
        reason_code:      "cbc:AllowanceChargeReasonCode",
        amount:           "cbc:Amount",
        base_amount:      "cbc:BaseAmount",
        multiplier_factor: "cbc:MultiplierFactorNumeric",
        tax_category_code: "cac:TaxCategory/cbc:ID",
        tax_percent:       "cac:TaxCategory/cbc:Percent",
      }.freeze

      # InvoiceLine (BG-25)
      INVOICE_LINE = "cac:InvoiceLine"
      LINE = {
        id:                    "cbc:ID",
        invoiced_quantity:     "cbc:InvoicedQuantity",
        unit_code:             "cbc:InvoicedQuantity/@unitCode",
        line_extension_amount: "cbc:LineExtensionAmount",
        note:                  "cbc:Note",
      }.freeze

      # Line-level allowances/charges (BG-27/BG-28)
      LINE_ALLOWANCE_CHARGE = "cac:AllowanceCharge"

      # Line object identifier (BT-128)
      LINE_DOC_REF = "cac:DocumentReference"
      LINE_DOC_REF_ID = "cbc:ID"

      # Line order reference (BT-132)
      LINE_ORDER_REF = "cac:OrderLineReference/cbc:LineID"

      # Item (BG-31)
      ITEM = "cac:Item"
      ITEM_FIELDS = {
        name:              "cbc:Name",
        description:       "cbc:Description",
        sellers_identifier: "cac:SellersItemIdentification/cbc:ID",
        buyers_identifier:  "cac:BuyersItemIdentification/cbc:ID",
        standard_identifier: "cac:StandardItemIdentification/cbc:ID",
        tax_category:      "cac:ClassifiedTaxCategory/cbc:ID",
        tax_percent:       "cac:ClassifiedTaxCategory/cbc:Percent",
        country_of_origin: "cac:OriginCountry/cbc:IdentificationCode",
      }.freeze
      ITEM_CLASSIFICATION = "cac:CommodityClassification/cbc:ItemClassificationCode"

      # Price (BG-29)
      PRICE = "cac:Price"
      PRICE_FIELDS = {
        amount: "cbc:PriceAmount",
      }.freeze
    end
  end
end
