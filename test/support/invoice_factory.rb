require "bigdecimal"
require "date"

# Builds a minimal valid invoice for testing.
# All new optional fields are nil by default — tests set only what they need.
module InvoiceFactory
  def build_invoice(**overrides)
    defaults = {
      number: "TEST-001",
      issue_date: Date.new(2024, 3, 15),
      currency_code: "EUR",
    }
    inv = Zugpferd::Model::Invoice.new(**defaults.merge(overrides))

    inv.seller ||= Zugpferd::Model::TradeParty.new(
      name: "Seller GmbH",
      vat_identifier: "DE123456789",
      postal_address: Zugpferd::Model::PostalAddress.new(country_code: "DE"),
    )
    inv.buyer ||= Zugpferd::Model::TradeParty.new(
      name: "Buyer SA",
      postal_address: Zugpferd::Model::PostalAddress.new(country_code: "FR"),
    )

    inv.line_items << Zugpferd::Model::LineItem.new(
      id: "1", invoiced_quantity: "1", unit_code: "C62",
      line_extension_amount: "100.00",
      item: Zugpferd::Model::Item.new(
        name: "Item", tax_category: "S", tax_percent: BigDecimal("20"),
      ),
      price: Zugpferd::Model::Price.new(amount: "100.00"),
    ) if inv.line_items.empty?

    inv.tax_breakdown ||= Zugpferd::Model::TaxBreakdown.new(
      tax_amount: "20.00", currency_code: "EUR",
    )
    inv.tax_breakdown.subtotals << Zugpferd::Model::TaxSubtotal.new(
      taxable_amount: "100.00", tax_amount: "20.00",
      category_code: "S", percent: BigDecimal("20"), currency_code: "EUR",
    ) if inv.tax_breakdown.subtotals.empty?

    inv.monetary_totals ||= Zugpferd::Model::MonetaryTotals.new(
      line_extension_amount: "100.00", tax_exclusive_amount: "100.00",
      tax_inclusive_amount: "120.00", payable_amount: "120.00",
    )

    inv
  end

  def cii_roundtrip(invoice)
    xml = Zugpferd::CII::Writer.new.write(invoice)
    [xml, Zugpferd::CII::Reader.new.read(xml)]
  end

  def ubl_roundtrip(invoice)
    xml = Zugpferd::UBL::Writer.new.write(invoice)
    [xml, Zugpferd::UBL::Reader.new.read(xml)]
  end
end
