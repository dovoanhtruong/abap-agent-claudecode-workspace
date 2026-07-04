# SAP ABAP Cloud Agent Workspace (Claude Code)

Pair-programming workspace for developing on **SAP BTP ABAP Environment** / **S/4HANA Cloud (Clean Core)**. Sibling workspace to `abap_antigravity_workspace`, ported and re-plumbed for Claude Code's actual mechanics — same governance and domain knowledge, native invocation.

@.claude/rules/sap-dev-rule.md

## How this workspace works

- **Skills** (`.claude/skills/<name>/SKILL.md`, ~33 of them) auto-activate when their description matches your request — no manual routing needed. See `README.md` for the full catalog by category.
- **Workflows** are slash commands in `.claude/commands/`: `/sap-dev-fs-analytic`, `/sap-dev-create-report`, `/sap-dev-bug-fix`, `/sap-dev-api-inbound`, `/sap-dev-api-outbound`, `/sap-dev-code-analysis`, `/sap-dev-code-review`.
- **Outputs** always go under `artifacts/` (see rule §4) — never `.claude/` or the workspace root.

## Recommended MCP servers

For accurate CDS/documentation lookups (used by `find-released-cds-view` and several other skills), connect:
- [cds-kb-mcp](https://github.com/dovoanhtruong/cds-kb-mcp) — semantic search over 7,355 released S/4HANA Cloud CDS views.
- [mcp-sap-docs](https://github.com/dovoanhtruong/mcp-sap-docs) — SAP Help Portal / Accelerator Hub / Fiori Library search.

Full setup details in `README.md`.
