# Project: bmw-api-mm

| Field | Value |
|---|---|
| Customer / Engagement | BMW |
| Description | Tổng hợp danh sách API chuẩn SAP Public Cloud (MM/procurement) → tìm data hợp lệ trên hệ thống → tạo request test cases trong Postman. **Scope từ 2026-07-27: 8 package** — A1 Plant, A4 Product, B1 PR, B2 Contract, B3 PO, C2 SES, C3 Supplier Invoice, **A5 Business Partner (đưa lại chiều 27/07, biến thể supplier qua CPI iFlow)**; A2 PurchOrg, A3 PurchGroup, C1 Goods Receipt vẫn ngoài scope |
| SAP system (MCP tool) | `mcp__abap_bmw_cus__SAP` (CUS — user chốt 2026-07-27 cho phase 2 data lookup); host API test: `my439328-api.s4hana.cloud.sap` [Inference từ SD docs — cần user xác nhận] |
| Default Package | TBD (chưa cần — project hiện chỉ đọc/test API chuẩn, chưa tạo SAP object) |
| Current TR | TBD (chưa cần — no SAP object mutation yet) |
| Status | active |
| Created | 2026-07-27 (project dir created ad hoc 2026-07-26; project.md added via /sap-project-init gap-fill) |

## Objects & Status
<!-- One row per SAP object this project owns; workflows update this as they build. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| (none) | — | — | Project is API-testing only so far; no Z/Y object created |

## Key documents
<!-- Links to the project's own TS/walkthrough/analysis files as they appear. -->
- `Book1.xlsx` — user input: 39 function-level API rows (source list)
- `system_analysis/SPEC-INDEX.md` — ENTRY POINT for the API spec inventory (11 packages, 156 entity sets)
- `system_analysis/api-groups.md` — 39 rows → 11 API packages + open issues
- `system_analysis/write-feasibility.md` — write ops vs C/U/D caps + 5 constraints
- `system_analysis/pull-specs.sh` — re-pull all 11 $metadata + regenerate inventory (needs `SAP_API_HUB_KEY` in `.env`)
- `scratchpads/handoff_api-spec-extraction_20260726.md` — handoff: phase 1 done, phase 2 blocked (tenant info), phase 3 not started
- `scratchpads/phase2-situation_20260727.md` — phase-2 situation read-out: SD precedent (bmw-sd-apis), tenants my439193/my439328, auth/CSRF/comm-scenario facts, 3 access routes + what the user must confirm before GO
- `system_analysis/sample-data-cus_plant-product_20260727.md` — valid CUS data (3 plants, 6 products, NRW02 sample) + danh sách 11 request Plant/Product đã tạo trong Postman "Standard API" → Directly
- `system_analysis/sample-data-cus_pr-contract-po_20260727.md` — valid CUS data B1/B2/B3 (4 PR, contract 4600000000, 20 PO; org V000/001/Z0000001/VND; WBS D.26.001-01.01.02) + danh sách 15 request PR/Contract/PO (3 POST deep model theo chứng từ thật) + 17 quy tắc payload đúc kết từ test run
- `system_analysis/api-url-catalog-cpi_20260727.md` — **catalog URL theo chức năng cho 8 nhóm API qua CPI iFlow** (deliverable bàn giao KyTa): mọi GET/POST + cú pháp $expand V2/V4 + ghi chú rule payload từng endpoint

## Open decisions
1. ~~Book1 "Khởi tạo PR" duplicate row~~ — **RESOLVED 2026-07-27**: only KyTa→SAP is real (1 write test case for B1); the SAP→KyTa row is a data-entry error.
2. ~~Goods Receipt scope~~ — **RESOLVED rồi MOOT cùng ngày 2026-07-27**: user xác nhận GR chỉ cho PO từ PR (SSP), nhưng sau đó gỡ hẳn C1 khỏi task.
3. ~~BMW tenant for phase 2~~ — **RESOLVED 2026-07-27 (chiều)**: user chốt đọc data từ **CUS** (`mcp__abap_bmw_cus__SAP`). Phase 2+3 đã chạy cho A1 Plant + A4 Product: data trong `system_analysis/sample-data-cus_plant-product_20260727.md`, 11 request tạo vào collection "Standard API" → Directly. Host `my439328-api` còn [Inference] — chờ user xác nhận khi chạy thử.
4. ~~Postman workspace~~ — **RESOLVED 2026-07-27**: workspace **"BMW"** (id `00a13fb5-7508-4fcb-9955-cef77e54e41a`), 1 collection / **7 folders** (sau scope cut cùng ngày).
