# 🚀 SAP ABAP Cloud Agent Workspace (Claude Code)

Pair-programming workspace for developing on **SAP BTP ABAP Environment** and **S/4HANA Cloud (Clean Core)** with Claude Code. This is a sibling to `abap_antigravity_workspace` — same governance rules, same domain skills, same automated workflows — re-plumbed to use Claude Code's actual native mechanics (Skill auto-discovery, slash commands, `CLAUDE.md` imports) instead of Antigravity's router/rules-workflows conventions.

> ### ⭐ For best results, pair this workspace with 2 MCP servers
> Several skills (`find-released-cds-view`, `fs-logic-behavior-translator`, `fs-integration-api-analyzer`, `sap-fiori-apps-reference`, `atc-cloudification`, and rule §9's "verify a tool exists / use `ToolSearch`" guidance) call out to "whichever MCP server/tool your environment exposes" for SAP CDS/documentation search — they work without one, but are far faster and more accurate with these two connected:
>
> | MCP Server | What it gives the Agent |
> |---|---|
> | **[cds-kb-mcp](https://github.com/dovoanhtruong/cds-kb-mcp)** | Semantic search across 7,355 released S/4HANA Cloud CDS views (`search_cds`, `get_cds_view`, `get_views_by_tag`, `get_taxonomy`) — powers `find-released-cds-view` and the Clean-Core-replacement checks in the FS-analysis skills, instead of the Agent guessing a CDS view name. |
> | **[mcp-sap-docs](https://github.com/dovoanhtruong/mcp-sap-docs)** | Hybrid search over SAP Help Portal, SAP Accelerator Hub (OData/REST/SOAP APIs), the Fiori Apps Library, and Clean Core released-object data — backs the "search official SAP documentation before proposing an API/CDS replacement" steps required across the Consultant skills and workflows. |
>
> Add both to your Claude Code MCP config (`claude mcp add` or your `.mcp.json`) — see each repo's README for the exact server command. Once connected, when a skill needs one, Claude Code will surface it as a tool to load via `ToolSearch` on first use.

---

## 📂 Workspace Directory Structure

```text
abap-agent-claudecode-workspace/
├── CLAUDE.md                       # 🧠 Hub file — always loaded; @imports the rule file below
├── .claude/
│   ├── rules/
│   │   └── sap-dev-rule.md         # 🛡️ Mandatory rules (Clean Core, Custom Only, TR, evidence-based reporting...)
│   ├── skills/                     # 📚 33 skills, FLAT — Claude Code auto-discovers & auto-matches by description
│   │   ├── fs-data-model-extractor/ , fs-fiori-ui-elements-mapper/ , fs-logic-behavior-translator/ ,
│   │   │   fs-integration-api-analyzer/ , fs-vision-extractor/ , find-released-cds-view/     # Consultant (FS analysis)
│   │   ├── abap/ , abap-cloud/ , clean-abap/ , naming-convension/ , modern-abap-syntax/ ,
│   │   │   oo-design-patterns/ , rap/ , cds-view-entities/ , odata/ , authorization-iam/ , ...  # Developer (ABAP Cloud)
│   │   └── grill-me/ , caveman/ , handoff/ , scratchpad/ , document-markdown-converter/         # Productivity
│   └── commands/                   # ⚙️ Workflows as slash commands
│       ├── sap-dev-fs-analytic.md      # /sap-dev-fs-analytic — FS → Technical Spec (data on existing released CDS)
│       ├── sap-dev-create-report.md    # /sap-dev-create-report — TS → ABAP RAP source (read-mostly, on released CDS)
│       ├── sap-dev-fs-analytic-transactional-app.md  # /sap-dev-fs-analytic-transactional-app — FS → Technical Spec (new Z-table from scratch)
│       ├── sap-dev-create-transactional-app.md       # /sap-dev-create-transactional-app — TS → DDIC + full RAP tree from scratch
│       ├── sap-dev-bug-fix.md          # /sap-dev-bug-fix — root-cause + regression-safe fix
│       ├── sap-dev-api-inbound.md      # /sap-dev-api-inbound — Z_API_FWK inbound handler
│       ├── sap-dev-api-outbound.md     # /sap-dev-api-outbound — Z_API_FWK outbound call
│       ├── sap-dev-code-analysis.md    # /sap-dev-code-analysis — architecture documentation
│       └── sap-dev-code-review.md      # /sap-dev-code-review — strict QA review
├── artifacts/                      # 📦 Single root for all input/output artifacts (gitignored)
│   ├── fs_docs/                     # Input Functional Specification (FS) documents
│   ├── technical_specifications/    # Technical Specifications (TS_*.md)
│   ├── scratchpads/                 # Architectural drafts, planning & progress ledgers
│   │   └── review/                  # Code Review reports (review_*.md)
│   ├── walkthroughs/                # Deployment guides, testing & task checklists
│   ├── metadata_extensions/         # Generated Metadata Extension (DDLX) source, pending manual ADT creation
│   └── system_analysis/             # System/package analysis reports
├── .gitignore
└── README.md                       # 📖 This file
```

---

## 🛠️ Core Components & How They Work

### 1. Skill Auto-Discovery (`.claude/skills/`)
Claude Code scans `.claude/skills/<name>/SKILL.md` and matches each skill's `description` frontmatter against your request — **no manual router file to read**, unlike a typical Antigravity setup. When you ask for something that matches a skill's description, Claude Code loads it via the Skill tool automatically. Skills are intentionally flat (no Consultant/Developer/Productivity subfolders) because that's what Claude Code's discovery mechanism requires; the category groupings above are just for human browsing.

### 2. Always-On Rules (`CLAUDE.md` → `.claude/rules/sap-dev-rule.md`)
`CLAUDE.md` `@imports` the rule file, so it's unconditionally present in context every turn — more reliable than a "please read this file first" instruction. It forces the Agent to strictly follow:
* **Modern ABAP & Design Patterns:** Constructor Expressions, String Templates, GoF OO Design Patterns.
* **Clean Core:** CDS Views to read, EML to write. No direct modification of physical tables.
* **Custom Only (Z/Y):** Never modify SAP standard objects.
* **TR & Package:** Every new/modified object must declare a Package and Transport Request.
* **Evidence-Based Reporting:** "Activated" ≠ "Correct" — every completion claim needs cited evidence, never "should work / probably fine."
* **Token Efficiency:** Chat narration uses the `caveman` skill to stay terse — never on code, saved reports, or security/consent warnings.

### 3. Workflows as Slash Commands (`.claude/commands/`)
Same commands, same names, same governance as the Antigravity version:
* `/sap-dev-fs-analytic`: Analyzes Word/PDF/Excel FS files → Technical Specification (Data Model, Fiori Elements layout, business logic, Clean Core compliance). Assumes the FS's data already lives in an existing released CDS view.
* `/sap-dev-create-report`: Takes a Technical Spec → generates CDS View Entities, DCL, RAP Behavior Pools, OData Service, with automated testing and a runtime verify loop. Assumes the data already exists in a released standard CDS view.
* `/sap-dev-fs-analytic-transactional-app`: Same 6-phase design as `/sap-dev-fs-analytic`, but for an FS describing a brand-new Chức năng (Transactional App) with no existing table/view — its Data Model phase *designs* the new Z-table structure (fields/types/keys, status machine, numbering strategy) instead of just looking one up, and its Coding Implementation Plan always includes a DDIC Foundation step group.
* `/sap-dev-create-transactional-app`: Same 4-phase design as `/sap-dev-create-report`, but for a brand-new Chức năng (Transactional App) built from zero — designs & creates the DDIC Foundation (Domain, Data Element, Z-Table + Draft Table, Number Range, Message Class) first, then the full RAP composition tree (root + children) with actions/validations/determinations, supporting classes, and the OData service binding.
* `/sap-dev-bug-fix`: Root-causes a reported bug against user-provided mock data, gets explicit approval on a Cross-Impact Report before touching anything, fixes with a mandatory ABAP Unit Test as regression proof.
* `/sap-dev-api-inbound`: Builds an inbound API handler on the `Z_API_FWK` architecture.
* `/sap-dev-api-outbound`: Builds an outbound call via `Z_API_FWK`'s `execute_api`.
* `/sap-dev-code-analysis`: Scans and documents an existing object/package's architecture.
* `/sap-dev-code-review`: Strict QA review (risk, performance, maintainability) — advisory only, no auto-refactor.

---

## 🚀 Quick Start Guide

### Step 1: Prepare Input Documents
Place the Functional Specification (FS) document into `artifacts/fs_docs/` (e.g. a `.docx` or plain text file).

### Step 2: Trigger the FS Analysis Process
- Data already exists in a released CDS view (report/screen): `/sap-dev-fs-analytic artifacts/fs_docs/SAPER_2025_PM_FS.docx Z_INVENTORY_REPORT`
- Brand-new business object, no existing table/view (transactional app): `/sap-dev-fs-analytic-transactional-app artifacts/fs_docs/SAPER_2025_ZBOM_FS.docx ZPRODX_ZBOM`

### Step 3: Evaluate Technical Spec & Generate Code
Review the generated `artifacts/technical_specifications/TS_*.md`, then run the matching build workflow with the Package, Transport Request, and TS path: `/sap-dev-create-report` (TS §3 lists only existing released CDS views) or `/sap-dev-create-transactional-app` (TS §3 defines brand-new Z-tables — TS §2 states `Target Build Workflow: /sap-dev-create-transactional-app`).

---

## ⚙️ Notes for Developers
* **Relative Paths:** All configuration documents use relative paths so the workspace can move to any machine without breaking links.
* **Adding Skills:** Drop a new `.claude/skills/<name>/SKILL.md` with `name`/`description` frontmatter — Claude Code picks it up automatically, no registration table to edit.
* **document-markdown-converter setup:** This skill shells out to a local MarkItDown CLI in `.venv_markitdown/` (relative to workspace root). That venv is not included — run `python3 -m venv .venv_markitdown && ./.venv_markitdown/bin/pip install 'markitdown[all]'` once before first use of `/sap-dev-fs-analytic` on a binary FS file.
* **MCP Servers:** See the highlighted callout near the top of this README — connect `cds-kb-mcp` and `mcp-sap-docs` for the best experience.
* **Relationship to `abap_antigravity_workspace`:** This workspace was ported from it and is maintained separately — a fix or new skill added to one does not automatically propagate to the other.
