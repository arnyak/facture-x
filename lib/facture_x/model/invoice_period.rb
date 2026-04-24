module FactureX
  module Model
    # Invoice period (BG-14) or invoice line period (BG-26).
    #
    # @example
    #   period = InvoicePeriod.new(start_date: Date.new(2024, 1, 1), end_date: Date.new(2024, 1, 31))
    class InvoicePeriod
      # @return [Date, nil] BT-73/BT-134 Period start date
      # @return [Date, nil] BT-74/BT-135 Period end date
      attr_accessor :start_date, :end_date

      # @param rest [Hash] additional attributes set via accessors
      def initialize(**rest)
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
