# Weblog - TStorie Blog Engine
# A TUI blog reader built with TStorie
# This file is included by tstorie.nim, so all TStorie APIs are available

import strutils, tables, times
when not defined(emscripten):
  import os, json

import lib/storie_md
import nimini

# Layers (forward declared for use in nimini runtime)
var headerLayer: Layer
var contentLayer: Layer
var footerLayer: Layer

# Global nimini runtime environment (persists across code executions)
var blogRuntimeEnv: ref Env = nil

proc ensureBlogRuntime() =
  if blogRuntimeEnv.isNil:
    initRuntime()
    initStdlib()
    blogRuntimeEnv = runtimeEnv
    
    # Register TStorie drawing functions for nimini code
    registerNative("fgWriteText", proc(env: ref Env; args: seq[Value]): Value =
      if args.len < 3:
        echo "fgWriteText requires at least 3 arguments: x, y, text"
        return valNil()
      
      let x = args[0].i
      let y = args[1].i
      let text = args[2].s
      
      # Use content layer for drawing (layer must be initialized first)
      if not contentLayer.isNil:
        var drawStyle = defaultStyle()
        contentLayer.buffer.writeText(x, y, text, drawStyle)
      else:
        echo "Warning: contentLayer not initialized"
      
      valNil()
    )
    
    registerNative("defaultStyle", proc(env: ref Env; args: seq[Value]): Value =
      # Return a placeholder value (we handle styling in the fgWriteText wrapper)
      valNil()
    )

# ================================================================
# BLOG ENGINE TYPES AND DATA
# ================================================================

type
  Article = object
    title: string
    author: string
    date: string
    category: string
    excerpt: string
    filename: string      # Path to article file
    content: seq[string]  # Pre-split lines (loaded on demand)
    loaded: bool          # Whether content has been loaded
    codeBlocks: seq[CodeBlock]  # Nimini code blocks from markdown

var articles: seq[Article]
var currentArticleIndex = 0
var currentView = "list"  # "list" or "article"
var scrollPos = 0
var isLoadingArticle = false  # Track loading state

# ================================================================
# ARTICLE LOADING
# ================================================================

when defined(emscripten):
  # JavaScript interop for fetch API using EM_JS macros
  {.emit: """/*INCLUDESECTION*/
#include <emscripten.h>

// Global state for articles
EM_JS(void, emFetchArticleIndex, (), {
  if (!window.articlesFetched) {
    window.articlesFetched = true;
    window.articlesData = null;
    window.articleContentCallbacks = {};
    
    // Get base path from current page location (works for GitHub Pages subdirectories)
    var basePath = window.location.pathname.substring(0, window.location.pathname.lastIndexOf('/') + 1);
    var articlesUrl = basePath + 'articles/index.json';
    
    console.log('Base path:', basePath);
    console.log('Fetching articles index from:', articlesUrl);
    fetch(articlesUrl)
      .then(response => {
        if (!response.ok) {
          console.error('Failed to fetch articles index:', response.status, response.statusText);
          throw new Error('HTTP error ' + response.status);
        }
        return response.json();
      })
      .then(data => {
        console.log('Articles fetched:', data);
        console.log('data["articles"]:', data['articles']);
        if (data && data['articles'] && Array.isArray(data['articles'])) {
          window.articlesData = data['articles'];
        } else {
          window.articlesData = [];
        }
        console.log('window.articlesData set to:', window.articlesData);
        console.log('Calling _emOnArticlesLoaded with', window.articlesData.length, 'articles');
        _emOnArticlesLoaded();
      })
      .catch(error => {
        console.error('Error fetching articles:', error);
        window.articlesData = [];
        _emOnArticlesLoaded();
      });
  } else {
    console.log('Articles already fetched, skipping');
  }
});

EM_JS(int, emGetArticlesCount, (), {
  return window.articlesData ? window.articlesData.length : 0;
});

EM_JS(char*, emGetArticleFieldRaw, (int index, const char* field), {
  if (!window.articlesData || index >= window.articlesData.length) {
    var ptr = _malloc(1);
    HEAP8[ptr] = 0;
    return ptr;
  }
  var fieldName = UTF8ToString(field);
  var value = window.articlesData[index][fieldName] || '';
  var lengthBytes = lengthBytesUTF8(value) + 1;
  var ptr = _malloc(lengthBytes);
  stringToUTF8(value, ptr, lengthBytes);
  return ptr;
});

EM_JS(void, emFetchArticleContentRaw, (const char* filename, int callbackId), {
  var fname = UTF8ToString(filename);
  
  // Get base path from current page location
  var basePath = window.location.pathname.substring(0, window.location.pathname.lastIndexOf('/') + 1);
  var articleUrl = basePath + 'articles/' + fname;
  
  console.log('Fetching article from:', articleUrl);
  fetch(articleUrl)
    .then(response => {
      if (!response.ok) {
        console.error('Failed to fetch article:', response.status, response.statusText, articleUrl);
        throw new Error('HTTP error ' + response.status);
      }
      return response.text();
    })
    .then(content => {
      if (!window.articleContentCallbacks) window.articleContentCallbacks = {};
      window.articleContentCallbacks[callbackId] = content;
      _emOnArticleContentLoaded(callbackId);
    })
    .catch(error => {
      console.error('Error fetching article:', error);
      if (!window.articleContentCallbacks) window.articleContentCallbacks = {};
      window.articleContentCallbacks[callbackId] = '';
      _emOnArticleContentLoaded(callbackId);
    });
});

EM_JS(char*, emGetArticleContentRaw, (int callbackId), {
  if (!window.articleContentCallbacks) window.articleContentCallbacks = {};
  var content = window.articleContentCallbacks[callbackId] || '';
  delete window.articleContentCallbacks[callbackId];
  var lengthBytes = lengthBytesUTF8(content) + 1;
  var ptr = _malloc(lengthBytes);
  stringToUTF8(content, ptr, lengthBytes);
  return ptr;
});
""".}
  
  proc emFetchArticleIndex() {.importc, nodecl.}
  proc emGetArticlesCount(): cint {.importc, nodecl.}
  proc emGetArticleFieldRaw(index: cint, field: cstring): cstring {.importc, nodecl.}
  proc emFetchArticleContentRaw(filename: cstring, callbackId: cint) {.importc, nodecl.}
  proc emGetArticleContentRaw(callbackId: cint): cstring {.importc, nodecl.}
  
  # Nim wrappers for C string handling
  proc emGetArticleField(index: cint, field: cstring): string =
    result = $emGetArticleFieldRaw(index, field)
  
  proc emFetchArticleContent(filename: cstring, callbackId: cint) =
    emFetchArticleContentRaw(filename, callbackId)
  
  proc emGetArticleContent(callbackId: cint): string =
    result = $emGetArticleContentRaw(callbackId)
  
  var articleContentCounter = 0
  var pendingArticleLoads: Table[int, int] = initTable[int, int]()  # callbackId -> articleIndex
  
  # Forward declaration
  proc loadArticleContent(index: int)
  
  proc emOnArticlesLoaded() {.exportc.} =
    ## Called from JavaScript when articles index is loaded
    let count = emGetArticlesCount()
    echo "Articles loaded callback: count = ", count
    articles = @[]
    
    for i in 0 ..< count:
      let article = Article(
        title: emGetArticleField(i.cint, "title"),
        date: emGetArticleField(i.cint, "date"),
        author: emGetArticleField(i.cint, "author"),
        category: emGetArticleField(i.cint, "category"),
        excerpt: emGetArticleField(i.cint, "excerpt"),
        filename: emGetArticleField(i.cint, "filename"),
        content: @[],
        loaded: false,
        codeBlocks: @[]
      )
      echo "  Article ", i, ": ", article.title
      articles.add(article)
    
    # Load first article if available
    if articles.len > 0:
      loadArticleContent(0)
  
  proc emOnArticleContentLoaded(callbackId: cint) {.exportc.} =
    ## Called from JavaScript when article content is loaded
    let content = emGetArticleContent(callbackId)
    let articleIndex = pendingArticleLoads.getOrDefault(callbackId.int, -1)
    
    if articleIndex >= 0 and articleIndex < articles.len:
      if content.len > 0:
        let lines = content.splitLines()
        var inFrontMatter = false
        var bodyStart = 0
        
        # Skip front matter
        for i, line in lines:
          if i == 0 and line.strip().startsWith("---"):
            inFrontMatter = true
            continue
          if inFrontMatter and line.strip().startsWith("---"):
            bodyStart = i + 1
            break
        
        # Add content lines
        articles[articleIndex].content = @[]
        for i in bodyStart ..< lines.len:
          articles[articleIndex].content.add(lines[i])
        
        # Parse markdown for nimini code blocks
        let doc = parseMarkdownDocument(content)
        articles[articleIndex].codeBlocks = doc.codeBlocks
        
        # Execute init code blocks
        for codeBlock in articles[articleIndex].codeBlocks:
          if codeBlock.lifecycle == "init":
            try:
              ensureBlogRuntime()
              let tokens = tokenizeDsl(codeBlock.code)
              let program = parseDsl(tokens)
              execProgram(program, blogRuntimeEnv)
            except:
              echo "Error executing init block: ", getCurrentExceptionMsg()
        
        articles[articleIndex].loaded = true
      
      pendingArticleLoads.del(callbackId.int)
      isLoadingArticle = false
  
  proc loadArticleContent(index: int) =
    ## Load content for a specific article
    if index < 0 or index >= articles.len:
      return
    
    if articles[index].loaded:
      return  # Already loaded
    
    isLoadingArticle = true
    inc articleContentCounter
    pendingArticleLoads[articleContentCounter] = index
    emFetchArticleContent(articles[index].filename.cstring, articleContentCounter.cint)
  
  proc initArticlesFromWeb() =
    ## Initialize articles by fetching from server
    emFetchArticleIndex()
when not defined(emscripten):
  proc loadArticlesFromIndex(): seq[Article] =
    ## Load articles from index.json
    result = @[]
    let indexPath = "articles/index.json"
    
    if fileExists(indexPath):
      try:
        let jsonContent = readFile(indexPath)
        let data = parseJson(jsonContent)
        
        for item in data["articles"]:
          var article = Article(
            title: item["title"].getStr(),
            date: item["date"].getStr(),
            author: item["author"].getStr(),
            category: item["category"].getStr(),
            excerpt: item["excerpt"].getStr(),
            filename: item["filename"].getStr(),
            content: @[],
            loaded: false,
            codeBlocks: @[]
          )
          
          # Load actual article content from file
          let articlePath = "articles/" & item["filename"].getStr()
          if fileExists(articlePath):
            let content = readFile(articlePath)
            let lines = content.splitLines()
            var inFrontMatter = false
            var bodyStart = 0
            
            # Skip front matter
            for i, line in lines:
              if i == 0 and line.strip().startsWith("---"):
                inFrontMatter = true
                continue
              if inFrontMatter and line.strip().startsWith("---"):
                bodyStart = i + 1
                break
            
            # Add content lines
            for i in bodyStart ..< lines.len:
              article.content.add(lines[i])
            
            # Parse markdown for nimini code blocks
            let doc = parseMarkdownDocument(content)
            article.codeBlocks = doc.codeBlocks
            article.loaded = true
          
          result.add(article)
      except:
        echo "Error loading articles: ", getCurrentExceptionMsg()

proc initArticles() =
  when defined(emscripten):
    # Fetch articles from server for web build
    initArticlesFromWeb()
  else:
    # Load from filesystem
    articles = loadArticlesFromIndex()
    if articles.len == 0:
      # Fallback if loading fails
      echo "Warning: Could not load articles from index.json"
      articles = @[
        Article(
          title: "Welcome to Weblog",
          author: "Maddest Labs",
          date: "2024-12-01",
          category: "announcements",
          excerpt: "An introduction to building terminal-based blogs",
          filename: "",
          content: @["# Welcome to Weblog", "", "No articles found in articles/index.json", "", "Please run: nim c -r tools/generate_index.nim"],
          loaded: true,
          codeBlocks: @[]
        )
      ]

# ================================================================
# RENDERING
# ================================================================

proc renderHeader(state: AppState) =
  if headerLayer.isNil:
    return
  
  headerLayer.buffer.clearTransparent()
  
  # Title
  var titleStyle = defaultStyle()
  titleStyle.fg = cyan()
  titleStyle.bold = true
  headerLayer.buffer.writeText(2, 0, "Weblog - TStorie Blog", titleStyle)
  
  # Navigation hint
  var navStyle = defaultStyle()
  navStyle.fg = yellow()
  headerLayer.buffer.writeText(state.termWidth - 20, 0, "L: List | Q: Quit", navStyle)
  
  # Separator
  var sepStyle = defaultStyle()
  for x in 0 ..< state.termWidth:
    headerLayer.buffer.writeText(x, 1, "─", sepStyle)

proc renderFooter(state: AppState) =
  footerLayer.buffer.clearTransparent()
  
  let y = state.termHeight - 1
  
  # Separator
  var sepStyle = defaultStyle()
  for x in 0 ..< state.termWidth:
    footerLayer.buffer.writeText(x, y - 1, "─", sepStyle)
  
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
  
  # Show loading indicator if article isn't loaded yet
  if not article.loaded:
    var loadingStyle = defaultStyle()
    loadingStyle.fg = yellow()
    contentLayer.buffer.writeText(2, y, "Loading article...", loadingStyle)
    when defined(emscripten):
      if not isLoadingArticle:
        loadArticleContent(currentArticleIndex)
    return
  
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
    contentLayer.buffer.writeText(x, y, "─", sepStyle)
  y += 2
  
  # Execute render code blocks
  for codeBlock in article.codeBlocks:
    if codeBlock.lifecycle == "render":
      try:
        ensureBlogRuntime()
        let tokens = tokenizeDsl(codeBlock.code)
        let program = parseDsl(tokens)
        execProgram(program, blogRuntimeEnv)
      except:
        echo "Error executing render block: ", getCurrentExceptionMsg()
  
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

proc initBlogCallbacks*() =
  ## Initialize blog engine callbacks
  ## Must be called explicitly in WASM builds
  onInit = proc(state: AppState) =
    headerLayer = state.addLayer("header", 100)
    contentLayer = state.addLayer("content", 50)
    footerLayer = state.addLayer("footer", 90)
    
    initArticles()
    currentArticleIndex = 0
    currentView = "article"
    scrollPos = 0

  onUpdate = proc(state: AppState, dt: float) =
    # Execute update code blocks for current article
    if currentView == "article" and currentArticleIndex >= 0 and currentArticleIndex < articles.len:
      let article = articles[currentArticleIndex]
      if article.loaded:
        for codeBlock in article.codeBlocks:
          if codeBlock.lifecycle == "update":
            try:
              ensureBlogRuntime()
              # Inject dt variable into runtime environment
              setVar(blogRuntimeEnv, "dt", valFloat(dt))
              let tokens = tokenizeDsl(codeBlock.code)
              let program = parseDsl(tokens)
              execProgram(program, blogRuntimeEnv)
            except:
              echo "Error executing update block: ", getCurrentExceptionMsg()

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
        # Load article content if not already loaded
        when defined(emscripten):
          if currentArticleIndex >= 0 and currentArticleIndex < articles.len:
            if not articles[currentArticleIndex].loaded and not isLoadingArticle:
              loadArticleContent(currentArticleIndex)
      return true
    
    of ord('l'), ord('L'):
      currentView = "list"
      return true
    
    of ord('q'), ord('Q'), INPUT_ESCAPE:
      state.running = false
      return true
    
    else:
      return false

# Auto-initialize callbacks for native builds
when not defined(emscripten):
  initBlogCallbacks()
