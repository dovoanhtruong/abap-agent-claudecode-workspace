# SAP ABAP Cloud Agent Workspace (Claude Code)

Pair-programming workspace for developing on **SAP BTP ABAP Environment** / **S/4HANA Cloud (Clean Core)**. Sibling workspace to `abap_antigravity_workspace`, ported and re-plumbed for Claude Code's actual mechanics — same governance and domain knowledge, native invocation.

@.claude/rules/sap-dev-rule.md

## How this workspace works

- **Skills** (`.claude/skills/<name>/SKILL.md`, 54 of them) auto-activate by description match — no manual routing. Catalog in `README.md`; heavy templates live in each skill's `references/`, loaded only when producing that object. The 18 `sap-process-*` skills carry SAP Public Cloud business-process knowledge for FS analysis (lean `SKILL.md` + on-demand `references/deep-dive.md`, read only when the FS needs that depth).
- **Subagents** (`.claude/agents/<team>-<layer>.md`, 6 of them) — Consultant/Dev/Tester × Lead (opus)/Executor (sonnet) — dispatched by workflows via `[Agent: y]` for isolated analysis/drafting, under rule §12's discipline (Manager-only SAP CUD authority, drafts to the active project's `scratchpads/` only, no ledger-DONE).
- **Workflows** are slash commands in `.claude/commands/`. Pick by scenario:

| Scenario | Analyze (FS → TS) | Build (TS → system) |
|---|---|---|
| Report/screen over EXISTING released CDS data | `/sap-dev-fs-analytic` | `/sap-dev-create-report` |
| Brand-new transactional app (no Z-table/CDS yet) | `/sap-dev-fs-analytic-transactional-app` | `/sap-dev-create-transactional-app` |
| Bug on an existing object (mock-data based) | — | `/sap-dev-bug-fix` |
| Single small task — quick mutation / lookup / how-to / snippet review (~70% of real interactions) | — | `/sap-task` (or a bare prompt — rule §15 routes it through the same skill map, opening every SAP answer with a `Skills: [...]` declaration) |
| Inbound / outbound API on Z_API_FWK | — | `/sap-dev-api-inbound` · `/sap-dev-api-outbound` |
| Document / review existing code (read-only) | `/sap-dev-code-analysis` · `/sap-dev-code-review` | — |
| Start working with a NEW project (skeleton + project.md) | — | `/sap-project-init <name>` |

- **Outputs are per-project** — rule §4 (hook-enforced): one project under `projects/<project>/`, 6 standard subfolders, `project.md` read first as base context; new projects only via `/sap-project-init`.
- **`.claude/` is locked** — rule §14 (hook-enforced): the USER must `touch .claude/.unlock` first (never the agent), and delete it when done.

## Recommended MCP servers

For accurate CDS/documentation lookups (used by `find-released-cds-view` and several other skills), connect:
- [cds-kb-mcp](https://github.com/dovoanhtruong/cds-kb-mcp) — semantic search over 7,355 released S/4HANA Cloud CDS views.
- [mcp-sap-docs](https://github.com/dovoanhtruong/mcp-sap-docs) — SAP Help Portal / Accelerator Hub / Fiori Library search.

Full setup details in `README.md`.
