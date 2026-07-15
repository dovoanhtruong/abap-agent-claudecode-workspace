# Sources — Deep-Dive Research Trail (`abap` skill)

Research conducted 2026-07-14 for Phase 2 of the ABAP dev skill enrichment initiative (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`). `sap-docs-extend-mcp` was unreachable for the entire session (`Server sap-docs-extend-mcp unavailable`) — fell back to `curl`-fetching the official SAP-samples cheat sheets directly (public GitHub repo, no auth), the same approach the Phase-1 pilots (`modern-abap-syntax`, `rap`) used.

## Primary sources retrieved

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines) — release-news digest, split into "ABAP for Cloud Development" (lines 32–2925) and "Standard ABAP" (2926+) sections. Used for every release-number claim below.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/04_ABAP_Object_Orientation.md` (9,129 lines) — read for OO constructs (abstract classes, interfaces, `FRIENDS`, `PARTIALLY IMPLEMENTED`) to check whether any are genuinely newer/gated; also cross-referenced to find *where* to look in the release-news file.
- `https://api.github.com/orgs/abapedia/repos?per_page=100` and `https://api.github.com/search/repositories?q=steampunk-api+org:abapedia` — used to verify currency of the `steampunk-2302-api` dependency pinned in this skill's existing `references/abaplint.md`.

## Release-number mapping method

Same method as the Phase-1 pilots: grep `33_ABAP_Release_News.md` for the topic keyword, note the line number, then map it to the nearest **preceding** `<summary>🟢 Release NNN [(QQQQ)]</summary>` header via a one-off Python script. **Correction to the Phase-1 pilots' method, found and fixed this session**: my first version of the mapping script only matched headers with a parenthesized quarter (`Release NNN (QQQQ)`), silently skipping headers without one (`Release NNN` — used for pre-quarterly-cadence releases, both in the early "ABAP for Cloud Development" section, e.g. `Release 765`/`766`, and throughout "Standard ABAP", e.g. `Release 610`, `Release 740`). This caused at least one wrong mapping in my own first pass (the `TYPES BEGIN OF ENUM` finding was briefly mis-mapped to 767/1702 instead of its correct nearest header, `Release 765`). Fixed by matching `summary>.*Release (\d+)(?:\s*\((\d+)\))?` instead. **This same gap was present in the Phase-1 pilots' mapping scripts** — confirmed post-hoc by the Manager, who re-verified every Phase-1 finding against the corrected script; all release-number claims held up, only the human-readable calendar-quarter glosses needed correcting in a few places (see `modern-abap-syntax`'s and `rap`'s own `sources-deep-dive.md` for that separate correction).

I did **not** attempt to translate the raw `(QQQQ)` code into a "20XX Q_N_" calendar-quarter label (the Phase-1 pilots did this, e.g. "789 (2208 / 2022 Q2)") — the source file's own note only says "the numbers in brackets describe quarterly releases," without stating the exact month→quarter-label convention, and I could not verify one this session. Findings below are cited using the raw `Release NNN (QQQQ)` form only, deliberately omitting an unverified quarter-label gloss. (Post-hoc note from the Manager: the convention is a fixed formula — `02`→Q1, `05`→Q2, `08`→Q3, `11`→Q4 — verified and applied consistently once discovered; this file's choice to omit the gloss entirely was a reasonable caution given the uncertainty at the time, not an error.)

## Verified findings

| Finding | Source location | Release |
|---|---|---|
| `TYPES ... BEGIN OF ENUM` (enumerated types) | `33_ABAP_Release_News.md` line 2574, Cloud section | Release 765 (no quarter suffix — predates the quarterly cadence, i.e. older than the earliest quarterly release 767/1702) |
| `RAISE EXCEPTION oref` — operand position for `oref` becomes a general expression position (enables `RAISE EXCEPTION NEW cx_...( )` directly) | `33_ABAP_Release_News.md` line 2476, Cloud section | Release 767 (1702) — earliest quarterly cloud release tracked in this file |
| `FRIENDS` concept (`CLASS ... DEFINITION ... FRIENDS`) and `INTERFACES ... ABSTRACT METHODS` / `FINAL METHODS` / `DATA VALUES` additions | `33_ABAP_Release_News.md` lines 7530–7535, Standard ABAP section | Release 610 (pre-quarterly; NetWeaver-era, well before ABAP Cloud existed) |
| `INTERFACES ... PARTIALLY IMPLEMENTED` (test-double support) | `33_ABAP_Release_News.md` line 5846, Standard ABAP section | Release 740 (2013-era classic ABAP, same generation as `VALUE`/`COND`/inline declarations) — not found anywhere in the Cloud section, consistent with the modern-abap-syntax pilot's negative-finding pattern (baseline because it predates the Cloud documentation window) |
| `steampunk-2302-api` (pinned in `abaplint.md`'s Steampunk/BTP starter config) is not the newest available dependency snapshot | GitHub API: `abapedia` org repo list includes `steampunk-2305-api`, `steampunk-2305-api-intersect-702`, `steampunk-2305-api-intersect-740` — the `-intersect-702` variant's `updated_at` timestamp was within the last few months of this research session | N/A (community-maintained repo, not an ABAP release) |

## Explicitly unverified / not pursued

- The exact semantics of the `abapedia/steampunk-*-intersect-*` repo naming (what "intersect with 702/740" precisely guarantees about API compatibility) — read that repo's own README (`"intersection with 702, really based on 2111, manual changes: removed ENUMs, cl_abap_regex & cl_abap_matcher, DOMA TZNTSTMPL, CLAS /UI2/CL_JSON"`) but did not find an authoritative SAP-side explanation of the intersect methodology. The deep-dive flags this as `[unverified — community project]` rather than asserting a specific guarantee.
- Did not re-verify `CleanABAP.md`'s own content line-by-line (192KB, already the verbatim official style guide) — treated it as ground truth per the task's instruction to focus on genuinely new value, not an audit of existing content.
