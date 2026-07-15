# BAdI & Enhancement Framework — Deep Dive

Read this for the single-use/multiple-use signature constraint the base SKILL.md's table doesn't explain, the filter-resolution search order, fallback-class design guidance, a real "finding the right BAdI" strategy beyond `api:badi`, and BAdI-specific exception handling — none of this duplicates `references/badi-walkthroughs.md`'s create/implement/dynamic-call code. Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

## Version Safety — a Negative Finding

**`GET BADI`/`CALL BADI` syntax, enhancement spots, filters, and fallback classes are not tracked anywhere in `33_ABAP_Release_News.md`'s "ABAP for Cloud Development" section** — zero hits for "BAdI", "enhancement spot", or "fallback" across the entire 2,894-line Cloud digest. The kernel-based BAdI framework predates the tracked release-news window entirely (it's a classic-ABAP-era mechanism carried into ABAP Cloud, not a Cloud-era addition), so treat the language mechanics as baseline on any real ABAP Cloud target — don't hedge on `GET BADI`/`CALL BADI` availability.

**The real version axis for cloud BAdI work is per-object, not global**: whether a *specific* BAdI definition has a C1 release contract for ABAP Cloud (searchable via `api:badi` in ADT, per the base SKILL.md) is decided per BAdI, not by an ABAP kernel release number. There is no single "release NNN" table to build for this — verify each candidate BAdI's own release status in ADT rather than assuming a pattern from one BAdI applies to another.

## Single-Use vs. Multiple-Use — the Signature Constraint That Drives Everything Else

The base SKILL.md's table lists single/multiple use as a property to configure; it doesn't say **why** the choice matters beyond "how many implementations can be active." The actual constraint, verified from the official cheat sheet:

- **Multiple-use BAdI methods can only declare `IMPORTING` and `CHANGING` parameters** — never `EXPORTING`/`RETURNING`. With zero-to-N implementations executing in sequence for one `CALL BADI`, there is no single "the" result to return; `CHANGING` lets each implementation sequentially alter a shared data object instead.
- **Single-use BAdI methods can have `RETURNING`/`EXPORTING` output parameters** — because exactly one implementation (or the fallback) runs per call, there's always exactly one result to produce.

Decision cue: if the extension point genuinely needs to *return a value the caller consumes* (a calculated result, a validation verdict), it must be single-use — multiple-use isn't just "less common" for this case, it's structurally impossible to get a return value from. If the extension point is "let every registered implementation react" (multiple independent converters, multiple independent checks that each append to a shared message table), multiple-use with `CHANGING`-only parameters is the natural fit — this is exactly why `badi-walkthroughs.md`'s implementation classes use `CHANGING ct_messages` rather than a `RETURNING` result.

## Filter-Based vs. Non-Filter — Decision Table

Filters and single/multiple-use are two independent dimensions; combine them deliberately:

| Situation | Configuration |
|---|---|
| Different implementations should apply to different business contexts distinguishable by a discrete runtime value (country, document type, org unit), and exactly one should win per context | **Single-use + filter** — the framework resolves to exactly one matching implementation (or the fallback) per filter value |
| The extension point is genuinely context-independent and only one implementation should ever exist | **Single-use, no filter** |
| All currently-registered implementations should run together, independent of context (a chain of independent validations/converters that don't conflict) | **Multiple-use, no filter** — this is `badi-walkthroughs.md`'s converter example (XML + JSON implementations both fire on every call) |
| Multiple-use **with** a filter | Technically possible but rarely meaningful — multiple-use already means "run everything registered"; adding a filter narrows which subset runs per context, useful only if some implementations are context-scoped and others aren't |

## Filter Resolution Order (verified, undocumented in the base skill)

When `GET BADI`/`CALL BADI` executes, the runtime searches in this order: **(1)** active implementation classes matching the filter criteria, **(2)** if none match, standard (SAP-delivered) implementations, **(3)** if still none, the fallback class if one exists. This is the mechanism behind "why did my fallback run" — it's not a first-resort, it's the last one, and only reached when no matching implementation (custom or standard) exists at all.

## Fallback-Class Design Guidance

- **Only meaningful for single-use BAdIs** — the source explicitly recommends a fallback "for scenarios where no (default) BAdI implementation is found or when the caller-provided filter values do not match existing filters." Multiple-use has no single "the" fallback slot — a caller of a multiple-use BAdI just needs to treat "zero implementations executed" as a valid, unremarkable outcome.
- **Design it to hold a genuine default business behavior, not a stub.** It runs on the exact same call path as a "real" implementation whenever nothing else matches — a `RAISE cx_badi_not_implemented`-only fallback just moves the "nothing happened" problem to every caller's `CATCH` block instead of solving it once. Reserve `cx_badi_not_implemented` for a case where there truly is no sensible default and callers are expected to handle that explicitly — don't make it the fallback's default behavior out of laziness.
- It must implement the **same BAdI interface** as every real implementation — it's a peer, not a special case, from the framework's point of view.

## Finding the Right BAdI — Beyond `api:badi`

The base SKILL.md's search recipe stops at `api:badi` in ADT. Two additional, verified entry points:

1. **api.sap.com Explore catalog**: go to `https://api.sap.com/`, choose **Explore** → **Categories** → **Business Add-Ins (BAdIs)**, filter by keyword/business area. This is a browsable catalog of released BAdIs across the whole SAP Cloud ERP surface — useful when you know the business process but not the exact BAdI name to search for in ADT.
2. **`api:badi` in ADT, keyword-filtered by the business object/process name** — the base skill's existing recipe, best used once you have a specific term (e.g., "travel", "sales order") from step 1 or the FS.

The classic-ABAP discovery route (breakpoint at `CL_BADI_INTERNAL_FACTORY=>GET_BADI`) doesn't apply in ABAP Cloud — there's no ADT breakpoint access into SAP standard/backend code from a cloud tenant, so the two routes above are the real cloud-era search strategy.

## Dynamic BAdI Calls — Deeper Pattern (`FILTER-TABLE`/`PARAMETER-TABLE`)

`badi-walkthroughs.md`'s dynamic example only varies the BAdI/method *name* dynamically while the filter and parameters stay static. When the filter values or parameter shape are **also** only known at runtime (a generic dispatcher that resolves both the BAdI and its filter/parameter binding from configuration), use the table-based additions instead:

```abap
"Dynamic GET BADI with a filter table (type badi_filter_bindings: name/value pairs)
DATA(filter_tab) = VALUE badi_filter_bindings(
  ( name  = CONV badi_filter_name( 'OPERATOR' )
    value = REF #( lv_operator ) ) ).

GET BADI badi_dyn TYPE (lv_badi_name) FILTER-TABLE filter_tab.

"Dynamic CALL BADI with a parameter table (type abap_parmbind_tab)
DATA(ptab) = VALUE abap_parmbind_tab(
  ( name = 'NUM1'   kind = cl_abap_objectdescr=>exporting value = NEW i( 10 ) )
  ( name = 'NUM2'   kind = cl_abap_objectdescr=>exporting value = NEW i( 5 ) )
  ( name = 'RESULT' kind = cl_abap_objectdescr=>returning value = REF #( dyn_result ) ) ).

CALL BADI badi_dyn->(lv_method_name) PARAMETER-TABLE ptab.
```

Decision cue: reach for `FILTER-TABLE`/`PARAMETER-TABLE` only when the filter/parameter *shape itself* is dynamic (unknown field count/names at compile time) — for a fixed, known parameter list with only the BAdI/method name resolved at runtime (the common case, and what `badi-walkthroughs.md`'s existing example covers), the plain dynamic form (`EXPORTING`/`RECEIVING` with static parameter names) is simpler and should stay the default.

## Exception Handling (missing from the base skill entirely)

Three distinct exception sources, easy to conflate:

- **`cx_badi_filter_error`** — raised by `GET BADI` itself when a required filter wasn't supplied (or a filter table was left initial/unbound for a BAdI that requires filters). Framework-level, not something the implementation class controls.
- **`cx_badi_initial_reference`** — raised by `CALL BADI` when invoked through a BAdI reference variable that is `CLEAR`ed/initial. **Asymmetry worth knowing**: this exception is only raised when the reference variable's static type refers to a **single-use** BAdI. For a **multiple-use** BAdI, calling through an initial reference is a silent no-op — no exception, no effect, nothing executes. Don't assume "no error" means "it ran."
- **`cx_badi_not_implemented`** (as declared on the interface method in `badi-walkthroughs.md`) — this is a **design-time choice by the interface author**, not a framework-raised exception. It signals "this implementation intentionally has no behavior for this case" and every caller of `CALL BADI` still needs its own `TRY`/`CATCH` for it if any registered/fallback implementation might raise it.
- Dynamic calls add two more from the general dynamic-programming family: `cx_sy_dyn_call_param_missing` (wrong/missing parameter name in a dynamic `CALL BADI`) and `cx_sy_dyn_call_illegal_method` (nonexistent method name passed dynamically).

```abap
TRY.
    GET BADI lo_badi.
    CALL BADI lo_badi->validate
      EXPORTING is_travel   = ls_travel
      CHANGING  ct_messages = lt_messages.
  CATCH cx_badi_filter_error INTO DATA(lx_filter).
    "Required filter not supplied / doesn't match any implementation
  CATCH cx_badi_initial_reference INTO DATA(lx_initial).
    "Only reachable for a single-use BAdI reference — see asymmetry note above
ENDTRY.
```
