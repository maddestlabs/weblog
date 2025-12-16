# Blog Engine for TStorie
# A simple TUI blog reader with article navigation

# ================================================================
# HARDCODED ARTICLE DATA (replace with JSON loading in production)
# ================================================================

type
  Article = object
    title: string
    author: string
    date: string
    category: string
    excerpt: string
    content: seq[string]  # Pre-split lines

var articles: seq[Article]
var currentArticleIndex = 0
var currentView = "list"  # "list" or "article"
var scrollPos = 0

# Layers
var headerLayer: Layer
var contentLayer: Layer
var footerLayer: Layer

# ================================================================
# ARTICLE DATA
# ================================================================

proc initArticles() =
  articles = @[
    Article(
      title: "Welcome to TStorie Blog",
      author: "TStorie Team",
      date: "2024-12-01",
      category: "announcements",
      excerpt: "An introduction to building terminal-based blogs",
      content: @[
        "# Welcome to TStorie Blog",
        "",
        "Welcome to the TStorie Blog Engine! This is a terminal user",
        "interface (TUI) blog system built on the powerful TStorie",
        "framework.",
        "",
        "## What is TStorie?",
        "",
        "TStorie is a versatile engine for creating interactive",
        "terminal applications. It combines:",
        "",
        "- Layer-based rendering - Organize UI into composable layers",
        "- Markdown support - Write content in familiar format",
        "- Code execution - Embed executable Nim code in articles",
        "- Cross-platform - Linux, macOS, Windows, and WebAssembly",
        "",
        "## Navigation",
        "",
        "Use these keyboard shortcuts:",
        "",
        "- UP/DOWN - Scroll through article or navigate list",
        "- L - Return to article list",
        "- ENTER - Open selected article (in list view)",
        "- Q or ESC - Quit the application",
        "- PAGE UP/DOWN - Scroll faster through articles",
        "",
        "Happy reading!"
      ]
    ),
    Article(
      title: "Creating Beautiful TUI Animations",
      author: "TStorie Team",
      date: "2024-12-15",
      category: "tutorials",
      excerpt: "Learn how to create smooth animations in terminals",
      content: @[
        "# Creating Beautiful TUI Animations",
        "",
        "Terminal User Interfaces don't have to be static! With",
        "TStorie, you can create smooth, beautiful animations that",
        "run at 60 FPS.",
        "",
        "## The Animation System",
        "",
        "TStorie provides a built-in animation system:",
        "",
        "### Frame-Based Updates",
        "",
        "Every frame, your onUpdate callback receives the delta time",
        "since the last frame. Use this to create time-based",
        "animations that run consistently regardless of frame rate.",
        "",
        "### Layer System",
        "",
        "Organize animated elements on different layers:",
        "",
        "- Background Layer - Static or slowly-changing content",
        "- Foreground Layer - Dynamic, frequently-updated content", 
        "- UI Layer - Interface elements and overlays",
        "",
        "### Animation Primitives",
        "",
        "TStorie offers several built-in animation capabilities:",
        "",
        "1. Position interpolation - Move objects smoothly",
        "2. Color transitions - Fade between colors over time",
        "3. Easing functions - Natural acceleration/deceleration",
        "4. Particle systems - Create complex visual effects",
        "",
        "## Performance Tips",
        "",
        "- Minimize redraws - Only update what changes",
        "- Use layers wisely - Static content on lower layers",
        "- Profile your code - Monitor FPS for smooth performance",
        "- Batch operations - Group related updates together",
        "",
        "TUI animations can be just as engaging as GUI animations!"
      ]
    ),
    Article(
      title: "Getting Started with TStorie",
      author: "TStorie Team",
      date: "2024-11-20",
      category: "tutorials",
      excerpt: "A comprehensive guide to setting up TStorie",
      content: @[
        "# Getting Started with TStorie",
        "",
        "This guide will walk you through setting up your first",
        "TStorie application.",
        "",
        "## Prerequisites",
        "",
        "Before you begin, make sure you have:",
        "",
        "- Nim compiler - Version 2.0 or later",
        "- Terminal emulator - Any modern terminal with ANSI support",
        "- Text editor - VSCode, Vim, or your favorite editor",
        "",
        "## Your First TStorie App",
        "",
        "Create a new file called hello.nim:",
        "",
        "  onInit = proc(state: AppState) =",
        "    echo \"Initializing...\"",
        "",
        "  onRender = proc(state: AppState) =",
        "    fgClear()",
        "    fgWriteText(10, 10, \"Hello, TStorie!\")",
        "",
        "  onInput = proc(state: AppState, event: InputEvent): bool =",
        "    if event.kind == KeyEvent and event.keyCode == ord('q'):",
        "      state.running = false",
        "      return true",
        "    return false",
        "",
        "## Understanding the Lifecycle",
        "",
        "TStorie applications follow a clear lifecycle:",
        "",
        "1. onInit - Called once when app starts",
        "2. onUpdate - Called every frame with delta time",
        "3. onRender - Called every frame to draw the UI",
        "4. onInput - Called when user input is received",
        "5. onShutdown - Called when application exits",
        "",
        "## The Layer System",
        "",
        "TStorie uses layer-based rendering:",
        "",
        "- Background Layer - Rendered first (lowest Z-index)",
        "- Content Layer - Main content area",
        "- Foreground Layer - UI overlays (highest Z-index)",
        "",
        "You can create custom layers and control render order.",
        "",
        "Happy coding!"
      ]
    )
  ]

# ================================================================
# RENDERING
# ================================================================

proc renderHeader(state: AppState) =
  headerLayer.buffer.clearTransparent()
  
  # Title
  var titleStyle = defaultStyle()
  titleStyle.fg = cyan()
  titleStyle.bold = true
  headerLayer.buffer.writeText(2, 0, "TStorie Blog Engine", titleStyle)
  
  # Navigation hint
  var navStyle = defaultStyle()
  navStyle.fg = yellow()
  headerLayer.buffer.writeText(state.termWidth - 20, 0, "L: List | Q: Quit", navStyle)
  
  # Separator
  var sepStyle = defaultStyle()
  for x in 0 ..< state.termWidth:
    headerLayer.buffer.writeText(x, 1, "\xC4", sepStyle)

proc renderFooter(state: AppState) =
  footerLayer.buffer.clearTransparent()
  
  let y = state.termHeight - 1
  
  # Separator
  var sepStyle = defaultStyle()
  for x in 0 ..< state.termWidth:
    footerLayer.buffer.writeText(x, y - 1, "\xC4", sepStyle)
  
  # Status
  var statusStyle = defaultStyle()
  if articles.len > 0:
    let status = "Article " & $(currentArticleIndex + 1) & "/" & $articles.len
    footerLayer.buffer.writeText(2, y, status, statusStyle)
  
  footerLayer.buffer.writeText(state.termWidth - 20, y, "Press H for help", statusStyle)

proc renderArticleList(state: AppState) =
  contentLayer.buffer.clearTransparent()
  
  var y = 3
  var titleStyle = defaultStyle()
  titleStyle.fg = cyan()
  titleStyle.bold = true
  contentLayer.buffer.writeText(2, y, "Articles", titleStyle)
  y += 2
  
  # Render article list
  for i in 0 ..< articles.len:
    if y >= state.termHeight - 3:
      break
    
    # Highlight current article
    if i == currentArticleIndex:
      var selStyle = defaultStyle()
      selStyle.fg = yellow()
      selStyle.bold = true
      contentLayer.buffer.writeText(0, y, ">", selStyle)
      contentLayer.buffer.writeText(2, y, articles[i].date & " - " & articles[i].title, selStyle)
    else:
      var normStyle = defaultStyle()
      contentLayer.buffer.writeText(2, y, articles[i].date & " - " & articles[i].title, normStyle)
    
    y += 1

proc renderArticle(state: AppState) =
  contentLayer.buffer.clearTransparent()
  
  if currentArticleIndex < 0 or currentArticleIndex >= articles.len:
    return
  
  let article = articles[currentArticleIndex]
  var y = 3
  
  # Title
  var titleStyle = defaultStyle()
  titleStyle.fg = cyan()
  titleStyle.bold = true
  contentLayer.buffer.writeText(2, y, article.title, titleStyle)
  y += 2
  
  # Metadata
  var metaStyle = defaultStyle()
  metaStyle.fg = gray(180)
  contentLayer.buffer.writeText(2, y, "By " & article.author & " on " & article.date, metaStyle)
  y += 2
  
  # Separator
  var sepStyle = defaultStyle()
  for x in 2 ..< state.termWidth - 2:
    contentLayer.buffer.writeText(x, y, "\xC4", sepStyle)
  y += 2
  
  # Content (with scrolling)
  let startLine = max(0, scrollPos)
  let maxLines = state.termHeight - y - 3
  var renderedLines = 0
  
  for i in startLine ..< article.content.len:
    if renderedLines >= maxLines:
      break
    
    let line = article.content[i]
    var lineStyle = defaultStyle()
    if line.len > 0:
      # Simple truncation if line is too long
      let maxWidth = state.termWidth - 4
      if line.len > maxWidth:
        contentLayer.buffer.writeText(2, y, line[0 ..< maxWidth], lineStyle)
      else:
        contentLayer.buffer.writeText(2, y, line, lineStyle)
    
    y += 1
    renderedLines += 1
  
  # Scroll indicators
  var scrollStyle = defaultStyle()
  scrollStyle.fg = rgb(100, 100, 100)
  if scrollPos > 0:
    contentLayer.buffer.writeText(state.termWidth - 10, 3, "^ More ^", scrollStyle)
  if startLine + renderedLines < article.content.len:
    contentLayer.buffer.writeText(state.termWidth - 10, y - 1, "v More v", scrollStyle)

# ================================================================
# CALLBACKS
# ================================================================

onInit = proc(state: AppState) =
  headerLayer = state.addLayer("header", 100)
  contentLayer = state.addLayer("content", 50)
  footerLayer = state.addLayer("footer", 90)
  
  initArticles()
  currentArticleIndex = 0
  currentView = "article"
  scrollPos = 0

onRender = proc(state: AppState) =
  renderHeader(state)
  
  if currentView == "list":
    renderArticleList(state)
  else:
    renderArticle(state)
  
  renderFooter(state)

onInput = proc(state: AppState, event: InputEvent): bool =
  if event.kind != KeyEvent or event.keyAction != Press:
    return false
  
  case event.keyCode
  of INPUT_UP:
    if currentView == "list":
      currentArticleIndex = max(0, currentArticleIndex - 1)
    else:
      scrollPos = max(0, scrollPos - 1)
    return true
  
  of INPUT_DOWN:
    if currentView == "list":
      currentArticleIndex = min(articles.len - 1, currentArticleIndex + 1)
    else:
      scrollPos += 1
    return true
  
  of INPUT_PAGE_UP:
    scrollPos = max(0, scrollPos - 10)
    return true
  
  of INPUT_PAGE_DOWN:
    scrollPos += 10
    return true
  
  of INPUT_ENTER:
    if currentView == "list":
      currentView = "article"
      scrollPos = 0
    return true
  
  of ord('l'), ord('L'):
    currentView = "list"
    return true
  
  of ord('q'), ord('Q'), INPUT_ESCAPE:
    state.running = false
    return true
  
  else:
    return false

onUpdate = proc(state: AppState, dt: float) =
  discard

onShutdown = proc(state: AppState) =
  discard
