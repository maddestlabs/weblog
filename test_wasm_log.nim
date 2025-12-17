# Quick test - add debugging to index.nim
import strutils

let indexContent = readFile("index.nim")
let lines = indexContent.splitLines()

var newLines: seq[string]
for line in lines:
  if line.contains("onInit = proc(state: AppState)"):
    newLines.add(line)
    newLines.add("  echo \"[DEBUG] onInit called\"")
  elif line.contains("onRender = proc(state: AppState)"):
    newLines.add(line)
    newLines.add("  echo \"[DEBUG] onRender called\"")
  elif line.contains("proc initArticles()"):
    newLines.add(line)
    newLines.add("  echo \"[DEBUG] initArticles called, emscripten:\", defined(emscripten)")
  else:
    newLines.add(line)

writeFile("index.nim", newLines.join("\n"))
echo "Added debug logging"
