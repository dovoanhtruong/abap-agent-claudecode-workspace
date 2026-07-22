#!/usr/bin/env bash
# PreToolUse guard for filesystem writes. Hard-enforces two rules from
# .claude/rules/sap-dev-rule.md that were previously prompt-only:
#   1. `.claude/` is locked: no Write/Edit/delete inside it unless the USER has
#      created the sentinel file `.claude/.unlock` (the agent itself is always
#      blocked from creating/editing that sentinel — that's what makes it a lock).
#   2. Output containment (§4): NEW files inside the workspace must be created
#      under `projects/<existing-project>/<standard-subfolder>/` (or be that
#      project's own `project.md`). The project directory must already exist —
#      creation is an explicit step (/sap-project-init), so a typo'd project
#      name fails loudly instead of spawning a junk folder. Editing files that
#      already exist is allowed, and paths outside the workspace (session
#      scratchpad, memory dir) are not this hook's business.
#      Exception: a small whitelist of root-level TOOL config (`.mcp.json`,
#      `.gitignore`, `.env`, `.env.*`) is exempt — these are Claude Code/repo
#      infra, not FS/TS/scratchpad deliverables, so §4's containment intent
#      doesn't apply to them. Root-level only (not matched inside subfolders).
# Matched on Write|Edit|NotebookEdit and on Bash (destructive commands touching
# .claude/ only).
#
# DEPENDENCY-FREE ON PURPOSE: an earlier version parsed JSON with `jq` and
# normalized paths with `python3`; neither exists on this machine, so with
# `set -e` the hook died before any check ran and every guarded call sailed
# through (fail-open). Everything below is pure bash + sed. If you edit this,
# do not reintroduce external binaries without verifying they exist in the
# HOOK's execution environment (not just your interactive shell).
set -uo pipefail

input=$(cat)

# Extract the first JSON string value for a key, unescaping \\ \" \/ .
json_str() {
  local raw
  raw=$(printf '%s' "$input" | sed -nE 's/.*"'"$1"'"[[:space:]]*:[[:space:]]*"((\\.|[^"\\])*)".*/\1/p' | head -n1)
  raw="${raw//\\\\/$'\x01'}"
  raw="${raw//\\\"/\"}"
  raw="${raw//\\\//\/}"
  raw="${raw//$'\x01'/\\}"
  printf '%s' "$raw"
}

# Canonical comparison form: backslashes→slashes, "C:/..."→"/c/...", lowercased
# (Windows filesystems are case-insensitive; there is no symlink resolution —
# acceptable on this Windows workspace, where the old python3 realpath never
# actually ran anyway).
# NOTE: lowercasing uses `tr`, not `${var,,}` — macOS ships /bin/bash 3.2
# (no GPLv3 upgrades), which doesn't support bash 4+ case-conversion
# expansion; `${var,,}` there is a silent "bad substitution" that makes this
# function always return "", corrupting every path comparison below it.
norm_path() {
  local p="${1//\\//}"
  if [[ "$p" =~ ^([A-Za-z]):(/.*)?$ ]]; then
    local d="${BASH_REMATCH[1]}"
    d=$(printf '%s' "$d" | tr '[:upper:]' '[:lower:]')
    p="/${d}${BASH_REMATCH[2]:-}"
  fi
  printf '%s' "$p" | tr '[:upper:]' '[:lower:]'
}

deny() {
  local reason="${1//\\/ }"
  reason="${reason//\"/\'}"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
  exit 0
}

tool_name=$(json_str tool_name)
root="${CLAUDE_PROJECT_DIR:-$PWD}"
root_fs="${root//\\//}"            # filesystem-usable form (for -f/-d tests)
root_n=$(norm_path "$root")        # comparison form
unlock="$root_fs/.claude/.unlock"

# --- Bash: only police destructive commands that target .claude/ ---
if [[ "$tool_name" == "Bash" ]]; then
  cmd=$(json_str command)
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
file_path=$(json_str file_path)
[[ -z "$file_path" ]] && file_path=$(json_str notebook_path)
[[ -z "$file_path" ]] && exit 0

fp_fs="${file_path//\\//}"
fp_n=$(norm_path "$file_path")
# Relative paths resolve against the project root (hooks run from it).
if [[ "$fp_n" != /* ]]; then
  fp_n="$root_n/$fp_n"
  fp_fs="$root_fs/$fp_fs"
fi

case "$fp_n" in
  "$root_n/.claude/"*|"$root_n/.claude")
    if [[ "${fp_n##*/}" == ".unlock" ]]; then
      deny "sap-dev-rule.md: the agent must never create or edit .claude/.unlock — only the user may, manually."
    fi
    [[ -f "$unlock" ]] && exit 0
    deny "sap-dev-rule.md: .claude/ (rules/skills/hooks/settings) is locked. If the user explicitly asked for this change, ask them to create .claude/.unlock first (and remove it when done)."
    ;;
  "$root_n/"*)
    # Inside the workspace but outside .claude/: block NEW file creation outside
    # projects/<existing-project>/<standard-subfolder>/ (or that project's project.md).
    if [[ "$tool_name" == "Write" && ! -e "$fp_fs" ]]; then
      base="${fp_n##*/}"
      if [[ "$fp_n" == "$root_n/$base" ]]; then
        case "$base" in
          .mcp.json|.gitignore|.env|.env.*) exit 0 ;;
        esac
      fi
      case "$fp_n" in
        "$root_n/projects/"*)
          rel="${fp_n#"$root_n"/projects/}"
          proj="${rel%%/*}"
          if [[ "$rel" == "$proj" ]]; then
            deny "sap-dev-rule.md §4: files never live directly under projects/ — every output belongs inside one project (projects/<project>/<subfolder>/). Pick or init a project first (/sap-project-init <name>)."
          fi
          if [[ ! -d "$root_fs/projects/$proj" ]]; then
            deny "sap-dev-rule.md §4: project '$proj' does not exist. Creating a project is an explicit step — run /sap-project-init $proj (or fix the project name) before writing into it."
          fi
          rest="${rel#*/}"
          if [[ "$rest" == "project.md" ]]; then exit 0; fi
          sub="${rest%%/*}"
          case "$sub" in
            fs_docs|technical_specifications|scratchpads|walkthroughs|metadata_extensions|system_analysis) exit 0 ;;
            *) deny "sap-dev-rule.md §4: '$sub' is not a standard project subfolder. New files in projects/$proj/ belong under fs_docs/, technical_specifications/, scratchpads/, walkthroughs/, metadata_extensions/, or system_analysis/ (or the project's own project.md)." ;;
          esac
          ;;
        *) deny "sap-dev-rule.md §4: new workspace files belong under projects/<project>/<standard-subfolder>/ (fs_docs/, technical_specifications/, scratchpads/, walkthroughs/, metadata_extensions/, system_analysis/). Use the session scratchpad dir for temp files." ;;
      esac
    fi
    ;;
esac

exit 0
