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
| ZR/ZC_ZBOM_CMP_LIST + ZBP_ZBOM_CMP_LIST | DDLS×2/BDEF×2/CLAS | ACTIVE (2026-09-25, D10) | **Option 1**: list 1 dong/BOM (join ZI_ZBOM_CMP_MAXV), BDEF unmanaged, action compareVersions (popup Version A+B, guard 001-005, D8 min/max) + GetDefaultsForCompare (BomNo + prefill 2 version moi nhat). ZPRODX_ZBOM_COMPARE / H9SK900004 |
| ZI_ZBOM_CMP_MAXV | DDLS | ACTIVE (2026-09-25) | Aggregate BomNo -> MaxVers + VersionCount |
| ZST_ZBOM_CMP_PARAM, ZC_ZBOM_CMP_VERS_VH | DDLS+BDEF, DDLS | ACTIVE (2026-09-25) | Param 2 field VersionA/VersionB (mandatory, VH additionalBinding #FILTER theo BomNo an) + VH view (da bo ValidFrom/To theo drift 17/09) |
| BDEF ZCE_ZBOM_CMP_H + ZBP_ZBOM_CMP_H | BDEF+CLAS | ACTIVE (2026-09-16) | Result-entity BO toi thieu (BDL yeu cau) — READ delegate engine, LOCK no-op |
| ZMC_ZBOM_CMP | MSAG | CREATED by user (thay trong DEVC 25/09) | Can xac nhan du 001-005 (005 moi them theo D10) |
| Compare REV v2 (D11-D14) | — | BUILT 2026-09-25 | Man detail refactor theo FS: 2 card per-version + 2 KPI FG/RM + diff Product+Batch/delta/5 category. ZCE_ZBOM_CMP_HDR DELETED. Engine test 3/3 PASS (tai hien vi du FS 2.1.2). Cho: user re-publish SRVB + evidence UI |

| ZTB_ZBOM_H / _H_D | TABL x2 | ACTIVE (2026-09-17) | Rename Component List: +`cl_descr` +`cl_type` +`project_id`(40) +`project_desc`(60). Cột cũ `bom_descr`/`bom_type`/`valid_from`/`valid_to` CÒN — drop ở Phase 7 (TR riêng). TR H9SK900004 |
| ZI/ZR/ZC_ZBOM_H | DDLS x3 | ACTIVE (2026-09-17) | `ClDescr`/`ClType` + `ProjectId`/`ProjectDesc`; bỏ `ValidFrom`/`ValidTo`. **`BomVers` GIỮ tên element** (D16) — chỉ đổi label |
| BDEF ZR_ZBOM_H + ZBP_ZBOM_H | BDEF+CLAS | ACTIVE (2026-09-17) | determination `deriveProjectFromWbs` (WBS → I_EnterpriseProject), side effect WbsElement→ProjectId/ProjectDesc; gỡ rule validity msg 002/062 |
| DDLX ZC_ZBOM_H | DDLX | ACTIVE (2026-09-17) | Label: CL Description / Component List / CL Version; xóa facet Validity; BomRef sang Assignments; +2 field Project |
| ZCL_IB_PRODORDER_GRRM | CLAS | ACTIVE (2026-09-17) | Payload đổi `bomDescr`/`bomType` → **`clDescr`/`clType`** — breaking change, user điều phối với đối tác |
| ZCL_ZBOM_MIG_CL_RENAME | CLAS | ACTIVE (2026-09-17) | **MỚI** classrun migration one-off: copy `bom_descr`→`cl_descr`, `bom_type`→`cl_type`. Idempotent. CHẠY sau khi import TR, TRƯỚC Phase 7 |
| ZCL_ZBOM_CMP_ENGINE | CLAS | ACTIVE (2026-09-17) | header diff 15 → 13 dòng (bỏ VALIDFROM/VALIDTO); 8/8 ABAP Unit PASS |

## Key documents
- **Package knowledge map (mới nhất, 2026-09-09): `system_analysis/analysis_report_ZPRODX_ZBOM.md`** — object map, data model, control flow, invariants + drift 2026-07-18→2026-09-09
- KTD (lịch sử fix chi tiết tới 2026-07-17): `system_analysis/KTD_ZPRODX_ZBOM.md`
- TS set: `technical_specifications/TS_ZPRODX_ZBOM_*.md` (5 specs)
- Latest handoffs: `scratchpads/handoff_zbom_*_20260716.md`
