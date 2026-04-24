require "nokogiri"
require "date"
require "bigdecimal"
require_relative "mapping"

module FactureX
  module CII
    # Reads UN/CEFACT CII CrossIndustryInvoice XML into the appropriate model class.
    #
    # @example
    #   doc = FactureX::CII::Reader.new.read(File.read("invoice.xml"))
    class Reader
      include Mapping

      TYPE_CODE_MAP = {
        "381" => Model::CreditNote,
        "384" => Model::CorrectedInvoice,
        "389" => Model::SelfBilledInvoice,
        "326" => Model::PartialInvoice,
        "386" => Model::PrepaymentInvoice,
      }.freeze

      # Parses a CII CrossIndustryInvoice XML string.
      #
      # @param xml_string [String] valid CII D16B XML
      # @return [Model::BillingDocument]
      # @raise [Nokogiri::XML::SyntaxError] if the XML is malformed
      def read(xml_string)
        doc = Nokogiri::XML(xml_string) { |config| config.strict }
        root = doc.root
        build_invoice(root)
      end

      private

      def build_invoice(root)
        settlement = root.at_xpath(SETTLEMENT, NS)
        delivery = root.at_xpath(DELIVERY, NS)
        ship_to = delivery&.at_xpath(SHIP_TO, NS)
        type_code = text(root, INVOICE[:type_code])
        model_class = TYPE_CODE_MAP.fetch(type_code, Model::Invoice)

        model_class.new(
          number: text(root, INVOICE[:number]),
          issue_date: parse_cii_date(text(root, INVOICE[:issue_date])),
          due_date: parse_cii_date(settlement ? text(settlement, PAYMENT_TERMS_DUE_DATE) : nil),
          delivery_date: parse_cii_date(delivery ? text(delivery, DELIVERY_DATE) : nil),
          type_code: text(root, INVOICE[:type_code]),
          currency_code: text(root, INVOICE_SETTLEMENT[:currency_code]),
          buyer_reference: text(root, INVOICE_SETTLEMENT[:buyer_reference]),
          customization_id: text(root, INVOICE[:customization_id]),
          profile_id: text(root, INVOICE[:profile_id]),
          note: text(root, INVOICE[:note]),
          seller: build_party(root.at_xpath(SELLER, NS)),
          buyer: build_party(root.at_xpath(BUYER, NS)),
          line_items: root.xpath(INVOICE_LINE, NS).map { |n| build_line_item(n) },
          allowance_charges: settlement ? build_allowance_charges(settlement) : [],
          tax_breakdown: build_tax_breakdown(settlement),
          monetary_totals: build_monetary_totals(settlement&.at_xpath(MONETARY_TOTAL, NS)),
          payment_instructions: build_payment_instructions(settlement),
          invoice_period: build_invoice_period(settlement&.at_xpath(BILLING_PERIOD, NS)),
          # Document references
          purchase_order_reference: text(root, PURCHASE_ORDER_REF),
          contract_reference: text(root, CONTRACT_REF),
          project_reference: text(root, PROJECT_REF),
          sales_order_reference: text(root, SALES_ORDER_REF),
          preceding_invoice_references: settlement ? build_preceding_invoices(settlement) : [],
          additional_documents: build_additional_documents(root),
          # Additional parties
          payee: settlement ? build_party(settlement.at_xpath(PAYEE, NS)) : nil,
          seller_tax_representative: build_party(root.at_xpath(TAX_REPRESENTATIVE, NS)),
          # Deliver-to
          deliver_to_name: ship_to ? text(ship_to, SHIP_TO_NAME) : nil,
          deliver_to_identifier: ship_to ? text(ship_to, SHIP_TO_ID) : nil,
          deliver_to_address: ship_to ? build_postal_address_if_present(ship_to) : nil,
          # Document-level fields
          tax_currency_code: settlement ? text(settlement, TAX_CURRENCY_CODE) : nil,
          buyer_accounting_reference: settlement ? text(settlement, BUYER_ACCOUNTING_REF) : nil,
        )
      end

      def build_party(node)
        return nil unless node

        party = Model::TradeParty.new(
          name: text(node, PARTY[:name]),
          trading_name: text(node, PARTY[:trading_name]),
          identifier: text(node, PARTY[:identifier]),
          legal_registration_id: text(node, PARTY[:legal_registration_id]),
          legal_form: text(node, PARTY[:legal_form]),
          vat_identifier: text(node, PARTY[:vat_identifier]),
          electronic_address: text(node, PARTY[:electronic_address]),
        )

        id_node = node.at_xpath(PARTY[:identifier], NS)
        party.identifier_scheme = id_node["schemeID"] if id_node&.[]("schemeID")

        legal_id_node = node.at_xpath(PARTY[:legal_registration_id], NS)
        party.legal_registration_id_scheme = legal_id_node["schemeID"] if legal_id_node&.[]("schemeID")

        endpoint = node.at_xpath(PARTY[:electronic_address], NS)
        party.electronic_address_scheme = endpoint["schemeID"] if endpoint

        addr_node = node.at_xpath(POSTAL_ADDRESS, NS)
        party.postal_address = build_postal_address(addr_node) if addr_node

        contact_node = node.at_xpath(CONTACT, NS)
        party.contact = build_contact(contact_node) if contact_node

        party
      end

      def build_postal_address(node)
        Model::PostalAddress.new(
          country_code: text(node, ADDRESS[:country_code]),
          street_name: text(node, ADDRESS[:street_name]),
          additional_street_name: text(node, ADDRESS[:additional_street_name]),
          address_line_3: text(node, ADDRESS[:address_line_3]),
          city_name: text(node, ADDRESS[:city_name]),
          postal_zone: text(node, ADDRESS[:postal_zone]),
          country_subdivision: text(node, ADDRESS[:country_subdivision]),
        )
      end

      def build_contact(node)
        Model::Contact.new(
          name: text(node, CONTACT_FIELDS[:name]),
          telephone: text(node, CONTACT_FIELDS[:telephone]),
          email: text(node, CONTACT_FIELDS[:email]),
        )
      end

      def build_payment_instructions(settlement_node)
        return nil unless settlement_node

        means_node = settlement_node.at_xpath(PAYMENT_MEANS, NS)
        return nil unless means_node

        Model::PaymentInstructions.new(
          payment_means_code: text(means_node, PAYMENT[:payment_means_code]),
          payment_id: text(settlement_node, PAYMENT_REFERENCE),
          account_id: text(means_node, PAYMENT[:account_id]),
          account_name: text(means_node, PAYMENT[:account_name]),
          payment_service_provider_id: text(means_node, PAYMENT[:payment_service_provider_id]),
          card_account_id: text(means_node, PAYMENT[:card_account_id]),
          card_holder_name: text(means_node, PAYMENT[:card_holder_name]),
          debited_account_id: text(means_node, PAYMENT[:debited_account_id]),
          creditor_reference_id: text(settlement_node, CREDITOR_REFERENCE_ID),
          mandate_reference: text(settlement_node, PAYMENT_TERMS_MANDATE),
          note: text(settlement_node, PAYMENT_TERMS_NOTE),
        )
      end

      def build_tax_breakdown(settlement_node)
        return nil unless settlement_node

        totals_node = settlement_node.at_xpath(MONETARY_TOTAL, NS)
        tax_total_nodes = totals_node&.xpath(TOTALS[:tax_total_amount], NS)
        tax_total_node = tax_total_nodes&.first
        currency = tax_total_node&.[]("currencyID")

        breakdown = Model::TaxBreakdown.new(
          tax_amount: tax_total_node&.text,
          currency_code: currency,
        )

        # BT-111: second TaxTotalAmount with tax currency
        if tax_total_nodes && tax_total_nodes.length > 1
          second = tax_total_nodes[1]
          breakdown.tax_amount_in_accounting_currency = parse_decimal(second.text)
          breakdown.tax_amount_in_accounting_currency_code = second["currencyID"]
        end

        breakdown.subtotals = settlement_node.xpath(TAX_SUBTOTAL, NS).map do |sub|
          Model::TaxSubtotal.new(
            taxable_amount: text(sub, TAX[:taxable_amount]),
            tax_amount: text(sub, TAX[:tax_amount]),
            category_code: text(sub, TAX[:category_code]),
            percent: parse_decimal(text(sub, TAX[:percent])),
            currency_code: currency,
            exemption_reason: text(sub, TAX[:exemption_reason]),
            exemption_reason_code: text(sub, TAX[:exemption_reason_code]),
          )
        end

        breakdown
      end

      def build_monetary_totals(node)
        return nil unless node

        Model::MonetaryTotals.new(
          line_extension_amount: text(node, TOTALS[:line_extension_amount]),
          tax_exclusive_amount: text(node, TOTALS[:tax_exclusive_amount]),
          tax_inclusive_amount: text(node, TOTALS[:tax_inclusive_amount]),
          prepaid_amount: parse_decimal(text(node, TOTALS[:prepaid_amount])),
          payable_rounding_amount: parse_decimal(text(node, TOTALS[:payable_rounding_amount])),
          allowance_total_amount: parse_decimal(text(node, TOTALS[:allowance_total_amount])),
          charge_total_amount: parse_decimal(text(node, TOTALS[:charge_total_amount])),
          payable_amount: text(node, TOTALS[:payable_amount]),
        )
      end

      def build_line_item(node)
        item_node = node.at_xpath(ITEM, NS)
        price_node = node.at_xpath(PRICE, NS)
        tax_node = node.at_xpath(ITEM_TAX, NS)
        obj_ref = node.at_xpath(LINE_OBJECT_ID, NS)

        Model::LineItem.new(
          id: text(node, LINE[:id]),
          invoiced_quantity: text(node, LINE[:invoiced_quantity]),
          unit_code: node.at_xpath(LINE[:unit_code], NS)&.text,
          line_extension_amount: text(node, LINE[:line_extension_amount]),
          note: text(node, LINE[:note]),
          item: build_item(item_node, tax_node),
          price: build_price(price_node),
          invoice_period: build_invoice_period(node.at_xpath(LINE_BILLING_PERIOD, NS)),
          allowance_charges: build_line_allowance_charges(node),
          object_identifier: obj_ref ? text(obj_ref, LINE_OBJECT_ID_VALUE) : nil,
          object_identifier_scheme: obj_ref ? text(obj_ref, LINE_OBJECT_ID_SCHEME) : nil,
          order_line_reference: text(node, LINE_ORDER_REF),
        )
      end

      def build_line_allowance_charges(node)
        node.xpath(LINE_ALLOWANCE_CHARGE, NS).map do |ac_node|
          Model::AllowanceCharge.new(
            charge_indicator: text(ac_node, ALLOWANCE_CHARGE_FIELDS[:charge_indicator]) == "true",
            reason: text(ac_node, ALLOWANCE_CHARGE_FIELDS[:reason]),
            reason_code: text(ac_node, ALLOWANCE_CHARGE_FIELDS[:reason_code]),
            amount: text(ac_node, ALLOWANCE_CHARGE_FIELDS[:amount]),
            base_amount: parse_decimal(text(ac_node, ALLOWANCE_CHARGE_FIELDS[:base_amount])),
            multiplier_factor: parse_decimal(text(ac_node, ALLOWANCE_CHARGE_FIELDS[:multiplier_factor])),
            tax_category_code: text(ac_node, ALLOWANCE_CHARGE_FIELDS[:tax_category_code]),
            tax_percent: parse_decimal(text(ac_node, ALLOWANCE_CHARGE_FIELDS[:tax_percent])),
          )
        end
      end

      def build_item(node, tax_node)
        return nil unless node

        global_id_node = node.at_xpath(ITEM_GLOBAL_ID, NS)
        classification_nodes = node.xpath(ITEM_CLASSIFICATION, NS)

        Model::Item.new(
          name: text(node, ITEM_FIELDS[:name]),
          description: text(node, ITEM_FIELDS[:description]),
          sellers_identifier: text(node, ITEM_FIELDS[:sellers_identifier]),
          buyers_identifier: text(node, ITEM_BUYERS_ID),
          standard_identifier: global_id_node&.text,
          standard_identifier_scheme: global_id_node&.[]("schemeID"),
          country_of_origin: text(node, ITEM_ORIGIN_COUNTRY),
          classification_codes: classification_nodes.map do |cc|
            { id: cc.text, list_id: cc["listID"] }
          end,
          tax_category: tax_node ? text(tax_node, ITEM_TAX_FIELDS[:tax_category]) : nil,
          tax_percent: tax_node ? parse_decimal(text(tax_node, ITEM_TAX_FIELDS[:tax_percent])) : nil,
        )
      end

      def build_price(node)
        return nil unless node

        Model::Price.new(
          amount: text(node, PRICE_FIELDS[:amount]),
        )
      end

      def build_allowance_charges(settlement_node)
        settlement_node.xpath(ALLOWANCE_CHARGE, NS).map do |node|
          Model::AllowanceCharge.new(
            charge_indicator: text(node, ALLOWANCE_CHARGE_FIELDS[:charge_indicator]) == "true",
            reason: text(node, ALLOWANCE_CHARGE_FIELDS[:reason]),
            reason_code: text(node, ALLOWANCE_CHARGE_FIELDS[:reason_code]),
            amount: text(node, ALLOWANCE_CHARGE_FIELDS[:amount]),
            base_amount: parse_decimal(text(node, ALLOWANCE_CHARGE_FIELDS[:base_amount])),
            multiplier_factor: parse_decimal(text(node, ALLOWANCE_CHARGE_FIELDS[:multiplier_factor])),
            tax_category_code: text(node, ALLOWANCE_CHARGE_FIELDS[:tax_category_code]),
            tax_percent: parse_decimal(text(node, ALLOWANCE_CHARGE_FIELDS[:tax_percent])),
          )
        end
      end

      def build_preceding_invoices(settlement_node)
        settlement_node.xpath(PRECEDING_INVOICE, NS).map do |node|
          Model::DocumentReference.new(
            id: text(node, PRECEDING_INVOICE_ID),
            issue_date: parse_cii_date(text(node, PRECEDING_INVOICE_DATE)),
          )
        end
      end

      def build_additional_documents(root)
        root.xpath(ADDITIONAL_DOC, NS).map do |node|
          attachment_node = node.at_xpath(ADDITIONAL_DOC_ATTACHMENT, NS)
          Model::DocumentReference.new(
            id: text(node, ADDITIONAL_DOC_ID),
            description: text(node, ADDITIONAL_DOC_DESC),
            uri: text(node, ADDITIONAL_DOC_URI),
            attached_document: attachment_node&.text,
            mime_code: attachment_node&.[]("mimeCode"),
            filename: attachment_node&.[]("filename"),
          )
        end
      end

      def build_postal_address_if_present(node)
        addr_node = node.at_xpath(POSTAL_ADDRESS, NS)
        build_postal_address(addr_node) if addr_node
      end

      def build_invoice_period(node)
        return nil unless node
        Model::InvoicePeriod.new(
          start_date: parse_cii_date(text(node, PERIOD_START)),
          end_date: parse_cii_date(text(node, PERIOD_END)),
        )
      end

      def text(node, xpath)
        node.at_xpath(xpath, NS)&.text
      end

      def parse_cii_date(str)
        return nil unless str
        # CII format 102 = YYYYMMDD
        Date.strptime(str, "%Y%m%d")
      end

      def parse_decimal(str)
        BigDecimal(str) if str
      end
    end
  end
end
