# Project: pmc_zsc10

| Field | Value |
|---|---|
| Customer / Engagement | PMC |
| Description | Báo cáo quy đổi ĐVT tồn kho thành phẩm (ZSC10) — analytical report, Fiori Elements trên RAP/CDS |
| SAP system (MCP tool) | mcp__abap_pmc_dev__SAP (PMC_dev) |
| Default Package | ZSC10 |
| Current TR | B2KK903836 (B2KK903775 đã release) |
| Status | active |
| Created | 2026-08-27 |

> Naming note: tên project có underscore (lệch chuẩn kebab-case `pmc-zsc10`) — thư mục do user tạo tay trước, giữ nguyên theo xác nhận của user 2026-08-27.

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| ZI_SC10_WhsePlant | DDLS | Active | helper: plant/warehouse |
| ZI_SC10_WtIncoming | DDLS | Active | WT mở theo bin đích — predicate cần runtime verify (T3) |
| ZI_SC10_WtOutgoing | DDLS | Active | WT mở theo bin nguồn |
| ZI_SC10_SalesAreaMin1 | DDLS | Active | sales area determinizer 1/3 |
| ZI_SC10_SalesAreaMin2 | DDLS | Active | sales area determinizer 2/3 |
| ZI_SC10_SalesUom | DDLS | Active | sales area determinizer 3/3 |
| ZI_SC10_ClfnCharcValue | DDLS | Active | quy cách đóng gói (P-3 tên charc verbatim) |
| ZI_SC10_StockAgg | DDLS | Active | ROOT aggregate (GAP-1 SUM) |
| ZI_SC10_StockUomBase | DDLS | Active | L1 |
| ZI_SC10_StockUomCalc | DDLS | Active | L2 |
| ZC_SC10_StockUomConv | DDLS | Active | L3 consumption root — CHƯA có DCL (manual) |
| ZC_SC10_STOCKUOMCONV | DCLS | Active | user tạo tay ADT (Variant B, /SCWM/STB2) |
| ZC_SC10_StockUomConv | DDLX | Active | user tạo tay ADT từ draft metadata_extensions/ |
| ZUI_SC10_StockUomConv | SRVD | Active | |
| ZUI_SC10_StockUomConv_O4 | SRVB | **Pending manual (recreate)** | tool tạo nhầm V2-UI, chưa publish — user delete + tạo lại OData V4 - UI + publish |

## Key documents
<!-- Links to the project's own TS/walkthrough/analysis files as they appear. -->
- FS: `fs_docs/PMC_FS_SC_ZSC10_BaoCaoQuyDoiDVTTonKhoThanhPham_v0.1.docx`
- FS markdown: `scratchpads/fs_markdown.md` (converted 2026-08-27; mục 2.2.3 chỉ có trong TOC — user chốt bỏ qua)
- TS: `technical_specifications/TS_BaoCaoQuyDoiDVTTonKhoThanhPham.md` (Verify PASS 2026-08-27; Package/TR TBD; open points TS §11)
- Ledger: `scratchpads/scratchpad_BaoCaoQuyDoiDVTTonKhoThanhPham.md` (kèm Verified Data Model + verification evidence)
