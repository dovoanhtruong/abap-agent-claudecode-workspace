# Project: bmw-zppf01

| Field | Value |
|---|---|
| Customer / Engagement | BMW |
| Description | ZPPF01 – Xuất tiêu hao ngoài định mức (GI mvt 261 cho production order từ manual reservation Type = OUT) |
| SAP system (MCP tool) | mcp__abap_bmw_dev__SAP (DEV client 080, build) · mcp__abap_bmw_cus__SAP (customizing tenant, business data) |
| Default Package | ZPPF01 |
| Current TR | H9SK900159 |
| Status | active |
| Created | 2026-09-25 |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| ZCE_PPF01_RESVOUTVH | DDLS (custom entity, VH) | ACTIVE | TS §9 #1 |
| ZCE_PPF01_RESVITEM | DDLS (root custom entity) + BDEF (unmanaged) | ACTIVE | TS §9 #2, #8 |
| ZCL_PPF01_RESV_READER | CLAS | ACTIVE | TS §9 #3 (+ ZCX_PPF01_QUERY #3a ACTIVE) |
| ZCL_PPF01_RESVOUTVH_QP / ZCL_PPF01_RESVITEM_QP | CLAS (query providers) | ACTIVE | TS §9 #4, #5 |
| ZST_PPF01_POST_PARAM | DDLS (abstract) + BDEF (abstract) | ACTIVE | TS §9 #6, #7 |
| ZMC_PPF01 | MSAG | PLANNED | manual in ADT — TS §9 #9 |
| ZBP_PPF01_RESVITEM | CLAS (behavior pool) | ACTIVE | TS §9 #10 |
| ZUI_PPF01_EXCESSGI / ZUI_PPF01_EXCESSGI_O4 | SRVD / SRVB V4 | SRVD ACTIVE · SRVB pending | SRVB manual in ADT — TS §9 #11, #12 |
| ZI_PPF01_TMPCHECK / ZCL_PPF01_TMPCHECK | DDLS / CLAS (smoke test) | DELETED | absent from DEV search / inactive list 2026-09-25 |

## Key documents
<!-- Links to the project's own TS/walkthrough/analysis files as they appear. -->
- TS: [technical_specifications/TS_ExcessConsumptionIssue.md](technical_specifications/TS_ExcessConsumptionIssue.md) — Verify Loop PASS (attempt 2), 2026-09-25
- Ledger: [scratchpads/scratchpad_ExcessConsumptionIssue.md](scratchpads/scratchpad_ExcessConsumptionIssue.md) — decisions D1-D15, verifications V1-V14
