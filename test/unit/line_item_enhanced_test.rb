require "test_helper"

class LineItemEnhancedTest < Minitest::Test
  include XmlHelper
  include InvoiceFactory

  def setup
    @inv = build_invoice
    line = @inv.line_items.first
    line.order_line_reference = "5"
    line.object_identifier = "OBJ-001"
    line.object_identifier_scheme = "ABZ"
    line.allowance_charges << Zugpferd::Model::AllowanceCharge.new(
      charge_indicator: false, amount: "10.00", reason: "Discount",
    )
    line.allowance_charges << Zugpferd::Model::AllowanceCharge.new(
      charge_indicator: true, amount: "5.00", reason: "Service fee",
    )
  end

  # --- CII Line Allowances/Charges ---

  def test_cii_writes_line_allowances
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    acs = doc.xpath("//ram:IncludedSupplyChainTradeLineItem/ram:SpecifiedLineTradeSettlement/ram:SpecifiedTradeAllowanceCharge", CII_NS)
    assert_equal 2, acs.length
  end

  def test_cii_roundtrip_preserves_line_allowances
    _, inv2 = cii_roundtrip(@inv)
    acs = inv2.line_items.first.allowance_charges
    assert_equal 2, acs.length

    assert_equal false, acs[0].charge_indicator
    assert_equal BigDecimal("10"), acs[0].amount
    assert_equal "Discount", acs[0].reason

    assert_equal true, acs[1].charge_indicator
    assert_equal BigDecimal("5"), acs[1].amount
  end

  # --- CII Order Line Reference ---

  def test_cii_writes_order_line_reference
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "5",
      xpath_text(doc, "//ram:SpecifiedLineTradeAgreement/ram:BuyerOrderReferencedDocument/ram:LineID", CII_NS)
  end

  def test_cii_roundtrip_preserves_order_line_reference
    _, inv2 = cii_roundtrip(@inv)
    assert_equal "5", inv2.line_items.first.order_line_reference
  end

  # --- CII Object Identifier ---

  def test_cii_writes_object_identifier
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    ref = "//ram:SpecifiedLineTradeSettlement/ram:AdditionalReferencedDocument"
    assert_equal "OBJ-001", xpath_text(doc, "#{ref}/ram:IssuerAssignedID", CII_NS)
    assert_equal "130", xpath_text(doc, "#{ref}/ram:TypeCode", CII_NS)
    assert_equal "ABZ", xpath_text(doc, "#{ref}/ram:ReferenceTypeCode", CII_NS)
  end

  def test_cii_roundtrip_preserves_object_identifier
    _, inv2 = cii_roundtrip(@inv)
    assert_equal "OBJ-001", inv2.line_items.first.object_identifier
    assert_equal "ABZ", inv2.line_items.first.object_identifier_scheme
  end

  # --- UBL Line Allowances/Charges ---

  def test_ubl_writes_line_allowances
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    acs = doc.xpath("//cac:InvoiceLine/cac:AllowanceCharge", UBL_NS)
    assert_equal 2, acs.length
  end

  def test_ubl_roundtrip_preserves_line_allowances
    _, inv2 = ubl_roundtrip(@inv)
    acs = inv2.line_items.first.allowance_charges
    assert_equal 2, acs.length
    assert_equal BigDecimal("10"), acs[0].amount
  end

  # --- UBL Order Line Reference ---

  def test_ubl_writes_order_line_reference
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "5", xpath_text(doc, "//cac:InvoiceLine/cac:OrderLineReference/cbc:LineID")
  end

  def test_ubl_roundtrip_preserves_order_line_reference
    _, inv2 = ubl_roundtrip(@inv)
    assert_equal "5", inv2.line_items.first.order_line_reference
  end

  # --- UBL Object Identifier ---

  def test_ubl_writes_object_identifier
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    id_node = doc.at_xpath("//cac:InvoiceLine/cac:DocumentReference/cbc:ID", UBL_NS)
    assert_equal "OBJ-001", id_node.text
    assert_equal "ABZ", id_node["schemeID"]
  end

  def test_ubl_roundtrip_preserves_object_identifier
    _, inv2 = ubl_roundtrip(@inv)
    assert_equal "OBJ-001", inv2.line_items.first.object_identifier
    assert_equal "ABZ", inv2.line_items.first.object_identifier_scheme
  end

  # --- Defaults ---

  def test_defaults
    inv = build_invoice
    line = inv.line_items.first
    assert_empty line.allowance_charges
    assert_nil line.order_line_reference
    assert_nil line.object_identifier
  end
end
