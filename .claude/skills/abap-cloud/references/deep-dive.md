# ABAP Cloud — Deep Dive

The SKILL.md body already covers the 3-tier model and the headline language restrictions; this file adds **concrete "is X allowed" edge cases** verified against the official cheat sheets, plus a real piece of release-contract history. It deliberately does **not** re-expand the unreleased→released replacement table (that trim was a deliberate Phase 0 decision — see `[Skill: abap-cloud-migration]` for the full tables). Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

## "Is X Allowed in ABAP Cloud" — Concrete Edge Cases

The SKILL.md's Key Restrictions list is accurate but high-level (no `CALL TRANSACTION`, no classic list output, etc.). The official cheat sheet's own "nonsensical example" class — written specifically to trigger every syntax error/warning ABAP for Cloud Development would raise — surfaces several **specific statement-level restrictions not yet in the SKILL.md**:

| Statement | Status in ABAP for Cloud Development | Use instead |
|---|---|---|
| `MOVE num3 TO num1` | Invalid | The assignment operator (`num1 = num3`) |
| `DESCRIBE TABLE itab LINES num_lines` | Invalid | `lines( itab )` |
| `GET REFERENCE OF num1 INTO ref2` | Deprecated | `ref2 = REF #( num1 )` |
| `cl_salv_table=>factory( ... )` (classic ALV) | Not released — `cx_salv_msg` is not released either | No released ALV equivalent for a classic list-style grid inside ABAP Cloud code itself; render tabular data via a Fiori Elements List Report / RAP projection instead |
| `READ REPORT 'ZCL_...' INTO code` | Not allowed | N/A — reading another program's source is a classic-ABAP-only capability |
| `sy-uzeit`, `sy-datum`, `sy-timlo` | Not allowed | `CL_ABAP_CONTEXT_INFO` or `XCO_CP_TIME`/`XCO_CP` — see `[Skill: released-abap-classes]`'s deep-dive Date/Time section for the concrete decision between them |
| `WRITE 'hi'` / `BREAK-POINT` | Grouped by the source as invalid alongside the items above | `if_oo_adt_classrun`'s `out->write( )` for output; use ADT breakpoints (click left of the line number) instead of the `BREAK-POINT` statement |

These are on top of, not replacing, the SKILL.md's existing bullet list (`CALL TRANSACTION`, `SUBMIT`, `EXEC SQL`, classic BAdIs, `INCLUDE` programs, dynpro/selection screens — all still accurate, not re-verified again here since they weren't in question).

## The Subtler Case: a Released (C1) Class Can Still Warn

**This is the genuinely non-obvious finding** — being C1-released does not mean *any* type that happens to be structurally compatible is safe to use with that API. The cheat sheet's own example: `CL_ABAP_PROB_DISTRIBUTION` (C1-released) has a method `get_uniform_int_distribution` that expects a range table typed `if_abap_prob_types=>int_range`. At the time the example was written, a manually declared `TYPE RANGE OF i` was structurally identical — but using it instead of the API's own named type produces a **syntax warning**, not a clean compile, specifically because *"an API may be extended in the future, which can affect its usage... the type might be extended in the future, potentially breaking the code."*

```abap
"Triggers a syntax warning despite being C1-released and currently type-compatible:
TYPES ty_range TYPE RANGE OF i.
DATA(range) = VALUE ty_range( ( sign = 'I' option = 'BT' low = 1 high = 10 ) ).
DATA(dist) = cl_abap_prob_distribution=>get_uniform_int_distribution( range = range ).

"Clean — no warning:
TYPES ty_range TYPE if_abap_prob_types=>int_range.
```

**Decision criterion this establishes**: when consuming a released API's method signature, always reference the API's own named types (via `TYPE REF TO`, `LIKE`, or the API's own type group/interface constant) rather than a manually declared type that merely happens to match today — even on a fully C1-released, currently-compiling class. The release contract guarantees the API's *behavior*, not that its type shapes are frozen forever; a future-safe caller couples to the named type, not to today's structural shape.

## Release-Contract History: C0 Requirements for DDIC Developer Extensibility Are Not Static

The SKILL.md mentions release contracts (C0, C1) only as an aside. One verified, concrete history point from `33_ABAP_Release_News.md`:

- **Release 785 (2108)**: five new extensibility annotations (`@AbapCatalog.enhancement.fieldSuffix`, `.quotaMaximumFields`, `.quotaMaximumBytes`, `.quotaShareCustomer`, `.quotaSharePartner`) became **required for C0 release of a DDIC object** — itself a prerequisite for developer extensibility on that object.
- **Release 795 (2402)**: two of those five (`.quotaShareCustomer`, `.quotaSharePartner`) were removed and are **no longer available or required**.

Practical takeaway: "what a DDIC object needs to qualify for C0 release" is not a fixed checklist — it changed between these two releases. If a TS's extensibility requirement cites a specific annotation set from older documentation or a colleague's memory, verify against the current release rather than assuming the requirement list is stable; this is exactly the kind of thing that goes stale silently.

## Tier-Model Terminology History — Negative Finding

Searched `33_ABAP_Release_News.md` (8,016 lines, both the "ABAP for Cloud Development" and "Standard ABAP" sections) case-insensitively for `tier`: **zero matches**. The 3-tier extensibility model's terminology (Tier 1/2/3, "Cloud API enablement," etc.) is evidently not tracked in the ABAP Keyword Documentation's release-news channel — it's SAP's own developer-relations/marketing framing for the extensibility strategy, not a language-level release event. No verified date for when this terminology was formalized or changed is available from this source family; don't infer one. If this history genuinely matters for a future write-up, it would need to come from SAP Help Portal versioned documentation or blog history, not this release-news digest.
