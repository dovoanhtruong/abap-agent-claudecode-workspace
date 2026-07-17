# 🚀 SAP ABAP Cloud Agent Workspace (Claude Code)

![Claude Code](https://img.shields.io/badge/Claude%20Code-native-7A5AF8)
![SAP](https://img.shields.io/badge/SAP-ABAP%20Cloud%20%C2%B7%20Clean%20Core-0FAAFF)
![Skills](https://img.shields.io/badge/skills-53-2EA44F)
![Workflows](https://img.shields.io/badge/workflows-9-E8590C)
![Subagents](https://img.shields.io/badge/subagents-6-8957E5)
![Guardrails](https://img.shields.io/badge/guardrails-hook--enforced-CF222E)

Pair-programming workspace for developing on **SAP BTP ABAP Environment** and **S/4HANA Cloud (Clean Core)** with Claude Code. It turns Claude into a governed SAP developer: 53 domain skills auto-activate by description (35 ABAP Cloud engineering skills + 18 SAP Public Cloud business-process skills across O2C/Supply Chain/Manufacturing/Production/Finance/Project System), 10 slash-command workflows drive FS-to-deployed-code pipelines (plus a micro-workflow for single-prompt tasks), a 3-team/2-layer subagent pool (Consultant/Dev/Tester × Lead/Executor) handles isolated analysis and drafting, an always-loaded rule file enforces Clean Core discipline, and `PreToolUse` hooks hard-block the riskiest operations in code — not just in prompt text.

> Sibling to `abap_antigravity_workspace` — same governance and domain knowledge, re-plumbed for Claude Code's native mechanics (Skill auto-discovery, slash commands, `CLAUDE.md` imports).

---

## 🧭 Architecture at a Glance

```mermaid
flowchart LR
    subgraph CTX["Always in context"]
        CM["CLAUDE.md (hub)"] --> RULE["sap-dev-rule.md<br/>§1-§14 strict rules"]
    end
    subgraph ONDEMAND["Loaded on demand"]
        SK["53 skills<br/>.claude/skills/*"] --> REF["references/*<br/>templates, sources & deep-dive docs"]
        WF["10 workflows<br/>.claude/commands/*"]
        AG["6 subagents<br/>.claude/agents/*<br/>Consultant/Dev/Tester × Lead/Executor"]
    end
    subgraph ENFORCE["Hook-enforced (code)"]
        H1["pre-cud-guard.sh<br/>Z/Y-only · TR+Package · no TR CUD"]
        H2["workspace-write-guard.sh<br/>.claude/ lock · artifacts/-only outputs"]
    end
    USER((User)) --> WF
    USER --> SK
    WF -->|"[Skill: x]"| SK
    WF -->|"[Agent: y]"| AG
    AG -->|"[Skill: x]"| SK
    RULE -.governs.-> WF & SK & AG
    H1 & H2 -.block bad calls.-> WF & SK & AG
    SK --> MCP["MCP servers<br/>cds-kb · sap-docs · ADT"]
```

```mermaid
flowchart LR
    FS["📄 FS document<br/>artifacts/fs_docs/"] --> A{"New Z-tables<br/>needed?"}
    A -->|"no — data in released CDS"| FA["/sap-dev-fs-analytic"]
    A -->|"yes — brand-new app"| FAT["/sap-dev-fs-analytic-transactional-app"]
    FA --> TS["📋 TS_*.md + Verify Loop<br/>(max 3 iterations)"]
    FAT --> TS
    TS --> G1{{"👤 Human reviews TS"}}
    G1 --> CR["/sap-dev-create-report"]
    G1 --> CTA["/sap-dev-create-transactional-app"]
    CR --> BUILD["Sequential RAP build<br/>every object: Lint → Activate<br/>→ activation-guard 3 gates"]
    CTA --> BUILD
    BUILD --> G2{{"👤 Manual runtime verify<br/>evidence required, max 3 iterations"}}
    G2 --> WT["📦 Walkthrough + risk report<br/>artifacts/walkthroughs/"]
```

---

## ⭐ Recommended MCP Servers

Several skills (`find-released-cds-view`, `fs-logic-behavior-translator`, `fs-integration-api-analyzer`, `sap-fiori-apps-reference`, `atc-cloudification`, and rule §9's "verify a tool exists / use `ToolSearch`" guidance) call out to "whichever MCP server/tool your environment exposes" for SAP CDS/documentation search — they work without one, but are far faster and more accurate with these two connected:

| MCP Server | What it gives the Agent |
|---|---|
| **[cds-kb-mcp](https://github.com/dovoanhtruong/cds-kb-mcp)** | Semantic search across 7,355 released S/4HANA Cloud CDS views (`search_cds`, `get_cds_view`, `get_views_by_tag`, `get_taxonomy`) — powers `find-released-cds-view` and the Clean-Core-replacement checks in the FS-analysis skills, instead of the Agent guessing a CDS view name. |
| **[mcp-sap-docs](https://github.com/dovoanhtruong/mcp-sap-docs)** | Hybrid search over SAP Help Portal, SAP Accelerator Hub (OData/REST/SOAP APIs), the Fiori Apps Library, and Clean Core released-object data — backs the "search official SAP documentation before proposing an API/CDS replacement" steps required across the Consultant skills and workflows. |

Add both to your Claude Code MCP config (`claude mcp add` or your `.mcp.json`) — see each repo's README for the exact server command. Once connected, when a skill needs one, Claude Code will surface it as a tool to load via `ToolSearch` on first use.

---

## 📂 Workspace Directory Structure

```text
abap-agent-claudecode-workspace/
├── CLAUDE.md                       # 🧠 Hub file — always loaded; @imports the rule file below
├── .claude/
│   ├── rules/
│   │   └── sap-dev-rule.md         # 🛡️ 14 strict rules (Clean Core, Custom Only, TR, evidence, subagents, language, self-modification)
│   ├── skills/                     # 📚 53 skills, FLAT — auto-discovered & matched by description (catalog below)
│   │   └── <name>/SKILL.md          #    + references/ subfolders for heavy templates (loaded only when needed)
│   ├── agents/                     # 🤖 6 subagents — Team Consultant/Dev/Tester × Lead (opus)/Executor (sonnet)
│   │   └── <team>-<layer>.md        #    dispatched by workflows via [Agent: y]; Manager keeps sole SAP CUD authority
│   ├── hooks/                      # 🔒 Hard-enforced guardrails (PreToolUse) — code, not prompt text
│   │   ├── pre-cud-guard.sh         # Blocks non-Z/Y CUD, missing TR/Package, and any TR create/delete/modify
│   │   └── workspace-write-guard.sh # Locks .claude/ (open via user-created .claude/.unlock); new files → artifacts/ only
│   ├── settings.json               # Hook wiring
│   └── commands/                   # ⚙️ 10 workflows as slash commands (see Quick Start)
├── artifacts/                      # 📦 Single root for all input/output artifacts (gitignored)
│   ├── fs_docs/                     # Input Functional Specification (FS) documents
│   ├── technical_specifications/    # Technical Specifications (TS_*.md)
│   ├── scratchpads/                 # Drafts, progress ledgers, handoff notes (+ review/ for code reviews)
│   ├── walkthroughs/                # Deployment guides, testing & task checklists
│   ├── metadata_extensions/         # Generated Metadata Extension (DDLX) source, pending manual ADT creation
│   └── system_analysis/             # System/package analysis & audit reports
├── .gitignore
└── README.md                       # 📖 This file
```

---

## 📚 Skill Catalog (53, by category)

**🔎 FS Analysis / Consultant (8)** — `fs-data-model-extractor` (data model from FS: extract / design new Z-tables / trace lineage) · `fs-fiori-ui-elements-mapper` (FS layouts → Fiori Elements annotations + toolbar buttons) · `fs-logic-behavior-translator` (business rules → CDS vs Virtual Element vs Behavior Pool; status machine, numbering) · `fs-integration-api-analyzer` (FS integration specs → API design + payload mapping) · `fs-vision-extractor` (transcribe mockups/flowcharts/screenshots embedded in FS) · `document-markdown-converter` (binary FS → Markdown via MarkItDown) · `find-released-cds-view` (map a business field to its released Clean-Core CDS view) · `cds-data-model-analysis` (keys/foreign keys/cardinality/join-tree design + fan-out risk analysis across I_* views and Z-tables — the design step before CDS authoring).

**🌐 SAP Process Domain Knowledge (18)** — `sap-process-<area>-<item>` family, one skill per scope-item/sub-process, giving `consultant-lead` real SAP Public Cloud functional-consulting grounding during FS analysis (not just CDS/text parsing). Each has a lean always-loaded `SKILL.md` (process flow, CDS grounding, config touchpoints, cross-LOB "Related Processes" links) plus an on-demand `references/deep-dive.md` (business logic depth: partner determination, pricing, planning strategy, MRP, document splitting, etc.) — read only when the FS needs that depth. Auto-invoked once per FS during `/sap-dev-fs-analytic(-transactional-app)` Phase 1's Process-Domain Skill Check, then reused by name (no re-discovery cost) in Phase 2.
- **O2C**: `sap-process-o2c-sell-from-stock` (BD9) · `sap-process-o2c-customer-returns` (BKP) · `sap-process-o2c-down-payment-billing` (7S7)
- **Supply Chain**: `sap-process-supplychain-atp` (2LN) · `sap-process-supplychain-warehouse-mgmt` (3BR/3BS) · `sap-process-supplychain-inventory-mgmt` (BMC)
- **Manufacturing (execution)**: `sap-process-manufacturing-discrete-execution` (BJ5) · `sap-process-manufacturing-process-execution` (BJ8) · `sap-process-manufacturing-repetitive-execution` (BJH)
- **Production (planning)**: `sap-process-production-discrete-planning` (BJ5) · `sap-process-production-process-planning` (BJ8) · `sap-process-production-repetitive-planning` (BJH)
- **Finance**: `sap-process-finance-general-ledger` (J58, day-to-day) · `sap-process-finance-financial-close` (J58, period-end) · `sap-process-finance-asset-accounting` (J62)
- **Project System**: `sap-process-projectsystem-customer-project` (J11) · `sap-process-projectsystem-internal-project` (1A8) · `sap-process-projectsystem-resource-mgmt` (1KC)

**🧱 ABAP Cloud Foundations (10)** — `abap` (abaplint + Clean ABAP review, merged) · `abap-cloud` (3-tier model, language restrictions, released-API discovery) · `abap-cloud-migration` (classic → cloud code adaptation, wrapper pattern) · `atc-cloudification` (ATC cloud-readiness check variants) · `modern-abap-syntax` (VALUE/COND/REDUCE enforcement) · `abap-sql-amdp` (advanced SQL, AMDP, CDS table functions) · `abap-unit-testing` (test classes, test doubles, CDS/OSQL/RAP BO test environments) · `oo-design-patterns` (when-is-which-GoF-pattern-warranted decision table) · `released-abap-classes` (released class lookup by use case) · `abap-generative-ai` (ABAP AI SDK / ISLM completion API).

**⚙️ RAP & Services (7)** — `rap` (BDEF, EML, handlers/savers, draft, save sequence) · `rap-query-provider` (IF_RAP_QUERY_PROVIDER for custom entities; the "Query not fully covered" fix) · `rap-business-events` (event definition, binding, Event Mesh) · `cds-view-entities` (RAP composition-tree modeling: root/child/projection views, admin fields, association vs composition) · `cds-analytical-views` (general/analytical CDS authoring: expressions, aggregates, input parameters, joins, table entities, UI/value-help annotations — no RAP involved) · `odata` (service definition/binding, consumption, troubleshooting) · `badi-enhancement` (new BAdI framework, released BAdIs in Cloud).

**🔐 Platform & Security (4)** — `authorization-iam` (AUTHORITY-CHECK, DCL, RAP auth handlers, IAM apps/catalogs/roles) · `btp-abap-environment` (provisioning, ADT connectivity, communication management) · `btp-diagram-generator` (BTP solution diagrams as draw.io files) · `sap-fiori-apps-reference` (Fiori Launchpad URL generation, offline AppList fallback).

**🧭 Governance & Productivity (6)** — `activation-guard` (3-gate post-activation verification: log, active state, ripple check) · `naming-convention` (FPT project naming standards; explicit TS names win) · `scratchpad` (plan + progress ledger, single source of truth) · `handoff` (session-transition notes with ledger pointer) · `grill-me` (targeted requirement interviews, ≤3 rounds) · `caveman` (terse chat narration, never on code/reports).

---

## 🛠️ Core Components & How They Work

### 1. Skill Auto-Discovery (`.claude/skills/`)
Claude Code scans `.claude/skills/<name>/SKILL.md` and matches each skill's `description` frontmatter against your request — no manual router. Skills keep their body lean and push heavy templates (BDEF/handler skeletons, syntax guides, walkthroughs) into `references/` files that load only when actually writing that object — the same progressive-disclosure pattern across all 53. The 18 `sap-process-*` skills take this one layer further: a lean `SKILL.md` (process grounding, always safe to auto-load) + an on-demand `references/deep-dive.md` (functional-consulting depth) that only the agent that judges it necessary reads — kept separate specifically so every FS analysis doesn't pay for depth it doesn't need.

### 2. Always-On Rules (`CLAUDE.md` → `.claude/rules/sap-dev-rule.md`)
`CLAUDE.md` `@imports` the rule file, so it's unconditionally in context every turn. The 14 sections cover: DEV-only assumption, consent + Z/Y-only + TR/Package discipline, CDS-read/EML-write standards, `artifacts/`-only outputs, activation-guard gates after every object mutation, Iron Laws (no improvising beyond the TS), Red Flags, evidence-based reporting ("Activated ≠ Correct"), MCP tool verification, token efficiency, evidence floor for user verification, subagent policy, language policy (chat VN · code EN), and self-modification rules (`.claude/` locked behind user-created `.unlock`).

### 3. Workflows as Slash Commands (`.claude/commands/`)
Each workflow is a phase-gated protocol: input validation gate (grill-me on gaps) → ledger-tracked build (activation-guard after every object) → evidence-based verify loop (max 3 iterations, then stop and ask) → walkthrough report. See Quick Start for all 10.

### 4. Hard-Enforced Guardrails (`.claude/hooks/`)
Prompt rules can be ignored; hooks can't. `pre-cud-guard.sh` fires on every call to any connected SAP MCP server matching `mcp__sap_<project>_dev__*` and blocks: non-Z/Y object CUD, object CUD without TR+Package, and any agent-driven create/delete/modify of a Transport Request itself. It's heuristic (regex over the tool payload) — tighten the field lookups once you've inspected one real call. `workspace-write-guard.sh` fires on `Write|Edit|NotebookEdit|Bash` and blocks: any change inside `.claude/` unless the **user** has manually created the sentinel `.claude/.unlock` (the agent is permanently blocked from creating that sentinel itself), and creation of new files outside `artifacts/` (editing existing files stays allowed). Hooks enforce "did this happen" — the rule file still governs "was it done well".

### 5. Subagent Team (`.claude/agents/`)
Workflows dispatch isolated subagents via `[Agent: y]` instead of doing every analytical step in the main session: **Team Consultant** (business/FS analysis — `consultant-lead` for judgment-heavy translation, `consultant-executor` for mechanical pre-processing), **Team Dev**, **Team Tester** — each split **Lead** (opus, judgment) / **Executor** (sonnet, template-driven). The Manager (this session) is the only one holding SAP CUD authority; every subagent only drafts/analyzes and writes to `artifacts/scratchpads/`, never calling an SAP object-mutation tool, and never marking a ledger row DONE — the Manager reads their output file from disk before trusting it. `consultant-lead` additionally runs the Process-Domain Skill Check described above during FS-analytic Phase 1.

---

## 🚀 Quick Start

### First-time setup

1. Clone, then open the folder in Claude Code.
2. (Recommended) Connect the two MCP servers above, plus your SAP system's ADT MCP server (named `mcp__sap_<project>_dev__*` so the CUD guard covers it).
3. One-time venv for binary FS conversion: `python3 -m venv .venv_markitdown && ./.venv_markitdown/bin/pip install 'markitdown[all]'`.
4. Know the lock: if you ask Claude to modify `.claude/` (rules/skills/hooks), first run `touch .claude/.unlock`, and delete it when done.

### The 10 workflows

**Pipeline A — report/screen over existing released CDS data:**

```bash
# FS → Technical Specification
/sap-dev-fs-analytic artifacts/fs_docs/SAPER_2025_PM_FS.docx Z_INVENTORY_REPORT
# Review artifacts/technical_specifications/TS_*.md, then TS → activated RAP objects
/sap-dev-create-report ZREPORT_PM DEVK900123 artifacts/technical_specifications/TS_InventoryReport.md
```

**Pipeline B — brand-new transactional app (no existing Z-table/CDS):**

```bash
# FS → Technical Specification incl. DDIC Foundation design (tables/domains/number range/status machine)
/sap-dev-fs-analytic-transactional-app artifacts/fs_docs/SAPER_2025_ZBOM_FS.docx ZPRODX_ZBOM
# TS → DDIC Foundation + full RAP composition tree + OData binding
/sap-dev-create-transactional-app ZPRODX_ZBOM DEVK900124 artifacts/technical_specifications/TS_ZBom.md
```

**Maintenance & integration:**

```bash
# Root-cause + regression-safe fix (halts for your approval before touching code)
/sap-dev-bug-fix ZC_INVENTORY_REPORT "SO Type ZOR2: expected qty 10, got 0"

# Inbound API on Z_API_FWK (external system calls SAP)
/sap-dev-api-inbound CREATE_SALES_ORDER

# Outbound API via Z_API_FWK=>execute_api (SAP calls external system)
/sap-dev-api-outbound NOTIFY_WMS

# Deep-dive documentation of an existing object/package
/sap-dev-code-analysis ZPRODX_ZBOM "data flow + call graph"

# Strict advisory QA review (no auto-refactor)
/sap-dev-code-review ZCL_BOM_PROCESSOR "performance, security"
```

**Single-prompt micro tasks (~70% of real interactions):**

```bash
# One small task — auto-classified (small mutation / lookup / how-to / snippet review),
# routed through the §15 skill map, minimal governance (TR check + activation-guard on mutations)
/sap-task "thêm field ProfitCenter vào ZI_INVENTORY và expose ra projection"
```

Bare prompts (no slash command) get the same routing via rule §15 — every SAP-domain answer must open with a `Skills: [...]` declaration line naming what was consulted.

Every build workflow asks for anything missing (Package, TR, TS gaps) before touching the system, and refuses to mark work done without activation evidence.

---

## ⚙️ Notes for Developers

* **Relative paths** everywhere — the workspace moves between machines without breaking.
* **Adding a skill:** `touch .claude/.unlock`, drop `.claude/skills/<name>/SKILL.md` with `name` (= folder name) + `description` frontmatter, keep the body lean with heavy content in `references/`, then re-run the integrity check (frontmatter name = dir name; every `[Skill: x]` reference resolves) and delete `.unlock`. Claude Code picks it up automatically.
* **Audit trail:** the full skill/workflow/rule audit and upgrade history lives in `artifacts/system_analysis/skill_audit_*.md`.
* **Relationship to `abap_antigravity_workspace`:** ported from it, maintained separately — fixes do not auto-propagate between the two.
