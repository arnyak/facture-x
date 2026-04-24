require "test_helper"

class PostalAddressTest < Minitest::Test
  include XmlHelper
  include InvoiceFactory

  def setup
    @inv = build_invoice
    @inv.seller.postal_address = FactureX::Model::PostalAddress.new(
      country_code: "FR",
      street_name: "1 rue du Commerce",
      additional_street_name: "Batiment A",
      address_line_3: "Zone Industrielle",
      city_name: "Lyon",
      postal_zone: "69001",
      country_subdivision: "Rhone",
    )
  end

  # --- CII ---

  def test_cii_writes_additional_street_name
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "Batiment A",
      xpath_text(doc, "//ram:SellerTradeParty/ram:PostalTradeAddress/ram:LineTwo", CII_NS)
  end

  def test_cii_writes_address_line_3
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "Zone Industrielle",
      xpath_text(doc, "//ram:SellerTradeParty/ram:PostalTradeAddress/ram:LineThree", CII_NS)
  end

  def test_cii_writes_country_subdivision
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "Rhone",
      xpath_text(doc, "//ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountrySubDivisionName", CII_NS)
  end

  def test_cii_roundtrip_preserves_all_address_fields
    _, inv2 = cii_roundtrip(@inv)
    addr = inv2.seller.postal_address

    assert_equal "1 rue du Commerce", addr.street_name
    assert_equal "Batiment A", addr.additional_street_name
    assert_equal "Zone Industrielle", addr.address_line_3
    assert_equal "Lyon", addr.city_name
    assert_equal "69001", addr.postal_zone
    assert_equal "FR", addr.country_code
    assert_equal "Rhone", addr.country_subdivision
  end

  # --- UBL ---

  def test_ubl_writes_additional_street_name
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "Batiment A",
      xpath_text(doc, "//cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:AdditionalStreetName")
  end

  def test_ubl_writes_country_subentity
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "Rhone",
      xpath_text(doc, "//cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cbc:CountrySubentity")
  end

  def test_ubl_writes_address_line_3
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "Zone Industrielle",
      xpath_text(doc, "//cac:AccountingSupplierParty/cac:Party/cac:PostalAddress/cac:AddressLine/cbc:Line")
  end

  def test_ubl_roundtrip_preserves_all_address_fields
    _, inv2 = ubl_roundtrip(@inv)
    addr = inv2.seller.postal_address

    assert_equal "Batiment A", addr.additional_street_name
    assert_equal "Zone Industrielle", addr.address_line_3
    assert_equal "Rhone", addr.country_subdivision
  end

  # --- Omission ---

  def test_cii_omits_optional_fields_when_nil
    @inv.seller.postal_address = FactureX::Model::PostalAddress.new(country_code: "DE")
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_nil doc.at_xpath("//ram:SellerTradeParty/ram:PostalTradeAddress/ram:LineTwo", CII_NS)
    assert_nil doc.at_xpath("//ram:SellerTradeParty/ram:PostalTradeAddress/ram:LineThree", CII_NS)
    assert_nil doc.at_xpath("//ram:SellerTradeParty/ram:PostalTradeAddress/ram:CountrySubDivisionName", CII_NS)
  end
end
