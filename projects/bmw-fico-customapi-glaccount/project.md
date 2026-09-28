# Project: bmw-fico-customapi-glaccount

| Field | Value |
|---|---|
| Customer / Engagement | BMW |
| Description | Custom API for GL Account (FICO) — chi tiết bổ sung khi nhận task |
| SAP system (MCP tool) | mcp__abap_bmw_dev__SAP (DEV client 080) · mcp__abap_bmw_cus__SAP (customizing tenant) |
| Default Package | ZGLACCOUNT |
| Current TR | H9SK900151 |
| Status | active |
| Created | 2026-09-22 |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| ZCL_API_IB_GET_GLACCOUNT | CLAS | ACTIVE (2026-09-24) | Inbound handler, api_id `GL_ACCOUNT_READ` (renamed by user from ZCL_IB_GL_ACCOUNT). 23 ABAP Unit tests pass. Standing restriction GLAccountType = P (2026-09-24). TR H9SK900151 |
| ZMC_GLACCOUNT | MSAG | ACTIVE (2026-09-22, by user) | Messages 001-004 for OData V4 error bodies |
| GL_ACCOUNT_READ | API config row | ACTIVE (2026-09-22, by user) | api_group KYTA. Live calls logged 200 OK in ZAPI_FWK_LOG |
| ZAPI_IB_GET_GLACCOUNT | HTTP | INACTIVE | Separate HTTP service on TR H9SK900152 - not needed, Z_API_FWK routes via Z_API_INBOUND_HTTP + x-api-id. Decide delete or activate |

## Key documents

- [Book1.xlsx](Book1.xlsx) - API specification sheet (3.1 query params, 3.2 headers, 3.3 success nodes + 4 sample JSON cases, 3.4 failure matrix + 3 error samples, 4. business logic)
- [getbykey.txt](getbykey.txt) - live get-by-key response captured 2026-09-24
- [scratchpads/data_source_verification.md](scratchpads/data_source_verification.md) - AlternativeGLAccount source + data probe
- [scratchpads/scratchpad_inbound_GL_ACCOUNT_READ.md](scratchpads/scratchpad_inbound_GL_ACCOUNT_READ.md) - design, contract, build ledger
<!-- Links to the project's own TS/walkthrough/analysis files as they appear. -->
