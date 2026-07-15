# Sources — Deep-Dive Research Trail (abap-unit-testing)

Research conducted 2026-07-14 for the ABAP dev skill enrichment initiative Phase 2 (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`). `sap-docs-extend-mcp` unavailable for this entire session, not retried — fell back to `curl`-fetching the official SAP-samples cheat sheets directly, same method the Phase 1 pilot used.

## Primary sources retrieved

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/14_ABAP_Unit_Tests.md` (4,617 lines) — read in full structurally (table of contents grepped first, then the "Handling Dependencies" → "Using ABAP Frameworks" sections in detail, plus the "Creating Test Classes" section for the `PARTIALLY IMPLEMENTED` addition and the executable-example section around lines 1560–1660 for the `CL_ABAP_TESTDOUBLE` code sample).
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines) — grepped for `TEST-SEAM`, `PARTIALLY IMPLEMENTED`, `test relation`, and the test-double-framework class names, using the same line-number-to-nearest-preceding-`Release NNN (QQQQ)`-header script as the other two drafts in this batch.

## Cross-checked against this workspace's existing files (to avoid restating what's already covered)

- `.claude/skills/abap-unit-testing/SKILL.md` — read in full.
- `.claude/skills/abap-unit-testing/references/test-class-patterns.md` — read in full; its "Manual Test Double" section (`ltd_data_provider`) is the baseline this deep-dive's `CL_ABAP_TESTDOUBLE` and `PARTIALLY IMPLEMENTED` additions build on/contrast with, not duplicate.
- `.claude/skills/abap-unit-testing/references/test-environment-examples.md` — read in full; CDS/OSQL/RAP-BO test environments are already covered there in more depth than this deep-dive adds, so this deep-dive does not touch that ground.

## Verified release-number claims

| Finding | Release (quarter) |
|---|---|
| Test Relations (`"! @testing ...` ABAP Doc comment linking a test class/method to a repository object) | 769 (1708) |
| `TEST-SEAM`/`TEST-INJECTION` introduced for ABAP Unit | 760 (non-quarterly header, within the "ABAP for Cloud Development" section's line range but below the 767/1702 threshold that marks the first quarterly Cloud release — see baseline reasoning below) |
| `PARTIALLY IMPLEMENTED` addition to `INTERFACES` in test classes | Found only in the "Standard ABAP Documentation Release News" section, nearest header release 740 (no quarter — ABAP 7.40 era) |

## Baseline reasoning (why 760/740-era findings are treated as non-risks)

Same reasoning the Phase 1 pilot (`modern-abap-syntax`) and this batch's `abap-sql-amdp` draft both use: `33_ABAP_Release_News.md`'s "ABAP for Cloud Development" section spans lines 32–2925, and within it the earliest **quarterly-numbered** release header is 767 (1702 / 2017 Q1) — a handful of older, non-quarterly headers (down to 760) appear in that line range as historical backfill but predate any real BTP ABAP Environment/S/4HANA Cloud system. `PARTIALLY IMPLEMENTED` doesn't even appear in the Cloud section at all — only in "Standard ABAP Documentation Release News" (line 2926+), at the equally old release-740 header. Both are therefore safely baseline for this workspace's targets.

## Addendum — 2026-07-15, Team Tester enrichment (test-case diversity/realism section)

Research conducted for `artifacts/scratchpads/scratchpad_tester-skill-enrichment.md`. `sap-docs-extend-mcp` confirmed down again this session (`search` → 404 route not found) — same `curl`-fallback method used.

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/14_ABAP_Unit_Tests.md` — `zcl_demo_aunit_no_tdf_doc.calculate_price` and test class `ltc_calculate_price` (7 test methods: `test_discount_15/0/100/negative/over_100`, `test_rounding_2_dec_a/b`) — verbatim, Manager independently re-fetched and grep-confirmed line numbers (`calculate_price` at line 1213, all 5 `test_discount_*` method names present) before integrating.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/36_RAP_Behavior_Definition_Language.md` — `features : instance`/`features : global` on actions (quoted definitions), validation "all or nothing" rejection semantics — Manager independently re-fetched and grep-confirmed the exact quoted sentences ("entire transactional buffer is rejected, including instances without inconsistencies", "Enables dynamic feature control for actions...", "Enables global feature control for actions...") before integrating.
- Handler method signatures (`FOR INSTANCE FEATURES`, `FOR ACTION`, `FOR CREATE` with table-typed `keys`/`entities`) cross-checked against this workspace's own `.claude/skills/rap/references/behavior-pool-templates.md` — confirmed present (paraphrased in the draft, not verbatim, but faithful to the actual signatures).
- Determination-timing test-design implication points to (does not restate) `.claude/skills/rap/references/deep-dive.md`'s existing "Determination Trigger Timing" section — confirmed that section exists as cited.
- General boundary-value-analysis/equivalence-partitioning definitions: `https://en.wikipedia.org/wiki/Boundary-value_analysis` — general QA background, explicitly not an SAP-specific claim.
- The generalized quantity/date-range/field-length boundary examples and the "how many scenarios" heuristic are original guidance authored for this workspace (not fetched from an external source) — they reuse only syntax already established elsewhere in this skill (`CONV`, `cl_abap_unit_assert=>assert_true/assert_false`, AAA structure).

## Addendum — 2026-07-15, Team Tester enrichment (result recording/analysis section)

Research conducted for `artifacts/scratchpads/scratchpad_tester-skill-enrichment.md`. `sap-docs-extend-mcp` confirmed down. Sources fetched directly (`curl`/`WebFetch`):

- `14_ABAP_Unit_Tests.md` (already this skill's primary source) — re-read the "Running and Evaluating ABAP Unit Tests" section for result-viewing/coverage-running UI mechanics (menu paths, `SKIP` method purpose) not previously extracted.
- SAP Help "Evaluating ABAP Unit Results" (`saphelp_nw75` mirror — the modern `help.sap.com/docs/ABAP_PLATFORM_NEW/...` equivalent returned a JS shell, unreadable) — direct quotes on green-check/black-x, Failure Trace capturing short dumps as errors.
- SAP Help "Understanding the Code Coverage Display in the ABAP Unit Browser" (`saphelp_snc700_ehp01` mirror) — direct quotes on the 3-level (procedure/branch/statement) coverage metric and the `SCOV` transaction relationship. Manager independently re-fetched this exact page via `WebFetch` and confirmed the duration-band quote (see below) before integrating.
- SAP Help "Test Attributes" (`saphelp_snc70` mirror) — direct quotes on RISK LEVEL definitions and DURATION bands. **Manager independently re-fetched this page and confirmed**: Short = "less than one minute, the default"; Medium = 1-10 min; Long = 10-60 min — this directly contradicted `SKILL.md`'s existing "SHORT < 1s" claim, which was corrected in the same pass (see below).
- Several `help.sap.com/docs/...` modern pages (ABAP-Cloud-specific unit-testing/coverage guide included) returned JS shells with no body — stated honestly as unreadable, not guessed from title.
- One SAP Community thread on Steampunk RISK LEVEL restriction returned HTTP 403 — its claim (Steampunk restricted to HARMLESS only) is carried as `[unverified — could not confirm from a fetched primary source]`, not fact.

**Live-content fix applied during integration (not just additive enrichment)**: `SKILL.md`'s "Test Class Attributes" table stated `DURATION SHORT` as "< 1s (default for CI)" — corrected to "< 1 min (default)" per the independently-verified SAP Help quote above. This is a real factual error in the existing skill, not a rephrasing.

Claims explicitly left `[unverified]` in the integrated content, per the zero-fabrication rule: exact ADT label for a skipped test; behavior when a class's RISK LEVEL exceeds the client's configured maximum; the Steampunk/BTP-restricted-to-HARMLESS claim; green/red line-coloring in the coverage view; whether `SCOV` needs separate activation. None of these are asserted as fact in `deep-dive.md`.

## Not independently verifiable this session

- `CL_ABAP_TESTDOUBLE`, `CL_CDS_TEST_ENVIRONMENT`, `CL_OSQL_TEST_ENVIRONMENT`, `CL_BOTD_TXBUFDBL_BO_TEST_ENV`, and `CL_BOTD_MOCKEMLAPI_BO_TEST_ENV` — zero matches for any of these class names in `33_ABAP_Release_News.md`. This is a structural limitation of the source, not a negative finding: the release-news digest tracks ABAP *language* changes (statements, additions, keywords), not class-library additions, so a released system class's introduction date simply isn't the kind of fact this document records. The deep-dive states this explicitly as `[unverified — could not confirm this session]` rather than guessing a plausible-sounding release/quarter, per the workspace's no-fabrication rule.
- The exact `CL_ABAP_TESTDOUBLE` code sample in the deep-dive (`cl_abap_testdouble=>create(...)`, `configure_call(...)->returning(...)`) is adapted directly from the working executable example at `14_ABAP_Unit_Tests.md` lines ~1607–1627 (`test_double = CAST zif_demo_aunit_price( cl_abap_testdouble=>create( 'zif_demo_aunit_price' ) )` / `cl_abap_testdouble=>configure_call( test_double )->returning( discount_percentage )`) — renamed to generic interface/class names to match this workspace's `zif_data_provider`/`zcl_processor` example already used in `test-class-patterns.md`, not invented from memory.
