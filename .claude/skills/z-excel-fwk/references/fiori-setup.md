# Fiori Wiring — instructions for the Fiori developer

Three edits in the consuming Fiori Elements app. This skill documents them; the coding happens in the UI5 project, outside this ABAP workspace.

## 1. Declare the library dependency

`webapp/manifest.json` → `sap.ui5.dependencies.libs`:

```json
"libs": {
  "z.custom.excel.lib": {}
}
```

## 2. Add the toolbar button

`webapp/manifest.json` → the List Report table's `controlConfiguration` → `actions`:

```json
"onPrintExcelPress": {
  "press": "z.custom.excel.lib.PrintExcelHandler.onPrintExcelPress",
  "requiresSelection": true,
  "text": "Print Excel"
}
```

`requiresSelection: true` is a UX choice, not a technical one — the handler falls back to the table's currently loaded contexts when nothing is selected, and the ABAP action receives an empty `selected_keys`. Decide deliberately which behaviour the report should have, because "nothing selected" usually means an unbounded read in the backend.

## 3. Create `ExcelConfig.js`

The handler derives the path from the app's component namespace: `<namespace>/ext/controller/ExcelConfig`. The file must be at `webapp/ext/controller/ExcelConfig.js` — a different folder means "Thiếu file cấu hình ExcelConfig cho App này".

```js
sap.ui.define([], function () {
    "use strict";
    return {
        // MANDATORY — OData V4 path to the static action
        actionPath: "/{EntitySet}/com.sap.gateway.srvd.{ServiceDefinition}.v0001.{ActionName}(...)",

        appId: "MY_APP_01",     // passed through as app_id
        excelId: "",            // legacy fallback; the backend's excel_id wins
        idProperty: "",         // "" = read the key(s) from the OData metadata
        customParam: ""         // passed through as custom_param
    };
});
```

| Field | Notes |
|---|---|
| `actionPath` | The only mandatory one. Service-definition name and `v0001` come from the service binding; `{ActionName}` is the action as declared in the BDEF, case-sensitive. |
| `idProperty` | Leave empty and the handler reads `$Key` from the OData metadata — works for single and composite keys. Set a string or array only to override (e.g. to send a non-key field). |
| `appId` / `customParam` | Free-form pass-through to `ZABS_EX_LIB_ACTION_INPUT`. Use `customParam` for a filter the backend needs and the selection cannot express. |
| `excelId` | Fallback only; the backend's returned `excel_id` takes priority. Prefer deciding the template in ABAP so one app can print several layouts. |

## What the handler sends

Key values are collected per selected row into `[{"<KeyProp>":"<value>"}, ...]` and JSON-stringified into `selected_keys`. Property names are the **OData property names of the projection**, so the ABAP structure passed to `parse_json_keys` must use matching component names.

## Verifying an export

Open the app, select rows, press the button, and watch the browser console (F12) — the library logs every phase:

```
🚀 [Excel Core] Khởi động xuất Excel cho App: <namespace>
🔍 [Excel Core] Đang nạp động file cấu hình: <path>/ExcelConfig.js
⏱ [Excel Core] Thời gian ABAP Backend xử lý: 1092.35 ms
📊 [Metrics] Input JSON Size: ~0.20 MB
📥 [1/4] Thời gian tải Template từ Backend: 191.64 ms
⚙ [2/4] Thời gian nạp Workbook ExcelJS: 54.60 ms
📄 [3/4] Bắt đầu xử lý 1 Sheet(s)...
📦 [4/4] Thời gian đóng gói nhị phân & Tải file: 29.38 ms
✔ [Excel Library] THÀNH CÔNG RỰC RỠ! Đã xuất file: ...
```

Which line is missing tells you which layer failed — see `troubleshooting.md`. The whole render is client-side, so a slow export is the browser's CPU/RAM, not the backend; the backend time is printed separately.
