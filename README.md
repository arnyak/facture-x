# FactureX

A Ruby library for reading and writing **XRechnung**, **ZUGFeRD** and **Factur-X** electronic invoices according to **EN 16931**, supporting both **UBL 2.1** and **UN/CEFACT CII** syntaxes.

Built for Ruby developers integrating e-invoicing into their applications, with full support for the French electronic invoicing reform (réforme de la facturation électronique).

## Features

- Syntax-agnostic data model based on EN 16931 Business Terms (BTs)
- UBL 2.1 Reader & Writer (Invoice and Credit Note)
- UN/CEFACT CII Reader & Writer
- PDF/A-3 embedding via Ghostscript — create ZUGFeRD / Factur-X hybrid invoices
- XSD and Schematron validation (EN 16931 + XRechnung) — optional, requires Java + Saxon
- Supported document types:
  - `380` — Commercial Invoice
  - `381` — Credit Note (UBL: separate `<CreditNote>` root element)
  - `384` — Corrected Invoice
  - `389` — Self-billed Invoice
  - `326` — Partial Invoice
  - `386` — Prepayment Invoice
- French e-invoicing reform ready:
  - SIREN/SIRET support via identifier scheme IDs (BT-29-1, BT-30-1)
  - Invoicing period (BG-14 / BG-26)
  - Preceding invoice references (BG-3) and additional documents (BG-24)
  - Document references: purchase order (BT-13), contract (BT-12), project (BT-11), sales order (BT-14)
  - Payee party (BG-10) and seller tax representative (BG-11)
  - Deliver-to address (BG-15)
  - Line-level allowances/charges (BG-27 / BG-28)
  - Item identifiers: buyer's ID (BT-156), GTIN (BT-157), classification (BT-158), country of origin (BT-159)
  - Payment BIC/SWIFT (BT-86) and account name (BT-85)
  - Tax currency code (BT-6) with BT-111 accounting currency support
- No Rails dependency
- BigDecimal for all monetary amounts

## Installation

```ruby
# Gemfile
gem "facture_x"
```

```bash
bundle install
```

Or install directly:

```bash
gem install facture_x
```

## Usage

### Reading a UBL invoice

```ruby
require "facture_x"

xml = File.read("invoice_ubl.xml")
invoice = FactureX::UBL::Reader.new.read(xml)

puts invoice.number          # BT-1
puts invoice.seller.name     # BG-4
puts invoice.type_code       # "380", "381", etc.

invoice.line_items.each do |line|
  puts "#{line.item.name}: #{line.line_extension_amount}"
end
```

### Reading a CII invoice

```ruby
xml = File.read("invoice_cii.xml")
invoice = FactureX::CII::Reader.new.read(xml)
```

The data model is identical regardless of whether UBL or CII is used.

### Writing a UBL invoice

```ruby
invoice = FactureX::Model::Invoice.new(
  number: "INV-2024-001",
  issue_date: Date.today,
  type_code: "380",
  currency_code: "EUR",
)

invoice.seller = FactureX::Model::TradeParty.new(name: "Seller GmbH")
invoice.buyer  = FactureX::Model::TradeParty.new(name: "Buyer AG")

# ... set line items, tax, totals, payment ...

xml = FactureX::UBL::Writer.new.write(invoice)
File.write("output.xml", xml)
```

### Writing a Credit Note

```ruby
credit_note = FactureX::Model::CreditNote.new(
  number: "CN-2024-001",
  issue_date: Date.today,
)

# The writer automatically generates <CreditNote> instead of <Invoice>
xml = FactureX::UBL::Writer.new.write(credit_note)
```

### Converting between syntaxes

```ruby
# Read CII, write as UBL
invoice = FactureX::CII::Reader.new.read(cii_xml)
ubl_xml = FactureX::UBL::Writer.new.write(invoice)
```

### Creating a ZUGFeRD / Factur-X PDF

Requires [Ghostscript](https://ghostscript.com/) installed on the system.

```ruby
require "facture_x"
require "facture_x/pdf"  # explicit opt-in

xml = FactureX::CII::Writer.new.write(invoice)

embedder = FactureX::PDF::Embedder.new
embedder.embed(
  pdf_path: "rechnung.pdf",
  xml: xml,
  output_path: "rechnung_zugferd.pdf",
  version: "2p1",
  conformance_level: "XRECHNUNG"  # use "EN 16931" for non-XRechnung invoices
)
```

### Validating an invoice

Requires Java and Saxon HE. Install via `bin/setup-schemas`.

```ruby
require "facture_x"
require "facture_x/validation"  # explicit opt-in, requires Java + Saxon

xml = FactureX::CII::Writer.new.write(invoice)

validator = FactureX::Validation::SchematronValidator.new(schemas_path: "vendor/schemas")
errors = validator.validate(xml, rule_set: :xrechnung_cii)
fatals = errors.select { |e| e.flag == "fatal" }

if fatals.any?
  fatals.each { |e| puts "[#{e.id}] #{e.text}" }
end
```

## Data Model

The model maps to the Business Groups of EN 16931:

| Class | Business Group | Description |
|-------|---------------|-------------|
| `Model::Invoice` | BG-0 | Commercial Invoice (380) |
| `Model::CreditNote` | BG-0 | Credit Note (381) |
| `Model::CorrectedInvoice` | BG-0 | Corrected Invoice (384) |
| `Model::SelfBilledInvoice` | BG-0 | Self-billed Invoice (389) |
| `Model::PartialInvoice` | BG-0 | Partial Invoice (326) |
| `Model::PrepaymentInvoice` | BG-0 | Prepayment Invoice (386) |
| `Model::TradeParty` | BG-4 / BG-7 / BG-10 / BG-11 | Seller / Buyer / Payee / Tax representative |
| `Model::PostalAddress` | BG-5 / BG-8 / BG-15 | Postal address (incl. deliver-to) |
| `Model::Contact` | BG-6 / BG-9 | Contact information |
| `Model::InvoicePeriod` | BG-14 / BG-26 | Invoicing period (document and line level) |
| `Model::DocumentReference` | BG-3 / BG-24 | Preceding invoice reference / Additional documents |
| `Model::LineItem` | BG-25 | Invoice line (with line-level allowances/charges) |
| `Model::Item` | BG-31 | Item information (GTIN, classification, origin) |
| `Model::Price` | BG-29 | Price details |
| `Model::MonetaryTotals` | BG-22 | Document totals |
| `Model::TaxBreakdown` | BG-23 | VAT breakdown (incl. BT-111 accounting currency) |
| `Model::PaymentInstructions` | BG-16 | Payment information (IBAN, BIC, card, direct debit) |
| `Model::AllowanceCharge` | BG-20 / BG-21 / BG-27 / BG-28 | Document and line-level allowances and charges |

## Requirements

- Ruby >= 3.2
- nokogiri ~> 1.16
- bigdecimal ~> 3.1

## Development

```bash
bundle install
bin/setup-schemas    # Downloads XSD schemas, CEN Schematron, XRechnung test suite
bundle exec rake test
```

### Running integration tests

Integration tests (Schematron validation, roundtrips) require Java. Install OpenJDK:

```bash
# macOS
brew install openjdk
sudo ln -sfn "$(brew --prefix openjdk)/libexec/openjdk.jdk" /Library/Java/JavaVirtualMachines/openjdk.jdk

# Ubuntu / Debian
sudo apt-get install default-jre-headless
```

Then run the full suite:

```bash
bundle exec rake test              # unit + integration
bundle exec rake test:unit         # unit tests only (no Java needed)
bundle exec rake test:integration  # integration tests only (Java required)
```

## License

MIT
