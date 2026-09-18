# Project: bmw-z-excel-fwk

| Field | Value |
|---|---|
| Customer / Engagement | BMW |
| Description | Analyze the custom Excel-export-from-template framework in BMW DEV and author a reusable Claude Code skill for it |
| SAP system (MCP tool) | mcp__sap_bmw_dev__SAP — DEV |
| Default Package | Z_EXCEL_LIBRARY (framework, read-only) — new reports get their own package |
| Current TR | TBD |
| Status | active |
| Created | 2026-09-18 |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| _(none — this project created no SAP object)_ | | | Framework package `Z_EXCEL_LIBRARY` inspected read-only on bmw-dev |

## Framework facts (verified 2026-09-18, bmw-dev)
| Item | Value |
|---|---|
| ABAP package | `Z_EXCEL_LIBRARY` |
| Action in/out | `ZABS_EX_LIB_ACTION_INPUT` (selected_keys, app_id, custom_param) / `ZABS_EX_LIB_ACTION_RETURN` (excel_id char12, filename, json_content) |
| Payload type | `ZIF_EX_LIB_TYPES=>tt_sheets` (sheet_name + data REF TO data) |
| Utils | `ZCL_EX_LIB_UTILS=>parse_json_keys` (xco_cp_json, swallows malformed JSON) |
| Image helper | `ZCL_IMAGE_LIB=>get_latest_image_base64( iv_image_id )` over `ZI_IMG_I` |
| Template store | `ZTB_EX_LIB_H` / `ZTB_EX_LIB_I` (excel_id char12 + version), served by `ZIB_EX_LIB_TEMPLATE_CONTENT` |
| Reference app | `YT1_BP_R_ORDER` → `printExcel`, template `SALE_ORDER` |
| Rendering engine | UI5 lib `z.custom.excel.lib` — source at `~/IDE WorkSpaces/SAP_FIS_DEMO/ui5_excel_library/src/z/custom/excel/lib/` |

## Key documents
- **Deliverable:** skill `z-excel-fwk` installed at `.claude/skills/z-excel-fwk/` (SKILL.md + 4 references + assets)
- Draft copy kept at `scratchpads/skill-draft/z-excel-fwk/` (identical to the installed skill; delete once no longer needed)
- Inputs provided by the user: `scratchpads/ExcelLibrary_Guide.html`, `ExcelConfig.js`, `action_logic_sample.txt`, 3 sample `.xlsx` templates
- Note: the HTML guide's `${:rowType:{value}}` syntax is wrong — the engine parses `${rowType:L1}` / `${row_type:L1}`
