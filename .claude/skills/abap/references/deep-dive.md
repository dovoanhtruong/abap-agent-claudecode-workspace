# ABAP (Lint + Clean ABAP Review) — Deep Dive

Read this for what the four existing reference files (`CleanABAP.md` — the verbatim official style guide, `checklist.md`, `quick-reference.md`, `abaplint.md`) don't cover: version-safety framing for a few checklist items that currently hedge without a concrete answer, a decision rule for when abaplint's configured target and Clean ABAP's recommendation disagree, an abaplint config-currency note, and one holistic worked review example tying the "Output Format" together end to end. Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

**Honest scope note**: `CleanABAP.md` is SAP's own complete style guide (192KB) and already gives concrete rationale for nearly every rule — this deep-dive does not re-argue anything it already covers well (e.g. `CX_STATIC_CHECK` vs `CX_NO_CHECK` vs `CX_DYNAMIC_CHECK` is already a fully worked decision tree there; not repeated here). What follows is genuinely additive.

## Version Safety

The honest finding here mirrors `modern-abap-syntax`'s pilot: **none of the Clean ABAP constructs this skill recommends are actually release-gated on a real ABAP Cloud target.** Every one checked this session either predates the ABAP Cloud documentation window entirely (classic ABAP, pre-2017) or sits at the earliest tracked cloud releases:

| Construct | Origin | Practical read |
|---|---|---|
| `TYPES ... BEGIN OF ENUM` (enumerated types) | Release 765 — before quarterly cloud releases even started (i.e. older than the earliest quarterly release, 767/1702) | `checklist.md`'s "ENUM used for enumerations (**if ABAP version supports**)" hedge can be dropped — it's baseline-available on every real ABAP Cloud target. Don't caveat it. |
| `RAISE EXCEPTION oref` accepted as a general expression position (the basis for `RAISE EXCEPTION NEW cx_...( )`) | Release 767 (1702) — the earliest quarterly cloud release tracked | Baseline-safe; `checklist.md`'s "RAISE EXCEPTION NEW instead of RAISE EXCEPTION TYPE" rule needs no version caveat |
| `FRIENDS` concept, `INTERFACES ... ABSTRACT METHODS` / `FINAL METHODS` / `DATA VALUES` additions | Standard ABAP Release 610 (NetWeaver-era, well before ABAP Cloud existed as a concept) | Ancient/baseline — no caveat needed for any OO-design recommendation built on these |

**Constructs this skill's examples lean on that ARE genuinely release-gated belong to `modern-abap-syntax`'s deep-dive, not this one** — `FINAL(...)` (789/2208+), `CORRESPONDING ... DEFAULT` (791/2302+), and the table-expression/`READ TABLE` harmonization (912/2408+) are the real version risks in "modern, clean" ABAP code. Don't re-derive them here: `[Skill: modern-abap-syntax]` → `references/deep-dive.md` has the verified table. This skill's own Language/Variables checklist items (inline declarations, `CORRESPONDING`, table expressions) should defer to that table when a target release is old or unconfirmed.

## Decision Rule: When abaplint's Target and Clean ABAP's Recommendation Disagree

This is genuinely this skill's own gap — neither `abaplint.md` nor `CleanABAP.md` addresses the case where the two halves of this skill (automated lint + manual review) point in different directions, and it comes up in practice: abaplint's `syntax.version` / dependency snapshot defines what the *target system* can actually run; Clean ABAP's recommendations assume the *language feature is available*.

- **If abaplint's configured target doesn't support a Clean-ABAP-recommended construct** (e.g. `syntax.version: "v750"` but the review would otherwise suggest `FINAL(...)`, which needs 789+): don't flag its absence as a Clean ABAP violation. Recommend the older-but-still-clean alternative (`DATA(...)` instead of `FINAL(...)`) and note *why* — the target release, not code quality, is the constraint.
- **If Clean ABAP review and abaplint disagree on something abaplint doesn't model at all** (style/naming/method length — abaplint checks syntax and configurable rules, not prose-level Clean ABAP judgment calls): abaplint's clean pass is not evidence the code is Clean-ABAP-compliant. Report both independently, as the `SKILL.md` Output Format already does — don't let a clean abaplint run soften a Clean ABAP finding's severity.
- **Never lower a Clean ABAP severity because abaplint didn't also catch it** — the two tools check different things by design (syntax/configurable-rule automation vs. style/design judgment); silence from one is not corroboration for the other.

## abaplint Config Currency (extends `abaplint.md`'s Steampunk/BTP starter config)

`abaplint.md`'s Steampunk/BTP starter config pins `https://github.com/abapedia/steampunk-2302-api` (a 2023 snapshot) as the dependency source. Verified this session via the GitHub API (`abapedia` org repo listing): newer per-quarter snapshots exist beyond that pin — `steampunk-2305-api` and its `-intersect-702`/`-intersect-740` variants are the most recently updated (one was touched within the last few months as of this research). The API surface genuinely differs release to release (new released classes, changed types), so:

- **Don't default to the example's `2302` pin** — match the snapshot to the target system's actual release quarter, or use whichever `abapedia/steampunk-*-api` repo is current at build time.
- If the exact target quarter has no matching snapshot, prefer the nearest **older** one over a newer one — a newer dependency snapshot can make abaplint accept APIs that don't actually exist yet on the older target, producing false negatives (silently missed cloud-readiness violations) rather than false positives.
- The `-intersect-702`/`-intersect-740` variants (community-maintained, not an official SAP artifact) attempt to model an API surface common to two syntax versions — treat their exact semantics as `[unverified — community project, not confirmed against official SAP documentation this session]` before relying on one for a compliance-critical check.

## Worked Example: Applying the Output Format End to End

`SKILL.md`'s Output Format section defines the report structure but doesn't show it populated. A realistic input, combining several real issues at once (the way actual legacy code usually presents, not one issue per snippet):

```abap
CLASS lcl_order_helper DEFINITION.
  PUBLIC SECTION.
    METHODS check_order
      IMPORTING iv_order_id TYPE vbeln
      EXPORTING ev_valid    TYPE char1
                ev_message  TYPE string.
ENDCLASS.

CLASS lcl_order_helper IMPLEMENTATION.
  METHOD check_order.
    DATA: lt_items TYPE STANDARD TABLE OF vbap WITH DEFAULT KEY,
          lv_count TYPE i.

    SELECT * FROM vbap INTO TABLE lt_items WHERE vbeln = iv_order_id.

    IF lt_items IS INITIAL.
      ev_valid = 'X'.
    ELSE.
      lv_count = lines( lt_items ).
      IF lv_count > 999.
        ev_valid = space.
        ev_message = 'Too many items'.
      ELSE.
        ev_valid = 'X'.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

Populated review (abbreviated to the pattern, not full prose):

```markdown
### Critical Issues
#### Error Handling - Return Code Instead of Exception
**Location:** Method check_order (EXPORTING ev_valid/ev_message)
**Problem:** Validity is signaled via EXPORTING char1 flag + string message instead of a class-based exception.
**Recommendation:** RAISE EXCEPTION NEW zcx_order_invalid( item_count = lv_count ) with a message class; or RETURNING a result structure if "invalid" is a normal, expected outcome rather than an error.
**Anti-pattern:** `EXPORTING ev_valid TYPE char1 ev_message TYPE string.`
**Clean code:** `RETURNING VALUE(result) TYPE zorder_validity.` or RAISING for genuine errors.

#### Tables - Magic Number
**Location:** IF lv_count > 999.
**Problem:** 999 is an unexplained magic number — a maintainer can't tell if it's a real business rule or a leftover test value.
**Recommendation:** Named constant, e.g. `co_max_items_per_order = 999`, ideally sourced from customizing if it's business-configurable.

### Major Issues
#### Tables - DEFAULT KEY
**Location:** DATA: lt_items TYPE STANDARD TABLE OF vbap WITH DEFAULT KEY.
**Problem:** DEFAULT KEY silently includes every column in the key, cheapest for the compiler to warn about and easy to fix.
**Recommendation:** WITH EMPTY KEY (no key operations needed here) or an explicit key.

#### Variables - Up-front Declarations
**Location:** DATA: lt_items ..., lv_count TYPE i.
**Problem:** Chained up-front DATA declaration instead of inline.
**Recommendation:** DATA(lt_items) at first use; DATA(lv_count) = lines( lt_items ).

### Minor Issues
#### Booleans - CHAR1/space instead of ABAP_BOOL
**Location:** ev_valid = 'X'. / ev_valid = space.
**Recommendation:** Type ev_valid as ABAP_BOOL, assign ABAP_TRUE/ABAP_FALSE — this is also what surfaces once the EXPORTING parameter above is redesigned as a RETURNING structure.

### Overall Assessment
Functionally correct, but the return-code-based error signaling (Critical) is the one finding worth blocking a merge on — it's a genuine testability/composability problem (callers must remember to check ev_valid; a raised exception cannot be silently ignored). The rest are habitual, low-risk style fixes.
```

This demonstrates the point `checklist.md`'s Priority Assessment makes in the abstract: one Critical finding (error handling) can matter more than several Major/Minor ones combined, and the report should say so explicitly in Overall Assessment rather than just listing counts.

## Decision Trade-offs

- **abaplint clean + Clean ABAP review clean, but they checked different things**: report both sections even when both come back clean — an empty abaplint findings list is not itself evidence of Clean ABAP compliance, and vice versa. Don't compress "both passed" into a single line; the user is relying on this skill to have actually run both checks, not inferred one from the other.
- **When to skip Clean ABAP review and only lint**: honor the user's explicit "just lint" request (per `SKILL.md`'s workflow step 1) even if you can see obvious Clean ABAP issues in the same snippet — don't silently expand scope. Mention them only as a one-line aside, not a full review section, if surfacing them at all.
