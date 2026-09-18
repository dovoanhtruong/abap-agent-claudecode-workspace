# Troubleshooting

Diagnose by layer first. The console log (F12) prints a line per phase; the **first missing line** names the failing layer.

| Last line seen | Failing layer |
|---|---|
| nothing at all | button not wired to `PrintExcelHandler.onPrintExcelPress`, or the library is not in `manifest.json` `libs` |
| `🚀 Khởi động...` then `Thiếu file cấu hình` | `ExcelConfig.js` missing/misplaced (`webapp/ext/controller/`) or has a syntax error |
| `⏱ Thời gian ABAP Backend xử lý` never ends | the OData action failed — check `actionPath`, `use action` in the projection BDEF, authorizations |
| `📥 [1/4] tải Template` throws | `excel_id` not registered, or HTTP 404 from `zib_ex_lib_template_content` |
| `⚙️ [2/4] nạp Workbook` throws | the stored file is not a valid `.xlsx` |
| everything logs, file downloads, content wrong | a tag/payload mismatch — the table below |

## Symptom → cause

| Symptom | Cause | Fix |
|---|---|---|
| `${something}` printed literally in the output | tag name contains an illegal character (`.`, `-`, space, diacritic) so no regex matched | tag names are `[a-zA-Z0-9_]+`; flatten nested paths in ABAP |
| Cell is empty where a value was expected | the field is absent from the payload, or was never filled | fill it; a genuinely empty value rendering empty is correct behaviour |
| Cell shows `0` where blank was expected | `abap_to_json` (XCO) emits every component — an initial numeric field becomes `0` | type the field as `string`, or accept the zero and format it (`#,##0;;""`) |
| Whole sheet renders empty although the action returned JSON | `[unverified]` XCO may not dereference `ty_sheet-data` (`REF TO data`) — check whether the `data` node in `json_content` is populated | if it is empty, serialize that call with `/ui2/cl_json=>serialize( ... compress = abap_true pretty_name = camel_case )` instead |
| Cell shows a number where an ID was expected, leading zeros gone | whole-cell scalar tag + numeric-looking value → `Number()` coercion | keep static text in the cell (`SO ${soId}`), or send a non-numeric value, or accept it and set a number format |
| Cell shows text where a number was expected, right-align/format lost | ABAP sent a formatted string, or the tag was embedded in other text | send a numeric ABAP type and make the tag the entire cell content |
| Date shows as a serial number or as raw `20260918` | dates are not converted by the engine | format in ABAP: `\|{ lv_date DATE = USER }\|` |
| Table does not repeat, only one row | `${table:...}` array name ≠ the payload's array field name, or the array is not a JSON array | align the ABAP component name with the tag's array name |
| Two tables in one sheet, one of them filled from the wrong data | the engine keeps a single array name per sheet — the last one scanned wins | split into two sheets, or one array with `row_type` |
| Some items silently missing from the output | their `row_type` matches no `${rowType:}` variant and there is no DEFAULT row | add a DEFAULT template row or fix the `row_type` values |
| Subtotal/group rows render with detail-row styling | the item's `row_type` is initial; `""` is falsy in `item.row_type \|\| item.rowType \|\| "DEFAULT"` → falls back to DEFAULT | set `row_type` explicitly on every item that needs a variant |
| `|merge` produced no merges | equal values are not adjacent | sort the array in ABAP; the engine never sorts |
| Borders missing on merged cells after expansion | only the merge master was styled in the template | style every cell of the range (`style_span()` in `build_template.py`) |
| A blank row disappeared from the middle of the table | it sat inside the template block and was deleted with it | move spacers outside the block |
| Logo/QR is tiny, one cell wide | the tag cell was not merged | merge the box, put the tag in its top-left cell |
| Logo missing entirely | `zcl_image_lib=>get_latest_image_base64` returned `''` — wrong `image_id`, no row in `ZI_IMG_I`, or an exception it swallowed | check the image id and that a version exists |
| QR/barcode missing, no error on screen | bwip-js threw; the engine logs to console and continues | read the `❌ [Barcode Generation Error]` line — usually an empty or over-long value |
| Rows below the table did not move down | they were inside the template block, or the array was empty | inspect the block boundaries with `verify_template.py` |
| Conditional formatting stops partway down the table | the rule's range did not overlap the template block, so it was not expanded | define the rule over the template rows themselves |
| Export dies on a large selection | the whole render is client-side; RAM is the limit (the log prints input JSON size and heap usage) | reduce the selection, or split into more sheets |
| HTTP 400 `Thiếu tham số excel_id` | `excel_id` came back empty from the action | the action must always set `%param-excel_id` |
| Nothing happens, no file, no error | `%cid` not returned by the action, so RAP could not correlate the response | `%cid = ls_key-%cid` |
| Right template, stale layout | a newer version was uploaded to a different `excel_id`, or the browser cached the fetch | check `MAX( version )` in `ZTB_EX_LIB_I` for that id; hard-reload |
| Works in DEV, empty template in QA/PROD | templates are client-dependent table data, not transported | upload the `.xlsx` in the target system |

## Reading the template store directly

```abap
SELECT excel_id, version, file_name, file_size, created_by, created_at
  FROM zi_tb_ex_lib_i
  WHERE excelid = @lv_id
  ORDER BY version DESCENDING
  INTO TABLE @DATA(lt_versions).
```

The endpoint serves `MAX( version )` — if that is not the file you expect, the upload landed under a different `excel_id`.
