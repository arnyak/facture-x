require "nokogiri"
require "date"
require "bigdecimal"
require_relative "mapping"

module Zugpferd
  module UBL
    # Reads UBL 2.1 Invoice or Credit Note XML into the appropriate model class.
    #
    # @example
    #   doc = Zugpferd::UBL::Reader.new.read(File.read("invoice.xml"))
    class Reader
      include Mapping

      # Parses a UBL 2.1 Invoice or Credit Note XML string.
      #
      # @param xml_string [String] valid UBL 2.1 Invoice or Credit Note XML
      # @return [Model::BillingDocument]
      # @raise [Nokogiri::XML::SyntaxError] if the XML is malformed
      def read(xml_string)
        doc = Nokogiri::XML(xml_string) { |config| config.strict }
        root = doc.root
        @credit_note = root.name == "CreditNote"
        @ns = @credit_note ? CN_NS : NS
        build_invoice(root)
      end

      private

      def build_invoice(root)
        type_code_element = @credit_note ? "cbc:CreditNoteTypeCode" : INVOICE[:type_code]
        line_element = @credit_note ? "cac:CreditNoteLine" : INVOICE_LINE

        model_class = @credit_note ? Model::CreditNote : Model::Invoice

        delivery_node = root.at_xpath(DELIVERY, @ns)

        model_class.new(
          number: text(root, INVOICE[:number]),
          issue_date: parse_date(text(root, INVOICE[:issue_date])),
          due_date: parse_date(text(root, INVOICE[:due_date])),
          delivery_date: delivery_node ? parse_date(text(delivery_node, DELIVERY_DATE)) : nil,
          type_code: text(root, type_code_element),
          currency_code: text(root, INVOICE[:currency_code]),
          buyer_reference: text(root, INVOICE[:buyer_reference]),
          customization_id: text(root, INVOICE[:customization_id]),
          profile_id: text(root, INVOICE[:profile_id]),
          note: text(root, INVOICE[:note]),
          seller: build_party(root.at_xpath(SELLER, @ns)),
          buyer: build_party(root.at_xpath(BUYER, @ns)),
          line_items: root.xpath(line_element, @ns).map { |n| build_line_item(n) },
          allowance_charges: root.xpath(ALLOWANCE_CHARGE, @ns).map { |n| build_allowance_charge(n) },
          tax_breakdown: build_tax_breakdown(root),
          monetary_totals: build_monetary_totals(root.at_xpath(MONETARY_TOTAL, @ns)),
          payment_instructions: build_payment_instructions(root),
          invoice_period: build_invoice_period(root.at_xpath(INVOICE_PERIOD, @ns)),
          # Document references
          purchase_order_reference: text(root, PURCHASE_ORDER_REF),
          sales_order_reference: text(root, SALES_ORDER_REF),
          contract_reference: text(root, CONTRACT_REF),
          project_reference: text(root, PROJECT_REF),
          preceding_invoice_references: build_preceding_invoices(root),
          additional_documents: build_additional_documents(root),
          # Additional parties
          payee: build_payee_party(root.at_xpath(PAYEE_PARTY, @ns)),
          seller_tax_representative: build_tax_representative_party(root.at_xpath(TAX_REPRESENTATIVE_PARTY, @ns)),
          # Deliver-to
          deliver_to_name: build_delivery_party_name(root),
          deliver_to_identifier: build_delivery_location_id(root),
          deliver_to_address: build_delivery_address(root),
          # Document-level fields
          tax_currency_code: text(root, TAX_CURRENCY_CODE),
          buyer_accounting_reference: text(root, BUYER_ACCOUNTING_REF),
        )
      end

      def build_party(node)
        return nil unless node

        # Skip PartyIdentification with schemeID="SEPA" (that's BT-90 creditor reference, not BT-29)
        id_node = node.xpath("cac:PartyIdentification/cbc:ID", @ns)
          .reject { |n| n["schemeID"] == "SEPA" }.first

        party = Model::TradeParty.new(
          name: text(node, PARTY[:name]),
          trading_name: text(node, PARTY[:trading_name]),
          identifier: id_node&.text,
          legal_registration_id: text(node, PARTY[:legal_registration_id]),
          legal_form: text(node, PARTY[:legal_form]),
          vat_identifier: text(node, PARTY[:vat_identifier]),
          electronic_address: text(node, PARTY[:electronic_address]),
        )

        party.identifier_scheme = id_node["schemeID"] if id_node&.[]("schemeID")

        legal_id_node = node.at_xpath(PARTY[:legal_registration_id], @ns)
        party.legal_registration_id_scheme = legal_id_node["schemeID"] if legal_id_node&.[]("schemeID")

        endpoint = node.at_xpath(PARTY[:electronic_address], @ns)
        party.electronic_address_scheme = endpoint["schemeID"] if endpoint

        addr_node = node.at_xpath(POSTAL_ADDRESS, @ns)
        party.postal_address = build_postal_address(addr_node) if addr_node

        contact_node = node.at_xpath(CONTACT, @ns)
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

      def build_payment_instructions(root)
        means_node = root.at_xpath(PAYMENT_MEANS, @ns)
        return nil unless means_node

        # BT-90: In UBL, creditor reference is a PartyIdentification with schemeID="SEPA" on the seller
        creditor_ref = root.at_xpath(
          "#{SELLER}/cac:PartyIdentification/cbc:ID[@schemeID='SEPA']", @ns
        )&.text

        Model::PaymentInstructions.new(
          payment_means_code: text(means_node, PAYMENT[:payment_means_code]),
          payment_id: text(means_node, PAYMENT[:payment_id]),
          account_id: text(means_node, PAYMENT[:account_id]),
          account_name: text(means_node, PAYMENT[:account_name]),
          payment_service_provider_id: text(means_node, PAYMENT[:payment_service_provider_id]),
          card_account_id: text(means_node, PAYMENT[:card_account_id]),
          card_network_id: text(means_node, PAYMENT[:card_network_id]),
          card_holder_name: text(means_node, PAYMENT[:card_holder_name]),
          mandate_reference: text(means_node, PAYMENT[:mandate_reference]),
          debited_account_id: text(means_node, PAYMENT[:debited_account_id]),
          creditor_reference_id: creditor_ref,
          note: text(root, PAYMENT_TERMS_NOTE),
        )
      end

      def build_tax_breakdown(root)
        tax_totals = root.xpath(TAX_TOTAL, @ns)
        # Primary TaxTotal has subtotals; secondary (BT-111) has only TaxAmount
        primary = tax_totals.find { |tt| !tt.xpath(TAX_SUBTOTAL, @ns).empty? }
        primary ||= tax_totals.first
        return nil unless primary

        currency = primary.at_xpath("cbc:TaxAmount/@currencyID", @ns)&.text

        breakdown = Model::TaxBreakdown.new(
          tax_amount: text(primary, "cbc:TaxAmount"),
          currency_code: currency,
        )

        # BT-111: secondary TaxTotal without subtotals
        secondary = tax_totals.find { |tt| tt != primary && tt.xpath(TAX_SUBTOTAL, @ns).empty? }
        if secondary
          breakdown.tax_amount_in_accounting_currency = parse_decimal(text(secondary, "cbc:TaxAmount"))
          breakdown.tax_amount_in_accounting_currency_code = secondary.at_xpath("cbc:TaxAmount/@currencyID", @ns)&.text
        end

        breakdown.subtotals = primary.xpath(TAX_SUBTOTAL, @ns).map do |sub|
          sub_currency = sub.at_xpath("cbc:TaxableAmount/@currencyID", @ns)&.text
          Model::TaxSubtotal.new(
            taxable_amount: text(sub, TAX[:taxable_amount]),
            tax_amount: text(sub, TAX[:tax_amount]),
            category_code: text(sub, TAX[:category_code]),
            percent: parse_decimal(text(sub, TAX[:percent])),
            currency_code: sub_currency,
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
        item_node = node.at_xpath(ITEM, @ns)
        price_node = node.at_xpath(PRICE, @ns)
        doc_ref = node.at_xpath(LINE_DOC_REF, @ns)

        quantity_element = @credit_note ? "cbc:CreditedQuantity" : LINE[:invoiced_quantity]
        unit_code_element = @credit_note ? "cbc:CreditedQuantity/@unitCode" : LINE[:unit_code]

        obj_id_node = doc_ref&.at_xpath(LINE_DOC_REF_ID, @ns)

        Model::LineItem.new(
          id: text(node, LINE[:id]),
          invoiced_quantity: text(node, quantity_element),
          unit_code: node.at_xpath(unit_code_element, @ns)&.text,
          line_extension_amount: text(node, LINE[:line_extension_amount]),
          note: text(node, LINE[:note]),
          item: build_item(item_node),
          price: build_price(price_node),
          invoice_period: build_invoice_period(node.at_xpath(INVOICE_PERIOD, @ns)),
          allowance_charges: node.xpath(LINE_ALLOWANCE_CHARGE, @ns).map { |n| build_allowance_charge(n) },
          object_identifier: obj_id_node&.text,
          object_identifier_scheme: obj_id_node&.[]("schemeID"),
          order_line_reference: text(node, LINE_ORDER_REF),
        )
      end

      def build_item(node)
        return nil unless node

        std_id_node = node.at_xpath(ITEM_FIELDS[:standard_identifier], @ns)
        classification_nodes = node.xpath(ITEM_CLASSIFICATION, @ns)

        Model::Item.new(
          name: text(node, ITEM_FIELDS[:name]),
          description: text(node, ITEM_FIELDS[:description]),
          sellers_identifier: text(node, ITEM_FIELDS[:sellers_identifier]),
          buyers_identifier: text(node, ITEM_FIELDS[:buyers_identifier]),
          standard_identifier: std_id_node&.text,
          standard_identifier_scheme: std_id_node&.[]("schemeID"),
          country_of_origin: text(node, ITEM_FIELDS[:country_of_origin]),
          classification_codes: classification_nodes.map do |cc|
            { id: cc.text, list_id: cc["listID"] }
          end,
          tax_category: text(node, ITEM_FIELDS[:tax_category]),
          tax_percent: parse_decimal(text(node, ITEM_FIELDS[:tax_percent])),
        )
      end

      def build_price(node)
        return nil unless node

        Model::Price.new(
          amount: text(node, PRICE_FIELDS[:amount]),
        )
      end

      def build_allowance_charge(node)
        currency = node.at_xpath("cbc:Amount/@currencyID", @ns)&.text
        Model::AllowanceCharge.new(
          charge_indicator: text(node, ALLOWANCE_CHARGE_FIELDS[:charge_indicator]) == "true",
          reason: text(node, ALLOWANCE_CHARGE_FIELDS[:reason]),
          reason_code: text(node, ALLOWANCE_CHARGE_FIELDS[:reason_code]),
          amount: text(node, ALLOWANCE_CHARGE_FIELDS[:amount]),
          base_amount: parse_decimal(text(node, ALLOWANCE_CHARGE_FIELDS[:base_amount])),
          multiplier_factor: parse_decimal(text(node, ALLOWANCE_CHARGE_FIELDS[:multiplier_factor])),
          tax_category_code: text(node, ALLOWANCE_CHARGE_FIELDS[:tax_category_code]),
          tax_percent: parse_decimal(text(node, ALLOWANCE_CHARGE_FIELDS[:tax_percent])),
          currency_code: currency,
        )
      end

      def build_invoice_period(node)
        return nil unless node
        Model::InvoicePeriod.new(
          start_date: parse_date(text(node, PERIOD_START)),
          end_date: parse_date(text(node, PERIOD_END)),
        )
      end

      def build_preceding_invoices(root)
        root.xpath(PRECEDING_INVOICE_REF, @ns).map do |node|
          Model::DocumentReference.new(
            id: text(node, PRECEDING_INVOICE_REF_ID),
            issue_date: parse_date(text(node, PRECEDING_INVOICE_REF_DATE)),
          )
        end
      end

      def build_additional_documents(root)
        root.xpath(ADDITIONAL_DOC_REF, @ns).map do |node|
          attachment_node = node.at_xpath(ADDITIONAL_DOC_REF_ATTACHMENT, @ns)
          Model::DocumentReference.new(
            id: text(node, ADDITIONAL_DOC_REF_ID),
            description: text(node, ADDITIONAL_DOC_REF_DESC),
            uri: text(node, ADDITIONAL_DOC_REF_URI),
            attached_document: attachment_node&.text,
            mime_code: attachment_node&.[]("mimeCode"),
            filename: attachment_node&.[]("filename"),
          )
        end
      end

      def build_payee_party(node)
        return nil unless node
        Model::TradeParty.new(
          name: text(node, PARTY[:name]) || text(node, PARTY[:trading_name]),
          trading_name: text(node, PARTY[:trading_name]),
          identifier: text(node, PARTY[:identifier]),
          legal_registration_id: text(node, PARTY[:legal_registration_id]),
        )
      end

      def build_tax_representative_party(node)
        return nil unless node
        party = Model::TradeParty.new(
          name: text(node, "cac:PartyName/cbc:Name"),
          vat_identifier: text(node, PARTY[:vat_identifier]),
        )
        addr_node = node.at_xpath(POSTAL_ADDRESS, @ns)
        party.postal_address = build_postal_address(addr_node) if addr_node
        party
      end

      def build_delivery_party_name(root)
        delivery = root.at_xpath(DELIVERY, @ns)
        return nil unless delivery
        party = delivery.at_xpath(DELIVERY_PARTY, @ns)
        party ? text(party, DELIVERY_PARTY_NAME) : nil
      end

      def build_delivery_location_id(root)
        delivery = root.at_xpath(DELIVERY, @ns)
        return nil unless delivery
        location = delivery.at_xpath(DELIVERY_LOCATION, @ns)
        location ? text(location, DELIVERY_LOCATION_ID) : nil
      end

      def build_delivery_address(root)
        delivery = root.at_xpath(DELIVERY, @ns)
        return nil unless delivery
        location = delivery.at_xpath(DELIVERY_LOCATION, @ns)
        return nil unless location
        addr_node = location.at_xpath(DELIVERY_ADDRESS, @ns)
        return nil unless addr_node
        # UBL delivery address uses same structure but different element name
        Model::PostalAddress.new(
          country_code: text(addr_node, ADDRESS[:country_code]),
          street_name: text(addr_node, ADDRESS[:street_name]),
          additional_street_name: text(addr_node, ADDRESS[:additional_street_name]),
          city_name: text(addr_node, ADDRESS[:city_name]),
          postal_zone: text(addr_node, ADDRESS[:postal_zone]),
          country_subdivision: text(addr_node, ADDRESS[:country_subdivision]),
        )
      end

      def text(node, xpath)
        node.at_xpath(xpath, @ns)&.text
      end

      def parse_date(str)
        Date.parse(str) if str
      end

      def parse_decimal(str)
        BigDecimal(str) if str
      end
    end
  end
end
