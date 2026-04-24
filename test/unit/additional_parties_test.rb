require "test_helper"

class AdditionalPartiesTest < Minitest::Test
  include XmlHelper
  include InvoiceFactory

  def setup
    @inv = build_invoice
    @inv.payee = Zugpferd::Model::TradeParty.new(
      name: "Factor SAS",
      identifier: "FACTOR-001",
    )
    @inv.seller_tax_representative = Zugpferd::Model::TradeParty.new(
      name: "Rep Fiscal SARL",
      vat_identifier: "FR55555555555",
      postal_address: Zugpferd::Model::PostalAddress.new(
        country_code: "FR", city_name: "Marseille",
      ),
    )
  end

  # --- CII Payee ---

  def test_cii_writes_payee
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "Factor SAS",
      xpath_text(doc, "//ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:Name", CII_NS)
    assert_equal "FACTOR-001",
      xpath_text(doc, "//ram:ApplicableHeaderTradeSettlement/ram:PayeeTradeParty/ram:ID", CII_NS)
  end

  def test_cii_roundtrip_preserves_payee
    _, inv2 = cii_roundtrip(@inv)
    assert_equal "Factor SAS", inv2.payee.name
    assert_equal "FACTOR-001", inv2.payee.identifier
  end

  # --- CII Tax Representative ---

  def test_cii_writes_tax_representative
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "Rep Fiscal SARL",
      xpath_text(doc, "//ram:SellerTaxRepresentativeTradeParty/ram:Name", CII_NS)
    assert_equal "FR55555555555",
      xpath_text(doc, "//ram:SellerTaxRepresentativeTradeParty/ram:SpecifiedTaxRegistration/ram:ID", CII_NS)
  end

  def test_cii_roundtrip_preserves_tax_representative
    _, inv2 = cii_roundtrip(@inv)
    tr = inv2.seller_tax_representative
    assert_equal "Rep Fiscal SARL", tr.name
    assert_equal "FR55555555555", tr.vat_identifier
    assert_equal "FR", tr.postal_address.country_code
    assert_equal "Marseille", tr.postal_address.city_name
  end

  # --- UBL Payee ---

  def test_ubl_writes_payee
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "Factor SAS",
      xpath_text(doc, "//cac:PayeeParty/cac:PartyLegalEntity/cbc:RegistrationName")
    assert_equal "FACTOR-001",
      xpath_text(doc, "//cac:PayeeParty/cac:PartyIdentification/cbc:ID")
  end

  def test_ubl_roundtrip_preserves_payee
    _, inv2 = ubl_roundtrip(@inv)
    assert_equal "Factor SAS", inv2.payee.name
  end

  # --- UBL Tax Representative ---

  def test_ubl_writes_tax_representative
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "Rep Fiscal SARL",
      xpath_text(doc, "//cac:TaxRepresentativeParty/cac:PartyName/cbc:Name")
    assert_equal "FR55555555555",
      xpath_text(doc, "//cac:TaxRepresentativeParty/cac:PartyTaxScheme/cbc:CompanyID")
  end

  def test_ubl_roundtrip_preserves_tax_representative
    _, inv2 = ubl_roundtrip(@inv)
    tr = inv2.seller_tax_representative
    assert_equal "Rep Fiscal SARL", tr.name
    assert_equal "FR55555555555", tr.vat_identifier
  end

  # --- Omission ---

  def test_cii_omits_payee_when_nil
    @inv.payee = nil
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_nil doc.at_xpath("//ram:PayeeTradeParty", CII_NS)
  end

  def test_defaults_to_nil
    inv = build_invoice
    assert_nil inv.payee
    assert_nil inv.seller_tax_representative
  end
end
