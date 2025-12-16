# TStorie Blog Engine Architecture

A comprehensive guide to building a Terminal User Interface (TUI) blog using the TStorie engine.

## Overview

TStorie's built-in markdown support, layer system, and Nimini code execution make it ideal for building a dynamic TUI blog. Articles are markdown files with optional executable Nim code blocks, allowing for rich, interactive content.

## Directory Structure

```
blog/
├── templates/
│   ├── header.nim          # Reusable header component
│   ├── footer.nim          # Reusable footer component
│   ├── navigation.nim      # Navigation menu component
│   └── content.nim         # Default article renderer (handles markdown → TUI)
│
├── articles/
│   ├── 2024/
│   │   ├── 12/
│   │   │   ├── 2024-12-01-first-post.md
│   │   │   └── 2024-12-15-tui-animations.md
│   │   └── 11/
│   │       └── 2024-11-20-getting-started.md
│   ├── 2025/
│   │   └── 01/
│   │       └── 2025-01-05-advanced-topics.md
│   └── index.json          # Article metadata index
│
├── pages/
│   ├── about.md
│   ├── contact.md
│   └── index.md
│
├── assets/
│   ├── ascii-art/         # ASCII art assets for articles
│   └── data/              # Data files referenced by articles
│
└── blog_engine.nim         # Main blog orchestrator
```

## Article Organization Strategies

### 1. Date-Based Structure (Recommended for Blogs)

Organize articles by year and month for easy chronological browsing:

```
articles/
├── 2024/
│   ├── 12/
│   │   ├── 2024-12-01-first-post.md
│   │   ├── 2024-12-15-second-post.md
│   │   └── 2024-12-28-year-review.md
│   ├── 11/
│   └── 10/
└── 2025/
    └── 01/
```

**Naming Convention:** `YYYY-MM-DD-slug.md`

**Benefits:**
- Easy to find articles by date
- Natural archival structure
- Simple sorting and filtering
- Scales well with many articles

### 2. Category-Based Structure

Organize by topic when your blog has distinct subject areas:

```
articles/
├── tutorials/
│   ├── 2024-12-01-getting-started.md
│   └── 2024-12-15-advanced-features.md
├── reviews/
│   └── 2024-12-10-tool-review.md
├── projects/
│   └── 2024-12-20-my-project.md
└── misc/
    └── 2024-12-25-random-thoughts.md
```

**Benefits:**
- Thematic grouping
- Easy to build category navigation
- Good for multi-topic blogs

### 3. Hybrid Structure (Best of Both)

Combine categories with date organization:

```
articles/
├── tutorials/
│   ├── 2024/
│   │   └── 12/
│   │       └── 2024-12-01-getting-started.md
│   └── index.json
├── reviews/
│   ├── 2024/
│   │   └── 12/
│   │       └── 2024-12-10-tool-review.md
│   └── index.json
└── index.json              # Main index
```

### 4. Tag-Based Organization

Use flat structure with tags in front matter:

```
articles/
├── getting-started.md
├── advanced-features.md
└── tool-review.md
```

Tags defined in front matter:
```yaml
---
tags: tutorial, nim, beginner
category: tutorials
---
```

## Article Metadata Index

Create `articles/index.json` to track all articles:

```json
{
  "articles": [
    {
      "filename": "2024/12/2024-12-01-first-post.md",
      "title": "My First Post",
      "slug": "first-post",
      "date": "2024-12-01",
      "author": "Your Name",
      "category": "tutorials",
      "tags": ["nim", "tui", "beginner"],
      "excerpt": "An introduction to building TUI blogs...",
      "featured": true,
      "published": true
    },
    {
      "filename": "2024/12/2024-12-15-tui-animations.md",
      "title": "Creating TUI Animations",
      "slug": "tui-animations",
      "date": "2024-12-15",
      "author": "Your Name",
      "category": "tutorials",
      "tags": ["nim", "tui", "advanced", "animation"],
      "excerpt": "Learn how to create smooth animations...",
      "featured": false,
      "published": true
    }
  ],
  "categories": ["tutorials", "reviews", "projects"],
  "tags": ["nim", "tui", "beginner", "advanced", "animation"]
}
```

**Alternative:** Generate index automatically by scanning article front matter.

## Article Structure

### Basic Article Template

**articles/2024/12/2024-12-01-first-post.md:**

```markdown
---
title: My First Post
author: Your Name
date: 2024-12-01
category: tutorials
tags: nim, tui, beginner
excerpt: An introduction to building TUI blogs with TStorie
published: true
featured: false
---

# My First Post

Welcome to my TUI blog! This article demonstrates the basics of TStorie.

## Introduction

Regular markdown content is automatically rendered by `content.nim`.
You don't need to write any code blocks unless you want custom rendering.

## Features

- **Automatic rendering** - content.nim handles text layout
- **Custom code blocks** - Add interactivity when needed
- **Layers** - Content is rendered on the content layer by default
```

### Article with Custom Rendering

**articles/2024/12/2024-12-15-interactive-demo.md:**

```markdown
---
title: Interactive Counter Demo
author: Your Name
date: 2024-12-15
category: tutorials
tags: nim, tui, interactive, advanced
excerpt: An interactive counter built with TStorie
hasCustomCode: true
---

# Interactive Counter Demo

This article includes custom Nimini code for interactivity.

```nim on:init
# Initialize article-specific state
var counter = 0
var lastUpdate = 0.0
```

```nim on:render
# Custom rendering for this article
# The content.nim default renderer is bypassed when on:render is present

# Draw title
fgWriteText(2, 2, "Interactive Counter Demo")

# Draw counter
var counterText = "Count: " & intToStr(counter)
fgWriteText(2, 5, counterText)

# Draw instructions
fgWriteText(2, 8, "Press SPACE to increment")
fgWriteText(2, 9, "Press R to reset")
```

```nim on:input
# Handle keyboard input for this article
if keyCode == INPUT_SPACE:
  counter = counter + 1
  return true  # Indicate we handled the input

if keyCode == ord('r') or keyCode == ord('R'):
  counter = 0
  return true

return false  # Let the blog engine handle other keys
```

```nim on:update
# Optional: Auto-increment every 2 seconds
if totalTime - lastUpdate > 2.0:
  counter = counter + 1
  lastUpdate = totalTime
```
```

## Template Components

### content.nim - Default Article Renderer

This template handles rendering for articles without custom `on:render` blocks:

```nim
# templates/content.nim
# Default content renderer for blog articles

# Renders markdown content from front matter and article body
# This is called automatically unless the article has custom on:render blocks

proc renderArticleContent(article: Article, startY: int) =
  var y = startY
  var contentStyle = defaultStyle()
  contentStyle.fg = white()
  
  # Render title
  var titleStyle = defaultStyle()
  titleStyle.fg = cyan()
  titleStyle.bold = true
  fgWriteText(2, y, article.title)
  y = y + 2
  
  # Render metadata (author, date)
  var metaStyle = defaultStyle()
  metaStyle.fg = gray(180)
  fgWriteText(2, y, "By " & article.author & " on " & article.date)
  y = y + 2
  
  # Render tags
  if article.tags.len > 0:
    var tagText = "Tags: " & article.tags.join(", ")
    fgWriteText(2, y, tagText)
    y = y + 2
  
  # Separator
  var sepStyle = defaultStyle()
  sepStyle.fg = gray(100)
  fgFillRect(2, y, termWidth - 4, 1, "─")
  y = y + 2
  
  # Render article body (word-wrapped)
  # This would be the actual markdown content parsed and rendered
  for line in article.bodyLines:
    if y >= termHeight - 3:  # Leave room for footer
      break
    fgWriteText(2, y, line)
    y = y + 1
```

### header.nim - Blog Header

```nim
# templates/header.nim
# Renders the blog header (title, navigation)

proc renderHeader() =
  # Clear header layer
  bgClear()
  
  # Blog title
  var titleStyle = defaultStyle()
  titleStyle.fg = cyan()
  titleStyle.bold = true
  bgWriteText(2, 0, "My TUI Blog")
  
  # Navigation hint
  var navStyle = defaultStyle()
  navStyle.fg = yellow()
  bgWriteText(termWidth - 30, 0, "↑/↓: Navigate  Q: Quit")
  
  # Separator
  var sepStyle = defaultStyle()
  sepStyle.fg = gray(100)
  bgFillRect(0, 1, termWidth, 1, "─")
```

### footer.nim - Blog Footer

```nim
# templates/footer.nim
# Renders the blog footer (status, help)

proc renderFooter() =
  var y = termHeight - 1
  
  # Separator
  var sepStyle = defaultStyle()
  sepStyle.fg = gray(100)
  bgFillRect(0, y - 1, termWidth, 1, "─")
  
  # Status/help text
  var helpStyle = defaultStyle()
  helpStyle.fg = gray(150)
  bgWriteText(2, y, "Article " & intToStr(currentArticleIndex + 1) & "/" & intToStr(totalArticles))
  bgWriteText(termWidth - 20, y, "Press H for help")
```

### navigation.nim - Article Navigation

```nim
# templates/navigation.nim
# Handles article list and navigation

proc renderNavigationMenu() =
  fgClear()
  
  var y = 3
  var titleStyle = defaultStyle()
  titleStyle.fg = cyan()
  titleStyle.bold = true
  fgWriteText(2, y, "Articles")
  y = y + 2
  
  # Render article list
  var i = 0
  while i < articles.len:
    var style = defaultStyle()
    
    # Highlight current article
    if i == currentArticleIndex:
      style.fg = yellow()
      style.bold = true
      fgWriteText(0, y, "►")
    else:
      style.fg = white()
    
    var dateStr = articles[i].date
    var title = articles[i].title
    fgWriteText(2, y, dateStr & " - " & title)
    
    y = y + 1
    i = i + 1
    
    if y >= termHeight - 3:
      break
```

## Blog Engine Implementation

**blog_engine.nim:**

```nim
import strutils, os, json, tables
import tstorie
import lib/storie_md

type
  Article = object
    filename: string
    title: string
    slug: string
    date: string
    author: string
    category: string
    tags: seq[string]
    excerpt: string
    published: bool
    featured: bool
    bodyContent: string
    hasCustomCode: bool
    
  BlogState = ref object
    articles: seq[Article]
    currentArticleIndex: int
    currentView: string  # "list", "article", "about"
    scrollPos: int
    headerLayer: Layer
    contentLayer: Layer
    footerLayer: Layer

var blog: BlogState

proc loadArticleIndex(): seq[Article] =
  ## Load articles from index.json or scan directory
  result = @[]
  
  let indexPath = "articles/index.json"
  if fileExists(indexPath):
    let jsonContent = readFile(indexPath)
    let data = parseJson(jsonContent)
    
    for item in data["articles"]:
      var article = Article(
        filename: item["filename"].getStr(),
        title: item["title"].getStr(),
        slug: item["slug"].getStr(),
        date: item["date"].getStr(),
        author: item["author"].getStr(),
        category: item["category"].getStr(),
        excerpt: item["excerpt"].getStr(),
        published: item["published"].getBool(),
        featured: item{"featured"}.getBool(false)
      )
      
      # Parse tags
      for tag in item["tags"]:
        article.tags.add(tag.getStr())
      
      # Only include published articles
      if article.published:
        result.add(article)
  
  # Sort by date descending (newest first)
  result.sort(proc(a, b: Article): int = 
    if a.date > b.date: -1 
    elif a.date < b.date: 1 
    else: 0
  )

proc loadArticleContent(article: var Article) =
  ## Load the actual markdown content for an article
  let fullPath = "articles/" & article.filename
  if fileExists(fullPath):
    let content = readFile(fullPath)
    let doc = parseMarkdownDocument(content)
    
    # Check if article has custom code blocks
    article.hasCustomCode = doc.codeBlocks.len > 0
    
    # Store body content for default renderer
    article.bodyContent = content

proc renderCurrentArticle() =
  ## Render the currently selected article
  blog.contentLayer.buffer.clearTransparent()
  
  if blog.currentArticleIndex < 0 or blog.currentArticleIndex >= blog.articles.len:
    return
  
  var article = blog.articles[blog.currentArticleIndex]
  
  # Load content if not already loaded
  if article.bodyContent.len == 0:
    loadArticleContent(article)
  
  if article.hasCustomCode:
    # Article has custom rendering code - execute it
    # This would integrate with the Nimini execution system
    discard
  else:
    # Use default content.nim renderer
    renderArticleContent(article, startY = 3)

onInit = proc(state: AppState) =
  blog = BlogState()
  blog.headerLayer = state.addLayer("header", 100)
  blog.contentLayer = state.addLayer("content", 50)
  blog.footerLayer = state.addLayer("footer", 90)
  
  blog.articles = loadArticleIndex()
  blog.currentArticleIndex = 0
  blog.currentView = "article"
  blog.scrollPos = 0

onRender = proc(state: AppState) =
  renderHeader()
  
  case blog.currentView
  of "list":
    renderNavigationMenu()
  of "article":
    renderCurrentArticle()
  of "about":
    # Render about page
    discard
  else:
    discard
  
  renderFooter()

onInput = proc(state: AppState, event: InputEvent): bool =
  if event.kind != KeyEvent:
    return false
  
  case event.keyCode
  of INPUT_UP:
    if blog.currentView == "list":
      blog.currentArticleIndex = max(0, blog.currentArticleIndex - 1)
    else:
      blog.scrollPos = max(0, blog.scrollPos - 1)
    return true
  
  of INPUT_DOWN:
    if blog.currentView == "list":
      blog.currentArticleIndex = min(blog.articles.len - 1, blog.currentArticleIndex + 1)
    else:
      blog.scrollPos = blog.scrollPos + 1
    return true
  
  of INPUT_ENTER:
    if blog.currentView == "list":
      blog.currentView = "article"
    return true
  
  of ord('l'), ord('L'):
    blog.currentView = "list"
    return true
  
  of ord('q'), ord('Q'):
    state.running = false
    return true
  
  else:
    # Pass input to article's custom input handler if it has one
    return false
```

## Advanced Features

### Article Series

Add series support in front matter:

```yaml
---
series: Getting Started with TStorie
seriesPart: 2
seriesTotal: 5
---
```

### Draft Mode

```yaml
---
published: false
draft: true
---
```

### Featured Articles

```yaml
---
featured: true
---
```

### Reading Time Estimation

Calculate from word count in front matter or content:

```yaml
---
readingTime: 5
---
```

### Related Articles

```yaml
---
relatedArticles:
  - first-post
  - tui-animations
---
```

## Build and Deployment

### Generate Article Index

Create a script to scan articles and generate `index.json`:

```nim
# tools/generate_index.nim
import os, strutils, json, tables
import lib/storie_md

proc scanArticles() =
  var articles: seq[JsonNode] = @[]
  
  for file in walkDirRec("articles"):
    if file.endsWith(".md"):
      let content = readFile(file)
      let doc = parseMarkdownDocument(content)
      
      if doc.frontMatter.len > 0:
        var article = %* {
          "filename": file.replace("articles/", ""),
          "title": doc.frontMatter.getOrDefault("title", "Untitled"),
          "date": doc.frontMatter.getOrDefault("date", ""),
          "author": doc.frontMatter.getOrDefault("author", ""),
          "category": doc.frontMatter.getOrDefault("category", "uncategorized"),
          "excerpt": doc.frontMatter.getOrDefault("excerpt", ""),
          "published": doc.frontMatter.getOrDefault("published", "true") == "true",
          "featured": doc.frontMatter.getOrDefault("featured", "false") == "true"
        }
        
        # Parse tags
        let tags = doc.frontMatter.getOrDefault("tags", "").split(",")
        article["tags"] = %* tags.mapIt(it.strip())
        
        articles.add(article)
  
  let output = %* {"articles": articles}
  writeFile("articles/index.json", output.pretty())

scanArticles()
```

## Best Practices

1. **Keep articles focused** - One topic per article
2. **Use meaningful slugs** - Make URLs/filenames descriptive
3. **Write good excerpts** - Help readers decide what to read
4. **Tag consistently** - Establish a tagging convention early
5. **Date everything** - Even if not published immediately
6. **Use content.nim for most articles** - Only add custom code when needed
7. **Test interactivity** - If using custom `on:input` blocks
8. **Version your index** - Keep `index.json` in version control
9. **Backup articles** - Regular backups of your content
10. **Profile performance** - Monitor FPS with many articles

## Example Workflows

### Creating a New Article

```bash
# 1. Create file with date-based name
touch articles/2024/12/2024-12-16-new-post.md

# 2. Add front matter and content
# ... edit file ...

# 3. Regenerate index
nim c -r tools/generate_index.nim

# 4. Preview
./run.sh blog_engine
```

### Publishing a Draft

```bash
# 1. Edit article, change published: false → true
# 2. Regenerate index
nim c -r tools/generate_index.nim
```

## Conclusion

This architecture provides a flexible, extensible foundation for a TUI blog. The combination of default rendering through `content.nim` and custom Nimini code blocks allows for both simple text articles and rich, interactive experiences.
