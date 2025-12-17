---
title: Getting Started with TStorie
author: Maddest Labs
date: 2024-11-20
category: tutorials
tags: beginner, setup, guide
excerpt: A comprehensive guide to setting up and using the TStorie framework
published: true
featured: false
---

# Getting Started with TStorie

This guide will walk you through setting up your first TStorie application.

## Prerequisites

Before you begin, make sure you have:

- **Nim compiler** - Version 2.0 or later
- **Terminal emulator** - Any modern terminal with ANSI support
- **Text editor** - VSCode, Vim, or your favorite editor

## Installation

1. Clone the TStorie repository
2. Navigate to the project directory
3. Run the build script for your platform

### Linux/macOS

```bash
./build.sh
```

### Windows

```bash
./build-win.sh
```

## Your First TStorie App

Create a new file called `hello.nim`:

```nim
import tstorie

onInit = proc(state: AppState) =
  echo "Initializing..."

onRender = proc(state: AppState) =
  fgClear()
  fgWriteText(10, 10, "Hello, TStorie!")

onInput = proc(state: AppState, event: InputEvent): bool =
  if event.kind == KeyEvent and event.keyCode == ord('q'):
    state.running = false
    return true
  return false
```

## Understanding the Lifecycle

TStorie applications follow a clear lifecycle:

1. **onInit** - Called once when the application starts
2. **onUpdate** - Called every frame with delta time
3. **onRender** - Called every frame to draw the UI
4. **onInput** - Called when user input is received
5. **onShutdown** - Called when the application exits

## The Layer System

TStorie uses a layer-based rendering system:

- **Background Layer** - Rendered first (lowest Z-index)
- **Content Layer** - Main content area
- **Foreground Layer** - UI overlays (highest Z-index)

You can create custom layers and control the rendering order.

## Next Steps

Now that you understand the basics:

1. Explore the example applications in the `examples/` directory
2. Read the API documentation
3. Build your own TStorie application!

## Resources

- GitHub Repository: [Link to repo]
- Documentation: [Link to docs]
- Community Discord: [Link to Discord]

Happy coding!
