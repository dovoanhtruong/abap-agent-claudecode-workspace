# Project: pmc-sp-zsp05

| Field | Value |
|---|---|
| Customer / Engagement | PMC |
| Description | ZSP05 — Báo cáo mua bao bì (FS: PMC_FS_SP_ZSP05_BaoCaoMuaBaoBi_v1.0.docx) — analytical report, Fiori Elements trên RAP/CDS |
| SAP system (MCP tool) | mcp__abap_pmc_dev__SAP — PMC DEV (metadata/DDL only, client has no master data; data probes go to user on customizing tenant) |
| Default Package | TBD (đề xuất `ZSP05` theo pattern ZSC10/ZSC12 — user confirm) |
| Current TR | TBD |
| Status | active |
| Created | 2026-09-08 |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|

## Key documents
<!-- Links to the project's own TS/walkthrough/analysis files as they appear. -->
- FS input: `fs_docs/PMC_FS_SP_ZSP05_BaoCaoMuaBaoBi_v1.0.docx` (→ `scratchpads/fs_markdown.md`, converted 2026-09-08 via node mammoth — markitdown/Python unavailable on this machine)
- TS: `technical_specifications/TS_BaoCaoMuaBaoBi.md` — **FINAL v1.2, Verify PASS 2026-09-09 (attempt 2); all OQs resolved 2026-09-09 (user accepted defaults)**; scope = Fiori grid (FS §2.2.3) + action `Print` dựng print data 3 cấp (FS §2.2.1/§2.2.4) tới `ZST_SP05_PRINT_DATA` cho **dòng được chọn** (user 2026-09-09); form/ADS = luồng riêng. Only Package + TR outstanding → ready for `/sap-dev-create-report`
- Ledger: `scratchpads/scratchpad_BaoCaoMuaBaoBi.md` (Verified Data Model §0–§11, Conflicts, Handoff); drafts: `scratchpads/draft_ui_*`, `draft_logic_*`, `draft_integration_*`
- Architecture: Custom Entity `ZCE_SP05_PurchPackaging` (6 key: Supplier, Material + echo PostingDateFrom/To, PlanYear, PlantList) + `ZCL_SP05_QUERY_PROVIDER` → shared `ZCL_SP05_REPORT_ASSEMBLER` (`build_rows` / `build_print_data`) over `ZI_SP05_MatDocItem` / `ZI_SP05_PlanItem` / `ZI_SP05_ReversedOrig`; BDEF unmanaged + `ZBP_SP05_PurchPackaging` (instance action `Print`); DDIC `ZST_/ZTT_SP05_PRINT_*`; SRVD `ZUI_SP05_PurchPackaging`, SRVB `ZUI_SP05_PurchPackaging_O4`
- Precedent reused: `projects/pmc-zsc12` (Reversed=No pattern, ZPO8 branch A, DCL P1, manual-ADT quirks)
