# ABAP SQL & AMDP — Deep Dive

Read this for release-gating that the SKILL.md body's "Modern ABAP SQL Feature Checklist" doesn't call out, plus one topic (CDS Hierarchies) the base skill doesn't mention at all. Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

## Version Safety on ABAP Cloud Targets

The SKILL.md checklist lists window functions, set operations, and `PRIVILEGED ACCESS` as if they were all equally old. They aren't — several are notably younger than AMDP/CTE themselves:

| Feature | Introduced | Practical impact if unavailable |
|---|---|---|
| Window expressions (`win_func OVER( ... )`) usable at all in ABAP for Cloud Development — this is the gate for the *entire* feature (SUM/AVG/MAX/MIN/COUNT and the ranking functions RANK/DENSE_RANK/ROW_NUMBER included) | Release 775 (1902) | No window functions of any kind — aggregate manually with `LOOP`/`REDUCE` or a helper CTE |
| `LEAD`/`LAG` window functions | Release 777 (1908) | Emulate with a self-join or a windowed `ROW_NUMBER` + join on `rownum ± 1` |
| `FIRST_VALUE`/`LAST_VALUE` window functions + optional window frame specification (`ROWS BETWEEN ...`) | Release 778 (1911 / 2019 Q4) | Use `MIN`/`MAX` over an `ORDER BY`-defined window as a workaround for first/last-in-partition |
| `NTILE` window function | Release 779 (2002 / 2020 Q1) | Bucket manually via `ROW_NUMBER` + arithmetic on partition size |
| ABAP SQL set operators `INTERSECT`/`EXCEPT` (statement-level, e.g. inside an AMDP's embedded ABAP SQL or a plain `SELECT`) | Release 783 (2102 / 2021 Q1) | Rewrite as `WHERE EXISTS`/`WHERE NOT EXISTS` subqueries |
| CDS view entity `INTERSECT`/`EXCEPT` set operators (inside a CDS view's own definition) | Release 785 (2108) | Same rewrite, but at the CDS DDL level |
| `PRIVILEGED ACCESS` as a `SELECT`-statement addition (bypasses CDS access control for that one query) | Release 791 (2302 / 2023 Q1) | The older `WITH PRIVILEGED ACCESS` CDS-view-level addition (see below) is the only lever on an older target |
| AMDP `CLIENT INDEPENDENT` option | Release 793 (2308) | Only client-dependent AMDP methods are expressible; restructure to avoid a genuinely client-independent AMDP method |
| AMDP `CDS SESSION CLIENT DEPENDENT` option (the exact addition in this skill's own code sample) | Release 796 (2405) | This precise syntax doesn't exist yet — confirm the target's actual client-safety mechanism rather than assuming this addition is available; don't guess a substitute |
| `DEFINE HIERARCHY` (CDS Hierarchies — new topic below) | Release 773 (1808) | No CDS-level hierarchy support; a recursive AMDP procedure is the fallback |

**Baseline — don't hedge on these regardless of target release**: CTE (`WITH` statement), the `UNION` set operator, and AMDP procedures/table functions themselves all predate 767 (1702 / 2017 Q1) — the earliest quarterly-numbered release in the "ABAP for Cloud Development" documentation. Since no real BTP ABAP Environment or S/4HANA Cloud system runs anything older than that, these are unconditionally available; treating them as a version risk is the wrong question, same conclusion as `modern-abap-syntax`'s deep-dive reached for `VALUE`/`COND`/etc.

**Two different `PRIVILEGED ACCESS` additions, two different ages** — don't conflate them: `WITH PRIVILEGED ACCESS` is a CDS DDL addition written into a view's own definition (baseline-old, release 769 / 1708); `PRIVILEGED ACCESS` as a `SELECT`-statement addition disables access control for one specific ABAP SQL query at the call site and is the newer one (791 / 2302 / 2023 Q1, table above). If a target is on an older release, only the view-level addition is available — the access-control bypass has to be designed into the CDS view itself, not applied ad hoc at the call site.

**AMDP client safety is younger than the skill's own example implies.** The SKILL.md's "AMDP Client Safety" table presents `CDS SESSION CLIENT DEPENDENT` and `CLIENT INDEPENDENT` as if they'd always existed — `CLIENT INDEPENDENT` reaches back only to release 793 (2308), and `CDS SESSION CLIENT DEPENDENT` only to release 796 (2405). Both entries in the release news ("New AMDP Option CDS SESSION CLIENT DEPENDENT" and "Client Safety of AMDP Methods... mandatory for ABAP for Cloud Development") land on the *same* release (796), which strongly suggests this is when AMDP client-safety enforcement was formalized this way. What the equivalent mechanism looked like before 796 could not be confirmed this session — if a target is on an older release, ask/check the target-specific documentation rather than guessing a workaround.

## Window Functions — the Full Availability Picture

The checklist's one-liner ("`SUM/AVG/ROW_NUMBER/RANK/LEAD/LAG`") is correct that all of these exist as ABAP SQL window functions, but bundles a release-775 (1902) baseline with three later, separately-gated additions (777/1908, 778/1911, 779/2002) as if they all shipped together. In practice:

```abap
"Baseline (775/1902+): aggregate + ranking functions over a window
SELECT carrid, currency, fldate,
  SUM( paymentsum )  OVER( PARTITION BY carrid )               AS carrier_total,
  RANK( )            OVER( PARTITION BY carrid ORDER BY fldate ) AS rank_by_date,
  ROW_NUMBER( )      OVER( PARTITION BY carrid ORDER BY fldate ) AS row_num
  FROM zdemo_abap_fli_ve
  INTO TABLE @DATA(result).

"777/1908+ only: LEAD/LAG
SELECT carrid, fldate,
  LAG( price )  OVER( PARTITION BY carrid ORDER BY fldate ) AS prev_price,
  LEAD( price ) OVER( PARTITION BY carrid ORDER BY fldate ) AS next_price
  FROM zdemo_abap_fli_ve
  INTO TABLE @DATA(lead_lag_result).
```

`ORDER BY` is mandatory for the ranking functions `RANK`/`DENSE_RANK` (per the ABAP Keyword Documentation for `SELECT` windowing) — without it there's no defined processing sequence to rank against.

## New Topic: CDS Hierarchies

Not mentioned anywhere in the current SKILL.md, but a genuine ABAP-SQL-adjacent capability worth knowing about before reaching for a hand-rolled recursive AMDP procedure to walk tree-shaped data (BOM explosions, org charts, account hierarchies — the same shapes `oo-design-patterns`' Composite pattern entry flags for the ABAP-object side).

**Decision cue**: if the requirement is ancestor/descendant/level/rank queries over parent-child data and a released CDS view already exposes the parent-child columns, a CDS hierarchy is usually less code than a recursive AMDP procedure and stays fully in ABAP SQL — reach for AMDP recursion only when the traversal logic needs more than what the hierarchy generator/navigators below express (e.g., non-trivial cycle handling logic, or the source genuinely can't be modeled as a self-association).

```cds
// CDS view exposing a self-association — the parent-child relation
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity Z_I_ORGNODE_TREE
  as select from z_orgnode
  association [1..1] to Z_I_ORGNODE_TREE as _Tree
    on $projection.ParentNode = _Tree.NodeId
{
  _Tree,
  key node_id as NodeId,
  parent_id  as ParentNode,
  node_name  as NodeName
}
```

```cds
// CDS hierarchy built from that view
define hierarchy Z_H_ORGNODE
  with parameters
    p_root_id : abap.int4
  as parent child hierarchy(
    source Z_I_ORGNODE_TREE
      child to parent association _Tree
      start where NodeId = :p_root_id
      siblings order by NodeId ascending
  )
  { NodeId, ParentNode, NodeName }
```

```abap
"Consuming it — hierarchy columns (hierarchy_rank, hierarchy_level, ...) are
"available implicitly once a CDS hierarchy is a SELECT's data source
SELECT FROM z_h_orgnode( p_root_id = @root_id )
  FIELDS node_id, parent_node, node_name,
         hierarchy_rank, hierarchy_level, hierarchy_tree_size
  INTO TABLE @FINAL(org_tree).
```

`HIERARCHY_DESCENDANTS`/`HIERARCHY_ANCESTORS`/`HIERARCHY_SIBLINGS` navigators (and their `_AGGREGATE` variants for rolling up values across a subtree) are available once a hierarchy exists, without writing recursive logic by hand.

**Honesty flag on this section**: the official cheat sheet this pattern is adapted from carries its own disclaimer that its runnable demo (`demo_simple_tree`, `CL_DEMO_SQL_HIERARCHIES`) is Standard-ABAP/on-premise-only tooling — those specific demo objects aren't released APIs. The `DEFINE HIERARCHY` statement and hierarchy navigators are nonetheless documented under the CLOUD ABAP Keyword Documentation and appear with real quarter numbers in the "ABAP for Cloud Development" release news (773/1808 onward, per the Version Safety table), so the *syntax* is legitimately ABAP-Cloud-available — only the specific demo artifacts in the source cheat sheet are not. Verify the exact hierarchy-attribute column names (`hierarchy_rank` etc.) against the target release's keyword documentation before shipping — this session couldn't cross-check every attribute name against a live system.

## Decision Trade-offs (extends SKILL.md's ABAP SQL vs AMDP framing)

- Before CDS Hierarchies existed (pre-release-773 / 1808), a recursive AMDP procedure was the *only* way to walk parent-child data efficiently on the database — if you inherit code written that way, it's not automatically wrong, but a new requirement with the same shape today should default to a CDS hierarchy first, and only fall back to AMDP recursion if the navigators genuinely can't express the traversal.
- Don't reach for the statement-level `PRIVILEGED ACCESS` addition as a default "just in case" — it's both the newest access-control lever in this file (2023 Q1) and the one hook that bypasses generated CDS access control entirely; the workspace rule (see `[Skill: authorization-iam]`) requires explicit justification for exactly this reason.
