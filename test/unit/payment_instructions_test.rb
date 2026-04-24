require "test_helper"

class PaymentInstructionsEnhancedTest < Minitest::Test
  include XmlHelper
  include InvoiceFactory

  def setup
    @inv = build_invoice
    @inv.payment_instructions = Zugpferd::Model::PaymentInstructions.new(
      payment_means_code: "30",
      account_id: "FR7630006000011234567890189",
      account_name: "Vendeur SARL",
      payment_service_provider_id: "BNPAFRPP",
    )
  end

  # --- CII ---

  def test_cii_writes_account_name
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "Vendeur SARL",
      xpath_text(doc, "//ram:PayeePartyCreditorFinancialAccount/ram:AccountName", CII_NS)
  end

  def test_cii_writes_bic
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "BNPAFRPP",
      xpath_text(doc, "//ram:PayeeSpecifiedCreditorFinancialInstitution/ram:BICID", CII_NS)
  end

  def test_cii_roundtrip_preserves_payment_fields
    _, inv2 = cii_roundtrip(@inv)
    pi = inv2.payment_instructions

    assert_equal "Vendeur SARL", pi.account_name
    assert_equal "BNPAFRPP", pi.payment_service_provider_id
    assert_equal "FR7630006000011234567890189", pi.account_id
  end

  # --- UBL ---

  def test_ubl_writes_account_name
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "Vendeur SARL",
      xpath_text(doc, "//cac:PaymentMeans/cac:PayeeFinancialAccount/cbc:Name")
  end

  def test_ubl_writes_bic
    xml, = ubl_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_equal "BNPAFRPP",
      xpath_text(doc, "//cac:PaymentMeans/cac:PayeeFinancialAccount/cac:FinancialInstitutionBranch/cbc:ID")
  end

  def test_ubl_roundtrip_preserves_payment_fields
    _, inv2 = ubl_roundtrip(@inv)
    pi = inv2.payment_instructions

    assert_equal "Vendeur SARL", pi.account_name
    assert_equal "BNPAFRPP", pi.payment_service_provider_id
  end

  # --- Omission ---

  def test_cii_omits_bic_when_nil
    @inv.payment_instructions = Zugpferd::Model::PaymentInstructions.new(
      payment_means_code: "30", account_id: "DE89370400440532013000",
    )
    xml, = cii_roundtrip(@inv)
    doc = parse_xml(xml)
    assert_nil doc.at_xpath("//ram:PayeeSpecifiedCreditorFinancialInstitution", CII_NS)
  end
end
