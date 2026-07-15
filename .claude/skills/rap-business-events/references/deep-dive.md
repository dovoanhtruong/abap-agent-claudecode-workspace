# RAP Business Events — Deep Dive

Read this for the raising-vs-consumption release gap, two producer/consumer patterns [references/event-code-examples.md](event-code-examples.md) doesn't show, and decision criteria for local-only vs. enterprise Event Mesh publishing. This file does not re-derive the base `event`/`RAISE ENTITY EVENT`/`FOR ENTITY EVENT` syntax already verified in `event-code-examples.md` — treat that file as ground truth for those. Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

## Version Safety

RAP business events did not all ship at once — raising, local consumption, and several event *types* were added across five separate releases:

| Feature | Introduced | If unavailable |
|---|---|---|
| RAP business events themselves — `event` definition in BDEF + `RAISE ENTITY EVENT` | Release 789 (2208 / 2022 Q3) | No business events at all on that target — model the notification as a regular action or a plain field-triggered side effect instead |
| Officially-documented local consumption mechanism: `METHODS ... FOR ENTITY EVENT`, `CLASS ... FOR EVENTS OF`, `CL_ABAP_BEHAVIOR_EVENT_HANDLER` | Release 792 (2305 / 2023 Q2) | Raising still works, but there's no documented local-handler-class mechanism yet — the only consumer would be whatever sits on the other side of an already-configured Event Mesh binding |
| RAP derived events (`managed event ... on ...`) and interface-BDEF event reuse (`use event`) | Release 793 (2308 / 2023 Q3) | Define each payload variant as its own independent event instead of one base event + derived redefinitions |
| RAP business events for child entities (previously root-only) | Release 796 (2405 / 2024 Q2) | Define the event on the root entity and carry the child's key/data as part of the payload instead |
| Event-driven side effects (`event ... for side effects`) | Release 914 (2502 / 2025 Q1) | Wire the reload manually — e.g., a regular field-triggered side effect on a status field the event handler itself updates, instead of the event triggering the reload directly |
| Enterprise Event Enablement / Event Mesh binding (BTP-service-level availability) | `[unverified — could not confirm this session]` | This is a communication-scenario/BTP-service capability, not a language construct — `33_ABAP_Release_News.md` doesn't track it. Check the target system's own Communication Scenario catalog (`SAP_COM_0092`) rather than assuming a date. |

**Notably, raising and locally consuming an event were not simultaneously documented.** There's roughly a 3-quarter gap (2022 Q3 → 2023 Q2) between `RAISE ENTITY EVENT` shipping and the officially-documented handler-class mechanism (`FOR EVENTS OF` / `CL_ABAP_BEHAVIOR_EVENT_HANDLER`) appearing in the release notes. On a target from that window, raising would work but the documented local-consumption pattern might not yet — check both independently rather than assuming one implies the other.

## Two Local Consumption Patterns Not Shown in event-code-examples.md

That file's "Local Event Consumption" section shows one pattern: a plain global class with a `FOR ENTITY EVENT ... FOR <Alias>~<event>` method. The official cheat sheet (`08_EML_ABAP_for_RAP.md`) documents the declaration part more fully, with two distinct forms:

```abap
"Global RAP event handler class — a standalone, independently reusable consumer
CLASS cl_event_handler DEFINITION PUBLIC FOR EVENTS OF some_bdef.
  ...
ENDCLASS.

"Local event handler class — implemented in the CCIMP include of a
"dedicated "RAP event handler class" ADT object, the same pattern as a
"behavior pool's CCIMP include for local handler/saver classes
CLASS lhe_event DEFINITION INHERITING FROM cl_abap_behavior_event_handler.
  ...
ENDCLASS.

"The handler method signature is the same either way — private
"instance method, no RAP response parameters:
METHODS meth FOR ENTITY EVENT par FOR some_bdef~some_evt.
```

Decision cue: reach for the global `FOR EVENTS OF` class when the consumer is a standalone, independently testable/reusable utility (e.g., one notification dispatcher several BOs' events feed into). Reach for the local class in a RAP event handler object's CCIMP include when the consumption logic is tightly scoped to one BO and you want it discoverable alongside that BO's other RAP artifacts.

**Flag, not a correction, on the existing skill content**: `event-code-examples.md`'s global-class example (`zcl_travel_event_handler ... PUBLIC FINAL CREATE PUBLIC`) doesn't show the `FOR EVENTS OF some_bdef` clause the official cheat sheet's declaration-part syntax includes for a global handler class. This deep-dive does not assert that example is wrong — compiler behavior wasn't checked against a live system this session — only that the fuller official form above includes a clause that snippet omits. Verify in ADT before assuming either form alone is complete.

**Also verified**: local RAP event handler methods execute **asynchronously** ("Note that these methods are called asynchronously" — `08_EML_ABAP_for_RAP.md`). This reinforces the existing SKILL.md's idempotency guidance with a concrete mechanism: don't assume a handler runs synchronously within, or immediately after, the triggering save.

## New Event Types: Derived Events and Side-Effect Events

```
event evt1;
event evt2 parameter SOME_ENTITY;
event evt3 deep parameter SOME_ENTITY;

managed event evt4 on evt1 parameter SOME_ENTITY;

event evt5 for side effects;
```

- **`deep parameter`** (vs. plain `parameter`): the payload's abstract entity must be one specified `with hierarchy`. Use for a payload that itself has a nested/hierarchical shape, not a flat structure.
- **RAP derived events** (`managed event <name> on <base_event> [parameter ...]`, 793/2308+): automatically raised whenever the referenced base event is raised, carrying its own (typically redefined/narrower) payload. Decision cue: use this instead of hand-raising two near-identical events when several consumers need different slices of the same underlying occurrence — one `RAISE ENTITY EVENT` call still drives both.
- **Events for side effects** (`event ... for side effects`, 914/2502+): needs no consumer class at all — specifying it as a `for side effects` target makes the *event itself* the trigger for reloading defined UI targets, the same mechanism as a field-triggered side effect but event-triggered instead of field-triggered. Decision cue: use this specifically when the reaction is "reload this UI facet/field in the same session." For anything needing real business logic (notification, related-record update) or crossing systems, that's still a handler class or Event Mesh, not a side effect.

## Decision: Local-Only vs. Enterprise Event Mesh

The SKILL.md body already lists the enablement steps; the actual decision criterion isn't there. Publish to Event Mesh only when a consumer genuinely needs to be **outside this ABAP system** (another BTP service, an on-prem system via Integration Suite, a non-SAP subscriber). If every consumer is same-system ABAP logic (updating a related Z-table, writing an application log, triggering a UI reload), a local handler class or a side-effect event is strictly less to configure and operate — no Event Binding, no Communication Arrangement, no topic versioning to maintain — and the commit-coupling guarantee (SKILL.md's Event Processing Flow) applies identically either way.

## Decision Trade-offs

- Derived events cut down on duplicate `RAISE ENTITY EVENT` calls, but every derived event is still a distinct topic once bound for Event Mesh — use them to avoid duplicating the *raise* logic for a shared underlying occurrence, not to avoid *designing* genuinely different payloads different consumers actually need.
- Side-effect events are the cheapest reaction mechanism when the goal is purely "reload this data in the UI" — reaching for a full handler class (local or global) for that case alone is more code than the requirement needs.
