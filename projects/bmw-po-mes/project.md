# Project: bmw-po-mes

| Field | Value |
|---|---|
| Customer / Engagement | BMW |
| Description | ProductionOrder Release → MES integration: detect "not released → released" transition on I_ProductionOrderTP~Changed event, trigger outbound integration. Status: PLAN (no build yet — TS pending) |
| SAP system (MCP tool) | mcp__abap_bmw_dev__SAP (event handler verified on client 100 — log ZTB_PO_EVENT_LOG) |
| Default Package | TBD |
| Current TR | TBD |
| Status | active — planning phase |
| Created | 2026-07-17 (migrated from artifacts/) |

## Objects & Status
| Object | Type | Status | Notes |
|---|---|---|---|
| ZTB_PO_EVENT_LOG | Table | active | event-handler verification log (evidence in system_analysis report §5) |

## Key documents
- Plan (open decisions pending): `scratchpads/plan_po_release_transition_integration.md`
- Foundation analysis: `system_analysis/analysis_report_ProductionOrder_Release_MES_Integration.md`
- Event-handler verification: `walkthroughs/verify_po_event_handler_walkthrough.md`
