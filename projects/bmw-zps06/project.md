# Project: bmw-zps06

| Field | Value |
|---|---|
| Customer / Engagement | BMW |
| Description | ZPS06 — Báo cáo theo dõi đặt hàng thành phẩm (WBS level 5 × dòng sản phẩm: KL kế hoạch vs đặt hàng TP / lệnh SX / nhập kho TP / xuất kho giao hàng) |
| SAP system (MCP tool) | mcp__abap_bmw_dev__SAP — DEV, tenant client 080 |
| Default Package | TBD |
| Current TR | TBD |
| Status | active |
| Created | 2026-09-16 |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| ZI_PS_WbsDemand | CDS view (existing core) | pre-existing | Base view: WBS L5 key + dòng SP + ĐVT + KL kế hoạch |
| ZPS06 | DEVC | planned | package mới theo sibling pattern — chờ TR |
| ZCE_ZPS06_FGORDERTRACKING | DDLS custom entity | planned | 14 fields, inline annotations |
| ZCL_ZPS06_FGORDERTRACKING | CLAS query provider | planned | Mode A/B, 4 cột logic [open] |
| ZUI_ZPS06_FGORDERTRACKING | SRVD + SRVB V4 | planned | SRVB tạo tay ADT (MCP quirk V2) |

## Key documents
<!-- Links to the project's own TS/walkthrough/analysis files as they appear. -->
- `fs_docs/fs-note-zps06.txt` — FS note (thay thế FS chính thức) + mockup bảng báo cáo
- `technical_specifications/TS_Zps06FgOrderTracking.md` — **TS skeleton (2026-09-16)** — build blocked đến khi P1–P4 (§9) đóng
- `scratchpads/scratchpad_Zps06FgOrderTracking.md` — ledger workflow fs-analytic (DONE) + handoff state
- `system_analysis/ZI_PS_WbsDemand_ddl.md`, `system_analysis/source_probes_zps06.md` — evidence hệ thống
