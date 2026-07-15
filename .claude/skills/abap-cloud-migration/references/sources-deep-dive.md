# Sources — Deep-Dive Research Trail (`abap-cloud-migration` skill)

Research conducted 2026-07-14 for Phase 2 of the ABAP dev skill enrichment initiative (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`). `sap-docs-extend-mcp` was unreachable for the entire session (`Server sap-docs-extend-mcp unavailable`) — fell back to `curl`-fetching the official SAP-samples cheat sheets directly (public GitHub, no auth), same approach as the Phase-1 pilots.

## Primary sources retrieved

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/19_ABAP_for_Cloud_Development.md` (285 lines — much shorter than expected; this cheat sheet is a concise conceptual overview with one detailed worked "Excursions" section, not a long reference). **This is the primary source for this deep-dive** — its "Excursions" section contains SAP's own official demo class specifically written to trigger every deprecated/invalid ABAP-for-Cloud-Development construct when activated, and a second worked example demonstrating a released-API type-compatibility warning.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines) — used to date the origin of "ABAP for Cloud Development" as a distinct language version.

## Verified findings

| Finding | Source location | Detail |
|---|---|---|
| "ABAP for Cloud Development" introduced as a distinct ABAP language version (internal ID 5 in `TRDIR-UCCHECK`) | `33_ABAP_Release_News.md` line 2346, Cloud section | Release 770 (1711) |
| `MOVE a TO b.` invalid; `DESCRIBE TABLE ... LINES` invalid; `GET REFERENCE OF` deprecated; `sy-uzeit`/`sy-datum`/`sy-timlo` discouraged; `USING CLIENT` addition not allowed; `cl_salv_table` not released; `READ REPORT` not released; dynamic SQL against an unreleased/nonexistent source compiles but fails at runtime | `19_ABAP_for_Cloud_Development.md`, "Excursions" §1, the official `zcl_demo_abap` excursion class (lines ~62–198 of the fetched file) — every line in that class carries an inline comment from SAP stating exactly what's wrong with it and why | All directly quoted/paraphrased from the source's own inline comments, not inferred |
| A Released (C1) API (`CL_ABAP_PROB_DISTRIBUTION`) can still emit a syntax warning if the caller manually reconstructs its expected type instead of referencing the API's own published type (`if_abap_prob_types=>int_range`) | `19_ABAP_for_Cloud_Development.md`, "Excursions" §3 (lines ~228–251 of the fetched file) | Directly quoted from the source's own explanatory prose, including the code snippet |

## Cross-reference used, not independently re-verified

- `atc-cloudification`'s Clean Core Level A/B/C/D mapping (used in the "Decision Bridge" section) — read from that skill's existing `SKILL.md`/`references/quick-reference.md`, not re-fetched from the Cloudification Repository in this pass (that verification was done separately for the `atc-cloudification` deep-dive — see that skill's `sources-deep-dive.md`).

## Explicitly not pursued / out of scope for this skill

- `CL_ABAP_BEHAVIOR_SAVER_FAILED` (RAP unmanaged-save error-signaling class) was found to have been released with the C1 contract at Release 794 (2311) (`33_ABAP_Release_News.md` line 679, Cloud section) while researching this skill's cloud-development timeline. This is a genuinely notable, verified finding, but it's a `rap`-domain fact (the class the Phase-1 `rap` pilot's deep-dive already uses in its unmanaged-save code example), not an `abap-cloud-migration` one — flagged to the Manager as a follow-up for the already-completed `rap` deep-dive (applied: see `rap/references/deep-dive.md`'s Version Safety table and its `sources-deep-dive.md`'s "Post-publication correction" note), not incorporated into this skill's content to avoid scope creep.
- Did not re-verify `SKILL.md`'s existing FM/API replacement tables (`GUID_CREATE`, `CONVERSION_EXIT_ALPHA_INPUT`, etc.) — treated as already-correct existing content per the task's instruction to focus on new value, not an audit pass.
