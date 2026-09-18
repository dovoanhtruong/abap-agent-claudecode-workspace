---
name: z-excel-fwk
description: Usage guide for the custom Excel export-from-template framework (ABAP package Z_EXCEL_LIBRARY + SAPUI5 library z.custom.excel.lib) — how to build the ABAP side (static RAP action PrintExcel returning ZABS_EX_LIB_ACTION_RETURN with a camelCase JSON sheets payload), how to AUTHOR the .xlsx template itself with the engine's tag grammar (${var}, ${image:x}, ${table:arr.field|merge}, ${rowType:L1}, ${x|qrcode}), and how to wire the Fiori app (manifest dependency, custom action, ext/controller/ExcelConfig.js). Use this skill INSTEAD of reading the framework source whenever a task touches Excel export on this framework — creating or debugging a PrintExcel action, designing or generating an Excel template with mapping tags, registering an excel_id template version, embedding a logo/QR code, or explaining why a tag did not resolve. Triggers include "Z_EXCEL_LIBRARY", "z.custom.excel.lib", "excel library", "excel template", "PrintExcel", "printExcel action", "ExcelConfig.js", "ExcelExportHelper", "excel_id", "mapping tag", "export excel from template"; Vietnamese triggers "xuất excel theo template", "in excel", "tạo template excel", "làm report excel", "tag không đổ dữ liệu", "nhúng logo/QR vào excel". For OData service definition/binding use odata; for RAP BO modeling use rap; for generic ABAP SQL use abap-sql-amdp.
---

# Z_EXCEL_LIBRARY — Excel Export from Template

Client-side templating engine. The browser downloads a registered `.xlsx` template, merges a JSON payload produced by an ABAP RAP action into it, and saves the result locally. **The SAP backend never writes an Excel file** — it only returns JSON + a template id.

Everything in this skill is verified against live source: ABAP package `Z_EXCEL_LIBRARY` on bmw-dev and the UI5 library source `ExcelExportHelper.js` / `PrintExcelHandler.js`. Where a statement is inference, it is marked `[unverified]`.

## 1. Runtime flow

```
User ticks rows → presses "Print Excel" (custom action on the table toolbar)
  → PrintExcelHandler.onPrintExcelPress
      1. resolves App Component → requires <namespace>/ext/controller/ExcelConfig.js
      2. collects key fields of selected rows → selected_keys = JSON array of key objects
      3. POST OData action at oAppConfig.actionPath
          ↓  ABAP: static action PrintExcel
             parameter ZABS_EX_LIB_ACTION_INPUT ( selected_keys, app_id, custom_param )
             result [1] ZABS_EX_LIB_ACTION_RETURN ( excel_id, filename, json_content )
      4. GET /sap/bc/http/sap/zib_ex_lib_template_content?excel_id=<excel_id>
         → latest version of the .xlsx from ZTB_EX_LIB_I
      5. ExcelExportHelper.generateExcel( excel_id, JSON.parse(json_content), filename )
         → clones template sheet 1 per element of the JSON array, resolves tags, saves file
```

Three components, three owners:

| Component | Object | Who touches it |
|---|---|---|
| Template store + upload app | `ZTB_EX_LIB_H` / `ZTB_EX_LIB_I`, Fiori app on `ZUI_EX_LIB_O4` | BA / key user uploads the `.xlsx`, versioned per `excel_id` |
| Template delivery endpoint | HTTP service `ZIB_EX_LIB_TEMPLATE_CONTENT` (class `ZCL_IB_EX_LIB_TEMPLATE_CONTENT`) | nobody — fixed framework code |
| Rendering engine | UI5 library `z.custom.excel.lib` (`ExcelExportHelper`, `PrintExcelHandler`) | nobody — fixed framework code |

**Never modify the three framework pieces.** A new report = one ABAP action + one template + one `ExcelConfig.js`.

## 2. The JSON contract (the one thing both sides must agree on)

`json_content` is the serialization of `zif_ex_lib_types=>tt_sheets`:

```abap
TYPES: BEGIN OF ty_sheet,
         sheet_name TYPE zde_ex_lib_sheetname,
         data       TYPE REF TO data,   " any structure, becomes the sheet's tag namespace
       END OF ty_sheet,
       tt_sheets TYPE STANDARD TABLE OF ty_sheet WITH DEFAULT KEY.
```

Serialized with the Z_API_FWK utility `zcl_api_fwk=>abap_to_json( ia_abap = lt_sheets iv_mapping_camel = abap_true )` (XCO JSON under the hood — see `[Skill: z-api-fwk]`), so the payload is:

```json
[ { "sheetName": "Order_SO0001",
    "data": { "soId": "SO0001", "logo": "data:image/png;base64,...",
              "items": [ { "matId": "M1", "quantity": 3 } ] } } ]
```

Rules that follow directly from the engine source:

- One array element = one output sheet. The template's **sheet 1** is the master for every sheet and is deleted at the end.
- `iv_mapping_camel = abap_true` applies XCO's `underscore_to_camel_case`, so `mat_id` → `matId`. **Tag names in the template are the camelCase names**, not the ABAP field names.
- XCO emits **every** component, including initial ones — `abap_to_json` has no `compress` equivalent. An initial `string` arrives as `""` and renders as an empty cell, but an initial numeric field arrives as `0` and **prints `0`, not blank**. Decide per field: either it is always filled, or the template must tolerate a zero.
- A tag whose field is absent from the payload resolves to empty and the tag is removed — that is intended behaviour, not an error.
- Tag names must match `[a-zA-Z0-9_]+`. No dots, no nesting: `${header.soId}` never resolves. Flatten everything into the sheet's `data` structure.
- `sheetName` ≤ 31 chars and must not contain `[ ] : * ? / \` — ExcelJS throws otherwise.

> Migrating from `/ui2/cl_json=>serialize( ... compress = abap_true pretty_name = camel_case )`: the JSON shape is identical, the two deltas are the initial-field behaviour above and `[unverified]` XCO's handling of the `data TYPE REF TO data` component of `ty_sheet` — `/ui2/cl_json` dereferences it, XCO's `from_abap` has not been confirmed to. Verify the first export end-to-end (a real file with real values) before relying on it, and keep `/ui2/cl_json=>serialize` as the fallback if the `data` node comes out empty.

## 3. What to read next

| Task | Read |
|---|---|
| Write / fix the ABAP `PrintExcel` action | `references/abap-action-cookbook.md` |
| Author or generate the `.xlsx` template | `references/template-builder.md` (how to build it with openpyxl) + `references/tag-reference.md` (the grammar) |
| Understand exactly how a tag behaves | `references/tag-reference.md` — authoritative, derived from `ExcelExportHelper.js` |
| Wire the Fiori app | `references/fiori-setup.md` — instructions for the Fiori developer, no coding done here |
| A tag did not render / file is wrong | `references/troubleshooting.md` |

Sample assets in `references/assets/`: three real templates (`sale_order_styled.xlsx`, `material_report_styled.xlsx`, `store_revenue_tmp.xlsx`), the reference ABAP action (`printexcel_sample.abap`), and two Python tools (`build_template.py`, `verify_template.py`).

## 4. Hard limits (check these before designing anything)

| Limit | Value | Source |
|---|---|---|
| `excel_id` length | **12 chars**, `abap.char(12)` | `ZTB_EX_LIB_I`, `ZABS_EX_LIB_ACTION_RETURN` |
| `filename` length | 255 | `ZABS_EX_LIB_ACTION_RETURN` |
| Item arrays per sheet | **exactly one** — `${table:a.x}` and `${table:b.y}` in the same sheet do NOT both work | `ExcelExportHelper.js`: single `tableArrayName` variable |
| Sheet name | ≤31 chars | Excel / ExcelJS |
| Image formats | PNG / JPEG as data-URI or bare base64; the engine always declares `extension:'png'` | `ExcelExportHelper.js` |
| Barcode types | `barcode` (Code128), `qrcode`, `datamatrix` | `ExcelExportHelper.js` |
| Nesting depth of tags | flat only — one scalar namespace + one item array | tag regexes |

Need two independent item tables in one report → split them into **two sheets** (two elements of the sheets array), each with its own array named identically in both templates, or fold them into one array distinguished by `rowType`.

## 5. Governance floor

- New ABAP objects (action, behavior implementation, helper class): TR + Package required (rule §2); run `[Skill: activation-guard]` after every object change (rule §5).
- The template `.xlsx` is **data, not a transportable object** — it lives in `ZTB_EX_LIB_I` per client and is uploaded through the Fiori app. Moving a report to another system means re-uploading the template there. Say this explicitly when handing over.
- Business data stays read-only: the action only SELECTs. It is a `static action` with no `%key`, so it must never modify the BO.
