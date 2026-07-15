# ABAP Unit Testing — Deep Dive

Read this for what the SKILL.md body and the two existing reference files (`test-class-patterns.md`, `test-environment-examples.md`) don't cover: a dynamic test-double alternative to the manual double already documented, an interface addition that removes friction from that manual double, external/global test classes, the version-safety picture, how to design diverse/realistic test scenarios (boundary value analysis, RAP-specific categories, a concrete "how many scenarios" stopping rule), and how to record/analyze results and report completion vs. goal plus limitations. This file doesn't repeat either existing reference's skeletons. Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

## Version Safety on ABAP Cloud Targets

| Feature | Introduced | Practical impact if unavailable |
|---|---|---|
| Test Relations — the `"! @testing ...` ABAP Doc annotation linking a test class/method to the repository object it tests | Release 769 (1708) | No formal linkage between an external test class and its subject — document the relationship in a plain comment instead |
| `TEST-SEAM` / `TEST-INJECTION` | Release 760 (non-quarterly, pre-2017 baseline — see `references/sources-deep-dive.md` for why this counts as baseline) | Baseline; not a real version risk on any real ABAP Cloud target |
| `PARTIALLY IMPLEMENTED` addition to `INTERFACES` in a test class | Baseline (ABAP 7.40 era, Standard ABAP section, predates the Cloud documentation window entirely) | Baseline; not a real version risk |

The CDS/OSQL/RAP-BO test-double framework classes (`CL_CDS_TEST_ENVIRONMENT`, `CL_OSQL_TEST_ENVIRONMENT`, `CL_BOTD_TXBUFDBL_BO_TEST_ENV`, `CL_BOTD_MOCKEMLAPI_BO_TEST_ENV`, `CL_ABAP_TESTDOUBLE` below) could **not** be release-dated this session — the release-news digest tracks language/keyword changes, not class-library additions, so none of these classes appear in it at all. Treat their exact introduction release as `[unverified — could not confirm this session]`; if a target's release is old or unconfirmed and one of these classes doesn't resolve in ADT, that's the signal to ask, not a reason to assume a workaround.

## New Content: `CL_ABAP_TESTDOUBLE` — the Dynamic Alternative to a Manual Test Double

`test-class-patterns.md`'s "Manual Test Double" section (`ltd_data_provider` implementing `zif_data_provider`) is one valid approach, but it's not the only one, and the SKILL.md body doesn't currently distinguish when to reach for the other: the ABAP OO Test Double Framework generates a double from an interface at runtime — no local test-double class to write or maintain.

```abap
CLASS ltc_processor DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA test_double TYPE REF TO zif_data_provider.  "the generated double

    METHODS setup.
    METHODS test_process_with_data FOR TESTING.
ENDCLASS.

CLASS ltc_processor IMPLEMENTATION.
  METHOD setup.
    "Generates a double implementing zif_data_provider — no ltd_ class needed
    test_double = CAST zif_data_provider( cl_abap_testdouble=>create( 'ZIF_DATA_PROVIDER' ) ).
  ENDMETHOD.

  METHOD test_process_with_data.
    DATA(expected_data) = VALUE ztab_data( ( key = '1' value = 'A' ) ).

    " Arrange — configure what the double returns for the next call
    cl_abap_testdouble=>configure_call( test_double )->returning( expected_data ).
    test_double->get_data( ).   " "records" that returning( ) applies to this call

    DATA(cut) = NEW zcl_processor( io_provider = test_double ).

    " Act
    DATA(lv_result) = cut->process( ).

    " Assert
    cl_abap_unit_assert=>assert_not_initial( act = lv_result ).
  ENDMETHOD.
ENDCLASS.
```

**Decision criteria — manual double vs. `CL_ABAP_TESTDOUBLE`**:
- Reach for `CL_ABAP_TESTDOUBLE` when the interface is small/stable and the test only needs to stub a couple of return values — it removes the maintenance cost of a hand-written `ltd_*` class entirely.
- Fall back to the manual double (already in `test-class-patterns.md`) when the double needs to hold and mutate test-specific state across multiple calls in one test (e.g., a fake in-memory table the double appends to), or when the interaction itself is complex enough that configuring it call-by-call is more code than just writing the class.
- **Hard limitation, not a style choice**: `CL_ABAP_TESTDOUBLE` does not support local classes/interfaces, or a class declared `FINAL`, `FOR TESTING`, `CREATE PRIVATE`, or with a constructor that has mandatory parameters. Any of those means a manual double is the only option, not a preference.

## New Content: External Test Classes and the `"! @testing` Relation

Both existing reference files assume the test class lives in the local test include (`ltc_*`) of the class it tests. There's a second, legitimate shape: a **global** test class that tests another global class, linked via the `"! @testing` ABAP Doc annotation (769/1708+, table above) — typically combined with granting the production class's friendship to the test class so it can reach private members without a bridge method inside the production class itself.

```abap
"! @testing zcl_demo_aunit_external_cl
CLASS ztcl_demo_aunit_external_cl DEFINITION PUBLIC FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PUBLIC SECTION.
    METHODS test_public_calculation FOR TESTING.
    METHODS test_private_calculation FOR TESTING.
ENDCLASS.
```

Use this when the test class needs to be reusable/discoverable outside the one class pool it's testing, or when the production class's friend list is already managed centrally — not as a default; a local `ltc_` test include stays the norm per the SKILL.md's own "Best Practices" line.

## New Content: `PARTIALLY IMPLEMENTED` — Removing the Friction from a Manual Test Double

The manual test double pattern in `test-class-patterns.md` (`ltd_data_provider IMPLEMENTS zif_data_provider`) implicitly requires implementing every method of the interface, even ones the test never calls. The `PARTIALLY IMPLEMENTED` addition (baseline, table above) removes that requirement — genuinely useful the moment a DOC interface has more methods than a given test double needs to fake:

```abap
CLASS ltd_data_provider DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_data_provider PARTIALLY IMPLEMENTED.
    DATA mt_test_data TYPE ztab_data.
ENDCLASS.

CLASS ltd_data_provider IMPLEMENTATION.
  METHOD zif_data_provider~get_data.
    rt_data = mt_test_data.
  ENDMETHOD.
  " Any other zif_data_provider method is left unimplemented —
  " only a runtime error if the test under this double actually calls it.
ENDCLASS.
```

Decision cue: add `PARTIALLY IMPLEMENTED` whenever the DOC interface has 2+ methods and a given test double only exercises a subset — don't stub out unused methods with `ASSERT 1 = 0` or empty bodies just to satisfy the compiler.

## Decision Trade-offs (extends SKILL.md's "Choosing the Approach" table)

- The SKILL.md's table already routes "Class depends on other objects" to "Interface + constructor/setter injection + manual test double." That's still the right default; this file's addition is narrower: once you're already down that path, choose `CL_ABAP_TESTDOUBLE` vs. a manual `ltd_*` class by the criteria above, not by habit.
- Don't reach for an external/global test class (`"! @testing`) as a way to avoid writing proper constructor injection — it's a legitimate shape for a specific reuse/friendship scenario, not a shortcut around designing the class under test for testability in the first place.

## Designing Diverse, Realistic Test Cases (Beyond the Happy Path)

A test class that only exercises the nominal, expected input proves the code runs — it does not prove the code is correct at the edges where bugs actually live. This section is about **which scenarios to write**, not how to write the ABAP for a scenario (that's the SKILL.md body, `test-class-patterns.md`, `test-environment-examples.md`).

### Boundary Value Analysis & Equivalence Partitioning, applied to ABAP

General software-testing techniques, grounded here in a real ABAP example:

- **Equivalence partitioning**: group possible inputs into classes the code is expected to treat identically (e.g. "valid discount 1–99", "zero discount", "negative discount", "discount over 100"); one representative test per partition is enough — two values from the same partition add no new coverage.
- **Boundary value analysis**: put test cases exactly *on* the edges (minimum, maximum, one step below, one step above) — off-by-one and `<` vs `<=` mistakes concentrate there, not in the middle of a range.

The official SAP-samples cheat sheet's `zcl_demo_aunit_no_tdf_doc.calculate_price` is a real, verified worked example — its own doc comment describes the test class as covering "normal, boundary, invalid, rounding, and no data cases":

```abap
" Production logic (verbatim, 14_ABAP_Unit_Tests.md):
METHOD calculate_price.
  DATA(discount_percentage) = data_prov_price->get_discount( ).
  DATA(discount_factor) = CONV decfloat34( 1 - ( discount_percentage / 100 ) ).
  final_price = COND #( WHEN discount_factor < 0 OR discount_factor > 1
                        THEN round( val = current_price dec = 2 )
                        ELSE round( val = current_price * discount_factor dec = 2 ) ).
ENDMETHOD.
```

Its test class covers five distinct partitions/boundaries with five tests — `test_discount_15` (nominal), `test_discount_0` (lower boundary of valid partition), `test_discount_100` (upper boundary of valid partition), `test_discount_negative` (invalid partition, below 0), `test_discount_over_100` (invalid partition, above 100) — plus two more (`test_rounding_2_dec_a`/`_b`) testing the separate rounding branch at its own edges. Seven tests total, matching seven genuinely distinct things being verified — not seven arbitrary discount values.

**Applying the same technique to other common ABAP field shapes** (pattern, not a specific verified production class):

```abap
METHOD test_approval_required_at_threshold.
  " Boundary: exactly at the approval threshold — must require approval
  DATA(lv_result) = cut->check_approval_required( iv_amount = CONV decfloat34( '1000.00' ) ).
  cl_abap_unit_assert=>assert_true( act = lv_result msg = 'Amount exactly at threshold must require approval' ).
ENDMETHOD.

METHOD test_approval_not_required_just_below_threshold.
  " Boundary: one cent below the threshold — must NOT require approval
  DATA(lv_result) = cut->check_approval_required( iv_amount = CONV decfloat34( '999.99' ) ).
  cl_abap_unit_assert=>assert_false( act = lv_result msg = 'Amount just below threshold must not require approval' ).
ENDMETHOD.
```

- **`p`/`i` quantity or amount fields**: zero, a small positive value, the exact threshold in a business rule, and one cent/unit on each side of it.
- **Date range fields** (`BEGDA`/`ENDDA`-shaped): one day before start, exactly on start, exactly on end, one day after end, and same-day range if the business rule allows it.
- **Field length**: if a business rule caps a text field, test at exactly the max length and one character over.

### RAP-Specific Scenario Categories Beyond CRUD Happy Path

CRUD-happy-path tests (create, read back, update one field, delete) prove the framework wiring works. They don't exercise where custom logic — and bugs — actually live:

- **Status-machine / state transitions — valid vs. invalid attempts.** Test both: (a) the transition succeeds when the instance is in a state that permits it, and (b) attempting it from a state that does **not** permit it is rejected (`FAILED`/`REPORTED`, not silently accepted). This is what `features : instance` on an action is for — per the RAP BDL cheat sheet: *"Enables dynamic feature control for actions, allowing the action to be available only if certain preconditions regarding the instance state are met"* — implemented in the `get_instance_features FOR INSTANCE FEATURES` handler (already in `references/behavior-pool-templates.md` of the `rap` skill).
- **Action preconditions — instance vs. global.** `features : instance` (depends on the BO instance's own state) vs. `features : global` (*"Enables global feature control for actions, allowing availability only if specific global, RAP BO-external preconditions are met"*) are different handler methods (`FOR INSTANCE FEATURES` vs. `FOR GLOBAL FEATURES`) — test at least one true/false case for each kind actually used; instance-level coverage doesn't prove global-level coverage.
- **Determination timing (`on modify` vs `on save`).** See [Skill: rap]'s `references/deep-dive.md` ("Determination Trigger Timing") for the mechanism — not restated here. The test-design implication: an `on modify` determination's effect must be asserted as visible **immediately** after the triggering change (before save); an `on save` determination's effect must be asserted as visible only **after** save completes. Asserting on the wrong side of save is a common false-positive/false-negative test-design mistake.
- **Batch-safety — 2+ rows in one request, not just 1.** RAP handler methods take **tables** (`keys`/`entities`), because EML/OData can send multiple root instances per request. A single-row test cannot catch: code that reads only `entities[ 1 ]` instead of looping the full table; a `LOOP AT entities` that accumulates into a shared variable without resetting per iteration; or a validation that should reject only the specific invalid row but instead affects the whole batch. The RAP BDL cheat sheet's validation semantics are explicit: *"When inconsistent RAP BO instance data is rejected, the entire transactional buffer is rejected, including instances without inconsistencies. This 'all or nothing' approach ensures that a final commit to the database occurs only if all data is consistent."* — so the correct batch-safety assertion for a validation is "one invalid row correctly triggers all-or-nothing rejection with the right row identified in `reported`," not "each row is judged independently." A concrete test: call the same action/CREATE with two keys/entities — one that should succeed, one that should fail a validation — and assert `failed` names the correct row's `%tky`, `reported` carries a message attributable to that row, and the successful row's data wasn't corrupted by sharing a loop iteration with the failing one.

### Decision Rule — "How Many Scenarios Is Enough"

A concrete stopping rule, so "don't enumerate trivial/redundant cases" (per `tester-lead.md`) doesn't silently drift into either padding or under-coverage:

```
N = 1                          (one happy-path / nominal case)
  + B                          (one per genuinely distinct boundary — a threshold
                                 comparison, a range edge, a max-length cutoff)
  + R                          (one per distinct business-rule branch/partition —
                                 each IF/CASE arm the code treats differently)
  + 1                          (at least one clearly invalid/negative input case)
  + 1 if batch-safety applies  (2+ rows — RAP BOs whose actions/determinations/
                                 validations loop over keys/entities with real logic)
```

- **A test can satisfy more than one bucket at once** — count it once. The 100%-discount test above is simultaneously the upper boundary (`B`) and its own business-rule branch (`R`); it doesn't need a second near-duplicate test.
- **Two values in the same partition are one test, not two** — this is the concrete definition of "redundant," not a vague feeling of "too many tests."
- **A branch the code doesn't actually have doesn't get a test** — if there's no explicit check for it, confirm the code branches on it (or should, per the TS — in which case that's a TS gap to flag, not a test to silently add).
- **Worked check**: `calculate_price` has 1 nominal + 2 boundaries (0%, 100%) + 2 invalid partitions (<0, >100) + 2 rounding-branch edges = 7, matching the cheat sheet's actual 7 tests exactly. No 8th test (e.g. `discount = 50`) is needed — same partition as `test_discount_15`, no new assertion.
- **For RAP BOs**: add the batch-safety test only when the handler actually loops over `keys`/`entities` with row-sensitive logic (accumulation, first-row assumptions, cross-row validation) — a trivial 1:1 field-copy determination with no cross-row state doesn't need one.

## Recording and Analyzing ABAP Unit Test Results

This section covers what happens *after* a test class is written and run: how to read the result, how to read coverage, and — per `sap-dev-rule.md` §8 (no "should work" claims) and §11 (evidence floor) — how to report completion vs. goal without overclaiming.

### How Result Reporting Works in ADT

- Running a test (`Ctrl+Shift+F10`, or right-click → *Run as → ABAP Unit Test*) shows results in the **ABAP Unit** tab. A green check marks a passed test; a black "x" marks a failed one. Clicking a failed test opens the **Failure Trace** — either the `CL_ABAP_UNIT_ASSERT` assertion that failed or another error; a "Stack" list in the trace is double-clickable to navigate to the failing source location. Verified: SAP Help "Evaluating ABAP Unit Results" states short dumps are captured and shown in the Failure Trace as an error — i.e. an uncaught exception surfaces through the same Failure Trace as a failed assertion, not a separately labeled status.
- `CL_ABAP_UNIT_ASSERT=>SKIP` exists to "skip a test because of missing prerequisites" — the mechanism for a test that intentionally didn't run its assertions. **`[unverified]`**: the exact ADT label/icon for a skipped test (e.g. whether it's shown as "Aborted") could not be confirmed from a fetched source this session.
- **A test not executed due to RISK LEVEL/DURATION is a real, distinct mechanism** (verified, SAP Help "Test Attributes"): each system/client has a configured maximum risk level via transaction `SAUNIT_CLIENT_SETUP`. `CRITICAL` = "the test could change system settings or the Customizing"; `DANGEROUS` = "the test could change persistent application data"; `HARMLESS` = "the test has no effect on persistent data or system settings." Duration bands: `SHORT` < 1 min (default), `MEDIUM` 1-10 min, `LONG` 10-60 min — verified directly, "if a test run exceeds the expected execution duration, the test is stopped." Subclasses may only raise a superclass's risk level, never lower it (attempts are ignored with a warning). **`[unverified]`**: exactly what happens when a class's declared RISK LEVEL exceeds the client's configured maximum (skipped/blocked/errored) — no fetched source states the resulting behavior. One SAP Community thread title (page returned HTTP 403, unreadable) suggested BTP ABAP Environment/Steampunk systems restrict execution to `HARMLESS` only with no override — flag this as `[unverified — could not confirm from a fetched primary source]`, not fact.
- **Practical implication**: "no test failures" and "the test actually ran" are two different claims. Before reporting "N tests passed," confirm in the ABAP Unit tab that the count *executed* matches the count *defined* — a RISK LEVEL/DURATION mismatch, `SKIP`, or a class-level setup failure can all silently reduce the executed count.

### Code Coverage Measurement

Verified (SAP Help "Understanding the Code Coverage Display in the ABAP Unit Browser"):

- To measure: `Ctrl+Shift+F11`, or right-click → *Run as → ABAP Unit Test With...* → check **Coverage** → *Execute*. Results appear in the **ABAP Coverage** view.
- Coverage is three separate metrics, not one: *"The Coverage fields give you precise information on the code coverage at the procedure, branch, and statement levels."* Procedure (was the method entered at all), statement (which statements executed), branch (did each condition resolve both ways) are individually reportable.
- The ADT coverage view is *"a subset of the fields and functions offered by the Detail Display in the Coverage Analyzer (transaction `SCOV`)"* — the classic Coverage Analyzer transaction is a confirmed real name, and the ADT view measures the same underlying metric, not a separate tool.
- A coverage run measures only that specific unit-test run: *"The metrics show the code coverage by the unit tests alone. Other coverage statistics already recorded by the Coverage Analyzer are ignored."*
- **`[unverified]`**: green/red line-highlighting convention in the coverage view, and whether `SCOV` needs separate activation for the ADT-side measurement — neither confirmed from a fetched source this session.
- **Practical implication**: a coverage percentage is a real, measured number you obtain by actually running the Coverage option and reading the view — not something to estimate from the test code. Reporting a coverage number without having run it is exactly the bare claim `sap-dev-rule.md` §11 exists to block; record "coverage not measured this session" instead of guessing.

### Reporting Template: Completion vs. Goal

A reporting-discipline pattern (not a factual/citable claim) to fill in immediately after a run, per `sap-dev-rule.md` §12 (a test-writing claim is unverified until its output is actually read):

```markdown
### ABAP Unit Test Report — <object under test>

**Scope executed**: <N> of <M> planned scenarios ran.
(M = scenarios from the TS's test plan / this class's designed method count;
 N = what ADT actually reports as executed — confirmed by reading the ABAP Unit tab,
 not by counting METHODS ... FOR TESTING in the source.)

**Results**:
- Pass: <X> — <method names>
- Fail: <Y> — <method: exact assertion mismatch/exception, quoted from Failure Trace>
- Blocked / not executed: <Z> — <method: exact reason, e.g. "RISK LEVEL DANGEROUS above
  this client's SAUNIT_CLIENT_SETUP maximum", "SKIP: <message>", "class_setup raised an
  exception, all methods in the class did not run">

**Coverage** (only if the Coverage run actually executed):
- Statement: <N%> | Branch: <M%> | Procedure: <P%>
- If not measured: state "Coverage not measured" — do not estimate.

**Explicitly NOT covered by this run, and why**:
- <scenario> — requires live authorization context; test doubles don't exercise real IAM/PFCG.
- <scenario> — requires a real background job/commit boundary outside the test's LUW.
- <scenario> — requires cross-system integration; needs an integration/E2E test instead.

**Verdict**: <"All planned scenarios pass, N% statement / M% branch coverage, evidence at
<path>" — OR "PASS — unverified, user-accepted" (rule §11) — OR "FAIL: <Y> scenario(s)
failing, root cause under investigation">
```

"Blocked / not executed" is a distinct bucket from "Fail" — conflating a RISK-LEVEL-blocked test with a failed one overstates risk in one direction and hides it in the other. The "Explicitly NOT covered" section exists so a green run doesn't get reported as "fully tested" when whole categories (auth, real persistence, cross-system) were never exercised.

### Known Limitations — State These in Every Report

Structural properties of the tool, not defects to fix — a test report should name which apply so "green" isn't mistaken for "production-proven":

- **Test doubles don't exercise the real persistence/authorization layer.** The CDS/OSQL test environments and RAP BO doubles (`test-environment-examples.md`) stub the data/BO layer in-memory. A green test proves the logic behaves correctly against the data fed to it — not against real DB constraints (foreign keys, check tables, number-range buffers), real `AUTHORITY-CHECK`/DCL authorization, or real concurrency (lock objects). If the TS requires any of those, they need separate verification (manual ADT test against a real object, or an integration test).
- **Coverage percentage does not imply correctness.** 100% statement coverage means every statement executed at least once — not that every input combination or business rule was checked. A method can be fully statement-covered and still contain a wrong constant or comparison operator. Branch coverage is stronger (each condition resolves both ways) but still says nothing about *which* values hit each branch. Never equate "100% coverage" with "no bugs" — report it as the execution metric it is, alongside the actual pass/fail/blocked breakdown.
- **RAP BO test environments simulate the framework, not the database.** The transactional buffer double and mock EML API let a test exercise RAP handler/EML logic without a real BO instance — neither enforces real DB-level constraints, triggers, or standard-BO validations/determinations a Z/Y object might indirectly depend on. A green test here is evidence the RAP logic behaves as coded, not evidence the same flow behaves identically end-to-end against the live system — this is exactly why `sap-dev-rule.md` §5 (activation-guard) and manual verification remain necessary before a build step is marked DONE, even after a fully green suite.
- **A green suite is a floor, not a ceiling, of confidence.** State explicitly which of the above apply to the object under test — most Z/Y objects touching persistence or authorization will trigger at least the first one. This extends `sap-dev-rule.md` §8's "Activated ≠ Correct" framing to "Tested-green ≠ Correct."
