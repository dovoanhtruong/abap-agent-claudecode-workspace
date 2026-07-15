# SAP ABAP Cloud Agent Workspace (Claude Code)

Pair-programming workspace for developing on **SAP BTP ABAP Environment** / **S/4HANA Cloud (Clean Core)**. Sibling workspace to `abap_antigravity_workspace`, ported and re-plumbed for Claude Code's actual mechanics — same governance and domain knowledge, native invocation.

@.claude/rules/sap-dev-rule.md

## How this workspace works

- **Skills** (`.claude/skills/<name>/SKILL.md`, 52 of them) auto-activate when their description matches the request — no manual routing. Grouped catalog in `README.md`; heavy templates live in each skill's `references/`, loaded only when writing that object. 18 of them are `sap-process-*` — SAP Public Cloud business-process/functional-consulting knowledge (O2C, Supply Chain, Manufacturing, Production, Finance, Project System) for `consultant-lead` to draw on during FS analysis; each has a lean always-loaded `SKILL.md` + an on-demand `references/deep-dive.md` for deeper business-logic depth (partner determination, pricing, planning strategy, etc.), read only when the FS genuinely needs it.
- **Subagents** (`.claude/agents/<team>-<layer>.md`, 6 of them) — Team Consultant/Dev/Tester × Lead (opus, judgment-heavy)/Executor (sonnet, template-driven) — dispatched by workflows via `[Agent: y]` for isolated analysis/drafting. The Manager (this session) alone holds SAP CUD authority; subagents only draft to `artifacts/scratchpads/` and never mark a ledger row DONE.
- **Workflows** are slash commands in `.claude/commands/`. Pick by scenario:

| Scenario | Analyze (FS → TS) | Build (TS → system) |
|---|---|---|
| Report/screen over EXISTING released CDS data | `/sap-dev-fs-analytic` | `/sap-dev-create-report` |
| Brand-new transactional app (no Z-table/CDS yet) | `/sap-dev-fs-analytic-transactional-app` | `/sap-dev-create-transactional-app` |
| Bug on an existing object (mock-data based) | — | `/sap-dev-bug-fix` |
| Inbound / outbound API on Z_API_FWK | — | `/sap-dev-api-inbound` · `/sap-dev-api-outbound` |
| Document / review existing code (read-only) | `/sap-dev-code-analysis` · `/sap-dev-code-review` | — |

- **Outputs** always go under `artifacts/` (rule §4, hook-enforced) — never `.claude/` or the workspace root.
- **`.claude/` is locked** (rule §14, hook-enforced): to modify rules/skills/hooks on the user's request, the USER must first `touch .claude/.unlock` (the agent must never create that file) — remind them, and remind them to delete it afterwards.

## Recommended MCP servers

For accurate CDS/documentation lookups (used by `find-released-cds-view` and several other skills), connect:
- [cds-kb-mcp](https://github.com/dovoanhtruong/cds-kb-mcp) — semantic search over 7,355 released S/4HANA Cloud CDS views.
- [mcp-sap-docs](https://github.com/dovoanhtruong/mcp-sap-docs) — SAP Help Portal / Accelerator Hub / Fiori Library search.

Full setup details in `README.md`.
