# Sources — Deep-Dive Research Trail (abap-sql-amdp)

Research conducted 2026-07-14 for the ABAP dev skill enrichment initiative Phase 2 (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`). `sap-docs-extend-mcp` was reported unavailable for this entire session (`Server sap-docs-extend-mcp unavailable`) — not retried. Fell back to the same method the Phase 1 pilot used: direct `curl` retrieval of the official SAP-samples cheat sheets (public GitHub repo, no auth) plus one direct fetch of a SAP Help Portal page for cross-checking.

## Primary sources retrieved

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines) — same release-news digest the pilot used. All release-number claims below were found by grepping this file for SQL/AMDP-related terms and mapping each finding's line number to the nearest preceding `Release NNN (QQQQ)` header via a one-off Python script (`map_release.py`, same method the pilot documented in its own sources file).
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/03_ABAP_SQL.md` (4,067 lines) — used for the window-expression syntax example and to confirm the official window-function list.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/12_AMDP.md` (873 lines) — used to confirm the exact `CDS SESSION CLIENT DEPENDENT` / `CLIENT INDEPENDENT` client-safety wording and code shape already used in the SKILL.md, and to verify AMDP table-function/scalar-function origin lines.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/10_ABAP_SQL_Hierarchies.md` (724 lines) — used for the CDS Hierarchies "new topic" section (this skill had zero prior coverage of hierarchies).
- `https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/abapselect_over.html` (SAP Help Portal, ABAP Keyword Documentation for `SELECT` windowing, CLOUD version) — fetched directly via `curl -sL` after following the site's JS redirect manually. Used specifically to confirm `RANK`, `DENSE_RANK`, and `ROW_NUMBER` are genuine ABAP SQL window functions (they don't appear anywhere in `03_ABAP_SQL.md`'s worked examples, so this was checked rather than assumed — see "Caught-and-avoided fabrication" below) and that `ORDER BY` is mandatory for the ranking functions.

## Verified release-number claims (line → release mapping done via the one-off script matching each finding to the nearest preceding `Release NNN (QQQQ)` header in `33_ABAP_Release_News.md`)

| Finding | Release (verified code) |
|---|---|
| Window expressions (`OVER(...)`) usable in the SELECT list of a query — first appearance in the "ABAP for Cloud Development" section | 775 (1902) |
| New window functions LEAD and LAG | 777 (1908) |
| New window functions FIRST_VALUE and LAST_VALUE + optional window frame specification | 778 (1911 / 2019 Q4) |
| New window function NTILE | 779 (2002 / 2020 Q1) |
| ABAP SQL new set operators INTERSECT and EXCEPT (statement-level) | 783 (2102 / 2021 Q1) |
| CDS view entity new set operators EXCEPT/INTERSECT (view-definition-level) | 785 (2108) |
| New addition PRIVILEGED ACCESS (SELECT-statement-level CDS access control bypass) | 791 (2302 / 2023 Q1) |
| New AMDP option CLIENT INDEPENDENT | 793 (2308) |
| New AMDP option CDS SESSION CLIENT DEPENDENT + "Client Safety of AMDP Methods ... mandatory for ABAP for Cloud Development" (same release entry) | 796 (2405) |
| New statement DEFINE HIERARCHY (CDS Hierarchies) | 773 (1808) |

## Manager correction (2026-07-14, applied before integrating into live content)

The draft version of this file (and `references/deep-dive.md`) originally labeled release 783/2102 as "2021 Q2" and release 791/2302 as "2023 Q2", reusing labels already used elsewhere in the Phase-1 pilots at the time of drafting. A separate post-pilot review found the pilots' own `02`-suffix releases had been mislabeled (the correct SAP `YYMM`→quarter mapping is `02`→Q1, `05`→Q2, `08`→Q3, `11`→Q4 — a fixed formula, not a per-year quirk as an earlier draft of this file speculated). Both labels are corrected here and in `deep-dive.md`: 783 (2102) is 2021 **Q1** (was Q2), and 791 (2302) is 2023 **Q1** (was Q2). All other release codes and their labels in the table above were unaffected (778/1911→Q4, 779/2002→Q1 were already correct).

## Important negative/baseline findings (absence is the evidence, cross-checked against the section boundary)

- `33_ABAP_Release_News.md` has two top-level sections: `## ABAP for Cloud Development Documentation Release News` (line 32–2925) and `## Standard ABAP Documentation Release News` (line 2926+). Within the Cloud section, the earliest **quarterly-numbered** release header is 767 (1702 / 2017 Q1); a handful of older, non-quarterly headers (766 down to 760) also appear inside the Cloud section's line range as historical backfill, but since no real BTP ABAP Environment/S/4HANA Cloud system predates 2017, anything at or below those non-quarterly headers is unconditionally baseline for this workspace's targets.
- The `WITH` statement (Common Table Expressions) has its introduction header ("Common Table Expressions") at release 765 (non-quarterly) — below the 767 baseline threshold. AMDP table functions ("AMDP Table Functions" header) sit at release 761 (also non-quarterly, older still). The `UNION` set operator's origin is explicitly dated "From ABAP release 7.60" at the release-760 header. All three predate every real quarterly Cloud release and are therefore baseline — same reasoning `modern-abap-syntax`'s deep-dive used for `VALUE`/`COND`/etc.
- No occurrence of `ROW_NUMBER`, `RANK`, or `DENSE_RANK` exists anywhere in `03_ABAP_SQL.md`, `12_AMDP.md`, or `33_ABAP_Release_News.md`. This was flagged as a possible correction to the SKILL.md's existing checklist line (which lists `ROW_NUMBER`/`RANK` as window functions) — but before writing that up as a finding, it was cross-checked against the live SAP Help Portal page for `SELECT, FROM ... OVER` windowing, which explicitly documents `RANK`, `DENSE_RANK`, and references `ROW_NUMBER( )` by name as an existing function ("The result is the same as that returned by the ROW_NUMBER( ) function"). **This is exactly the kind of claim the workspace's no-fabrication rule warns about** — the absence of a term in three cheat-sheet files is not proof the corresponding ABAP SQL feature doesn't exist; it just means those particular documents didn't showcase it. The SKILL.md's existing line was correct; no correction was made, and no release-gate could be pinned for these three functions specifically since they never appear as a "new" item in the release news (implying they're at least as old as window expressions became available at all — release 775 — but the exact release they were first offered as *sub-functions* of the windowing capability could not be isolated from the two functions that did get their own "new function" entries, LEAD/LAG/FIRST_VALUE/LAST_VALUE/NTILE).

## Not independently verifiable this session

- The precise ABAP release/quarter at which `CL_CDS_TEST_ENVIRONMENT`, `CL_OSQL_TEST_ENVIRONMENT`, or the AMDP-adjacent test-double classes were introduced is out of scope for this file (that's `abap-unit-testing` territory) but the same limitation applies broadly: `33_ABAP_Release_News.md` tracks *language/keyword* changes, not class-library additions, so no class name mentioned in this skill's SKILL.md or deep-dive was release-dated from this source — only statement/addition-level syntax was.
- What AMDP's client-dependent-access syntax looked like before release 796 (2405) could not be confirmed from the sources fetched this session — flagged as `[unverified — could not confirm this session]` in the deep-dive rather than guessed.
