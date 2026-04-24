---
outline: deep
---

# PDF Embedder

Embed XML invoices into PDF/A-3 documents using Ghostscript. Loaded via `require "facture_x/pdf"` (not included by default).

## Embedder

```ruby
require "facture_x/pdf"

embedder = FactureX::PDF::Embedder.new
embedder.embed(
  pdf_path: "input.pdf",
  xml: xml_string,
  output_path: "output.pdf"
)
```

### `embed(pdf_path:, xml:, output_path:, version: "2p1", conformance_level: "EN 16931") → String`

Converts a PDF to PDF/A-3 and embeds the given XML as an associated file.

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `pdf_path` | `String` | (required) | Path to the input PDF |
| `xml` | `String` | (required) | XML content to embed (UBL or CII) |
| `output_path` | `String` | (required) | Path for the output PDF/A-3 file |
| `version` | `String` | `"2p1"` | ZUGFeRD version: `"2p1"`, `"2p0"`, `"1p0"`, `"rc"` |
| `conformance_level` | `String` | `"EN 16931"` | Profile level (version-dependent). Must match the invoice's CIUS — use `"XRECHNUNG"` for XRechnung invoices. |

**Returns:** `String` — the `output_path`

**Raises:**

| Exception | When |
|-----------|------|
| `FactureX::PDF::Embedder::GhostscriptNotFound` | `gs` is not installed or not in PATH |
| `FactureX::PDF::Embedder::EmbedError` | Ghostscript execution failed or `zugferd.ps` / ICC profile missing |
| `ArgumentError` | Invalid version, conformance level, or input file not found |

## Constants

### `FactureX::PDF::Embedder::VERSIONS`

```ruby
%w[rc 1p0 2p0 2p1]
```

### `FactureX::PDF::Embedder::CONFORMANCE_LEVELS`

Valid conformance levels per version:

| Version | Levels |
|---------|--------|
| `"2p1"` | MINIMUM, BASIC WL, BASIC, EN 16931, EXTENDED, XRECHNUNG |
| `"2p0"` | MINIMUM, BASIC WL, BASIC, EN 16931, EXTENDED, XRECHNUNG |
| `"1p0"` | BASIC, COMFORT, EXTENDED |

## Exceptions

### `FactureX::PDF::Embedder::GhostscriptNotFound`

Inherits from `FactureX::Error`. Raised when the `gs` binary cannot be found in PATH.

### `FactureX::PDF::Embedder::EmbedError`

Inherits from `FactureX::Error`. Raised when Ghostscript returns a non-zero exit code, or when required vendor files (`zugferd.ps`, `default_rgb.icc`) are missing.
