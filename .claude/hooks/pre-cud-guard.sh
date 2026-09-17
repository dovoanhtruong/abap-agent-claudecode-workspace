#!/usr/bin/env bash
# PreToolUse guard for SAP CUD calls (mcp__sap_nfg_dev__*).
# Hard-enforces 3 rules from .claude/rules/sap-dev-rule.md §2 that were previously
# prompt-only: Z/Y-only naming, TR+Package presence, and no agent-driven TR CUD.
#
# Heuristic / schema-agnostic: greps the raw tool_input JSON as text rather than
# parsing named fields, because the real mcp__sap_nfg_dev__SAP argument schema was
# not available to verify at write time (server was disconnected). Once connected,
# inspect one real call's tool_input and tighten the field lookups below instead of
# blind regex — see README "Notes for Developers".
#
# DEPENDENCY-FREE ON PURPOSE: an earlier version used `jq` both to slice out
# tool_input and to emit the deny JSON; `jq` does not exist on this machine, so
# the guard silently failed open (payload fell back to '{}' → every check
# passed, and deny() printed nothing even when triggered). Pure bash/sed below —
# do not reintroduce external binaries without verifying they exist in the
# HOOK's execution environment.
set -uo pipefail

input=$(cat)
# Slice from "tool_input": onward (sed, no jq). Slightly wider than the exact
# object if other envelope fields follow it — acceptable for a heuristic guard,
# and infinitely better than the '{}' fail-open. Falls back to the whole input.
tool_input=$(printf '%s' "$input" | sed -nE 's/.*"tool_input"[[:space:]]*:[[:space:]]*(\{.*)/\1/p')
[[ -z "$tool_input" ]] && tool_input="$input"
payload=$(printf '%s' "$tool_input" | tr '[:upper:]' '[:lower:]')

deny() {
  local reason="${1//\\/ }"
  reason="${reason//\"/\'}"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$reason"
  exit 0
}

# Rule: agent must never create/delete/modify a Transport Request itself.
# NOTE: deliberately does NOT match on a bare "tr" token — that's also the likely
# field name for a *reference* to an existing TR on an unrelated object-CUD call
# (e.g. {"action":"create","object_name":"ZFOO","tr":"DEVK900123"} must still be
# allowed through to the TR+Package check below, not blocked as "TR mutation").
# Only explicit, SAP-specific TR tokens count as "acting on the TR itself".
tr_token='(transport[_ ]?request|trkorr)'
verb='(create|delete|remove|release|change|modify)'
if echo "$payload" | grep -qE "${tr_token}.{0,60}${verb}" \
   || echo "$payload" | grep -qE "${verb}.{0,60}${tr_token}"; then
  deny "sap-dev-rule.md: agent must never create/delete/modify a Transport Request. Stop and ask the user to supply/manage the TR."
fi

# Below only applies to calls that look like an object CUD action.
if echo "$payload" | grep -qE '"(action|operation|method)"[[:space:]]*:[[:space:]]*"(create|insert|update|modify|delete|activate)"' \
   || echo "$payload" | grep -qE '\b(create|insert|update|modify|delete|activate)_object\b'; then

  # Rule: TR + Package mandatory for every new/modified object.
  # SAP TR format: 3-char SID + 1-char category letter (K/T/...) + 6-digit number, e.g. DEVK900123.
  has_tr="no"
  echo "$payload" | grep -qE '[a-z0-9]{3}[a-z][0-9]{6}' && has_tr="yes"
  echo "$payload" | grep -qE '"transport"[[:space:]]*:[[:space:]]*"local(_object)?"' && has_tr="yes"
  has_pkg="no"
  echo "$payload" | grep -qE '"package"' && has_pkg="yes"
  if [[ "$has_tr" == "no" || "$has_pkg" == "no" ]]; then
    deny "sap-dev-rule.md: TR + Package mandatory for object CUD. Missing here — stop and ask the user to supply them (do not auto-generate a TR)."
  fi

  # Rule: Custom Z/Y objects only — never touch Standard objects.
  obj_name=$(echo "$tool_input" | grep -oE '"(object_name|objectname|name|obj_name)"[[:space:]]*:[[:space:]]*"[^"]+"' \
    | head -1 | sed -E 's/.*:"([^"]+)"/\1/')
  if [[ -n "$obj_name" ]]; then
    first_char=$(echo "${obj_name:0:1}" | tr '[:upper:]' '[:lower:]')
    if [[ "$first_char" != "z" && "$first_char" != "y" ]]; then
      deny "sap-dev-rule.md: Custom Z/Y objects only. Target object '$obj_name' does not match Z*/Y* naming — never touch Standard objects."
    fi
  fi
fi

exit 0
