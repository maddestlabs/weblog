---
title: Interactive Code Demonstrations
author: Maddest Labs
date: 2024-12-20
category: tutorials
tags: nimini, interactive, code
excerpt: Learn how to embed executable code directly in your articles
published: true
featured: true
---

# Interactive Code Demonstrations

One of the most powerful features of the TStorie Blog Engine is the ability to embed executable code directly in your articles. This allows for interactive demonstrations and live examples.

## How It Works

Articles can contain Nim code blocks with lifecycle hooks:

- `on:init` - Executed once when the article loads
- `on:render` - Executed every frame while viewing the article
- `on:update` - Executed every frame with delta time

## Example: Dynamic Counter

Here's a simple counter that increments every second:

```nim on:init
var counter = 0
var elapsed = 0.0
```

```nim on:update
elapsed += dt
if elapsed >= 1.0:
  counter += 1
  elapsed = 0.0
```

```nim on:render
let msg = "Counter: " & $counter
fgWriteText(10, 15, msg, defaultStyle())
```

The code above creates a counter variable, updates it every second, and renders the current value to the screen!

## Benefits

This approach offers several advantages:

1. **Live Examples** - Readers can see code in action immediately
2. **No Setup Required** - Works in both native and web builds
3. **Educational** - Perfect for tutorials and demonstrations
4. **Interactive** - Create engaging, dynamic content

## Try It Yourself

When viewing this article, you should see the counter incrementing in real-time. This demonstrates how powerful embedded code execution can be for creating rich, interactive blog content.

Stay tuned for more advanced examples using the nimini scripting system!
