# Sources — Deep-Dive Research Trail

Research conducted 2026-07-14 for the ABAP dev skill enrichment initiative (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`, Phase 1 pilot). `mcp-sap-docs`/`sap-docs-extend-mcp` (the intended primary source) was unreachable for the entire session (`Server sap-docs-extend-mcp unavailable`, both `search` and `abap_feature_matrix` tools, retried multiple times across both pilot skills) — fell back to direct retrieval of the official SAP-samples cheat sheets via `curl`/GitHub API (public repo, no auth needed), the same upstream content those MCP tools wrap.

## Primary source retrieved

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines) — official ABAP Keyword Documentation release-news digest. All release-number claims below were found by grepping this file for RAP/BDL-related terms, then mapping each finding's line number to the nearest preceding `Release NNN (QQQQ)` header via a one-off script (same method used for `modern-abap-syntax`'s deep-dive — see that skill's `sources-deep-dive.md` for the mapping approach).
- Cross-checked against this workspace's own existing `references/bdef-templates.md`, `references/behavior-pool-templates.md`, `references/eml-quick-reference.md` to avoid re-stating content already covered there — this deep-dive only adds what those three files and the SKILL.md body don't already have.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/08_EML_ABAP_for_RAP.md` (3,224 lines) and `.../36_RAP_Behavior_Definition_Language.md` (1,266 lines) — used to verify the late-save-phase error-handling pattern. **Caught and corrected a fabrication during drafting**: an initial draft of this deep-dive included `RAISE SHORTDUMP TYPE cx_abap_behavior_internal_dump` as the saver-class error-handling pattern, invented from memory without verification. Cross-checking `08_EML_ABAP_for_RAP.md` (§"Allowed/Forbidden Operations", §"Special Case: Failures in the Late Save Phase") showed this was not just unverifiable but actively wrong — `RAISE EXCEPTION` is forbidden in every RAP transaction phase, and the actual documented mechanism for a late-phase failure is inheriting the saver class from `CL_ABAP_BEHAVIOR_SAVER_FAILED` instead of `CL_ABAP_BEHAVIOR_SAVER`. Corrected before this file was finalized — flagging here per the workspace's radical-honesty/no-fabrication rule, since the wrong version was briefly written to disk during drafting.

## Verified release-number claims (RAP/BDL feature history)

| Finding | Release (quarter) |
|---|---|
| `with additional save` (Additional Save in Managed BOs) | 778 (1911 / 2019 Q4) |
| `with unmanaged save` (Unmanaged Save in Managed BOs) | 778 (1911 / 2019 Q4) |
| `numbering:managed` statement (managed internal numbering) | 779 (2002 / 2020 Q1) |
| Determine actions (`determine action` as a new action type) | 781 (2008 / 2020 Q3) |
| Nested Determinations on Modify (a determination-on-modify can trigger another) | 782 (2011 / 2020 Q4) |
| `always` addition for determine-action-linked determinations/validations | 782 (2011 / 2020 Q4) |
| Early numbering usable for all primary-key fields inside a **managed** BO (originally unmanaged-only concept) | 783 (2102 / 2021 Q1) |
| `cleanup` method addition for additional/unmanaged save | 783 (2102 / 2021 Q1) |
| Late numbering extended to managed and draft-enabled BOs (originally unmanaged-only) | 786 (2111 / 2021 Q4) |
| `notrigger[:warn]` field characteristic (prevents a field from being used in a validation/determination trigger condition) | 790 (2211 / 2022 Q4) |
| `CL_ABAP_BEHAVIOR_SAVER_FAILED` C1-released for ABAP for Cloud Development | 794 (2311 / 2023 Q4) — found by `33_ABAP_Release_News.md` line 678 ("C1 Release of Class CL_ABAP_BEHAVIOR_SAVER_FAILED"); mapped to release 794/2311 via header at line 650 |

## Post-publication correction (2026-07-14, found during Phase 2 batch review)

A Phase 2 drafting agent working on unrelated skills (`abap`/`abap-cloud-migration`/`atc-cloudification`) independently found, while researching a different topic, that `CL_ABAP_BEHAVIOR_SAVER_FAILED` — the class this deep-dive recommends for late-save-phase failure handling — was only C1-released for the ABAP for Cloud Development language version at release 794 (2311 / 2023 Q4). The original deep-dive draft presented it as simply "the documented mechanism" without a version caveat. Verified directly (`33_ABAP_Release_News.md` line 678) and added the missing version-gate row + an in-body caveat. Separately, that same review found the original release-mapping script (used across both pilot skills) only matched headers with a parenthesized quarter (`Release NNN (QQQQ)`), silently skipping headers like `Release 766` with no quarter — re-verified every release-number claim in this file against a corrected script that also matches quarter-less headers; all of this file's claims held up unchanged (the gap only would have mattered for a finding whose true nearest header lacked a quarter, which none of this file's findings did).

**Also caught in the same review**: 3 of the 10 calendar-quarter glosses in the table above used the wrong month→quarter mapping (correct SAP `YYMM` mapping: `02`→Q1, `05`→Q2, `08`→Q3, `11`→Q4). Corrected in both this file and `references/deep-dive.md`: release 781 (2008) is 2020 **Q3** (was mislabeled Q2), release 783 (2102) is 2021 **Q1** (was Q2, both occurrences). The release numbers themselves were always correct — only the human-readable quarter gloss was wrong.

## Important framing note

Several of these — `with additional save`/`with unmanaged save`, `numbering:managed`, determine actions — are foundational-feeling BDL constructs that are easy to assume have "always" been available on any RAP-capable system. They were all introduced between 2019 Q4 and 2023 Q4 (the `CL_ABAP_BEHAVIOR_SAVER_FAILED` C1 release being the latest), meaningfully later than RAP's own initial release. On an older or unconfirmed target release, verify these are actually available before designing a TS around them, rather than assuming.
