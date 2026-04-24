require "test_helper"

class DocumentLevelFieldsTest < Minitest::Test
  include XmlHelper
  include InvoiceFactory

  def setup
    @inv = build_invoice(
      tax_currency_code: "GBP",
      buyer_accounting_reference: "COST-CENTER-42",
    )
  end

  # --- CII ---

  def test_cii_writes_tax_currency_code
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "GBP",
      xpath_text(doc, "//ram:ApplicableHeaderTradeSettlement/ram:TaxCurrencyCode", CII_NS)
  end

  def test_cii_writes_buyer_accounting_reference
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "COST-CENTER-42",
      xpath_text(doc, "//ram:ReceivableSpecifiedTradeAccountingAccount/ram:ID", CII_NS)
  end

  def test_cii_roundtrip_preserves_fields
    _, inv2 = cii_roundtrip(@inv)
    assert_equal "GBP", inv2.tax_currency_code
    assert_equal "COST-CENTER-42", inv2.buyer_accounting_reference
  end

  # --- UBL ---

  def test_ubl_writes_tax_currency_code
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "GBP", xpath_text(doc, "//cbc:TaxCurrencyCode")
  end

  def test_ubl_writes_buyer_accounting_reference
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "COST-CENTER-42", xpath_text(doc, "//cbc:AccountingCost")
  end

  def test_ubl_roundtrip_preserves_fields
    _, inv2 = ubl_roundtrip(@inv)
    assert_equal "GBP", inv2.tax_currency_code
    assert_equal "COST-CENTER-42", inv2.buyer_accounting_reference
  end

  # --- Omission ---

  def test_cii_omits_tax_currency_when_nil
    inv = build_invoice
    xml, = cii_roundtrip(inv)
    doc = parse_xml(xml)
    assert_nil doc.at_xpath("//ram:TaxCurrencyCode", CII_NS)
  end

  def test_cii_omits_accounting_ref_when_nil
    inv = build_invoice
    xml, = cii_roundtrip(inv)
    doc = parse_xml(xml)
    assert_nil doc.at_xpath("//ram:ReceivableSpecifiedTradeAccountingAccount", CII_NS)
  end

  def test_defaults_to_nil
    inv = build_invoice
    assert_nil inv.tax_currency_code
    assert_nil inv.buyer_accounting_reference
  end
end
