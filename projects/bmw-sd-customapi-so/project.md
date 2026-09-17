# Project: bmw-sd-customapi-so

| Field | Value |
|---|---|
| Customer / Engagement | BMW |
| Description | Custom API for Sales Order (SD) — chi tiết bổ sung khi nhận task |
| SAP system (MCP tool) | mcp__abap_bmw_dev__SAP (DEV client 080) · mcp__abap_bmw_cus__SAP (customizing tenant) |
| Default Package | Z_CUSTOMAPI_CREATE_SO |
| Current TR | H9SK900004 |
| Status | active |
| Created | 2026-08-20 |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| ZCL_API_IB_CREATE_SO_DEMAND | CLAS | Active (dev), unit-tested 7/7 (2026-08-22) | Inbound handler CREATE_SO_DEMAND: parse → validate → 2× execute_api keep_session (INTERNAL_GET_CSRF → INTERNAL_SALE_ORDER); workaround call_so_api_same_session đã xóa — chi tiết: scratchpads/issue-zapifwk-csrf-session-enhancement.md |
| ZCL_SO_DEMAND_VALIDATOR | CLAS | Active (dev), unit-tested 11/11 | Business rules: 1 open demand (≠Closed 04100), unit match, qty ≤ remaining |
| ZIF_SO_DEMAND_DATA | INTF | Active (dev) | Data-access contract (DI cho unit test) |
| ZCL_SO_DEMAND_DATA | CLAS | Active (dev) | CDS SELECTs: I_EnterpriseProjectElement / I_ProjectDemand(Material) / I_SalesOrderItem |
| ZCL_SO_DEMAND_VALIDATOR_TEST | CLAS | Active (dev), all PASS | Global test class (CDS-double bị cấm trên tenant → mock DI) |
| ZCL_API_IB_CREATE_SO_DMND_TEST | CLAS | Active (dev), all PASS | Parse variants + 400-details flow |
| ZMC_SO_DEMAND | MSAG | ⚠️ USER TẠO TAY | Tool không tạo được MSAG — danh sách message trong plan §5 / báo cáo 2026-08-20 |

## Key documents
<!-- Links to the project's own TS/walkthrough/analysis files as they appear. -->
- `scratchpads/plan-create-so-demand-inbound-api.md` — agreed plan (2026-08-20): custom inbound API CREATE_SO_DEMAND, validate SO items vs Project Demand, pass-through to API_SALES_ORDER_SRV. Build on abap_bmw_dev, test on abap_bmw_cus.
- `scratchpads/postman-custom-so-testcases.md` — 9 Postman test cases TC1–TC9 (collection Custom API / folder Custom Create SO with Demand Validation, workspace BMW) targeting CPI iflow KYTA/SaleorderWithDemandValidation.
- `scratchpads/postman-standard-demand-request.md` — Postman request tạo Project Demand qua API chuẩn API_PROJECTDEMAND_0001 (OData V2, SAP_COM_0783) — dùng tạo demand thứ 2 cho case multi-demand. Test data gốc: WBS D.26.001-01.02 / RAW_MATERIAL / 10 KG / plant V001.
