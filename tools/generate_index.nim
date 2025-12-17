## Article Index Generator
##
## Scans the blog/articles directory and generates index.json
## with metadata for all published articles.

import os, strutils, json, tables, sequtils, algorithm
import ../lib/storie_md

proc extractSlug(filename: string): string =
  ## Extract slug from filename like "2024-12-01-first-post.md"
  let base = filename.splitFile().name
  let parts = base.split('-')
  if parts.len >= 4:
    # Skip YYYY-MM-DD prefix
    return parts[3 .. ^1].join("-")
  return base

proc scanArticles() =
  ## Scan articles directory and generate index.json
  var articles: seq[JsonNode] = @[]
  var allCategories: seq[string] = @[]
  var allTags: seq[string] = @[]
  
  echo "Scanning articles directory..."
  
  for file in walkDirRec("articles"):
    if file.endsWith(".md"):
      echo "  Found: ", file
      
      try:
        let content = readFile(file)
        let doc = parseMarkdownDocument(content)
        
        if doc.frontMatter.len > 0:
          # Extract relative path from articles/
          let relPath = file.replace("articles/", "")
          
          # Get values from front matter
          let title = doc.frontMatter.getOrDefault("title", "Untitled")
          let date = doc.frontMatter.getOrDefault("date", "")
          let author = doc.frontMatter.getOrDefault("author", "")
          let category = doc.frontMatter.getOrDefault("category", "uncategorized")
          let excerpt = doc.frontMatter.getOrDefault("excerpt", "")
          let published = doc.frontMatter.getOrDefault("published", "true") == "true"
          let featured = doc.frontMatter.getOrDefault("featured", "false") == "true"
          
          # Parse tags
          let tagsStr = doc.frontMatter.getOrDefault("tags", "")
          var tags: seq[string] = @[]
          if tagsStr.len > 0:
            tags = tagsStr.split(",").mapIt(it.strip())
          
          # Build article JSON
          var article = %* {
            "filename": relPath,
            "title": title,
            "slug": extractSlug(file),
            "date": date,
            "author": author,
            "category": category,
            "excerpt": excerpt,
            "published": published,
            "featured": featured,
            "tags": tags
          }
          
          articles.add(article)
          
          # Collect unique categories and tags
          if category notin allCategories:
            allCategories.add(category)
          
          for tag in tags:
            if tag notin allTags:
              allTags.add(tag)
          
          echo "    ✓ Added: ", title
      except:
        echo "    ✗ Error processing file: ", getCurrentExceptionMsg()
  
  # Sort articles by date (newest first)
  articles = articles.sorted(proc(a, b: JsonNode): int =
    let dateA = a["date"].getStr()
    let dateB = b["date"].getStr()
    if dateA > dateB: -1
    elif dateA < dateB: 1
    else: 0
  )
  
  # Build final output
  let output = %* {
    "articles": articles,
    "categories": allCategories,
    "tags": allTags,
    "generated": "2024-12-16T00:00:00Z",
    "totalArticles": articles.len
  }
  
  # Write to file
  let indexPath = "articles/index.json"
  writeFile(indexPath, output.pretty())
  
  echo "\n✓ Generated index.json with ", articles.len, " articles"
  echo "  Categories: ", allCategories.join(", ")
  echo "  Tags: ", allTags.len, " unique tags"

when isMainModule:
  echo "TStorie Blog - Article Index Generator"
  echo "======================================"
  echo ""
  
  if not dirExists("articles"):
    echo "Error: articles directory not found"
    echo "Please run this from the project root directory"
    quit(1)
  
  scanArticles()
  echo "\nDone!"
