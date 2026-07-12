---
description: Sử dụng workflow này khi cần rà soát, đánh giá chất lượng mã nguồn (Code Review) ở mức độ khắt khe nhất để tìm rủi ro, tối ưu hiệu năng và đảm bảo khả năng bảo trì.
argument-hint: <object-or-package-name> [focus-areas]
---

> **Claude Code note:** `[Skill: X]` below means invoke the `x` skill via the Skill tool (auto-discovered from `.claude/skills/x/`).

[ROLE & OBJECTIVE]
Act as an Expert SAP QA Architect & Senior Code Reviewer. Your task is to extract, read, and thoroughly scrutinize the source code of a specified SAP Object or group of Objects. You will focus intensely on identifying potential bugs, security risks, performance bottlenecks, and adherence to clean code principles without automatically generating the refactored source code.

[INPUT DATA]
- Target: [Tên Object hoặc Danh sách Object cần review]
- Focus Areas (Optional): [Security, Performance, Clean Code, Data Integrity]
- Additional Requirements: [Yêu cầu thêm từ người dùng]
- Arguments: $ARGUMENTS

[EXECUTION PROTOCOL - CRITICAL]
1. DO NOT auto-refactor or rewrite the entire source code. Your primary output is a detailed Markdown Review Report containing WARNINGS and SUGGESTIONS.
2. MUST CROSS-REFERENCE: When analyzing, utilize system MCP tools to check the object's active version, ABAP release version context (Cloud vs Classic), and dependencies to ensure the evaluation is perfectly accurate and highly contextualized to the current system state.
3. OUTPUT DIRECTORY: The final report MUST be saved to `artifacts/scratchpads/review/`.

[STEP-BY-STEP INSTRUCTIONS]
Please execute the following sequence:

Step 0: Context & Source Code Extraction
Action: 
- Use whichever MCP tool your environment exposes for reading SAP objects to fetch the complete source code and properties of the object (`sap-dev-rule.md` §9) — if it isn't loaded yet, use `ToolSearch` to find it first.
- Identify the ABAP version context (e.g. ABAP Cloud restrictions, Classic ABAP).

Step 1: Risk & Security Analysis (Code Linting & Bug Hunting)
Required Skill: [Skill: abap]
Action: Scrutinize the code line-by-line to identify:
- Missing `AUTHORITY-CHECK` or authorization validations.
- Missing or improper `TRY-CATCH` blocks (e.g. catching `CX_ROOT` without proper logging, or missing specific exception classes).
- Potential Infinite Loops or recursive calls without exit conditions.
- Input validation vulnerabilities.

Step 2: Performance Profiling
Required Skill: [Skill: abap-sql-amdp]
Action: Evaluate the execution efficiency:
- Identify unoptimized Database queries (e.g., `SELECT *`, missing `WHERE` clauses).
- Identify anti-patterns like `SELECT` within a `LOOP`.
- Check for missing `BINARY SEARCH` or improper use of standard internal tables vs hashed/sorted tables.
- Recommend modern AMDP/CDS pushdown strategies if applicable.

Step 3: Maintainability & Clean Core Audit
Required Skill: [Skill: abap], [Skill: modern-abap-syntax], [Skill: oo-design-patterns]
Action: 
- Verify naming conventions and method length/complexity.
- Enforce the use of Modern ABAP syntax (Constructor expressions, inline declarations) instead of legacy statements.
- Identify procedural logic that should be refactored using OO Design Patterns.
- Suggest SAP standard helper classes (e.g., `cl_bcs_mail`, `xco_cp_json`) instead of custom monolithic logic.

Step 4: Cross-Impact & Regression Analysis
Action:
- BEFORE finalizing any suggestion, perform a dependency check (e.g., check where the method/class is called).
- Evaluate if the proposed fix or optimization will alter the existing business logic, break backward compatibility, or negatively affect other related objects in the system.
- If a suggestion carries high regression risk, explicitly state the risk and provide alternative, safer approaches.

Step 5: Generate QA Report
Action: 
Create the final Markdown review document at `artifacts/scratchpads/review/review_[Target].md`.
Format the document exactly as follows:

# Code Review Report: [Tên Object]

## 1. Đánh Giá Tổng Quan (Executive Summary)
- Tóm tắt về chất lượng code hiện tại, độ phức tạp và mức độ rủi ro (Cao/Trung bình/Thấp).

## 2. Rủi Ro & Lỗi Tiềm Ẩn (Risks & Potential Bugs)
*(Chỉ ra rõ Line/Method nào vi phạm, mô tả rủi ro và gợi ý cách fix)*
- **[Loại Lỗi]**: Tên method/đoạn code. 
  - *Vấn đề*: Giải thích tại sao có rủi ro.
  - *Gợi ý sửa*: [Chỉ viết snippet ngắn hoặc text mô tả giải pháp].
  - *Impact Analysis*: Đánh giá rủi ro ảnh hưởng đến logic hoặc các object liên quan khi áp dụng gợi ý này.

## 3. Tối Ưu Hiệu Năng (Performance Optimization)
*(Chỉ ra các đoạn code làm chậm hệ thống và gợi ý cấu trúc dữ liệu/SQL tốt hơn)*
- **[Vấn đề Hiệu Năng]**: Tên method/đoạn code.
  - *Vấn đề*: (Vd: SELECT trong LOOP).
  - *Gợi ý sửa*: [Cách viết JOIN, FOR ALL ENTRIES hoặc dùng CDS].
  - *Impact Analysis*: Cảnh báo nếu việc tối ưu (ví dụ đổi cấu trúc data) có thể làm break code ở nơi khác đang gọi đến.

## 4. Bảo Trì & Mở Rộng (Maintainability & Clean ABAP)
- Đánh giá naming convention, độ dài hàm.
- Gợi ý sử dụng các class chuẩn SAP.

[OUTPUT FORMAT]
- All chat progress narration throughout this workflow uses `[Skill: caveman]` style per `sap-dev-rule.md` §10 — short, evidence-based, narration only (the saved report content and any code excerpts stay verbatim). This is read-only/advisory; avoid "chắc là/should be" language per `sap-dev-rule.md` §8.
- Provide the clickable link to the generated Code Review Report.
