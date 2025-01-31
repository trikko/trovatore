# Trovatore

A fast tool for searching files by name

## Installation

### Prerequisites
- D compiler [dlang.org](https://dlang.org)

### Building from source

Clone the repository and build with DUB:

```bash
git clone https://github.com/yourusername/trovatore.git
cd trovatore
dub build --build=release
```

## Usage

Basic usage:
```bash
trovatore report.pdf
```

### Search Patterns

```bash
# Wildcards
# it matches report.pdf, report-blah.pdf, report-blah.pdf.2, ...
trovatore re?or*f

# Search modes (-m option):
# exact   - exact match
# ends    - matches if filename ends with pattern
# starts  - matches if filename starts with pattern
# contains - matches if filename contains pattern (default)
trovatore -m ends report.pdf
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
