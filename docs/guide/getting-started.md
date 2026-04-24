---
outline: deep
---

# Getting Started

FactureX is a Ruby library for reading and writing XRechnung, ZUGFeRD and Factur-X electronic invoices (e-Rechnung) according to EN 16931.

## Installation

Add FactureX to your Gemfile:

```ruby
gem "facture_x"
```

Then run:

```bash
bundle install
```

## Requirements

- Ruby >= 3.2
- [Nokogiri](https://nokogiri.org/) ~> 1.16

## Quick Example

```ruby
require "facture_x"

# Read a UBL invoice
xml = File.read("invoice.xml")
invoice = FactureX::UBL::Reader.new.read(xml)

puts invoice.number        # => "INV-2024-001"
puts invoice.seller.name   # => "Seller GmbH"
puts invoice.monetary_totals.payable_amount  # => 1190.00

# Write it back
output = FactureX::UBL::Writer.new.write(invoice)
File.write("output.xml", output)
```

## CII Format

The same workflow works with UN/CEFACT CII invoices:

```ruby
xml = File.read("invoice_cii.xml")
invoice = FactureX::CII::Reader.new.read(xml)
output = FactureX::CII::Writer.new.write(invoice)
```

## Format Conversion

Since both formats share the same data model, you can convert between UBL and CII:

```ruby
# Read CII, write UBL
invoice = FactureX::CII::Reader.new.read(cii_xml)
ubl_xml = FactureX::UBL::Writer.new.write(invoice)
```
