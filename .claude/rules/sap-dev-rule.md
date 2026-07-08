# SAP CLOUD DEV RULES (STRICT)

**1. SKILL ROUTING:** Skills auto-activate by description match — Claude Code loads `.claude/skills/<name>/SKILL.md` automatically when its description matches the task. Workflows live in `.claude/commands/` as slash commands (`/sap-dev-fs-analytic`, etc.). No manual routing table needed.
**2. SCOPE & SAFETY:**
- Consent before any CUD op. Z/Y custom objects only — never touch Standard objects. Stay strictly in task scope, no side-effects.
- Check names globally before creating; if taken, propose a new name and ask.
- TR + Package mandatory for every new/modified object — ask if missing.
- Business data is read-only unless explicitly testing a RAP BO.
**3. CODE STANDARDS:**
- Modern ABAP (VALUE/COND/REDUCE) + GoF patterns; reject legacy procedural code.
- Read via CDS Views only, never physical tables. Write via EML or Released APIs only, never direct INSERT/UPDATE.
**4. WORKFLOW & FILES:**
- Draft complex architecture in a scratchpad first.
- All outputs under `artifacts/` (never `.claude/` or root): FS inputs → `fs_docs/` · TS → `technical_specifications/` · Scratchpads → `scratchpads/` · Walkthroughs → `walkthroughs/` · Metadata Ext → `metadata_extensions/` · System Analysis → `system_analysis/`.
**5. VALIDATION & ERRORS:**
- Trigger activation; on failure extract the exact SAP error, don't guess the cause.
- Post-CUD final check: no mutation outside scope, no syntax errors, activated, isolated — run `[Skill: Activation Guard]`'s 3 gates (full activation log incl. warnings, confirmed active state, ripple/cross-impact check on dependents) after every single object create/edit/delete, not just at the end of a workflow. This is what "isolated" means in practice: an object breaking something it's connected to is a failure of this check, even if the object itself activated with no error.
**6. IRON LAWS (NO EXCEPTIONS):**
- No TS handoff without a passed Verify Loop (or a FAIL the user explicitly accepted in writing).
- No object/logic creation absent from the TS's Coding Implementation Plan — missing info means STOP, don't improvise; go back to the user or `/sap-dev-fs-analytic`.
- No activation-only claims — see §8 (Activated ≠ Correct).
- No object marked DONE in a build ledger without passing all 3 `[Skill: Activation Guard]` gates — a warning waved through without assessment, or a downstream object silently broken by this change, is not a completed step.
**7. RED FLAGS — STOP if you catch yourself thinking:**
- "Simple FS, skip a step" → still run every step, just faster.
- "Missing a field, I'll infer it while coding" → patch the TS first, don't improvise.
- "It activated, so it's probably correct" → unverified until the Verify step actually runs.
- "Just a warning, moving on" → run `[Skill: Activation Guard]` Gate 1's assessment first; a warning waved through unassessed is exactly how a later object inherits a silent defect.
- "That object's not mine, no need to recheck it" → if it's downstream of what you just changed, `[Skill: Activation Guard]` Gate 3 re-checks it anyway — that's the whole point.
- "One more fix" after ≥3 attempts → stop, it's an architecture/TS problem — ask the user.
**8. REPORTING LANGUAGE:** Never say "should work / probably fine / likely correct." Every "Activated/Passed/Correct" claim needs cited evidence (command run, output observed) — Activated ≠ Correct, state both separately.
**9. MCP TOOL USAGE:** Skills dispatch whatever MCP server/tool their function needs. Verify a tool actually exists before its first use in a session — never assume another skill's tool name/syntax applies here. In Claude Code specifically, a not-yet-loaded MCP tool appears as a deferred stub — use the `ToolSearch` tool with a relevant query to find and load its schema before calling it.
**10. TOKEN EFFICIENCY:**
- Chat narration (progress, status, completion summaries) uses **[Skill: Caveman]** — scope and exceptions are defined in `caveman/SKILL.md` (never applies to code, saved deliverable files, or security/consent warnings).
- Never re-print a full TS/scratchpad — quote only the section needed, reference the path for the rest.
- Reference other skills as `[Skill: X]` — this means "invoke the `x` skill via the Skill tool" (auto-discovered from `.claude/skills/x/`); don't re-embed their content.
- `[Skill: Grill Me]`: 1-3 targeted questions per round, not open interviews.
- `[Skill: Handoff]`: mandatory before a session is likely to be compacted/interrupted mid-workflow.
**11. EVIDENCE FLOOR FOR USER VERIFICATION:** A bare "looks fine / ok / works" is not a PASS — ask again for the actual evidence the step requires (payload, field values, screenshot) before recording a result. If the user insists without it, record "PASS — unverified, user-accepted", never a plain PASS.
