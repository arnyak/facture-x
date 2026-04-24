require "test_helper"

class DocumentReferencesTest < Minitest::Test
  include XmlHelper
  include InvoiceFactory

  def setup
    @inv = build_invoice(
      purchase_order_reference: "PO-2024-001",
      contract_reference: "CONTRACT-99",
      project_reference: "PROJ-A",
      sales_order_reference: "SO-2024-001",
    )
    @inv.preceding_invoice_references << FactureX::Model::DocumentReference.new(
      id: "INV-2023-100", issue_date: Date.new(2023, 12, 1),
    )
    @inv.additional_documents << FactureX::Model::DocumentReference.new(
      id: "DOC-001", description: "Timesheet", uri: "https://example.com/ts.pdf",
    )
  end

  # --- CII ---

  def test_cii_writes_purchase_order_reference
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "PO-2024-001",
      xpath_text(doc, "//ram:ApplicableHeaderTradeAgreement/ram:BuyerOrderReferencedDocument/ram:IssuerAssignedID", CII_NS)
  end

  def test_cii_writes_contract_reference
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "CONTRACT-99",
      xpath_text(doc, "//ram:ApplicableHeaderTradeAgreement/ram:ContractReferencedDocument/ram:IssuerAssignedID", CII_NS)
  end

  def test_cii_writes_project_reference
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "PROJ-A",
      xpath_text(doc, "//ram:ApplicableHeaderTradeAgreement/ram:SpecifiedProcuringProject/ram:ID", CII_NS)
  end

  def test_cii_writes_sales_order_reference
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "SO-2024-001",
      xpath_text(doc, "//ram:ApplicableHeaderTradeAgreement/ram:SellerOrderReferencedDocument/ram:IssuerAssignedID", CII_NS)
  end

  def test_cii_writes_preceding_invoice
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "INV-2023-100",
      xpath_text(doc, "//ram:InvoiceReferencedDocument/ram:IssuerAssignedID", CII_NS)
    assert_equal "20231201",
      xpath_text(doc, "//ram:InvoiceReferencedDocument/ram:FormattedIssueDateTime/qdt:DateTimeString", CII_NS)
  end

  def test_cii_writes_additional_document
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "DOC-001",
      xpath_text(doc, "//ram:AdditionalReferencedDocument/ram:IssuerAssignedID", CII_NS)
    assert_equal "Timesheet",
      xpath_text(doc, "//ram:AdditionalReferencedDocument/ram:Name", CII_NS)
    assert_equal "https://example.com/ts.pdf",
      xpath_text(doc, "//ram:AdditionalReferencedDocument/ram:URIID", CII_NS)
  end

  def test_cii_roundtrip_preserves_all_references
    _, inv2 = cii_roundtrip(@inv)

    assert_equal "PO-2024-001", inv2.purchase_order_reference
    assert_equal "CONTRACT-99", inv2.contract_reference
    assert_equal "PROJ-A", inv2.project_reference
    assert_equal "SO-2024-001", inv2.sales_order_reference

    ref = inv2.preceding_invoice_references.first
    assert_equal "INV-2023-100", ref.id
    assert_equal Date.new(2023, 12, 1), ref.issue_date

    doc = inv2.additional_documents.first
    assert_equal "DOC-001", doc.id
    assert_equal "Timesheet", doc.description
    assert_equal "https://example.com/ts.pdf", doc.uri
  end

  # --- UBL ---

  def test_ubl_writes_purchase_order_reference
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "PO-2024-001", xpath_text(doc, "//cac:OrderReference/cbc:ID")
  end

  def test_ubl_writes_sales_order_reference
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "SO-2024-001", xpath_text(doc, "//cac:OrderReference/cbc:SalesOrderID")
  end

  def test_ubl_writes_contract_reference
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "CONTRACT-99", xpath_text(doc, "//cac:ContractDocumentReference/cbc:ID")
  end

  def test_ubl_writes_project_reference
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "PROJ-A", xpath_text(doc, "//cac:ProjectReference/cbc:ID")
  end

  def test_ubl_writes_preceding_invoice
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "INV-2023-100",
      xpath_text(doc, "//cac:BillingReference/cac:InvoiceDocumentReference/cbc:ID")
    assert_equal "2023-12-01",
      xpath_text(doc, "//cac:BillingReference/cac:InvoiceDocumentReference/cbc:IssueDate")
  end

  def test_ubl_writes_additional_document
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "DOC-001", xpath_text(doc, "//cac:AdditionalDocumentReference/cbc:ID")
    assert_equal "Timesheet", xpath_text(doc, "//cac:AdditionalDocumentReference/cbc:DocumentDescription")
  end

  def test_ubl_roundtrip_preserves_all_references
    _, inv2 = ubl_roundtrip(@inv)

    assert_equal "PO-2024-001", inv2.purchase_order_reference
    assert_equal "CONTRACT-99", inv2.contract_reference
    assert_equal "PROJ-A", inv2.project_reference
    assert_equal "SO-2024-001", inv2.sales_order_reference

    ref = inv2.preceding_invoice_references.first
    assert_equal "INV-2023-100", ref.id
    assert_equal Date.new(2023, 12, 1), ref.issue_date
  end

  # --- Omission ---

  def test_defaults_to_empty
    inv = build_invoice
    assert_empty inv.preceding_invoice_references
    assert_empty inv.additional_documents
    assert_nil inv.purchase_order_reference
    assert_nil inv.contract_reference
    assert_nil inv.project_reference
    assert_nil inv.sales_order_reference
  end
end
