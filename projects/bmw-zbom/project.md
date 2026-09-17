# Project: bmw-zbom

| Field | Value |
|---|---|
| Customer / Engagement | BMW |
| Description | ZBOM transactional app (BOM header + FG/RM items, batch creation, import/download template) — package ZPRODX_ZBOM, Fiori app ZPPF00 |
| SAP system (MCP tool) | mcp__abap_bmw_dev__SAP — DEV client 080 (user tests on customizing tenant) |
| Default Package | ZPRODX_ZBOM |
| Current TR | H9SK900004 |
| Status | active |
| Created | 2026-07-17 (migrated from artifacts/) |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| (see system_analysis/KTD_ZPRODX_ZBOM.md) | — | — | KTD v7 is the authoritative object inventory for this package |
| ZCL_ZBOM_PO_CREATOR | CLAS | ACTIVE (2026-09-14) | `ty_component` +`rm_no`; component CREATE set `matlcompfreedefinedattribute = RmNo` (RESB-SORTF) -> link RM line <-> PO component. TR H9SK900004. **Runtime VERIFIED 2026-09-14** tren order O55PITT.007 (BOM 2000000037): 10/10 component co SORTF = RmNo |
| ZBP_ZBOM_H | CLAS (CCIMP) | ACTIVE (2026-09-14) | `createProductionOrder` truyen `rm_no` vao `it_components`. TR H9SK900004 |
| ZCL_ZBOM_CMP_ENGINE | CLAS | ACTIVE (2026-09-16) | Compare diff engine + 8 ABAP Unit PASS. Package ZPRODX_ZBOM_COMPARE, TR H9SK900004. TS: TS_ZPRODX_ZBOM_COMPARE_v1 |
| ZCL_ZBOM_CMP_QUERY | CLAS | ACTIVE (2026-09-16) | IF_RAP_QUERY_PROVIDER cho 4 custom entity compare. ZPRODX_ZBOM_COMPARE / H9SK900004 |
| ZCE_ZBOM_CMP_H / _HDR / _FG / _RM | DDLS ×4 | ACTIVE (2026-09-16) | Custom entities man hinh compare (root + 3 section), UI annotation inline. ZPRODX_ZBOM_COMPARE / H9SK900004 |
| ZUI_ZBOM_CMP | SRVD | ACTIVE (2026-09-16) | 8 expose: BomVersion (list chinh) + 4 compare entity + 3 VH. SRVB ZUI_ZBOM_CMP_O4 user da tao — **can RE-PUBLISH sau khi SRVD them entity** |
| ZR/ZC_ZBOM_CMP_LIST + ZBP_ZBOM_CMP_LIST | DDLS×2/BDEF×2/CLAS | ACTIVE (2026-09-16) | List BO read-only tren ztb_zbom_h; action compareWithVersion (guard 001-004, D8 min/max, D9) + GetDefaultsForCompare (O1b VH loc theo BOM). ZPRODX_ZBOM_COMPARE / H9SK900004 |
| ZST_ZBOM_CMP_PARAM, ZC_ZBOM_CMP_VERS_VH | DDLS+BDEF, DDLS | ACTIVE (2026-09-16) | Param action (TargetVersion + BomNo an, additionalBinding #FILTER) + VH view |
| BDEF ZCE_ZBOM_CMP_H + ZBP_ZBOM_CMP_H | BDEF+CLAS | ACTIVE (2026-09-16) | Result-entity BO toi thieu (BDL yeu cau) — READ delegate engine, LOCK no-op |
| ZMC_ZBOM_CMP | MSAG | **CHUA CO — user tao tay ADT** | 4 message 001-004 theo TS §5; handler da tham chieu id nay |

## Key documents
- **Package knowledge map (mới nhất, 2026-09-09): `system_analysis/analysis_report_ZPRODX_ZBOM.md`** — object map, data model, control flow, invariants + drift 2026-07-18→2026-09-09
- KTD (lịch sử fix chi tiết tới 2026-07-17): `system_analysis/KTD_ZPRODX_ZBOM.md`
- TS set: `technical_specifications/TS_ZPRODX_ZBOM_*.md` (5 specs)
- Latest handoffs: `scratchpads/handoff_zbom_*_20260716.md`
