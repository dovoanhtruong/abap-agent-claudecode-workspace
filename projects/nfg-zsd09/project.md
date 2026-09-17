# Project: nfg-zsd09

| Field | Value |
|---|---|
| Customer / Engagement | NFG |
| Description | ZSD09 — Báo cáo KD Top loại quả nhóm sản phẩm (SD analytics report, FS NFG_SAP_2026_TH_FS_SD_ZSD09) |
| SAP system (MCP tool) | `mcp__abap_nfg_dev__SAP` (verified in build session 2026-07-13) |
| Default Package | ZSD09 |
| Current TR | HL8K900362 |
| Status | active — build Phase 1 done (v1.0); FS v1.1 received 2026-08-21, diff/update pending |
| Created | 2026-07-17 (migrated from artifacts/) |

## Objects & Status
| Object | Type | Status | Notes |
|---|---|---|---|
| ZCE_SD09BIZPERF | Custom Entity (DDLS) | Active | 58 cols + row dims + 8 filter elements; VH annotations build-2/3 |
| ZCL_SD09_BIZPERF_QP | Class (IF_RAP_QUERY_PROVIDER) | Active | Full logic; build-4 (L1/L3 optional), build-5 (exclude blank L1/L3) |
| ZCE_SD09BIZPERF (MDE) | DDLX | Active (user-created manually) | Source: artifacts/metadata_extensions/ZMD_ZSD09BaoCaoKDTopLoaiQuaNhomSanPham.md |
| ZUI_SD09BIZPERF | Service Definition | Active | Exposes BizPerf + 8 VH entities |
| ZUI_SD09BIZPERF_O4 | Service Binding OData V4 UI | Active, published [Inference] | Preview works (user confirmed via screenshots) |
| ZI_SD09PRODHIERL1VH / L3VH | CDS VH views | Active | distinct values from cube |
| ZI_SD09FISCALYEARVH / PERIODVH | CDS VH views | Active | fixed lists (I_CalendarYear 2015–2050 / I_CalendarMonth→001-012) |
| Z_SD09_SO | Authorization Object | **PENDING — user manual (ADT)** | + IAM app/catalog/role; class passes through until created (DEV deviation) |

## Key documents
- FS v1.0: `fs_docs/NFG_SAP_2026_TH_FS_SD_ZSD09_BaoCaoKDTopLoaiQuaNhomSanPham_v1.0.docx` + `fs_docs/ZSD09-layout.xlsx`
- FS v1.1 (2026-08-21, chưa phân tích): `fs_docs/NFG_SAP_2026_TH_FS_SD_ZSD09_BaoCaoKDTopLoaiQuaNhomSanPham_v1.1.docx`
- TS: `technical_specifications/TS_ZSD09BaoCaoKDTopLoaiQuaNhomSanPham.md` (đồng bộ đến build-5)
- Build ledger (legacy path): `artifacts/scratchpads/scratchpad_ZSD09_BaoCaoKDTopLoaiQuaNhomSanPham.md`
- FS v1.0 markdown (legacy path): `artifacts/scratchpads/fs_markdown.md`

## Outstanding
- Phase 2 Runtime Verify chưa PASS (đang test; các fix build-2..5 đã xong)
- Z_SD09_SO + IAM trước khi lên PRD
- FS v1.1 diff DONE 2026-08-21: 67 diffs (`scratchpads/fs_markdown_v1.1.md` §Mechanical Diff); update plan tại `scratchpads/update_plan_fs_v1.1.md` — CHỜ user chốt 7 Open Questions (3 blocker: nguồn L1/L3 cho SO-data, định nghĩa approved/order types, nguồn giá thành thực tế) trước khi patch TS + code
