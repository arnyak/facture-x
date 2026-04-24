require "test_helper"

class IdentifierSchemesTest < Minitest::Test
  include XmlHelper
  include InvoiceFactory

  def setup
    @inv = build_invoice
    @inv.seller.identifier = "12345678901234"
    @inv.seller.identifier_scheme = "0009"
    @inv.seller.legal_registration_id = "RCS-LYON-123"
    @inv.seller.legal_registration_id_scheme = "0002"
  end

  # --- CII ---

  def test_cii_writes_identifier_scheme
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    node = doc.at_xpath("//ram:SellerTradeParty/ram:ID", CII_NS)
    assert_equal "12345678901234", node.text
    assert_equal "0009", node["schemeID"]
  end

  def test_cii_writes_legal_registration_id_scheme
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    node = doc.at_xpath("//ram:SellerTradeParty/ram:SpecifiedLegalOrganization/ram:ID", CII_NS)
    assert_equal "RCS-LYON-123", node.text
    assert_equal "0002", node["schemeID"]
  end

  def test_cii_roundtrip_preserves_schemes
    _, inv2 = cii_roundtrip(@inv)
    assert_equal "0009", inv2.seller.identifier_scheme
    assert_equal "0002", inv2.seller.legal_registration_id_scheme
  end

  # --- UBL ---

  def test_ubl_writes_identifier_scheme
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    node = doc.at_xpath("//cac:AccountingSupplierParty/cac:Party/cac:PartyIdentification/cbc:ID", UBL_NS)
    assert_equal "12345678901234", node.text
    assert_equal "0009", node["schemeID"]
  end

  def test_ubl_writes_legal_registration_id_scheme
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    node = doc.at_xpath("//cac:AccountingSupplierParty/cac:Party/cac:PartyLegalEntity/cbc:CompanyID", UBL_NS)
    assert_equal "RCS-LYON-123", node.text
    assert_equal "0002", node["schemeID"]
  end

  def test_ubl_roundtrip_preserves_schemes
    _, inv2 = ubl_roundtrip(@inv)
    assert_equal "0009", inv2.seller.identifier_scheme
    assert_equal "0002", inv2.seller.legal_registration_id_scheme
  end

  # --- No scheme ---

  def test_cii_omits_scheme_when_nil
    @inv.seller.identifier_scheme = nil
    @inv.seller.legal_registration_id_scheme = nil
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    node = doc.at_xpath("//ram:SellerTradeParty/ram:ID", CII_NS)
    assert_nil node["schemeID"]
  end

  def test_defaults_to_nil
    party = Zugpferd::Model::TradeParty.new(name: "Test")
    assert_nil party.identifier_scheme
    assert_nil party.legal_registration_id_scheme
  end
end
