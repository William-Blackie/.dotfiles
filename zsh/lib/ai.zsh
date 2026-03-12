##### Gemini CLI & AI Features (Wow Factor 🌟)
if command -v gemini >/dev/null 2>&1; then
  alias ai="gemini"
  alias aip="gemini -p"
  
  # AI Command Explainer
  explain() {
    local cmd="${1:-}"
    if [[ -z "$cmd" ]]; then
       # Fallback to last history command if fc is available
       if command -v fc >/dev/null 2>&1; then
         cmd="$(fc -ln -1)"
       fi
    fi
    
    if [[ -z "$cmd" ]]; then
      echo "❌ No command provided to explain."
      return 1
    fi
    
    echo "✨ Asking Gemini to explain: $cmd"
    gemini -c "Explain what this terminal command does in simple terms: $cmd" || {
      echo "❌ Failed to get explanation from Gemini."
      return 1
    }
  }
  
  # AI Commit Message Generator
  gai() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "Not in a git repository."
      return 1
    fi
    
    local staged
    staged="$(git diff --staged)"
    if [[ -z "$staged" ]]; then
      echo "No staged changes found. Use 'git add' first."
      return 1
    fi
    
    echo "✨ Asking Gemini to analyze changes..."
    local prompt="Analyze the following git diff and write a concise, conventional commit message. Return ONLY the commit message text, with no markdown formatting or extra explanation:

${staged}"
    local msg
    msg="$(gemini -c "$prompt" 2>/dev/null)"
    
    if [[ -n "$msg" ]]; then
      echo "
Proposed Commit Message:"
      echo "\033[0;32m$msg\033[0m
"
      echo -n "Commit with this message? [Y/n] "
      read -q "REPLY"
      echo
      if [[ $REPLY =~ ^[Yy]$ || -z $REPLY ]]; then
        git commit -m "$msg"
      else
        echo "Aborted."
      fi
    else
      echo "❌ Failed to generate commit message."
    fi
  }

  # AI Git Explainer
  gge() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
      echo "Not in a git repository."
      return 1
    fi
    
    local ref="${1:-HEAD}"
    echo "✨ Asking Gemini to explain $ref..."
    local diff
    diff="$(git show "$ref" 2>/dev/null || git diff "$ref" 2>/dev/null)"
    
    if [[ -z "$diff" ]]; then
      echo "Could not find any changes for $ref."
      return 1
    fi
    
    gemini -c "Explain what these code changes do in plain English, focusing on the functional impact: 

${diff}"
  }
fi
