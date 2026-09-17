# Project: bmw.sc.batch-customlogic

| Field | Value |
|---|---|
| Customer / Engagement | BMW |
| Description | Gán số batch tự động PT(2)+YY(2)+SEQ(6) qua custom logic BAdI + custom number range, thay cho internal batch number assignment chuẩn |
| SAP system (MCP tool) | mcp__abap_bmw_dev__SAP — DEV client 080 (build) · mcp__abap_bmw_cus__SAP — customizing client (test/config) |
| Default Package | ZASSIGN_BATCH_NUMBER |
| Current TR | Workbench TR: TBD (user thao tác tay trong ADT) · Customizing TR: H9SK900090 (Config - Assign Batch Number) |
| Status | active |
| Created | 2026-08-21 |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| ZNR_BATCH | Number Range Object | Active | Until Year + Rolling, No Buffering, Sub Type = ZDE_PRODUCT_TYPE_SUFFIX |
| ZDO_SUFFIX_BATCH_NUMBER | Domain | Active | Number length domain của ZNR_BATCH |
| ZDO_PRODUCT_TYPE_SUFFIX | Domain | Active | CHAR2, value table ZTB_PT_SUFFIX |
| ZDE_PRODUCT_TYPE_SUFFIX | Data Element | Active, Released (C1 + Key User Apps) | Sub Type của ZNR_BATCH |
| ZDE_SUFFIX_BATCH_NUMBER | Data Element | Active, Released (C1 + Key User Apps) | Kiểu trả về của wrapper |
| ZTB_PT_SUFFIX | Table (delivery class C) | Active | Value table các PT suffix hợp lệ; invertedIndividualIndex |
| ZCL_BATCH_NUMBER_PROVIDER | Class | Active, Released (C1 + Key User Apps) | Wrapper CL_NUMBERRANGE_RUNTIME cho BLE |
| ZALLOWEDPRODUCTTYPES | SMBC (BC Maintenance Object) | Active | Maintain qua app Custom Business Configurations |
| ZALLOWEDPRODUCTTYPEST | TOBJ (Individual Transaction Object) | Active | Transport recording cho config data |
| ZI_ALLOWEDPRODUCTTYPES_S / ZI_ALLOWEDPRODUCTTYPES | CDS (RAP singleton + child) | Active | Generated stack |
| ZBP_I_ALLOWEDPRODUCTTYPES_S | Behavior Pool | Active | Generated, MBC API delegation |
| ZUI_ALLOWEDPRODUCTTYPES / _O4 | SRVD / SRVB | Active, Published | OData V4 UI |
| IAM App (Z..._MBC) + Catalog Z_BC_BATCH_CONFIG | IAM | Published locally | Cần S_TABU_NAM (TABLE=ZI_ALLOWEDPRODUCTTYPES, ACTVT 02/03) |
| YY1_LOBM_BEFORE_BATCH_NUMBER_I | Custom Logic (LOBM_BEFORE_BATCH_NUMBER_INT) | Published | Skip internal assignment |
| YY1_LOBM_AFTER_BATCH_NUMBER_IN | Custom Logic (LOBM_CBO_BATCH_NUMBER_INT) | Published | Build batch number, gọi wrapper |

## Key documents
- [walkthroughs/batch-number-assignment-setup-guide.docx](walkthroughs/batch-number-assignment-setup-guide.docx) — mô tả object + hướng dẫn setup/config đầy đủ
