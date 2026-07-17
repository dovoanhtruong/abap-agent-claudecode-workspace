# Project: bmw-zsc01

| Field | Value |
|---|---|
| Customer / Engagement | BMW |
| Description | ZSC01 stock report (FS BMW_FS_SC_ZSC01) — variant/characteristic config via ZTB_VARIANT_I, batch VE bugfixes, Project/ProjectName fields |
| SAP system (MCP tool) | mcp__abap_bmw_dev__SAP — DEV client 080 |
| Default Package | TBD |
| Current TR | H9SK900004 |
| Status | active |
| Created | 2026-07-17 (migrated from artifacts/) |

## Objects & Status
| Object | Type | Status | Notes |
|---|---|---|---|
| ZCL_ZSC01_BATCH_VE | Class | active | bugfixed — see walkthroughs/walkthrough_bugfix_ZCL_ZSC01_BATCH_VE.md |
| zcl_variant_seeder | Class (adt classrun) | draft | variant seeder for Z_* characteristics (source in scratchpads/) |

## Key documents
- Analysis: `system_analysis/analysis_report_ZSC01.md`
- Field-add ledger: `scratchpads/scratchpad_ZSC01_add_project_fields.md`
