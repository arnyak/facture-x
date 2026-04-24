require "test_helper"

class InvoicePeriodTest < Minitest::Test
  include XmlHelper
  include InvoiceFactory

  def setup
    @inv = build_invoice
    @inv.invoice_period = Zugpferd::Model::InvoicePeriod.new(
      start_date: Date.new(2024, 3, 1),
      end_date: Date.new(2024, 3, 31),
    )
    @inv.line_items.first.invoice_period = Zugpferd::Model::InvoicePeriod.new(
      start_date: Date.new(2024, 3, 1),
      end_date: Date.new(2024, 3, 15),
    )
  end

  # --- CII document-level ---

  def test_cii_writes_document_period
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    settlement = "//rsm:SupplyChainTradeTransaction/ram:ApplicableHeaderTradeSettlement"
    assert_equal "20240301",
      xpath_text(doc, "#{settlement}/ram:BillingSpecifiedPeriod/ram:StartDateTime/udt:DateTimeString", CII_NS)
    assert_equal "20240331",
      xpath_text(doc, "#{settlement}/ram:BillingSpecifiedPeriod/ram:EndDateTime/udt:DateTimeString", CII_NS)
  end

  def test_cii_roundtrip_preserves_document_period
    _, inv2 = cii_roundtrip(@inv)
    assert_equal Date.new(2024, 3, 1), inv2.invoice_period.start_date
    assert_equal Date.new(2024, 3, 31), inv2.invoice_period.end_date
  end

  # --- CII line-level ---

  def test_cii_writes_line_period
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    line = "//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement"
    assert_equal "20240301",
      xpath_text(doc, "#{line}/ram:BillingSpecifiedPeriod/ram:StartDateTime/udt:DateTimeString", CII_NS)
  end

  def test_cii_roundtrip_preserves_line_period
    _, inv2 = cii_roundtrip(@inv)
    lp = inv2.line_items.first.invoice_period
    assert_equal Date.new(2024, 3, 1), lp.start_date
    assert_equal Date.new(2024, 3, 15), lp.end_date
  end

  # --- UBL document-level ---

  def test_ubl_writes_document_period
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "2024-03-01",
      xpath_text(doc, "//cac:InvoicePeriod/cbc:StartDate")
    assert_equal "2024-03-31",
      xpath_text(doc, "//cac:InvoicePeriod/cbc:EndDate")
  end

  def test_ubl_roundtrip_preserves_document_period
    _, inv2 = ubl_roundtrip(@inv)
    assert_equal Date.new(2024, 3, 1), inv2.invoice_period.start_date
    assert_equal Date.new(2024, 3, 31), inv2.invoice_period.end_date
  end

  # --- UBL line-level ---

  def test_ubl_roundtrip_preserves_line_period
    _, inv2 = ubl_roundtrip(@inv)
    lp = inv2.line_items.first.invoice_period
    assert_equal Date.new(2024, 3, 1), lp.start_date
    assert_equal Date.new(2024, 3, 15), lp.end_date
  end

  # --- Omission ---

  def test_cii_omits_document_period_when_nil
    @inv.invoice_period = nil
    @inv.line_items.first.invoice_period = nil
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_nil doc.at_xpath("//ram:ApplicableHeaderTradeSettlement/ram:BillingSpecifiedPeriod", CII_NS)
    assert_nil doc.at_xpath("//ram:SpecifiedLineTradeSettlement/ram:BillingSpecifiedPeriod", CII_NS)
  end

  def test_model_defaults_to_nil
    inv = build_invoice
    assert_nil inv.invoice_period
  end
end
