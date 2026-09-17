# Project: bmw-zps07

| Field | Value |
|---|---|
| Customer / Engagement | BMW |
| Description | ZPS07 — Báo cáo lắp đặt theo tuần/tháng (WBS level 5, phân bổ khối lượng/doanh thu theo 12 kỳ + Còn lại qua zcl_period_calculator) |
| SAP system (MCP tool) | mcp__abap_bmw_dev__SAP — DEV client 080 (test data của user nằm trên tenant customizing, không query business data qua MCP) |
| Default Package | ZPS07 (tạo mới lúc build, tiền lệ ZPS05) |
| Current TR | H9SK900127 |
| Status | active |
| Created | 2026-09-15 |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| ZPS07 | DEVC | active | pre-existed |
| **CORE (ZREPORT_PS)** — refactor 2026-09-16 | | | dùng chung cho mọi report nhóm cột mốc |
| ZI_PS_WbsMilestonePair | DDLS | active | pivot generic, params p_Start/EnddateMilestoneCode |
| ZI_PS_WbsDemandMilestone | DDLS | active | base join + unit fallback I_Product.BaseUnit |
| ZI_PS_PeriodTypeVH | DDLS | active | dropdown W/M |
| ZCX_PS_QUERY_ERROR | CLAS | active | concrete cx_rap_query_provider |
| ZCL_PS_PERIOD_REPORT_ENGINE | CLAS | active | toàn bộ thuật toán Strategy A |
| **CONSUMER ZPS07** | | | |
| ZCE_ZPS07_Installation | DDLS (CE) | active | 38 cột, element names trung tính, labels lắp đặt |
| ZCL_ZPS07_INSTALLATION | CLAS | active | wrapper bind '170'/'171' → engine |
| ZUI_ZPS07_Installation | SRVD | active | exposes CE + 3 VH |
| ~~ZI_ZPS07_* / ZCX_ZPS07_*~~ | | DELETED | thay bằng core 2026-09-16 |
| ⚠️ ZCL_ZPS07_PERIODTYPEVH | CLAS | inactive, NGOÀI thiết kế | user tạo tay? — cần user xóa/xử lý (TR H9SK900128) |
| Messages 006–010 in ZMC_REPORT_PS | MSAG | active | user-maintained |
| ZUI_ZPS07_INSTALLATION_O4 | SRVB | PENDING manual | user creates in ADT (OData V4 UI) |
| IAM App + Business Catalog | IAM | PENDING manual | after SRVB |
| ⚠️ TR | — | check | objects may sit on H9SK900128 instead of H9SK900127 — verify in ADT |

## Key documents
- `technical_specifications/TS_Zps07Installation.md` — **TS hoàn chỉnh (Verify PASS)** — input duy nhất cho /sap-dev-create-report.
<!-- Links to the project's own TS/walkthrough/analysis files as they appear. -->
- `fs_docs/fs_zps07.txt` — FS gốc (text). `layout_zps07.xlsx` tạm còn ở project root (file đang mở trong Excel, chưa move được vào fs_docs/).
- `scratchpads/fs_markdown.md` — FS + layout đã convert (nguồn đọc chuẩn cho workflow).
- `scratchpads/scratchpad_Zps07Installation.md` — ledger /sap-dev-fs-analytic + Confirmed Decisions + System Evidence.
