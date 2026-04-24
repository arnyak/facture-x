module Zugpferd
  module Model
    # A document reference used for preceding invoices (BG-3) and
    # additional supporting documents (BG-24).
    #
    # @example Preceding invoice reference
    #   ref = DocumentReference.new(id: "INV-001", issue_date: Date.new(2024, 1, 15))
    #
    # @example Additional supporting document with attachment
    #   ref = DocumentReference.new(id: "ATT-001", description: "Timesheet",
    #     attached_document: Base64.encode64(file_content),
    #     mime_code: "application/pdf", filename: "timesheet.pdf")
    class DocumentReference
      # @return [String] BT-25/BT-122 Document reference identifier
      # @return [Date, nil] BT-26/BT-123 Document issue date (BG-3 only)
      # @return [String, nil] BT-123 Supporting document description (BG-24 only)
      # @return [String, nil] BT-124 External document location (URI)
      # @return [String, nil] BT-125 Attached document (Base64-encoded)
      # @return [String, nil] BT-125-1 Attached document MIME code
      # @return [String, nil] BT-125-2 Attached document filename
      attr_accessor :id, :issue_date, :description, :uri,
                    :attached_document, :mime_code, :filename

      # @param id [String] Document reference identifier
      # @param rest [Hash] additional attributes set via accessors
      def initialize(id:, **rest)
        @id = id
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
