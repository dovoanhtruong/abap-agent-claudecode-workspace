# Sources — Deep-Dive Research Trail (`odata`)

Research conducted 2026-07-14 for the ABAP dev skill enrichment initiative (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`, Phase 2 batch 2). `sap-docs-extend-mcp` confirmed down for this entire session (not retried) — fell back to `curl`-fetching the official SAP-samples cheat-sheet GitHub repo directly.

## Primary sources retrieved

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/36_RAP_Behavior_Definition_Language.md` (1,266 lines) — holds the actual "Service definition"/"Service binding" glossary entries (lines 160–190), the Concurrency Control BDL syntax table (lines 538–560, `etag master`/`etag dependent by`/`total etag`/`lock master`/`lock dependent by`), and the `external` alias syntax for behavior definitions (lines 470–495). Used for: the ETag section, the `external` alias section, and the `static default factory` action description (lines 870–900).
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/08_EML_ABAP_for_RAP.md` (3,224 lines) — grepped for "service definition"/"service binding"/"OData"; found only incidental OData mentions — confirmed via full TOC scan that this file's actual scope is EML statements/BDEF derived types/RAP transaction phases, not service exposure.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines; Cloud section lines 32–2925). Grepped for `service binding`, `service definition`, `odata`, `draft`, `etag`, `repeatable`, `factory action`, `side effect`; mapped each finding's line to its nearest preceding release header using the quarter-tolerant regex (`Release\s+(\S+?)(?:\s*\((\d+)\))?\s*</summary>`).
- Also grepped `33_ABAP_Release_News.md` (both sections) for `client proxy` / `/iwbep` / `proxy_fact` — **zero hits anywhere in the file**. Basis for the deep-dive's explicit negative finding on OData Client Proxy version history.

## Verified release-number claims

| Finding | Release (quarter) | Verified via |
|---|---|---|
| `EXTEND SERVICE` (CDS service definition extensions) | 789 (2208 / 2022 Q3) | Release news line 1011–1012, header at line 928: "It is now possible to define service definition extensions in CDS SDL using the statement EXTEND SERVICE." |
| `PROVIDER CONTRACTS` statement for service definitions | 789 (2208 / 2022 Q3) | Same header block, line 1015–1016: "The new statement PROVIDER CONTRACTS is now available for CDS service definitions... stricter syntax checks are applied." |
| Repeatable RAP actions/functions (`repeatable`, `%cid`) | 789 (2208 / 2022 Q3) | Line 1007–1008, same header block: "RAP actions and RAP functions can be defined as repeatable... within the same ABAP EML or OData request." |
| `static default factory` action | 790 (2211 / 2022 Q4) | Line 906–907, header at line 883: "The syntax addition default is available for static factory actions... evaluated by consuming frameworks, such as OData." |
| `with managed instance filter` on projection/interface BDEFs | 793 (2308 / 2023 Q3) | Line 707, header at line 663. |
| Draft Action `Activate` `optimized` | 793 (2308 / 2023 Q3) | Line 702–703, same header block. |
| Draft Action `AdditionalSave` | 793 (2308 / 2023 Q3) | Line 714–715, same header block. |
| `with draft` (draft support itself) | 781 (2008 / 2020 Q3) | Line 1580–1581, header at line 1557: "The new statement with draft can be used to enable the draft concept for a RAP BO." |
| RAP Collaborative Draft (`with collaborative draft`) | 916 (2508 / 2025 Q3) | Line 149–150, header at line 106. |
| CDS service definitions exposing AMDP procedures (`EXPOSE METHOD`) | 914 (2502 / 2025 Q1) | Line 280–281, header at line 261. |
| `DEFINE SERVICE` (service definitions, base statement) | 775 (1902 / 2019 Q1) | Line 2015–2016, header at line 1992. Same release as RAP `ROOT`/`COMPOSITION`. |

Quarter glosses computed with the fixed `YYMM`→quarter formula (`02`→Q1, `05`→Q2, `08`→Q3, `11`→Q4) — every row double-checked against the formula before being written into `deep-dive.md` (a first draft briefly mis-labeled the two 793/2308 draft-action rows as "2023 Q4"; corrected to Q3 during self-review since `08`→Q3, not Q4).

## Concurrency-control (ETag) content — exact source text

`36_RAP_Behavior_Definition_Language.md` lines 538–560 (paired code/description table row titled "Concurrency control"):

```abap
//ETag for optimistic concurrency control
etag master some_etag_field
etag dependent by _Assoc
total etag some_total_etag_field

//Locking for pessimistic concurrency control
lock master
lock dependent by _Assoc
```

Description text used verbatim for the annotation names: `@Semantics.systemDateTime.localInstanceLastChangedAt: true` (plain ETag, managed BOs) and `@Semantics.systemDateTime.lastChangedAt: true` (`total etag`, draft-enabled BOs).

## Deliberately excluded / honestly flagged as unverifiable

- OData protocol-level feature timeline ($apply aggregation transformation, deep create/update support by version, `/iwbep/cl_cp_client_proxy_fact` introduction release) — none of these terms appear in `33_ABAP_Release_News.md` at all. This digest tracks ABAP language/CDS/BDL syntax, not the SAP Gateway/RAP-runtime protocol implementation, so this is a genuine source gap, not a "these are baseline" finding.
- `STRING_AGG`, `GROUPING SETS`, and other ABAP-SQL-topic aggregate features found while grepping — excluded as out of scope for `odata`.

## Live-URL check (per the workspace's incident-4 lesson)

Checked every URL currently cited in `odata/SKILL.md`'s References section:

| URL | Status |
|---|---|
| `https://help.sap.com/docs/abap-cloud/abap-rap/odata-service` | 200 |
| `https://help.sap.com/docs/abap-cloud/abap-rap/service-binding` | 200 |
| `https://help.sap.com/docs/abap-cloud/abap-rap/odata-client-proxy` | 200 |

All live — no fix needed for this skill.
