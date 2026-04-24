require "test_helper"

class DeliveryEnhancedTest < Minitest::Test
  include XmlHelper
  include InvoiceFactory

  def setup
    @inv = build_invoice(
      deliver_to_name: "Warehouse Paris",
      deliver_to_identifier: "LOC-001",
      deliver_to_address: FactureX::Model::PostalAddress.new(
        country_code: "FR",
        street_name: "10 rue de la Paix",
        city_name: "Paris",
        postal_zone: "75001",
      ),
    )
  end

  # --- CII ---

  def test_cii_writes_ship_to_party
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    ship_to = "//ram:ApplicableHeaderTradeDelivery/ram:ShipToTradeParty"
    assert_equal "Warehouse Paris", xpath_text(doc, "#{ship_to}/ram:Name", CII_NS)
    assert_equal "LOC-001", xpath_text(doc, "#{ship_to}/ram:ID", CII_NS)
    assert_equal "Paris", xpath_text(doc, "#{ship_to}/ram:PostalTradeAddress/ram:CityName", CII_NS)
    assert_equal "FR", xpath_text(doc, "#{ship_to}/ram:PostalTradeAddress/ram:CountryID", CII_NS)
  end

  def test_cii_roundtrip_preserves_delivery
    _, inv2 = cii_roundtrip(@inv)
    assert_equal "Warehouse Paris", inv2.deliver_to_name
    assert_equal "LOC-001", inv2.deliver_to_identifier
    assert_equal "Paris", inv2.deliver_to_address.city_name
    assert_equal "FR", inv2.deliver_to_address.country_code
  end

  # --- UBL ---

  def test_ubl_writes_delivery_location_and_party
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "LOC-001",
      xpath_text(doc, "//cac:Delivery/cac:DeliveryLocation/cbc:ID")
    assert_equal "Paris",
      xpath_text(doc, "//cac:Delivery/cac:DeliveryLocation/cac:Address/cbc:CityName")
    assert_equal "Warehouse Paris",
      xpath_text(doc, "//cac:Delivery/cac:DeliveryParty/cac:PartyName/cbc:Name")
  end

  def test_ubl_roundtrip_preserves_delivery
    _, inv2 = ubl_roundtrip(@inv)
    assert_equal "Warehouse Paris", inv2.deliver_to_name
    assert_equal "LOC-001", inv2.deliver_to_identifier
    assert_equal "Paris", inv2.deliver_to_address.city_name
  end

  # --- Omission ---

  def test_cii_omits_ship_to_when_nil
    inv = build_invoice
    xml, = cii_roundtrip(inv)
    doc = parse_xml(xml)
    assert_nil doc.at_xpath("//ram:ShipToTradeParty", CII_NS)
  end

  def test_defaults_to_nil
    inv = build_invoice
    assert_nil inv.deliver_to_name
    assert_nil inv.deliver_to_identifier
    assert_nil inv.deliver_to_address
  end
end
