# Project: poc-abap2ui5-custom-controls

| Field | Value |
|---|---|
| Customer / Engagement | Internal POC / research |
| Description | Nghiên cứu addon abap2UI5-addons/custom-controls (11 custom UI5 control cho framework abap2UI5) |
| SAP system (MCP tool) | `my439349.s4hana.cloud.sap`, client 080 — S/4HANA Cloud Public Edition (`mcp__abap_bmw_dev__SAP`; guidance-only, no MCP mutations per user) |
| Default Package | `Y_A2U5` — **local package, non-transportable (user-confirmed 2026-08-18)** (sub: `Y_A2U5_00` libs, `_01` internal, `_02` released APIs; `_99` deleted) |
| Current TR | N/A — local package, no transport (user-confirmed 2026-08-18) |
| Status | active |
| Created | 2026-08-17 |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| `Y_A2U5` + `_00/_01/_02` | DEVC | Active (user-reported) | abapGit pull from fork `truongdva2/abap2UI5`; `_99` deleted from fork before pull |
| `YHS_A2U5` | HTTP service | Active, roundtrip works via FLP app | CSP issue RESOLVED 2026-08-18 by deployed frontend. Manifest dataSource uri = `/sap/bc/http/sap/YHS_A2U5` (a typo `/sap/bc/YHS_A2U5` caused a Web-Dispatcher 403 first — fixed) |
| Handler class | CLAS | Active (user-reported) | Exact name not reported by user |
| `Y_A2U5` (UI5 repo) | UI5 ABAP repository | Deployed + renders in FLP (screenshot 2026-08-18) | Frontend branch `cloud`, deployed via Fiori tools, package `Y_A2U5` local/no TR. LADI `Y_A2U5` (SAPUI5 App ID `z2ui5`, `z2ui5`/`display`) + IAM App/Catalog/Role chain done by user |

## Key documents
- [abap2UI5 custom-controls — repo overview](system_analysis/abap2ui5-custom-controls-overview.md)
- [Deploy frontend UI5 app (branch `cloud`) — walkthrough](walkthroughs/deploy-frontend-ui5-cloud-branch.md) — chosen fix for the CSP block; user executes in VS Code
