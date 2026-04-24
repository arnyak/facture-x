require "bigdecimal"

module FactureX
  module Model
    # An invoice line (BG-25).
    class LineItem
      # @return [String] BT-126 Line identifier
      # @return [BigDecimal] BT-129 Invoiced quantity
      # @return [String] BT-130 Unit of measure code
      # @return [BigDecimal] BT-131 Line extension amount
      # @return [String, nil] BT-127 Invoice line note
      # @return [Item, nil] BG-31 Item information
      # @return [Price, nil] BG-29 Price details
      # @return [InvoicePeriod, nil] BG-26 Invoice line period
      # @return [Array<AllowanceCharge>] BG-27/BG-28 Line-level allowances and charges
      # @return [String, nil] BT-128 Invoice line object identifier
      # @return [String, nil] BT-128-1 Invoice line object identifier scheme
      # @return [String, nil] BT-132 Referenced purchase order line reference
      attr_accessor :id, :invoiced_quantity, :unit_code,
                    :line_extension_amount, :note, :item, :price,
                    :invoice_period, :allowance_charges,
                    :object_identifier, :object_identifier_scheme,
                    :order_line_reference

      # @param id [String] BT-126 Line identifier
      # @param invoiced_quantity [String, BigDecimal] BT-129 Quantity
      # @param unit_code [String] BT-130 Unit of measure code
      # @param line_extension_amount [String, BigDecimal] BT-131 Line total
      # @param rest [Hash] additional attributes set via accessors
      def initialize(id:, invoiced_quantity:, unit_code:,
                     line_extension_amount:, **rest)
        @id = id
        @invoiced_quantity = BigDecimal(invoiced_quantity.to_s)
        @unit_code = unit_code
        @line_extension_amount = BigDecimal(line_extension_amount.to_s)
        @allowance_charges = []
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
