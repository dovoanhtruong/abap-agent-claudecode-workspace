---
name: abap-sql-amdp
version: 1.0
description: Help with advanced ABAP SQL and AMDP — window functions, CTEs, AMDP classes/procedures, AMDP/CDS table functions, scalar functions, UNION/INTERSECT/EXCEPT, PRIVILEGED ACCESS, SQLScript, database-level performance optimization. Use even for quick single-prompt SQL asks — "AMDP", "window function", "CTE", "table function", "advanced SQL", "tối ưu SELECT", "viết/sửa câu SQL", "tính tổng theo nhóm trong SQL", "đẩy logic xuống DB". For constructor expressions, internal-table operations, and string templates use modern-abap-syntax.
---

# ABAP SQL & AMDP

You already know standard ABAP SQL (SELECT, GROUP BY, HAVING, joins, subqueries, aggregates, window functions, CTE) — don't re-derive it here. This skill exists for the decisions and the AMDP-specific syntax that gets hallucinated.

## Workspace Constraint First (rule §3)

Read SAP data via released CDS views (`I_*`) only — never physical SAP tables. Custom Z-tables are read via their own CDS interface views once those exist. Any example below using a `z*_ve` source means "your CDS view entity", not a bare table.

## Modern ABAP SQL Feature Checklist

One-line reminders of what's available in ABAP for Cloud Development — expand any of them from the cheat sheets in References when needed:

- Inline results: `SELECT ... INTO TABLE @DATA(lt_x)` — always the default
- SQL expressions in field lists: `CASE`, arithmetic, `concat()`, `division()`, `coalesce()`
- Window functions: `OVER ( PARTITION BY ... ORDER BY ... )` with `SUM/AVG/ROW_NUMBER/RANK/LEAD/LAG`
- CTE: `WITH +cte AS ( SELECT ... ) SELECT FROM +cte ...` — prefer over nested subqueries for readability
- Set operations: `UNION [ALL]`, `INTERSECT`, `EXCEPT`
- Existence checks: `WHERE EXISTS ( SELECT ... )` / `FOR ALL ENTRIES` (only with a filled, deduplicated driver table)
- `PRIVILEGED ACCESS` — bypasses CDS access control; only with explicit justification, see [Skill: authorization-iam]

## ABAP SQL vs AMDP — the decision

Prefer ABAP SQL for almost everything (optimizer-friendly, debuggable, no HANA lock-in). Reach for AMDP only when: the logic needs SQLScript features ABAP SQL lacks (imperative logic between set operations, script-side variables), a **CDS table function** needs an implementation, or measured mass-data processing genuinely benefits from staying on the database.

## AMDP Class Structure

```abap
CLASS zcl_my_amdp DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_amdp_marker_hdb.  "Mandatory for AMDP

    TYPES: BEGIN OF ty_result,
             carrier_id TYPE s_carr_id,
             total      TYPE i,
           END OF ty_result,
           tt_result TYPE STANDARD TABLE OF ty_result WITH EMPTY KEY.

    "AMDP procedure
    METHODS get_carrier_stats
      AMDP OPTIONS READ-ONLY CDS SESSION CLIENT DEPENDENT
      EXPORTING VALUE(et_result) TYPE tt_result.

    "AMDP table function for CDS table function
    CLASS-METHODS get_data FOR TABLE FUNCTION zdemo_amdp_tf.
ENDCLASS.
```

Implementation shape (procedure — table functions are analogous with `BY DATABASE FUNCTION` + `RETURN SELECT`):

```abap
METHOD get_carrier_stats
  BY DATABASE PROCEDURE
  FOR HDB
  LANGUAGE SQLSCRIPT
  OPTIONS READ-ONLY
  USING zflight_ve.                "declare EVERY consumed view/entity

  et_result = SELECT carrier_id, COUNT(*) AS total
              FROM zflight_ve
              GROUP BY carrier_id;
ENDMETHOD.
```

## CDS Table Function

```cds
@ClientHandling.type: #CLIENT_DEPENDENT
@ClientHandling.algorithm: #SESSION_VARIABLE
define table function ZDEMO_AMDP_TF
  with parameters @Environment.systemField: #SYSTEM_LANGUAGE p_lang : abap.lang
  returns {
    key carrier_id : s_carr_id;
    carrier_name   : s_carrname;
    flight_count   : abap.int4;
  }
  implemented by method zcl_my_amdp=>get_data;
```

## AMDP Client Safety (ABAP Cloud) — the table that prevents the classic bug

| Addition                       | Use Case                                      |
| ------------------------------ | --------------------------------------------- |
| `CDS SESSION CLIENT DEPENDENT` | Uses client-dependent CDS views (most common) |
| `CLIENT INDEPENDENT`           | Uses only client-independent objects          |
| `AMDP OPTIONS READ-ONLY`       | Mandatory in ABAP for Cloud Development       |

Forgetting the client-handling addition (or `USING`) is the #1 AMDP activation failure — declare every consumed entity and match its client handling.

## Deep Dive

For which window-function/set-operation/AMDP-client-safety additions are actually release-gated (several are notably younger than AMDP/CTE themselves), the full window-function availability picture, and CDS Hierarchies (a topic not covered above at all), read [references/deep-dive.md](references/deep-dive.md).

## References

- ABAP SQL Cheat Sheet: https://github.com/SAP-samples/abap-cheat-sheets (03_ABAP_SQL)
- AMDP Cheat Sheet: https://github.com/SAP-samples/abap-cheat-sheets/blob/main/12_AMDP.md
- ABAP SQL Reference: https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/index.htm?file=abenabap_sql.htm
