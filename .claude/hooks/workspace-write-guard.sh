#!/usr/bin/env bash
# PreToolUse guard for filesystem writes. Hard-enforces two rules from
# .claude/rules/sap-dev-rule.md that were previously prompt-only:
#   1. `.claude/` is locked: no Write/Edit/delete inside it unless the USER has
#      created the sentinel file `.claude/.unlock` (the agent itself is always
#      blocked from creating/editing that sentinel — that's what makes it a lock).
#   2. Output containment (§4): NEW files inside the workspace must be created
#      under `artifacts/`. Editing files that already exist is allowed, and paths
#      outside the workspace (session scratchpad, memory dir) are not this hook's
#      business.
# Matched on Write|Edit|NotebookEdit and on Bash (destructive commands touching
# .claude/ only).
set -euo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // ""')
root="${CLAUDE_PROJECT_DIR:-$PWD}"
unlock="$root/.claude/.unlock"

deny() {
  jq -n --arg reason "$1" \
    '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":$reason}}'
  exit 0
}

# --- Bash: only police destructive commands that target .claude/ ---
if [[ "$tool_name" == "Bash" ]]; then
  cmd=$(echo "$input" | jq -r '.tool_input.command // ""')
  if echo "$cmd" | grep -qE '(^|[[:space:];&|])(rm|mv|sed[[:space:]]+-i|perl[[:space:]]+-p?i|tee)[^|;&]*\.claude/' \
     || echo "$cmd" | grep -qE '>>?[[:space:]]*[^[:space:]]*\.claude/'; then
    if echo "$cmd" | grep -q '\.claude/\.unlock'; then
      deny "sap-dev-rule.md: the agent must never create or touch .claude/.unlock — only the user may, manually."
    fi
    [[ -f "$unlock" ]] && exit 0
    deny "sap-dev-rule.md: .claude/ is locked. If the user explicitly asked for this change, ask them to create the sentinel file .claude/.unlock first (and remove it afterwards)."
  fi
  exit 0
fi

# --- Write/Edit/NotebookEdit ---
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.notebook_path // ""')
[[ -z "$file_path" ]] && exit 0

# Normalize to an absolute, symlink-resolved path (parent-resolved for new files).
norm=$(python3 - "$file_path" <<'PY'
import os, sys
p = sys.argv[1]
d, b = os.path.split(os.path.abspath(p))
print(os.path.join(os.path.realpath(d), b))
PY
)
root_real=$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$root")

case "$norm" in
  "$root_real/.claude/"*|"$root_real/.claude")
    if [[ "$(basename "$norm")" == ".unlock" ]]; then
      deny "sap-dev-rule.md: the agent must never create or edit .claude/.unlock — only the user may, manually."
    fi
    [[ -f "$unlock" ]] && exit 0
    deny "sap-dev-rule.md: .claude/ (rules/skills/hooks/settings) is locked. If the user explicitly asked for this change, ask them to create .claude/.unlock first (and remove it when done)."
    ;;
  "$root_real/"*)
    # Inside the workspace but outside .claude/: block NEW file creation outside artifacts/.
    if [[ "$tool_name" == "Write" && ! -e "$norm" ]]; then
      case "$norm" in
        "$root_real/artifacts/"*) exit 0 ;;
        *) deny "sap-dev-rule.md §4: new workspace files belong under artifacts/ (fs_docs/, technical_specifications/, scratchpads/, walkthroughs/, metadata_extensions/, system_analysis/). Use the session scratchpad dir for temp files." ;;
      esac
    fi
    ;;
esac

exit 0
