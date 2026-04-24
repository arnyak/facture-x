require "bigdecimal"

module FactureX
  module Model
    # Shared behaviour for all billing document types (BG-0).
    #
    # Each including class must define a +TYPE_CODE+ constant that serves as
    # the default value for +type_code+.
    #
    # @example
    #   class Invoice
    #     include BillingDocument
    #     TYPE_CODE = "380"
    #   end
    module BillingDocument
      # @return [String] BT-1 Invoice number
      # @return [Date] BT-2 Issue date
      # @return [Date, nil] BT-9 Payment due date
      # @return [String] BT-3 Invoice type code
      # @return [String] BT-5 Document currency code (default: "EUR")
      # @return [Date, nil] BT-72 Actual delivery date
      # @return [String, nil] BT-10 Buyer reference
      # @return [String, nil] BT-24 Specification identifier
      # @return [String, nil] BT-23 Business process type
      # @return [String, nil] BT-22 Invoice note
      # @return [TradeParty, nil] BG-4 Seller party
      # @return [TradeParty, nil] BG-7 Buyer party
      # @return [Array<LineItem>] BG-25 Invoice lines
      # @return [TaxBreakdown, nil] BG-23 VAT breakdown
      # @return [MonetaryTotals, nil] BG-22 Document totals
      # @return [PaymentInstructions, nil] BG-16 Payment information
      # @return [Array<AllowanceCharge>] BG-20/BG-21 Document-level allowances and charges
      # @return [InvoicePeriod, nil] BG-14 Invoicing period
      # @return [Array<DocumentReference>] BG-3 Preceding invoice references
      # @return [String, nil] BT-13 Purchase order reference
      # @return [String, nil] BT-12 Contract document reference
      # @return [String, nil] BT-11 Project reference
      # @return [String, nil] BT-14 Sales order reference
      # @return [Array<DocumentReference>] BG-24 Additional supporting documents
      # @return [TradeParty, nil] BG-10 Payee party
      # @return [TradeParty, nil] BG-11 Seller tax representative party
      # @return [String, nil] BT-75 Deliver to party name
      # @return [String, nil] BT-76 Deliver to location identifier
      # @return [PostalAddress, nil] BG-15 Deliver to address
      # @return [String, nil] BT-6 Tax currency code
      # @return [String, nil] BT-19 Buyer accounting reference
      attr_accessor :number, :issue_date, :due_date, :type_code,
                    :currency_code, :delivery_date, :buyer_reference,
                    :customization_id, :profile_id, :note, :seller, :buyer,
                    :line_items, :tax_breakdown, :monetary_totals,
                    :payment_instructions, :allowance_charges,
                    :invoice_period,
                    :preceding_invoice_references,
                    :purchase_order_reference, :contract_reference,
                    :project_reference, :sales_order_reference,
                    :additional_documents,
                    :payee, :seller_tax_representative,
                    :deliver_to_name, :deliver_to_identifier,
                    :deliver_to_address,
                    :tax_currency_code, :buyer_accounting_reference

      # @param number [String] BT-1 Invoice number
      # @param issue_date [Date] BT-2 Issue date
      # @param type_code [String] BT-3 Invoice type code (defaults to the class's TYPE_CODE)
      # @param currency_code [String] BT-5 Document currency code
      # @param rest [Hash] additional attributes set via accessors
      def initialize(number:, issue_date:, type_code: self.class::TYPE_CODE,
                     currency_code: "EUR", **rest)
        @number = number
        @issue_date = issue_date
        @type_code = type_code
        @currency_code = currency_code
        @line_items = []
        @allowance_charges = []
        @preceding_invoice_references = []
        @additional_documents = []
        @tax_breakdown = nil
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
