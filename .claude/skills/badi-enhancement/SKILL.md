---
name: badi-enhancement
description: Help with BAdI (Business Add-In) development and the ABAP enhancement framework — new and classic BAdIs, enhancement spots/implementations, filter-based BAdIs, fallback classes, implicit/explicit enhancement points, extending SAP standard code. Triggers: "create/implement/find a BAdI", "enhancement spot", "BAdI filter", "fallback class", "extend standard", "custom logic injection", "enhancement framework". For the extensibility tier model and key-user extensibility use abap-cloud.
---

# BAdI & Enhancement Framework

Guide for extending SAP standard functionality via BAdIs. Recipes and decision tables here; full code in [references/badi-walkthroughs.md](references/badi-walkthroughs.md) — read it when actually writing the objects.

## New vs. Classic BAdIs

| Aspect               | New BAdI Framework              | Classic BAdI Framework |
| -------------------- | ------------------------------- | ---------------------- |
| **Transactions**     | ADT or `SE18`/`SE19`            | `SE18`/`SE19`          |
| **Enhancement Spot** | Required container              | Not applicable         |
| **Multiple Use**     | Configurable (single- or multiple-use, via a checkbox on the BAdI Definition) | Configurable |
| **Filter**           | Filter types supported          | Filter values          |
| **Fallback Class**   | Supported                       | Not available          |
| **ABAP Cloud**       | Supported (released BAdIs only) | Not available          |
| **Recommendation**   | Use for all new development     | Maintain existing only |

**In ABAP Cloud, only SAP-released BAdIs can be implemented** — search in ADT with `api:badi`. Classic BAdIs, user exits, and implicit/explicit enhancements are unavailable; touching Standard objects is blocked by workspace rule §2 regardless.

## Creating a Custom BAdI (recipe)

1. **Enhancement Spot**: ADT → New → Enhancements → Enhancement Spot (`Z_ENH_SPOT_*`).
2. **BAdI Interface**: `zif_badi_*` with the extension method signatures (+ `RAISING cx_badi_not_implemented`).
3. **BAdI Definition** inside the spot: name, interface, multiple-use flag, optional filter types.
4. **Fallback Class** (optional but recommended): implements the interface with default behavior — callers then never need to handle "no implementation".
5. **Call site**: `GET BADI lo_badi [FILTERS f = val].` then `CALL BADI lo_badi->method ...` — CALL BADI loops through all active implementations.

## Implementing an Existing BAdI (recipe)

1. **Find it**: ADT search / `SE18` / breakpoint at `CL_BADI_INTERNAL_FACTORY=>GET_BADI` during the process / SAP docs. Cloud: `api:badi` search only.
2. **Enhancement Implementation**: ADT → New → Enhancements → Enhancement Implementation, assigned to the spot.
3. **Implementation class**: implements the BAdI interface; register it in the enhancement implementation (+ filter values if filtered).

## Best Practices

1. Prefer the new BAdI framework; use filters to scope implementations to specific contexts.
2. Provide fallback classes for default behavior.
3. One concern per implementation; test each with [Skill: abap-unit-testing].
4. Classic explicit/implicit enhancements: legacy-maintenance-only knowledge — details in the reference file, out of scope for new Clean Core work.

## Deep Dive

For the signature constraint that actually drives single-use vs. multiple-use (why multiple-use can only have IMPORTING/CHANGING), the filter-resolution search order, fallback-class design guidance, the `api.sap.com` Explore-catalog discovery route, `FILTER-TABLE`/`PARAMETER-TABLE` dynamic calls, and BAdI-specific exception handling (including a single-use/multiple-use asymmetry when calling through an initial reference), read [references/deep-dive.md](references/deep-dive.md).

## References

- [references/badi-walkthroughs.md](references/badi-walkthroughs.md) — interface/fallback/implementation/dynamic-call code + classic enhancement syntax
- BAdI Cheat Sheet: https://github.com/SAP-samples/abap-cheat-sheets/blob/main/35_BAdIs.md
- Enhancement Framework: https://help.sap.com/docs/abap-cloud/abap-development-tools-user-guide/enhancement
