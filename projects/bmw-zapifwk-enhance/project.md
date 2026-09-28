# Project: bmw-zapifwk-enhance

| Field | Value |
|---|---|
| Customer / Engagement | BMW — Z_API_FWK framework enhancements |
| Description | Nâng cấp framework Z_API_FWK — bổ sung log UUID trả ra cho consumer (outbound) để navigate tới app log |
| SAP system (MCP tool) | mcp__abap_bmw_dev__SAP — DEV client 080 |
| Default Package | Z_API_FWK |
| Current TR | H9SK900004 |
| Status | active |
| Created | 2026-09-22 |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| ZIF_API_FWK_TYPES | INTF | ACTIVE (3 gates passed) | thêm `log_uuid TYPE sysuuid_c32` vào `ty_logger` |
| ZCL_API_FWK | CLAS | ACTIVE (3 gates passed) | `save_log` trả `ev_log_uuid`; `execute_api` gán `es_logger-log_uuid` ở cả 2 call-site |
| ZCX_API_FWK | CLAS | ACTIVE (3 gates passed) | thêm attribute `log_uuid` + param constructor (nhánh `execute_error`) |

## Key documents
<!-- Links to the project's own TS/walkthrough/analysis files as they appear. -->
