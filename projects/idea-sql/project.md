# Project: idea-sql

| Field | Value |
|---|---|
| Customer / Engagement | TBD (internal idea) |
| Description | Thiết kế tool "Query Variant Report" — Fiori app khai báo query variant (metadata-driven SQL) cho report đơn giản trên SAP S/4HANA Cloud Public Edition |
| SAP system (MCP tool) | mcp__abap_bmw_dev__SAP — DEV client 080 (data variant nằm ở **client 100**) |
| Default Package | **ZSQLRPT** (software component HOME — transportable) |
| Current TR | **H9SK900004** |
| Status | active |
| Created | 2026-08-04 · dựng lại sang ZSQLRPT 2026-08-06 |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
Package cũ `ZSQL_VARIANT` (local) đã bị user xoá sạch object 2026-08-06. Bảng dưới là package MỚI.
Ledger đầy đủ + evidence từng object: [scratchpads/ledger_rebuild_sqlrpt.md](scratchpads/ledger_rebuild_sqlrpt.md).

| Object | Type | Status | Notes |
|---|---|---|---|
| ZTB_SQLRPT / _D, ZTB_SQLRPTPRM / _D, ZTB_SQLRPTSRC / _D, ZTB_SQLRPTLOG, ZTB_SQLRPTRES | TABL ×8 | ACTIVE | prefix ZTB (ZA_ bị DT101 chặn); `ZTB_SQLRPTSRC_D` thêm 2026-08-06 để draft-enable whitelist cho V4. **2026-09-07: `ZTB_SQLRPTPRM`/`_D` đổi key → `param_uuid` (sysuuid_x16), `param_name` thành field thường** (bug fix inline create; bảng draft user activate tay qua ADT vì cần conversion) |
| ZR_SQLRPT, ZR_SQLRPTPRM, ZR_SQLRPTSRC, ZR_SQLRPTLOG, ZI_SQLRPTSRC_VH | DDLS ×5 | ACTIVE | cặp root/child dựng bằng bootstrap 3 bước; 2026-09-07 `ZR_SQLRPTPRM`/`ZC_SQLRPTPRM` key `ParamUuid` |
| ZABS_SQLRPT_RUN_PARAM, ZABS_SQLRPT_RUN_RESULT | DDLS abstract ×2 | ACTIVE | `ZI_QRY_CHECK_PARAM_A` cố ý không dựng lại. 2026-09-07: action `addParameter` + `ZABS_SQLRPT_ADD_PARAM` từng được dựng để nhập key Parameter qua popup rồi **đã revert cùng ngày** (user chốt không dùng custom action) — bug gốc còn mở: FE V4 inline create không nhập được key `ParamName` của child (key immutable sau POST); **→ ĐÃ FIX 2026-09-07 bằng UUID key cho child** — xem [walkthroughs/walkthrough_bugfix_ZR_SQLRPTPRM.md](walkthroughs/walkthrough_bugfix_ZR_SQLRPTPRM.md) |
| ZR_SQLRPT, ZR_SQLRPTSRC, ZR_SQLRPTLOG | BDEF ×3 | ACTIVE | |
| ZCX_SQLRPT_ENGINE, ZCL_SQLRPT_SCHEMA_GEN, ZCL_SQLRPT_ENGINE | CLAS ×3 | ACTIVE | **2026-09-07: optional predicate block `[ ... ]` trong WHERE/HAVING (FS §8/TS §12), test include `ltc_optional_block` 12/12 PASS** · engine activate zero warning · 2026-08-18: `c_column_limit` nâng 50/150 → **200** ở cả 2 class; thêm hỗ trợ cột **RAW/UUID** (`type_token` → `RAW(len)`, `build_target_table` → `get_x`) fix lỗi probe "PRODUCTUUID not compatible" khi `SELECT *` trên `I_PRODUCT`; sau đó bịt nốt **FLTP/DF16/DF34/INT8/UTCL** (lỗi tương tự với `CharcFromNumericValue` kiểu F trong `I_BatchCharacteristicValueTP_2`) + right-align các kiểu số mới trong `build_metadata` (TR H9SK900004) |
| ZBP_SQLRPT, ZBP_SQLRPTSRC, ZBP_SQLRPTLOG | CLAS ×3 | ACTIVE — CCIMP đầy đủ | 2026-09-07: `ZBP_SQLRPT` + `val_param_unique` (child) + test include `ltc_parameter` 3/3 PASS; file mirror `CCIMP_ZBP_SQLRPT.txt` **stale**. user đã dán CCIMP tay; **2026-08-18: MCP ghi được Local Types** (`object_url .../includes/implementations`) — sửa trực tiếp được, file `.txt` trong project chỉ còn là mirror. 2026-08-18: key `ReportId`/`SourceView` **cho phép lowercase, lưu đúng như gõ** — validation check trên tên đã `to_upper`, mọi match whitelist đổi sang `upper()` 2 vế (val_root_source, val_frm_whitelist, release + engine static_check, load_report); RAP không thể tự uppercase key user gõ (determination không sửa được key, augment không override được giá trị consumer — SAP docs abenbdl_augment_projection) |
| ZC_SQLRPT, ZC_SQLRPTPRM, ZC_SQLRPTLOG, ZC_SQLRPTSRC | DDLS projection ×4 | ACTIVE | 2026-09-07: `ZC_SQLRPT` + `virtual GuideText` (ZCL_SQLRPT_GUIDE) + quickInfo; `ZC_SQLRPTPRM` + quickInfo (giới hạn 67 ký tự). DDLX ZC_SQLRPT cần thêm facet Guide (tay) |
| ZC_SQLRPT, ZC_SQLRPTSRC | BDEF projection ×2 | ACTIVE | |
| ZC_SQLRPTFLD + ZCL_SQLRPT_FIELD_QUERY | Custom entity + IF_RAP_QUERY_PROVIDER | ACTIVE | grid field của view trên Object Page whitelist — **không lưu data**, resolve lúc đọc; `@UI.lineItem` inline nên không cần DDLX riêng |
| ZUI_SQLRPT, ZUI_SQLRPTSRC | SRVD ×2 | ACTIVE | expose `ReportParameter` (Parameter là reserved) |
| ZCL_SQLRPT_RUN, ZCL_SQLRPT_SET_SCHEMA | CLAS classrun ×2 | ACTIVE | |
| ZCL_SQLRPT_GUIDE | CLAS (IF_SADL_EXIT_CALC_ELEMENT_READ) | ACTIVE | 2026-09-07 in-app authoring guide cho virtual element `ZC_SQLRPT.GuideText`; test `ltc_guide` 2/2 PASS |
| ZCL_SQLRPT_IMPORT | CLAS classrun | ACTIVE — chưa chạy | nạp 13 whitelist + 4 report từ dump client 100 qua EML (create→check→release); **F9 ở client 100**, cần CCIMP xong trước |
| ZUI_SQLRPT (V4, `_0001_G4BA`) | SRVB | ACTIVE | user tạo tay; **thiếu suffix `_O4`** so với chuẩn FPT |
| ZUI_SQLRPTSRC (V2, `_0001` IWSG) | SRVB | REPLACE | V2 → phải thay bằng `ZUI_SQLRPTSRC_O4` (V4) vì custom entity grid; BO đã draft-enable xong |
| DDLX ×4 (tên trùng entity ZC_*) | MDE | TODO | tay — chạy `scratchpads/rename_to_sqlrpt.sh` trước |
| DCL ×2 + auth object ZQRY_VAR | — | TODO | tay; hiện `@AccessControl #CHECK` không có DCL → full access |
| IAM app, Launchpad tile | — | TODO | tay |
| UI5 app | Fiori app | TODO — **mất backup** | `ZQRYVARIANT` biến mất khỏi hệ thống, phải làm lại từ đầu |
| Data (whitelist + 5 report) | — | TODO | nạp bằng classrun, map `variant_id`→`report_id`, **F9 ở client 100** |

## Backup trước khi dựng lại package
- [system_analysis/backup_00_index.md](system_analysis/backup_00_index.md) — **đọc file này trước**: cái gì đã lưu, cái gì phải copy tay, thứ tự dựng lại
- [system_analysis/backup_01_tables.md](system_analysis/backup_01_tables.md) · [backup_02_cds.md](system_analysis/backup_02_cds.md) · [backup_03_bdef_srvd.md](system_analysis/backup_03_bdef_srvd.md)

## Key documents
<!-- Links to the project's own TS/walkthrough/analysis files as they appear. -->
- [walkthroughs/sql-report-brief.html](walkthroughs/sql-report-brief.html) — **Brief 2026-09-08** (EN, short): what it is, overview structure (1 diagram), standard-vs-tool comparison (1 diagram + table), 6 benefit cards, 2 mockups
- [walkthroughs/sql-report-article.html](walkthroughs/sql-report-article.html) — **Community article 2026-09-08** (EN, single self-contained HTML, anonymized sample data): BI/end-user oriented (rev 2): roles, lifecycle, report anatomy, optional filters, safety, 9 Horizon-dark UI mockups, step-by-step example, tips; tech summary in one paragraph. Outline + source list: [scratchpads/article_sqlrpt_outline.md](scratchpads/article_sqlrpt_outline.md)
- [walkthroughs/walkthrough_inapp_guide_ZC_SQLRPT.md](walkthroughs/walkthrough_inapp_guide_ZC_SQLRPT.md) — **Feature 2026-09-07**: tooltip + section "Authoring Guide" (virtual element, FS §9/TS §13); còn bước DDLX tay
- [walkthroughs/walkthrough_optional_block_ZCL_SQLRPT_ENGINE.md](walkthroughs/walkthrough_optional_block_ZCL_SQLRPT_ENGINE.md) — **Feature 2026-09-07**: khối `[ ... ]` cho tham số optional bỏ trống (FS §8, TS §12, user guide §5.5)
- [walkthroughs/walkthrough_bugfix_ZR_SQLRPTPRM.md](walkthroughs/walkthrough_bugfix_ZR_SQLRPTPRM.md) — **Fix Report 2026-09-07**: Parameter read-only sau Create → UUID key child, val_param_unique, 3 ABAP Unit PASS
- [scratchpads/ledger_rebuild_sqlrpt.md](scratchpads/ledger_rebuild_sqlrpt.md) — **ledger dựng lại ZSQLRPT**: 33 object + evidence từng cái, bảng warning đã đánh giá, 6 hạng mục còn làm tay
- [scratchpads/rename_to_sqlrpt.sh](scratchpads/rename_to_sqlrpt.sh) — đổi tên cũ→mới cho 7 file `.txt` (CCIMP ×3, DDLX ×4) trước khi dán vào ADT
- [scratchpads/handoff_rebuild_sqlrpt_20260806.md](scratchpads/handoff_rebuild_sqlrpt_20260806.md) — handoff gốc: giới hạn MCP, bẫy đã trả giá, 6 nợ kỹ thuật
- [technical_specifications/TS_SqlVariant.md](technical_specifications/TS_SqlVariant.md) — **TS chính thức (Direct SQL, verify PASS)** — input cho /sap-dev-create-transactional-app
- [technical_specifications/TS_SqlVariantTest_O2CFlow.md](technical_specifications/TS_SqlVariantTest_O2CFlow.md) — **TS test**: variant `ZSD_O2C_FLOW` (O2C document flow SO→OD→GI→Billing→Invoice) + 26 test case
- [fs_docs/fs_direct_sql_variant.md](fs_docs/fs_direct_sql_variant.md) — FS phương án Direct SQL (đã chốt)
- [scratchpads/query-variant-tool-design.md](scratchpads/query-variant-tool-design.md) — thiết kế phương án metadata (giữ làm guided-mode tương lai)
- [scratchpads/scratchpad_SqlVariant.md](scratchpads/scratchpad_SqlVariant.md) — ledger workflow fs-analytic + build (DONE/PARTIAL/BLOCKED)
- [walkthroughs/user_guide_SqlVariant.md](walkthroughs/user_guide_SqlVariant.md) — **hướng dẫn sử dụng cho end user/author**: cách khai báo, ý nghĩa từng trường, status machine, lỗi thường gặp
- [walkthroughs/walkthrough_SqlVariant.md](walkthroughs/walkthrough_SqlVariant.md) — kết quả build: 25 object active, 6 hạng mục manual
- [scratchpads/manual_sources_SqlVariant.md](scratchpads/manual_sources_SqlVariant.md) — **source code cho phần làm tay**: local handler ×3, DCL ×2 + auth object, SRVB steps, execute( ), manifest
- [metadata_extensions/ZMD_SqlVariant.md](metadata_extensions/ZMD_SqlVariant.md) — source 4 DDLX
- [scratchpads/seed_store_revenue_SqlVariant.md](scratchpads/seed_store_revenue_SqlVariant.md) — **variant `ZSD_STORE_MAT_REVENUE`** (doanh số mặt hàng theo cửa hàng, nguồn `YT1_TINY_RAP_STORE_REVENUE`): lineage, SQL, + source classrun `ZCL_QRY_SEED_STORE_REV` chờ tạo tay
