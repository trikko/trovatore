# Trovatore

A fast tool for searching files by name.

When using `find` or similar tools, searches often dive into useless directories full of temporary files and subfolders (cache, build, node_modules, etc.). When looking for *that file* you saved somewhere, it's definitely not in one of those. In fact, it's probably in one of the most obvious places (Desktop, Documents, etc.).

Trovatore combines these two insights: it ignores "blackhole" folders and prioritizes searching in directories where your file is most likely to be found.

Unlike other solutions, it doesn't rely on an indexed database, performing real-time searches directly on the filesystem.

## Quick install

Simply run the following command in your terminal:

```bash
curl https://trikko.github.io/trovatore/install.sh | bash
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

> [!WARNING]
> When using shells like zsh (default on macOS), wildcards need to be quoted to prevent shell expansion. For example:
> ```bash
> # This won't work in zsh
> trovatore re?or*f
>
> # Use this instead
> trovatore "re?or*f"
> ```


## Download

Automatically compiled binaries are available [here](https://trikko.github.io/trovatore/)

## Building from source

### Prerequisites
- D compiler [dlang.org](https://dlang.org)

### Build

Clone the repository and build with DUB:

```bash
git clone https://github.com/trikko/trovatore
cd trovatore
dub build --build=release
```
## Configuration

Trovatore allows you to customize the directories it searches and excludes by modifying configuration files.

### Sources and Blacklist

The directories to be searched are specified in the `sources.d` directory. Each file in this directory can list one or more directories to include in the search. By default, if no sources are found, Trovatore will create default sources including user directories, the home directory, and some system directories.

Directories to be excluded from the search are specified in the `blacklist` file. This file contains a list of directories that Trovatore will ignore during the search. If the `blacklist` file does not exist, a default blacklist is created, which includes common temporary and system directories.

To customize these settings, edit the files in the `sources.d` directory and the `blacklist` file located in the configuration directory. The configuration directory path varies by operating system:
- On Linux: `~/.config/trovatore/`
- On macOS: `~/Library/Application Support/trovatore/`

## License

This project is licensed under the MIT License - see the LICENSE file for details.
