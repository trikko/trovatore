# Trovatore

A fast tool for searching files by name


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
## Nightly builds:

Automatically compiled binaries are available [here](https://www.dropbox.com/scl/fo/2pjv2ul8emf36m0ol0fhd/AHTj41H5iyns_uyHi7KQwSY?rlkey=bv7x3wsqtgs6q1oj84zo3jxha&st=49yzn64o&dl=0)

## Building from source

### Prerequisites
- D compiler [dlang.org](https://dlang.org)

### Build

Clone the repository and build with DUB:

```bash
git clone https://github.com/yourusername/trovatore.git
cd trovatore
dub build --build=release
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.
