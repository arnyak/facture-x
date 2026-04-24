require "test_helper"

class ItemEnhancedTest < Minitest::Test
  include XmlHelper
  include InvoiceFactory

  def setup
    @inv = build_invoice
    item = @inv.line_items.first.item
    item.buyers_identifier = "BUY-SKU-001"
    item.standard_identifier = "4012345678901"
    item.standard_identifier_scheme = "0160"
    item.country_of_origin = "FR"
    item.classification_codes = [
      { id: "12345678", list_id: "STI" },
      { id: "98765432", list_id: "CPV" },
    ]
  end

  # --- CII ---

  def test_cii_writes_buyers_identifier
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "BUY-SKU-001",
      xpath_text(doc, "//ram:SpecifiedTradeProduct/ram:BuyerAssignedID", CII_NS)
  end

  def test_cii_writes_standard_identifier_with_scheme
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    node = doc.at_xpath("//ram:SpecifiedTradeProduct/ram:GlobalID", CII_NS)
    assert_equal "4012345678901", node.text
    assert_equal "0160", node["schemeID"]
  end

  def test_cii_writes_country_of_origin
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "FR",
      xpath_text(doc, "//ram:SpecifiedTradeProduct/ram:OriginTradeCountry/ram:ID", CII_NS)
  end

  def test_cii_writes_classification_codes
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    codes = doc.xpath("//ram:SpecifiedTradeProduct/ram:DesignatedProductClassification/ram:ClassCode", CII_NS)
    assert_equal 2, codes.length
    assert_equal "12345678", codes[0].text
    assert_equal "STI", codes[0]["listID"]
    assert_equal "98765432", codes[1].text
    assert_equal "CPV", codes[1]["listID"]
  end

  def test_cii_roundtrip_preserves_item_fields
    _, inv2 = cii_roundtrip(@inv)
    item = inv2.line_items.first.item

    assert_equal "BUY-SKU-001", item.buyers_identifier
    assert_equal "4012345678901", item.standard_identifier
    assert_equal "0160", item.standard_identifier_scheme
    assert_equal "FR", item.country_of_origin
    assert_equal 2, item.classification_codes.length
    assert_equal "12345678", item.classification_codes.first[:id]
    assert_equal "STI", item.classification_codes.first[:list_id]
  end

  # --- UBL ---

  def test_ubl_writes_buyers_identifier
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "BUY-SKU-001",
      xpath_text(doc, "//cac:Item/cac:BuyersItemIdentification/cbc:ID")
  end

  def test_ubl_writes_standard_identifier_with_scheme
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    node = doc.at_xpath("//cac:Item/cac:StandardItemIdentification/cbc:ID", UBL_NS)
    assert_equal "4012345678901", node.text
    assert_equal "0160", node["schemeID"]
  end

  def test_ubl_writes_country_of_origin
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "FR",
      xpath_text(doc, "//cac:Item/cac:OriginCountry/cbc:IdentificationCode")
  end

  def test_ubl_writes_classification_codes
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    codes = doc.xpath("//cac:Item/cac:CommodityClassification/cbc:ItemClassificationCode", UBL_NS)
    assert_equal 2, codes.length
    assert_equal "12345678", codes[0].text
    assert_equal "STI", codes[0]["listID"]
  end

  def test_ubl_roundtrip_preserves_item_fields
    _, inv2 = ubl_roundtrip(@inv)
    item = inv2.line_items.first.item

    assert_equal "BUY-SKU-001", item.buyers_identifier
    assert_equal "4012345678901", item.standard_identifier
    assert_equal "0160", item.standard_identifier_scheme
    assert_equal "FR", item.country_of_origin
    assert_equal 2, item.classification_codes.length
  end

  # --- Defaults ---

  def test_defaults
    item = Zugpferd::Model::Item.new(name: "Test")
    assert_nil item.buyers_identifier
    assert_nil item.standard_identifier
    assert_nil item.country_of_origin
    assert_empty item.classification_codes
  end
end
