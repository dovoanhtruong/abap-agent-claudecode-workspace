# Project: bmw.mobileService

**Mô tả:** Setup app **SAP Warehouse Operator** (iOS) trên SAP BTP Mobile Services, kết nối S/4HANA Cloud Public Edition qua OData V4 + OAuth2SAMLBearerAssertion. Thuần cấu hình hệ thống — **không tạo object ABAP** → không có Package/TR.

## System / Tools

| Hạng mục | Giá trị |
|---|---|
| S/4HANA Cloud tenant | `my439328` (Public Edition) — API host `my439328-api.s4hana.cloud.sap` |
| MCP tool | `mcp__abap_bmw_cus__SAP` — ⚠ data preview bị chặn (S_DEVELOP), chỉ đọc metadata/source |
| BTP subaccount | `64687166-d306-4f3b-9dff-b9f6f7786077` · region `ap11` · CF space `BMW.DEV.ADS` |
| Mobile Services | instance `mobile.service.test` · plan `free` (cần đổi `resources` — free chặn 5 destination, app cần 9) |
| Mobile app ID | `com.sap.mobile.apps.warehouseoperator` (Native) |
| S/4 business user test | `CB9980000017` · email `truongdva2@fpt.com` |
| Docs | SAP Help/Community đọc qua MCP `sap-docs-extend-mcp` (WebFetch bị 403) |

## Package / TR

- Default package: **n/a** (không có ABAP object)
- Current TR: **n/a**

## Object status

Không có object SAP. Trạng thái cấu hình + next steps: xem file handoff mới nhất trong `scratchpads/` (hiện tại: `handoff_warehouse-operator-mobile-setup_20260812.md` — nguồn trạng thái duy nhất, gồm cấu hình đang chạy, root cause đã giải quyết, addendum docs 9bis).

Vấn đề đang mở: màn `Select a Resource` hiển thị `Resources (0)` (HTTP 200 + rỗng) — nghi thiếu business role restriction (DCL) hoặc master data resource.
