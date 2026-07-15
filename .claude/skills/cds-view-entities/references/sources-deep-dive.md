# Sources — Deep-Dive Research Trail (cds-view-entities, post-split / RAP-composition scope)

Research conducted 2026-07-14 for the ABAP dev skill enrichment initiative Phase 2 batch 2 (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`). `sap-docs-extend-mcp` was reported unavailable for this entire session (not retried) — fell back to `curl`-fetching the official SAP-samples cheat sheets directly.

## Scope note — the mapped cheat sheet turned out not to be the useful one

The task mapped `15_CDS_View_Entities.md` to this skill. Fetched it (73 lines) and read it in full: it is almost entirely a pointer page (links to demo DDL source files) covering input parameters, aggregate expressions, joins, and associations — i.e., exactly the general/analytical CDS authoring scope this skill's post-split description explicitly delegates to the sibling `cds-analytical-views` skill. It contains **no** composition-tree, root/child-entity, admin-field, or draft-specific content, so it was not used as a source for this deep-dive beyond confirming that scope boundary.

The actually useful sources for this skill's real scope (RAP composition mechanics) turned out to be the two RAP-specific cheat sheets instead, since composition trees, admin fields, ETag, and draft tables are documented as part of RAP behavior modeling, not CDS view authoring:

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/36_RAP_Behavior_Definition_Language.md` (1,266 lines) — primary source for BDEF-side `etag master`/`etag dependent by`/`total etag`, `lock master`/`lock dependent by`, draft-table requirements (`draft table`, `DRAFTUUID`, `%admin` include), the cascade-delete fact, and the root-mandatory/child-optional behavior-definition fact.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines) — grepped for `composition|root view entity|child view entity|admin field|etag|lock dependent|draft table|DRAFTUUID` (case-insensitive); release-number claims mapped via the quarter-tolerant header regex used across this initiative.

## Verified release-number claims

| Finding | Line (Cloud section) | Nearest header | Release (quarter) |
|---|---|---|---|
| `ROOT` addition + `COMPOSITION`/`TO PARENT` association types — composition-tree modeling origin | 2043 | 2023 | 775 (1902 / 2019 Q1) |
| Non-Standard Operations for Associations (`link action`/`unlink action`/`inverse function`) | 323 | 292 | 914 (2502 / 2025 Q1) |
| Subentities usable as RAP Authorization Master (previously root-only) | 534 | 502 | 796 (2405 / 2024 Q2) |
| Stricter association `ON`-condition rules (shared DDL engine with CDS custom entities) | 148 | 137 | 916 (2508 / 2025 Q3) |

Quarter mapping applied the fixed formula: `02`→Q1, `05`→Q2, `08`→Q3, `11`→Q4.

**Cross-check**: the composition-tree origin (775/1902) and the CDS-custom-entity origin used in the sibling `rap-query-provider` deep-dive's sources file are the same release (both found within a few lines of each other, lines 2038–2043) — confirmed by reading the raw block directly, not just trusting two separate grep hits landed on the same header by coincidence.

## Important negative finding — baseline, not version-gated

`grep -ni "etag\|lock dependent\|draft table\|root view entity\|DRAFTUUID\|sych_bdl_draft_admin"` against the full `33_ABAP_Release_News.md` returned **zero hits** anywhere in the file (Cloud or Standard section). This means ETag declarations, lock dependency, and draft-table mechanics — all covered in `36_RAP_Behavior_Definition_Language.md` in detail — are not tracked as "new" items in the quarterly release-news digest at all. Framed in the deep-dive as baseline/unconditionally-available, the same reasoning pattern `modern-abap-syntax`'s and `abap-sql-amdp`'s deep-dives already established for other foundational constructs.

## Verbatim quotes used (from 36_RAP_Behavior_Definition_Language.md)

- Lines 550–572 — ETag/lock declaration syntax and the draft resumability mechanism paragraph (exclusive lock → optimistic lock phase → `total etag` comparison), quoted/paraphrased faithfully in `references/deep-dive.md`.
- Lines 531–535 — draft table requirements paragraph, including the exact `DRAFTUUID` (16-character byte-like type, late-numbering-only) and `"%admin": include sych_bdl_draft_admin_inc;` requirement.
- Line 482 — "You must specify an entity behavior definition for the root entity. Defining behaviors for child entities is optional."
- Line 807 — "Delete operations on RAP BO instances of the parent entity in managed RAP BOs also delete associated child entity instances that are in a composition relationship."
- Lines 948–969 — `link action`/`unlink action`/`inverse function` BDL syntax and description, confirmed as a regular-association (non-composition) capability, cross-referenced against its release-914/2502 release-news entry.

## Not independently verifiable / out of scope this session

- The exact pre-2019 (pre-775/1902) syntax RAP composition trees might have used, if any existed at all before the `ROOT`/`COMPOSITION`/`TO PARENT` keywords — not investigated.
- CDS table entities (a persistence alternative found in the same release-914/2502 block as the non-standard-operations finding) were deliberately **not** included here — this skill's own SKILL.md explicitly defers "CDS table entities as a persistence alternative" to `[Skill: cds-analytical-views]` to avoid a duplicate copy.
