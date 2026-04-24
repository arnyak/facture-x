# Changelog

## [Unreleased]

## [0.4.0] - 2026-04-24

### Added

- **Invoice period** (BG-14 / BG-26): new `Model::InvoicePeriod` class with `start_date` and `end_date`, supported at both document and line level
- **Document references** (BG-3, BT-11 to BT-14, BG-24): new `Model::DocumentReference` class for preceding invoice references, additional supporting documents (with attachment/URI support), purchase order reference, contract reference, project reference, and sales order reference
- **Payee party** (BG-10): `payee` field on billing documents, reuses `TradeParty`
- **Seller tax representative** (BG-11): `seller_tax_representative` field on billing documents, reuses `TradeParty`
- **Deliver-to information** (BG-13 / BG-15): `deliver_to_name`, `deliver_to_identifier`, `deliver_to_address` fields for ship-to party and address
- **Enhanced postal address**: `additional_street_name` (BT-36), `address_line_3` (BT-162), `country_subdivision` (BT-39)
- **Payment account name** (BT-85) and **BIC/SWIFT** (BT-86): `account_name` and `payment_service_provider_id` on `PaymentInstructions`
- **Line-level allowances and charges** (BG-27 / BG-28): `allowance_charges` array on `LineItem`
- **Line object identifier** (BT-128): `object_identifier` and `object_identifier_scheme` on `LineItem`
- **Line order reference** (BT-132): `order_line_reference` on `LineItem`
- **Item buyer's identifier** (BT-156): `buyers_identifier` on `Item`
- **Standard item identification** (BT-157): `standard_identifier` and `standard_identifier_scheme` on `Item` (e.g., GTIN/EAN)
- **Item classification codes** (BT-158): read/write support for `classification_codes` (already existed in model)
- **Item country of origin** (BT-159): `country_of_origin` on `Item`
- **Identifier scheme IDs** (BT-29-1, BT-30-1): `identifier_scheme` and `legal_registration_id_scheme` on `TradeParty`
- **Tax currency code** (BT-6): `tax_currency_code` on billing documents
- **Tax amount in accounting currency** (BT-111): `tax_amount_in_accounting_currency` on `TaxBreakdown`, with proper second TaxTotal generation in UBL and CII
- **Buyer accounting reference** (BT-19): `buyer_accounting_reference` on billing documents

### Fixed

- UBL reader no longer reads SEPA creditor reference (`schemeID="SEPA"`) as the party identifier, preventing duplicate `PartyIdentification` elements on roundtrip (UBL-SR-29)

## [0.3.4] - 2026-02-19

### Fixed

- `bin/setup-schemas`: use `$(pwd)/vendor` instead of path relative to script location
- `bin/setup-schemas`: fix UBL ZIP extraction path (`xsd/*` instead of `os-UBL-2.1/xsd/*`)
- `bin/setup-schemas`: download CII D16B XSD from GitHub release asset (unece.org blocked by Cloudflare)
- `bin/setup-schemas`: flatten deeply nested CII XSD files after extraction
- `bin/setup-schemas`: fix XRechnung Schematron release tag (`v2.5.0` instead of `release-2.5.0`)

## [0.3.3] - 2026-02-19

### Fixed

- Set browser User-Agent on all curl requests in `bin/setup-schemas` to avoid throttling

## [0.3.2] - 2026-02-19

### Fixed

- Remove `spec.executables` — `bin/setup-schemas` is a project-local bash script, not a gem executable

## [0.3.1] - 2026-02-19

### Added

- `bin/setup-schemas` is now included in the gem as an executable

### Fixed

- Missing `require "zugpferd/validation"` in Rakefile `validate` task

## [0.3.0] - 2026-02-15

### Added

- PDF/A-3 embedding via Ghostscript (`Zugpferd::PDF::Embedder`) — create ZUGFeRD / Factur-X hybrid invoices
- Support for ZUGFeRD versions 1.0, 2.0 and 2.1 with all conformance levels
- XSD and Schematron validation included in gem (`require "zugpferd/validation"`) — optional, requires Java + Saxon
- Actual delivery date (BT-72) support in data model, UBL and CII readers/writers
- veraPDF validation wrapper (`Zugpferd::Validation::PdfValidator`) for PDF/A-3 compliance checks
- Mustangproject validation wrapper (`Zugpferd::Validation::MustangValidator`) for full ZUGFeRD validation
- Docker setup for veraPDF (REST API) and Mustangproject (CLI)
- `bin/setup-schemas` downloads Saxon HE, XSD schemas, CEN/XRechnung Schematron, `zugferd.ps` and `default_rgb.icc`

## [0.2.0] - 2026-02-15

### Added

- `BillingDocument` module with shared attributes and initialization logic
- Dedicated classes for each document type:
  - `Model::CreditNote` (type code 381)
  - `Model::CorrectedInvoice` (type code 384)
  - `Model::SelfBilledInvoice` (type code 389)
  - `Model::PartialInvoice` (type code 326)
  - `Model::PrepaymentInvoice` (type code 386)

### Changed

- `Model::Invoice` now includes `BillingDocument` instead of defining attributes directly
- UBL Reader returns `Model::CreditNote` for Credit Note documents
- CII Reader maps type codes to the appropriate model class
- Writer parameter renamed from `invoice` to `document`

### Breaking

- UBL Reader now returns `Model::CreditNote` (instead of `Model::Invoice`) for type code 381
- CII Reader returns type-specific classes based on the document's type code

## [0.1.0] - 2026-02-14

### Added

- Syntax-agnostic EN 16931 data model with all mandatory and common optional fields
- UBL 2.1 Reader and Writer (Invoice and Credit Note)
- UN/CEFACT CII Reader and Writer
- Document-level allowances and charges (BG-20/BG-21)
- XRechnung CIUS support (BT-10, BT-34/BT-49 electronic addresses)
- Payment types: credit transfer, direct debit, payment card
- VitePress documentation site
