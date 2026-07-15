# Sources — Deep-Dive Research Trail

Research conducted 2026-07-14 for the ABAP dev skill enrichment initiative (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`, Phase 2). `sap-docs-extend-mcp` confirmed down for this entire session — did not attempt it. Fell back to `curl`-fetching the official SAP-samples cheat sheets directly (public GitHub repo, no auth).

## Scope decision

Did **not** re-expand the unreleased→released replacement table (Phase 0 deliberately trimmed it to 3 illustrative rows pointing at `abap-cloud-migration`). Focused instead on content genuinely not already covered: concrete "is X allowed" edge cases, and any verifiable history of the 3-tier terminology or release-contract mechanics.

## Primary sources retrieved

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/19_ABAP_for_Cloud_Development.md` (285 lines, read in full — the exact topical match for this skill's "conceptual/reference" scope). The "Is X allowed" table and the C1-release-but-still-warns finding are both transcribed from the "Excursions" section's executable example:
  - Statement-level restrictions table: lines 60-198 (the full "nonsensical" `zcl_demo_abap` class written specifically to trigger ABAP-for-Cloud-Development syntax errors/warnings — every restriction cited was read directly from this code block's inline comments, not inferred).
  - `CL_ABAP_PROB_DISTRIBUTION`/`if_abap_prob_types=>int_range` type-compatibility warning finding: lines 228-251, including the prose explanation at lines 230-232 (*"An API may be extended in the future, which can affect its usage... the type might be extended in the future, potentially breaking the code"*) — quoted directly, not paraphrased into a stronger claim than the source makes.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines) — grepped for `tier`, `ABAP Cloud`, `abap for cloud development`, and `release contract|\bC0\b|\bC1\b|\bC2\b` (Cloud section only, i.e. before the documented line-2925 Cloud/Standard boundary). Release-number mapping used the corrected header regex from the `modern-abap-syntax`/`rap` pilots' post-publication fix (`Release (\S+?)(?:\s*\((\d+)\))?\s*</summary>`).

## Verified release-number claims

| Finding | Nearest header (exact text found in source) | Verified no intervening header between finding and mapped header? |
|---|---|---|
| 5 new `@AbapCatalog.enhancement.*` annotations required for C0 release of a DDIC object (prerequisite for developer extensibility) | `Release 785 (2108)`, line 1240; finding at lines 1331-1332 | Yes — `awk` range check lines 1240-1332, only one `<summary>` tag found |
| 2 of those 5 annotations (`.quotaShareCustomer`, `.quotaSharePartner`) removed/no-longer-required | `Release 795 (2402)`, line 609; finding at lines 643-644 | Yes — `awk` range check lines 609-645, only one `<summary>` tag found |

Neither release number carries a calendar-quarter gloss — deliberately, since no quarter-label conversion was attempted for these two findings.

## Negative findings (absence checked and confirmed, not assumed)

- Grepped `33_ABAP_Release_News.md` case-insensitively for `\btier\b` across the entire 8,016-line file: **zero matches**. The 3-tier extensibility model's own terminology (Tier 1/Tier 2/Tier 3 naming) is not tracked in this release-news digest at all — reported in the deep-dive as an honest absence, not a guessed formalization date.
- Grepped the same file for the literal string `XCO`: zero matches anywhere (cross-referenced with the same negative finding used in `released-abap-classes`' sources file) — the XCO library (used throughout this skill's Date/Time restriction example) has no tracked release history in this digest either.

## Cross-check against this skill's existing content (to avoid contradicting or duplicating Phase 0 work)

- Read the live `SKILL.md` in full before drafting — confirmed it already states "Only released SAP APIs (C1 contract) can be used" and separately cross-points to `abap-cloud-migration` for the full replacement tables (Phase 0 item A5). The C0-annotation history finding extends the existing C1-contract mention rather than re-explaining the C0/C1 concept from scratch; grepped `abap-cloud-migration/SKILL.md` and `atc-cloudification/SKILL.md` for `C0`/`developer extensibility` first and found no existing coverage there either, so this is placed here without creating a new duplicate.
- The `sy-uzeit`/`sy-datum` restriction row cross-points to `[Skill: released-abap-classes]`'s own deep-dive (drafted in this same research pass) rather than re-deriving the CL_ABAP_CONTEXT_INFO-vs-XCO_CP_TIME decision criteria a second time.
