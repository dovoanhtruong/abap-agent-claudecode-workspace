#!/usr/bin/env bash
# SessionStart check for the projects store (rule §4 "Projects store").
# `projects/` is a per-device junction/symlink to a separate git repo outside
# the workspace. This hook verifies the link exists and reports the store's
# sync state. Stdout of a SessionStart hook is added to Claude's context, so it
# stays SILENT when everything is in sync (zero token cost) and prints one
# short line per problem otherwise. Read-only: fetch is the only network call,
# never pull/push/commit. Idempotent — safe if SessionStart fires twice.
set -uo pipefail

root="${CLAUDE_PROJECT_DIR:-$PWD}"
root="${root//\\//}"
p="$root/projects"
tag="[projects-sync] Mention to the user before starting work:"

if [[ ! -d "$p" ]]; then
  echo "$tag projects/ is not linked on this device, so every project read/write fails. Setup: powershell -ExecutionPolicy Bypass -File .claude/scripts/link-projects.ps1 -Store <path-to-projects-repo> [-Remote <url>]"
  exit 0
fi

# Must test projects/.git directly: `git -C projects` on a plain folder would
# walk up and find the WORKSPACE repo instead.
if [[ ! -e "$p/.git" ]]; then
  echo "$tag projects/ is not a git repo, so cross-device sync is unavailable (README: Multi-device projects)."
  exit 0
fi

# Non-interactive fetch; `timeout` is coreutils (Git Bash has it, stock macOS
# does not) — fall back to the hook's own timeout from settings.json.
fetch_origin() {
  export GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never
  if command -v timeout >/dev/null 2>&1; then
    timeout 8 git -C "$p" fetch -q origin
  else
    git -C "$p" fetch -q origin
  fi
}

msgs=()
if git -C "$p" remote get-url origin >/dev/null 2>&1; then
  if fetch_origin >/dev/null 2>&1; then
    if git -C "$p" rev-parse -q --verify '@{u}' >/dev/null 2>&1; then
      behind=$(git -C "$p" rev-list --count 'HEAD..@{u}' 2>/dev/null || echo 0)
      ahead=$(git -C "$p" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)
      (( behind > 0 )) && msgs+=("behind origin by $behind commit(s) — run /sap-resume <project> (or git -C projects pull) before working")
      (( ahead > 0 ))  && msgs+=("$ahead local commit(s) not pushed — run /sap-sync")
    else
      msgs+=("branch has no upstream — run: git -C projects push -u origin HEAD")
    fi
  else
    msgs+=("could not reach the projects remote (offline/auth) — sync state unknown")
  fi
else
  msgs+=("no remote configured — cross-device sync not set up yet")
fi

dirty=$(git -C "$p" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
(( dirty > 0 )) && msgs+=("$dirty uncommitted change(s) — run /sap-handoff <project> or /sap-sync when the task is done")

(( ${#msgs[@]} == 0 )) && exit 0
joined=$(printf '%s; ' "${msgs[@]}")
echo "$tag projects repo: ${joined%; }."
exit 0
