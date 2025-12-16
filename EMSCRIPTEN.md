# Emscripten Setup Instructions

## Installation

Emscripten has been installed to: `~/.emsdk` (version 4.0.21)

## Usage

To use Emscripten in your current shell session:

```bash
source ~/.emsdk/emsdk_env.sh
```

Or use the provided .envrc file:

```bash
source .envrc
```

## Building for Web

Once Emscripten is activated, you can build for web using:

```bash
./build-web.sh
```

See `./build-web.sh --help` for more options.

## Updating Emscripten

To update to the latest version:

```bash
cd ~/.emsdk
./emsdk install latest
./emsdk activate latest
```

## Gitignore Configuration

The following Emscripten-related files/directories are ignored:
- `emsdk/` - SDK installation directory
- `.emsdk/` - Home directory SDK installation  
- `.emscripten_cache/` - Emscripten build cache
- `.emscripten_ports/` - Downloaded port libraries
- `.emscripten_sanity` - Sanity check file
- `.envrc` - Environment setup file
