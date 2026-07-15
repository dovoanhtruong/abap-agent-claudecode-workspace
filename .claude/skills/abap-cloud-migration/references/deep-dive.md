# ABAP Cloud Migration — Deep Dive

Read this for what `SKILL.md`'s replacement tables and `references/wrapper-walkthrough.md` don't cover: a historical anchor for "since when has ABAP Cloud existed at all," a longer verified list of concretely invalid/deprecated constructs (sourced from SAP's own official demo of broken Cloud-restricted code, not inferred), a real "released API but still risky" trap, and a decision bridge to `atc-cloudification`'s Clean Core level table for the wrapper-vs-migrate call. Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

## Version Safety

**Honest framing, same shape as the other two pilots' finding**: "ABAP Cloud" as a distinct, restricted language version is itself a relatively young concept — it was introduced as Release 770 (1711) (internal version ID 5 in table `TRDIR`, column `UCCHECK`). Every real ABAP Cloud target (BTP ABAP Environment, S/4HANA Cloud Public/Private Edition) postdates this by years, so there is no "does my target even have the restricted language version" question to ask — it's baseline. This is here as a factual anchor (useful if a user asks "since when has this restriction existed"), not a version risk to hedge on.

No other finding in this deep-dive is release-gated in a way that matters for migration decisions — the real variable in migration work is never "is this classic construct available at my release," it's "does a released replacement exist for this *specific* object yet," which is a live, per-object fact (check `I_ApiStateOfRepositoryObject` / the Released Objects app, as `SKILL.md` already directs), not something a static table can answer once and for all.

## Concretely Invalid / Deprecated Constructs — Verified Additions to SKILL.md's Table

`SKILL.md`'s "Language Constructs" table already lists 10 incompatible constructs. Cross-checked against SAP's own official demo of *invalid* ABAP-for-Cloud-Development code (`19_ABAP_for_Cloud_Development.md`'s "Excursions" section — a real class SAP ships specifically to trigger every one of these errors/warnings when activated under the ABAP for Cloud Development language version). These are additional, verified findings not currently in the table:

| Construct | Status in ABAP Cloud | Replacement |
|---|---|---|
| `MOVE a TO b.` (as a plain assignment) | Invalid statement | `b = a.` |
| `DESCRIBE TABLE itab LINES lv_lines.` | Invalid statement | `lv_lines = lines( itab ).` |
| `GET REFERENCE OF a INTO ref.` | Deprecated | `ref = REF #( a ).` |
| `sy-uzeit` / `sy-datum` / `sy-timlo` (direct `sy-*` time/date fields) | Discouraged / not the intended API | XCO time library, e.g. `xco_cp=>sy->date( xco_cp_time=>time_zone->user )->as( xco_cp_time=>format->iso_8601_extended )->value` |
| `... USING CLIENT @client` addition on ABAP SQL | Not allowed in the restricted language scope | Omit — client handling in ABAP Cloud is implicit, not something application code specifies |
| `cl_salv_table=>factory( ... )` (classic ALV) | Not released (consistent with the existing table's "list output not available" entries — `WRITE`/`SKIP`/`ULINE`) | Fiori Elements UI |
| `READ REPORT '...' INTO tab.` (reading another program's source) | Not released | No equivalent — this class of introspection isn't available in ABAP Cloud |
| Dynamic SQL against a not-released/nonexistent data source, e.g. `SELECT ... FROM ('SPFLI')` where `SPFLI` isn't released | **Compiles with no syntax error** — fails only at runtime | Validate the dynamic data source with `cl_abap_dyn_prg` *before* using it dynamically; don't rely on ATC/compile-time checks to catch this class of issue |

**The last row is the one worth calling out as a genuine migration-workflow trap**: a legacy report that builds its `FROM` clause dynamically (a common pattern for "generic" reports) will NOT show up as a syntax error during migration, and may not even trigger every ATC Cloud Readiness finding, because the check operates on what it can statically resolve. "No ATC finding" is not equivalent to "cloud-safe" for dynamically-constructed data sources — that code path needs either a runtime existence/release check via `cl_abap_dyn_prg`, or conversion to a static, ATC-checkable `SELECT`.

## Released ≠ Type-Stable: the Manually-Reconstructed-Type Trap

Verified via the same official excursion source (its third code example, using `CL_ABAP_PROB_DISTRIBUTION`): a **Released (C1)** API can still produce a syntax **warning** on correct, working code, if the caller manually reconstructs the API's expected type instead of referencing the type the API itself publishes.

```abap
"Compiles and runs correctly today — but triggers a syntax warning:
"the API expects if_abap_prob_types=>int_range, not "any TYPE RANGE OF i".
"The two happen to be structurally identical right now; that's not a contract.
TYPES ty_range TYPE RANGE OF i.
DATA(range) = VALUE ty_range( ( sign = 'I' option = 'BT' low = 1 high = 10 ) ).
DATA(dist) = cl_abap_prob_distribution=>get_uniform_int_distribution( range = range ).

"Warning-free — reference the API's own published type directly
TYPES ty_range TYPE if_abap_prob_types=>int_range.
```

Decision cue for migration/replacement work: when swapping a classic construct for a released API, type the surrounding variables against the types **the API itself exposes** (its own nested `TYPE`s, not a "looks equivalent" elementary-type reconstruction). A clean ATC run today doesn't guarantee the code stays warning-free if SAP later changes the underlying type of a manually-duplicated declaration — and it's a completely avoidable risk, since referencing the published type costs nothing.

## Decision Bridge: Wrapper (Tier 2) vs. Direct Replacement vs. Redesign

`SKILL.md`'s wrapper-pattern summary doesn't currently connect to the Clean Core Level classification that `atc-cloudification`'s Cloudification Repository actually uses to classify every SAP object. Concrete decision, cross-referencing that table:

- **Level B (Classic API)** — usable only in Standard ABAP, no released successor exists (yet). This is the *only* case where a Tier 2 wrapper is the right call — wrap it, release the wrapper for C1, and plan to retire the wrapper once/if SAP ships a Level A successor.
- **Level C (Not to be released)** — a successor API is documented in the same JSON classification. Migrate directly to the successor; don't wrap a Level C object. Wrapping something that already has a known replacement just relocates technical debt into Tier 2 instead of removing it.
- **Level D (No API)** — no successor planned, not recommended even in Standard ABAP. Wrapping this is not really a "migration" — it's carrying forward something SAP itself flags as unrecommended. Treat a Level D finding as a signal to redesign that piece of logic, not merely relocate it behind an interface.

`[Skill: atc-cloudification]` has the authoritative level table and the live JSON sources to check an object's actual current level — check there before committing to "wrap" as the answer, since Level assignment can and does change between SAP releases (a Level B object today can become Level A once SAP releases the equivalent API).

## Decision Trade-offs

- **Programmatic release check vs. ADT UI check**: `SKILL.md`'s `SELECT ... FROM i_apistateofrepositoryobject` snippet is right for a batch/bulk migration-assessment pass (checking dozens of objects found by ATC in one query). For a single one-off "is this specific class released" question during hands-on migration work, the ADT Properties → API State tab is faster and also shows the release contract level (C0/C1/etc.) and successor info in one view — don't reach for a SQL query for a single lookup.
- **Migrating a dynamically-built data source**: per the finding above, treat any report/class that assembles its `SELECT ... FROM (...)` dynamically as needing a manual runtime-safety pass regardless of what ATC reports — this is a case where "the tool didn't flag it" genuinely isn't sufficient evidence of cloud-readiness, unlike the majority of findings which ATC does catch reliably.
