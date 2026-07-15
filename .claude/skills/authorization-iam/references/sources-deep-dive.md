# Sources — Deep-Dive Research Trail (`authorization-iam`)

Research conducted 2026-07-14 for the ABAP dev skill enrichment initiative (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`, Phase 2 batch 2 round 2). `sap-docs-extend-mcp` was confirmed down for this entire session — used direct `curl` against the public SAP-samples cheat-sheet GitHub repo instead.

## Primary sources retrieved

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/25_Authorization_Checks.md` (644 lines) — the exact topical match. Read in full. Contains: `AUTHORITY-CHECK` basics, CDS access control basics, an "Executable Example (SAP BTP ABAP Environment)" section with a full IAM App → Business Catalog → Business Role → CDS DCL implementation walkthrough, and an "Excursion: Authorization Control in RAP" section with global/instance authorization handler skeletons and a pointer to `PRIVILEGED` mode / authorization contexts.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines) — grepped case-insensitively for `pfcg_auth`, `access control`, `authorization`, `AUTHORITY-CHECK`, `restriction type`, `privileged access`, `inherit`. Release-number mapping done with a corrected script implementing the quarter-tolerant header regex (`Release (\S+?)(?:\s*\((\d+)\))?\s*</summary>`) and the `YYMM→quarter` formula (`02`→Q1, `05`→Q2, `08`→Q3, `11`→Q4), applied programmatically.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/36_RAP_Behavior_Definition_Language.md` — checked for the exact BDL syntax of `define authorization context ... for disable ... save:early/save:late` and `with privileged mode disabling`. **Finding: this cheat sheet does not include a worked syntax example for this BDEF header option** — only a pointer to `ABENBDL_BDEF_HEADER` in the ABAP Keyword Documentation. The deep-dive therefore describes this feature from the release-news prose only and explicitly flags that the exact brace/keyword grammar was not independently verified.

## Important correction to the original research assumption

The original dispatch predicted the IAM-app/business-catalog/business-role admin model "is BTP-administrative, likely not in this cheat sheet." **This was checked and found incorrect** — `25_Authorization_Checks.md` lines 117-251 contain a full executable walkthrough (authorization field → authorization object → IAM app → business catalog → business role → CDS DCL role), including exact ADT wizard filter names and Fiori app names (`Maintain Business Roles`). The deep-dive's "Worked Example" section is built directly from this walkthrough, condensed to the object sequence and cross-referenced against this skill's own existing `Z_MY_AUTH`/`ZCARR` naming for consistency.

## Verified release-number claims (mapped against `33_ABAP_Release_News.md`, ABAP-for-Cloud-Development section only, lines 32-2925)

| Finding | Line | Release (quarter) |
|---|---|---|
| `INHERITING CONDITIONS FROM SUPER` new DCL variant | 1901-1906 | 777 (1908 / 2019 Q3) |
| `define authorization context` in BDEF + `with privileged mode disabling` supersedes deprecated `with privileged mode` + own-context variants | 998-1007 | 789 (2208 / 2022 Q3) |
| DCL: identifier syntax for `ASPECT PFCG_AUTH(...)` (no quotes) + SACF condition-set enable/disable via `pfcg_auth` | 1279-1296 | 785 (2108 / 2021 Q3) |
| DCL: role-based inheritance `REPLACING` section + generic element replacement for `INHERIT role FOR GRANT SELECT` | 1287-1292 | 785 (2108 / 2021 Q3) |
| `CL_ABAP_TX` (Controlled SAP LUW explicit phase control) | 838-839 | 792 (2305 / 2023 Q2) |
| RAP `authorization:global`/`authorization:instance` at action level | 807-808 | 792 (2305 / 2023 Q2) |
| RAP Authorization Context for Disable — `save:early`/`save:late` options | 888-889 | 791 (2302 / 2023 Q1) |
| DCL `PRIVILEGED ACCESS` addition (bare form, refinement of the older `WITH PRIVILEGED ACCESS`) | 897-898 | 791 (2302 / 2023 Q1) |
| `OPTIONS` keyword recommended in front of `PRIVILEGED ACCESS`/`BYPASSING BUFFER` | 560-561 | 796 (2405 / 2024 Q2) |
| RAP `authorization:update` action addition | 1307-1308 | 785 (2108 / 2021 Q3) |
| RAP Subentities as Authorization Master | 533-534 | 796 (2405 / 2024 Q2) |
| RAP `authorization master ( none )` | 398-399 | 913 (2411 / 2024 Q4) |
| RAP Dedicated Authorizations for Create-by-Association Operations | 176-177 | 916 (2508 / 2025 Q3) |
| DCL `WITH PRIVILEGED ACCESS` (original/baseline form) | 2393-2394 | 769 (1708 / 2017 Q3) — baseline, predates every real ABAP Cloud target |

## Quarter-label self-check (mandatory per this initiative's lesson)

Extracted every release+quarter pair written into `references/deep-dive.md` and this file and re-verified against the `02`→Q1/`05`→Q2/`08`→Q3/`11`→Q4 formula: 1908→Q3 ✓, 2208→Q3 ✓, 2108→Q3 (both 785 rows) ✓, 2305→Q2 ✓, 2302→Q1 (both 791 rows) ✓, 2405→Q2 (both 796 rows) ✓, 2411→Q4 ✓, 2508→Q3 ✓, 1708→Q3 ✓. All 9 distinct release/quarter pairs check out — no mislabeled quarter found.

## Negative/absence findings (verified, not just assumed)

- `restriction type` (the Unrestricted/Restricted/No Access terminology used in the "Maintain Business Roles" Fiori app) has **zero** matches anywhere in `33_ABAP_Release_News.md` — confirming this is Fiori-admin-app terminology, not an ABAP-language construct with its own release history.
- `AUTHORITY-CHECK OBJECT`, custom Authorization Objects/Fields, basic `aspect pfcg_auth(...)`, and basic `where inheriting conditions from entity` all have their earliest release-news mentions describing them as already-existing/being *expanded*, at or before the earliest documented Cloud-section release — treated as baseline.

## Live URL checks

| URL | Status |
|---|---|
| `https://help.sap.com/docs/abap-cloud/abap-development-tools-user-guide/access-controls` | 200 |
| `https://help.sap.com/docs/btp/sap-business-technology-platform/identity-and-access-management-iam` | 200 |

All live — no fix needed for this skill.
