# RAP — Deep Dive

Read this for the decision criteria and version history the SKILL.md body and the other three reference files (`bdef-templates.md`, `behavior-pool-templates.md`, `eml-quick-reference.md`) don't cover — this file doesn't repeat their templates. Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

## Version Safety

Several BDL constructs that feel foundational are newer than RAP itself — verify availability before designing a TS around them on an older or unconfirmed target release:

| Feature | Introduced | If unavailable |
|---|---|---|
| `with additional save` / `with unmanaged save` in a **managed** BO | Release 778 (1911 / 2019 Q4) | Redesign as a fully unmanaged BO, or move the extra persistence logic into a determination instead |
| `numbering:managed` (framework-generated UUID key) | Release 779 (2002 / 2020 Q1) | Implement early or late numbering manually instead |
| `determine action` (on-demand determinations/validations) | Release 781 (2008 / 2020 Q3) | Trigger the same logic via a regular action that calls the determination's logic directly |
| Nested determinations on modify (one determination-on-modify triggering another) | Release 782 (2011 / 2020 Q4) | Consolidate the chained logic into a single determination |
| Early numbering usable inside a **managed** BO (was unmanaged-only originally) | Release 783 (2102 / 2021 Q1) | Only rely on early numbering in a fully unmanaged BO |
| `CL_ABAP_BEHAVIOR_SAVER_FAILED` usable in ABAP Cloud (C1-released for the ABAP for Cloud Development language version — see the late-save-phase pattern below) | Release 794 (2311 / 2023 Q4) | Not available on an older/unconfirmed target — there is no supported escape hatch for a late-phase failure in that case, so the design must guarantee the early save phase (`finalize`/`check_before_save`) catches every possible failure before it, and avoid wrapping anything unpredictable (a BAPI, an external call) inside `save_modified` |
| Late numbering for **managed**/draft-enabled BOs (was unmanaged-only originally) | Release 786 (2111 / 2021 Q4) | Use managed internal numbering (`numbering:managed`) or unmanaged early numbering instead |
| `notrigger[:warn]` field characteristic | Release 790 (2211 / 2022 Q4) | Guard against determination-loop risk manually — check `%control` before re-triggering logic |

## Managed vs Unmanaged (decision criteria)

The SKILL.md body states the definitions; here's the concrete decision:

- **Default to managed** for any brand-new BO on a Z-table designed alongside it. The framework's standard CRUD, transactional buffer, and save orchestration are correct out of the box — you only write actions/validations/determinations.
- **Go unmanaged only when** you're wrapping existing business logic that already owns persistence (a legacy function-module-based save, a BAPI-driven process) and reimplementing it as managed CRUD would mean re-deriving logic that already works correctly elsewhere. Unmanaged means YOU implement every standard operation's handler method — there is no framework default to fall back on for `create`/`update`/`delete`.
- **A managed BO with `with additional save`** is the middle ground, not a compromise — use it when 95% of the persistence is standard CRUD but one specific side-effect (writing to a Z-log table, calling a legacy update FM) needs to happen in the same LUW. Don't reach for `with unmanaged save` just for one extra write — that discards the entire standard save sequence, not just extends it.
- **A managed BO with `with unmanaged save`** replaces the save sequence entirely while keeping the managed interaction-phase buffer — reach for this only when the actual persistence must go through a legacy path (e.g., a BAPI that both validates and saves) that can't be decomposed into "framework does CRUD, my code adds one side-effect."

## Numbering Strategy (decision tree)

| Situation | Use |
|---|---|
| New UUID-keyed entity, no legacy key format to match | `numbering:managed` — framework generates the UUID, zero custom code (779/2002+) |
| Key must be a business-meaningful, sequential, or externally-supplied value known **before** save (e.g., a number-range value the user sees during the interaction phase) | **Early numbering** — implement a `FOR NUMBERING` handler method |
| Key must be sequential/gap-free and can only be finalized in the same LUW as the commit (classic accounting-document-style numbering) | **Late numbering** — implement `adjust_numbers` in the saver class; only viable once you've confirmed it's available for your BO type at your target release (see table above) |
| Draft-enabled BO needing early numbering | Confirm target release ≥ 783 (2102) if it's a managed BO — this combination didn't exist before then |

Don't default to late numbering out of habit — it's the most complex option (implemented in the saver, tied to the save-sequence internals) and should only be chosen when the numbering genuinely cannot be resolved before the commit phase.

## Determination Trigger Timing — `on modify` vs `on save` vs `determine action`

The SKILL.md body's Best Practices line ("determinations = derived/calculated fields on modify") doesn't cover the full picture — there are three distinct trigger mechanisms with different use cases:

- **`determination X on modify { field ... }` / `{ create; }`**: fires immediately during the interaction phase whenever the trigger condition is met — the recalculated value is visible to the user before save. Use for anything the UI should reflect live (a total that updates as line items change).
- **`determination X on save { create; }`**: fires once, right before the save sequence — use for values that are expensive to compute or only meaningful at commit time (a final approval timestamp, a computed hash of the final state). Never use `on save` for something the UI needs to show interactively — it won't be there yet.
- **`determine action`** (781/2008+): lets a caller trigger a *specific set* of determinations/validations on demand via an explicit action call, rather than relying on a field-based trigger condition firing automatically. Use this when the trigger is a user-initiated event that isn't naturally expressible as "field X changed" — e.g., an explicit "Recalculate" button in the UI, or a `Prepare` draft action that must run a defined validation set before allowing `Activate` (this is exactly how `bdef-templates.md`'s `draft determine action Prepare { validation validateDescription; }` block works — that IS a determine action, just one the framework wires in automatically for drafts).
- **Chaining** (nested determinations on modify, 782/2011+): one `on modify` determination can trigger another. Use sparingly — a chain of 3+ determinations reacting to each other is a common source of "why did this field change twice" bugs. If you find yourself chaining more than two levels, consolidate into one determination instead.
- **`notrigger[:warn]`** (790/2211+): mark a field with this if it must never appear in a validation/determination trigger condition — typically a field a determination itself writes to, to make an accidental self-triggering loop a hard error (or warning) instead of a runtime surprise.

## Real Code Pattern: Unmanaged Save with an Actual Persistence Call

`behavior-pool-templates.md`'s saver class skeleton is comment-only. Here's what a real `save_modified` looks like when it's actually persisting something (e.g., writing a header + item table pair via a released API/EML down to the DB, or invoking a legacy update FM the BO wraps):

```abap
CLASS lsc_root IMPLEMENTATION.

  METHOD save_modified.
    " Database modifications are ONLY allowed here (the late save phase) —
    " not in finalize/check_before_save, and RAISE EXCEPTION is forbidden in
    " every RAP transaction phase, so by the time execution reaches here the
    " early phase (finalize/check_before_save) must have already guaranteed
    " this data is consistent. Treat a DB-level failure at this point as the
    " exceptional case it is — see the CL_ABAP_BEHAVIOR_SAVER_FAILED note below.
    LOOP AT create-root INTO DATA(new_root).
      INSERT zroot_tab FROM CORRESPONDING #( new_root ).
    ENDLOOP.

    LOOP AT update-root INTO DATA(changed_root).
      UPDATE zroot_tab FROM CORRESPONDING #( changed_root ).
    ENDLOOP.

    LOOP AT delete-root INTO DATA(deleted_root).
      DELETE FROM zroot_tab WHERE root_uuid = @deleted_root-RootUUID.
    ENDLOOP.
  ENDMETHOD.

  METHOD cleanup.
    " Clear any buffers/state built up during finalize/check_before_save —
    " this runs after save_modified regardless of success, so don't assume
    " save_modified completed when writing this method.
  ENDMETHOD.

ENDCLASS.
```

**Late-phase failure is a documented special case, not something to raise your way out of.** `RAISE EXCEPTION` is disallowed in every RAP transaction phase (interaction, early save, late save) — a saver method can never leave a RAP transaction that way. The basic rule is that failures must be caught in the early save phase (`finalize`/`check_before_save`), never surface for the first time in the late phase. The one documented exception: if `save_modified` wraps something outside RAP's control that can still fail this late (a BAPI call, for instance), inherit the saver class from `CL_ABAP_BEHAVIOR_SAVER_FAILED` instead of the usual `CL_ABAP_BEHAVIOR_SAVER` — this lets you fill RAP response parameters so BO consumers can react, and `COMMIT ENTITIES` reports it via `sy-subrc = 8`. After a late-phase failure the RAP BO consumer needs an explicit `ROLLBACK ENTITIES` before any further operation, or the next one risks a runtime error.

**This escape hatch is itself release-gated** — `CL_ABAP_BEHAVIOR_SAVER_FAILED` only got its C1 release contract for the ABAP for Cloud Development language version at release 794 (2311 / 2023 Q4, see the version table above). Before that release, this class isn't a supported option in ABAP Cloud at all — there is no clean way to surface a late-phase failure, which makes airtight early-phase validation not just best practice but the only real safety net on an older target.

Message pattern using a T100 message class instead of `new_message_with_text` (prefer this for anything user-facing and translatable — `new_message_with_text` produces a hard-coded, untranslated string):

```abap
APPEND VALUE #( %tky = entity-%tky
  %msg = new_message( id       = 'ZCX_ROOT_MSG'
                       number   = '001'
                       severity = if_abap_behv_message=>severity-error
                       v1       = entity-Description )
  %element-Description = if_abap_behv=>mk-on
) TO reported-root.
```

`new_message_with_text` (as shown in `behavior-pool-templates.md`) is fine for a quick internal/debug-facing message; anything a business user sees should go through a proper T100 message class so it's translatable and consistent with the rest of the system's messaging.
