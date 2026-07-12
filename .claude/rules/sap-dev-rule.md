# SAP CLOUD DEV RULES (STRICT)

**§1 ROUTING:** Skills auto-activate by description match (`.claude/skills/<name>/SKILL.md`); workflows are slash commands in `.claude/commands/`. Reference skills as `[Skill: x]` — meaning "invoke skill `x` (exact kebab directory name) via the Skill tool"; never re-embed another skill's content. Reference subagents as `[Agent: y]` — meaning "dispatch subagent `y` (`.claude/agents/y.md`) via the Agent tool with `subagent_type: y`, passing the exact input/output paths named in that step"; never dispatch without them, and never with `isolation: "worktree"` (breaks the hooks' path resolution against this workspace root).

**§2 SCOPE & SAFETY:**
- **DEV only**: this workspace assumes every SAP connection is a DEV system. If a connection is ever anything else, STOP and ask before any operation.
- Consent before any CUD op. Z/Y custom objects only — never touch Standard objects *(hook-enforced)*. Stay strictly in task scope, no side effects.
- Check names globally before creating; if taken, propose a new name and ask. Default names per [Skill: naming-convention]; an explicit TS/user-specified name always wins over the default.
- TR + Package mandatory for every new/modified object — ask if missing *(hook-enforced)*. Never create/delete/modify a Transport Request itself *(hook-enforced)* — if none is supplied, stop and ask; never auto-generate a TR.
- Business data is read-only unless explicitly testing a RAP BO.

**§3 CODE STANDARDS:** Modern ABAP (VALUE/COND/REDUCE) — reject legacy procedural code; GoF patterns only where genuinely warranted ([Skill: oo-design-patterns]). Read via CDS views only, never physical tables. Write via EML or Released APIs only, never direct INSERT/UPDATE.

**§4 WORKFLOW & FILES:** Draft complex architecture in a scratchpad first. All outputs under `artifacts/` — never `.claude/` or the workspace root *(hook-enforced: new files outside `artifacts/` are blocked)*: FS inputs → `fs_docs/` · TS → `technical_specifications/` · Scratchpads & Handoffs → `scratchpads/` · Walkthroughs → `walkthroughs/` · Metadata Ext → `metadata_extensions/` · System Analysis → `system_analysis/`.

**§5 VALIDATION & ERRORS:** On activation failure extract the exact SAP error, don't guess the cause. After EVERY single object create/edit/delete (not just at workflow end), run [Skill: activation-guard]'s 3 gates — full activation log incl. every warning assessed, confirmed active state, ripple/cross-impact check on dependents — before marking that step DONE. "Isolated" means dependents unbroken: an object that breaks something it's connected to fails this check even if it activated clean itself.

**§6 IRON LAWS (NO EXCEPTIONS):**
- No TS handoff without a passed Verify Loop (or a FAIL the user explicitly accepted in writing).
- No object/logic creation absent from the TS's Coding Implementation Plan — missing info means STOP; go back to the user or the fs-analytic workflow, don't improvise.
- No activation-only claims (§8). No ledger row DONE without all 3 [Skill: activation-guard] gates — a warning waved through unassessed, or a downstream object silently broken, is not a completed step.

**§7 RED FLAGS — STOP if you catch yourself thinking:** "Simple FS, skip a step" (run every step, just faster) · "Missing a field, I'll infer it while coding" (patch the TS first) · "It activated, so it's probably correct" (unverified until Verify runs) · "Just a warning, moving on" (assess it via Gate 1 first) · "That object's not mine, no need to recheck" (Gate 3 exists precisely for this) · "One more fix" after ≥3 attempts (it's an architecture/TS problem — ask the user).

**§8 REPORTING LANGUAGE:** Never say "should work / probably fine / likely correct." Every "Activated/Passed/Correct" claim needs cited evidence (command run, output observed). Activated ≠ Correct — state both separately.

**§9 MCP TOOL USAGE:** Skills dispatch whatever MCP server/tool their function needs. Verify a tool actually exists before its first use in a session — never assume another skill's tool name/syntax applies. A not-yet-loaded MCP tool appears as a deferred stub — use `ToolSearch` to load its schema before calling it.

**§10 TOKEN EFFICIENCY:** Chat narration (progress, status, completion summaries) uses [Skill: caveman] — scope and exceptions per its SKILL.md (never code, saved deliverable files, or security/consent warnings). Never re-print a full TS/scratchpad — quote only the section needed, reference the path for the rest. [Skill: grill-me]: 1-3 targeted questions per round, max ~3 rounds. [Skill: handoff]: mandatory before a session is likely to be compacted/interrupted mid-workflow.

**§11 EVIDENCE FLOOR:** A bare "looks fine / ok / works" is not a PASS — ask for the actual evidence the step requires (payload, field values, screenshot) before recording a result. If the user insists without it, record "PASS — unverified, user-accepted", never a plain PASS.

**§12 SUBAGENTS:** Dispatch parallel agents only for independent work over read-only shared inputs; each agent writes ONLY its own output file — no shared state. An agent's completion claim is unverified until you read its output on disk; never mark a ledger row DONE from the completion message alone. If an agent dies mid-task (spend limit, timeout), inspect the disk for partial writes, then finish the remainder inline — never assume it completed. **Team roles** (`.claude/agents/`): Consultant/Dev/Tester, each split Lead (judgment-heavy) / Executor (spec- or template-driven) — the Manager (this session) is the only one holding SAP CUD authority; no team subagent ever calls an SAP object-mutation tool, they draft/lint/analyze and write to `artifacts/scratchpads/` only, and the Manager itself runs Push → Activate → [Skill: activation-guard] after reading their file.

**§13 LANGUAGE:** Chat with the user: tiếng Việt. Code, identifiers, code comments, commit messages: English. TS/reports: bilingual per their templates. Skill/rule file bodies: English (trigger and instruction accuracy).

**§14 SELF-MODIFICATION & MEMORY:** `.claude/` (rules/skills/hooks/settings) may only be changed when the user explicitly requested it AND the user has manually created `.claude/.unlock` *(hook-enforced; the agent is permanently blocked from creating that sentinel)* — remind the user to delete `.unlock` when done. After any `.claude/` change, re-run the integrity check: every skill's frontmatter `name:` equals its directory name, every `[Skill: x]` reference resolves; every subagent's frontmatter `name:` equals its filename (`.claude/agents/<name>.md`), every `[Agent: y]` reference resolves. Lessons learned from a workflow → propose a skill/rule patch for the user to approve, never silently apply or stash. Memory holds user preferences/feedback only — task state belongs in the ledger/handoff, business data nowhere.

**HOOK-ENFORCED (code, not promises):** `.claude/hooks/pre-cud-guard.sh` — Z/Y-only naming, TR+Package presence, no agent TR CUD · `.claude/hooks/workspace-write-guard.sh` — `.claude/` lock via `.unlock` sentinel, new workspace files under `artifacts/` only.
