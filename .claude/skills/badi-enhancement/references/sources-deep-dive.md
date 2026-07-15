# Sources — Deep-Dive Research Trail (`badi-enhancement`)

Research conducted 2026-07-14 for the ABAP dev skill enrichment initiative (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`, Phase 2 batch 2). `sap-docs-extend-mcp` confirmed down for this entire session — fell back to `curl`-fetching the official SAP-samples cheat-sheet GitHub repo directly.

## Primary source retrieved

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/35_BAdIs.md` (945 lines) — the exact topical cheat sheet. Read in full. Source for every claim in `deep-dive.md` except the version-safety negative finding:
  - Lines 29–31: single-use vs. multiple-use definitions, including the explicit signature constraint ("With multiple functionalities being executed, there cannot be a single output parameter... Changing parameters incorporate input and output parameter capabilities...").
  - Line 30: fallback-class recommendation explicitly scoped to single-use.
  - Line 382 (`GET BADI` notes): "After instantiation, the system searches for BAdI implementation classes. Only active classes that match the filter criteria are included in the search. If no matching implementations are found, the system will look for standard implementations. If none are found, it will use the fallback class, if available."
  - Lines 524–526 (More Information section): the `api.sap.com` → Explore → Categories → Business Add-Ins (BAdIs) discovery path.
  - Lines 483–514 (executable example, dynamic specifications): `FILTER-TABLE`/`PARAMETER-TABLE` additions.
  - Lines 813–931 (executable example, exceptions section): `cx_badi_filter_error`, `cx_sy_dyn_call_param_missing`, `cx_sy_dyn_call_illegal_method`, `cx_badi_initial_reference` — and critically, the single-use vs. multiple-use asymmetry for calling through an initial/cleared reference (comment at lines 891–895 vs. 910–912). This asymmetry is the single most non-obvious finding in this deep-dive, quoted directly from the executable example's own inline comments.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines) — grepped the full file with `grep -in "badi\|enhancement spot\|fallback"`. **Zero hits for "BAdI" or "enhancement spot" anywhere in the file**; the one "fallback" hit (line 838) is an unrelated CDS access-control term (`FALLBACK ASSOCIATION` in a `GRANT SELECT` statement), not BAdI-related.

## Deliberately not fabricated / left as pointer only

- `IF_BADI_CONTEXT` / context-dependent BAdI instantiation (`GET BADI ... CONTEXT`) — the source cheat sheet itself states this "is not covered in this cheat sheet. Refer to the documentation for more details." Not included beyond the base skill's existing scope.
- Classic-BAdI-framework version history (SE18/SE19-era) — out of scope; base SKILL.md and `badi-walkthroughs.md` already correctly frame classic BAdIs/explicit enhancements as legacy-maintenance-only.

## Live-URL check

| URL | Status |
|---|---|
| `https://github.com/SAP-samples/abap-cheat-sheets/blob/main/35_BAdIs.md` | 200 |
| `https://help.sap.com/docs/abap-cloud/abap-development-tools-user-guide/enhancement` | 200 |
| `https://api.sap.com/` (new URL introduced in this deep-dive) | 200 |

All live — no fix needed for this skill.
