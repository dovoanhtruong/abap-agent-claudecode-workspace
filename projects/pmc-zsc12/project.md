# Project: pmc-zsc12

| Field | Value |
|---|---|
| Customer / Engagement | PMC |
| Description | ZSC12 — Biên bản thanh lý (FS: PMC_FS_SC_ZSC12_BienBanThanhLy_v0.1.docx) |
| SAP system (MCP tool) | mcp__abap_pmc_dev__SAP — PMC DEV (metadata/DDL only, client has no master data; data probes go to user on customizing tenant) |
| Default Package | ZSC12 |
| Current TR | B2KK903832 (B2KK903779 released 2026-09-16/17 — chứa toàn bộ build tới ATC-clean; lỗi release "CFDF YY1_QUYTNHBBTL assign to collection" → custom field đi theo software collection riêng) |
| Status | active |
| Created | 2026-08-27 |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| ZI_SC12_REVERSEDORIG | DDLS | Active | Anti-join helper (Reversed=No vế ii) |
| ZI_SC12_MATDOCITEM | DDLS (root) | Active | L1 — joins + Reversed predicate |
| ZST_SC12_PRINT_PARAMS | DDLS (abstract) | Active | Print action params |
| ZI_SC12_MATDOCITEM | BDEF | Active | unmanaged, action print |
| ZCL_SC12_PRINT_ASSEMBLER | CLAS | Active | Print data assembly (TS §5) |
| ZBP_SC12_MATDOCITEM | CLAS (BP) | Active | lhc handler + lsc saver |
| ZC_SC12_MATDOCITEM | DDLS (projection) | Active | consumption + VH + mandatory filters |
| ZC_SC12_MATDOCITEM | BDEF (projection) | Active | use action print |
| ZUI_SC12_MATDOCITEM | SRVD | Active | |
| ZUI_SC12_MATDOCITEM_O4 | SRVB (OData V4 UI) | Active — Published [unverified, user confirm ADT] | task B2KK903780 / TR B2KK903779 |
| ZI_SC12_MATDOCITEM | DCLS | PENDING manual ADT | source: scratchpads/dcl_ZI_SC12_MATDOCITEM.md |
| ZC_SC12_MATDOCITEM | DDLX (MDE) | PENDING manual ADT | source: metadata_extensions/ZMD_BienBanThanhLy.md |
| ZMC_SC12 | MSAG | PENDING manual ADT (optional) | BP hiện dùng new_message_with_text |

## Key documents
<!-- Links to the project's own TS/walkthrough/analysis files as they appear. -->
- FS input: `fs_docs/PMC_FS_SC_ZSC12_BienBanThanhLy_v0.1.docx` (→ `scratchpads/fs_markdown.md`)
- TS: `technical_specifications/TS_BienBanThanhLy.md` — **FINAL, Verify PASS 2026-08-27 (Q1–Q6+Q5b user-confirmed)**; ledger: `scratchpads/scratchpad_BienBanThanhLy.md`; probe reversal-doc còn treo cho build-time (TS §12 cuối)
- Đề xuất Package: `ZSC12` (pattern SC10); TR: TBD
