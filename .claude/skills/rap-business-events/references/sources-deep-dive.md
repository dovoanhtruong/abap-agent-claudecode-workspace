# Sources — Deep-Dive Research Trail (rap-business-events)

Research conducted 2026-07-14 for the ABAP dev skill enrichment initiative Phase 2 batch 2 (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`). `sap-docs-extend-mcp` was reported unavailable for this entire session (not retried) — fell back to `curl`-fetching the official SAP-samples cheat sheets, plus targeted `WebSearch`/`WebFetch` for Event Mesh/Enterprise-Event-Enablement availability, which the cheat sheets don't cover.

**Ground-truth precedence honored**: this skill already has a verified, correct reference file — `.claude/skills/rap-business-events/references/event-code-examples.md` — read in full before any research began. This deep-dive does not re-derive or re-verify the base `event`/`RAISE ENTITY EVENT`/`FOR ENTITY EVENT` syntax that file already documents; it only adds the two consumption patterns and version-history/event-type findings that file doesn't cover.

## Primary sources retrieved (curl, public GitHub raw content, no auth)

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines) — grepped for `business event|event mesh|RAISE ENTITY EVENT|event binding|event consumption|enterprise event` (case-insensitive); each finding's line mapped to the nearest preceding `Release NNN (QQQQ)` header via the quarter-tolerant regex used across this initiative.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/36_RAP_Behavior_Definition_Language.md` (1,266 lines) — source for the exact `event`/`managed event`/`for side effects` BDL syntax block (lines 1115–1145).
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/08_EML_ABAP_for_RAP.md` (3,224 lines) — source for the "Raising RAP Business Events" section (lines 2628–2700): the two declaration-part forms (`CLASS ... FOR EVENTS OF`, `CLASS ... INHERITING FROM cl_abap_behavior_event_handler`), the asynchronous-execution note, and the `RAISE ENTITY EVENT` code pattern.

## Verified release-number claims

| Finding | Line (Cloud section) | Nearest header | Release (quarter) |
|---|---|---|---|
| "RAP Business Events" origin — `event` definition + native event-driven-architecture support | 1030 | 959 | 789 (2208 / 2022 Q3) |
| `RAISE ENTITY EVENT` statement — "It is now possible to raise a RAP entity event using this statement" (same release block as the origin above) | 1070 | 959 | 789 (2208 / 2022 Q3) |
| `RAISE ENTITY EVENT` (later, EML-topic restatement), `METHODS ... FOR ENTITY EVENT`, `CLASS ... FOR EVENTS OF`, `CL_ABAP_BEHAVIOR_EVENT_HANDLER` (all in the same release-792 EML table block) | 822, 826, 830, 834 | 784 | 792 (2305 / 2023 Q2) |
| Interface BDEF `use event` | 726 | 694 | 793 (2308 / 2023 Q3) |
| RAP derived events (`managed event`) | 730 | 694 | 793 (2308 / 2023 Q3) |
| RAP Business Events for Child Entities (previously root-only) | 529 | 502 | 796 (2405 / 2024 Q2) |
| Event-Driven Side Effects (`event ... for side effects`) | 320 | 292 | 914 (2502 / 2025 Q1) |

Verified directly by reading the raw table rows around each header (`sed -n` on the fetched file), not just the grep hit — confirmed the release-792 (2305) EML block genuinely contains a *second*, separate documentation of `RAISE ENTITY EVENT` alongside `METHODS, FOR ENTITY EVENT` / `CLASS, FOR EVENTS OF` / `CL_ABAP_BEHAVIOR_EVENT_HANDLER` / `CL_ABAP_TX`, distinct from the release-789 (2208) block that documents the feature's origin. This is a genuine gap between raising and documented local consumption, not a contradiction or duplicate error, since the release-792 entries name three consumption-specific artifacts that don't appear in the 789/2208 block at all.

Quarter mapping applied the fixed formula: `02`→Q1, `05`→Q2, `08`→Q3, `11`→Q4.

## New syntax found (verbatim quotes, not in event-code-examples.md)

- `08_EML_ABAP_for_RAP.md` lines 2643–2669 — the two declaration-part forms:
  ```abap
  CLASS cl_event_handler DEFINITION PUBLIC FOR EVENTS OF some_bdef.
  CLASS lhe_event DEFINITION INHERITING FROM cl_abap_behavior_event_handler.
  METHODS meth FOR ENTITY EVENT par FOR some_bdef~some_evt.
  ```
  and the note (line 2634): "Note that these methods are called asynchronously."
- `36_RAP_Behavior_Definition_Language.md` lines 1122–1128 — the full event-type syntax block:
  ```abap
  event evt1;
  event evt2 parameter SOME_ENTITY;
  event evt3 deep parameter SOME_ENTITY;
  managed event evt4 on evt1 parameter SOME_ENTITY;
  event evt5 for side effects;
  ```
  with the accompanying prose (lines 1136–1143) explaining `deep parameter` requires an abstract BDEF `with hierarchy`, and the derived-event/side-effect-event descriptions used verbatim in the deep-dive.

## Flag: possible gap in this workspace's existing ground-truth file (not corrected, only noted)

`event-code-examples.md`'s "Local Event Consumption" example (`CLASS zcl_travel_event_handler DEFINITION PUBLIC FINAL CREATE PUBLIC.`) does not include the `FOR EVENTS OF some_bdef` clause that `08_EML_ABAP_for_RAP.md`'s official declaration-part syntax shows for a global RAP event handler class. Per this task's explicit instruction, the ground-truth file's event syntax was **not** re-derived, re-verified, or altered — this is flagged here only as new supplementary information (the fuller official declaration form), not as a correction, since compiler-level correctness of the existing example was not checked against a live system this session. The deep-dive presents both forms and recommends verifying in ADT before assuming either alone is complete.

## WebSearch / WebFetch attempts for Event Mesh / Enterprise Event Enablement release history

- `WebSearch: "RAP business events Event Mesh release ABAP for cloud development introduced version"` — search-engine synthesis claimed "With the release 2208, SAP supports the native exposure and consumption of business events" — this number (2208) coincidentally matches this file's own independently-verified `33_ABAP_Release_News.md` finding for the RAP Business Events origin, so it is *not* treated as a separately-sourced confirmation of Event Mesh timing specifically, only as (weak, unverified) corroboration of the already-confirmed 789/2208 origin date.
- `WebSearch: "SAP_COM_0092 Enterprise Event Enablement communication scenario release available since"` — surfaced a candidate ("available since SAP S/4HANA Cloud 2008 release") sourced from a blog titled "What's new with Cloud 2008" — a title pattern ("what's new") that typically signals an *enhancement*, not first availability, so this claim was not trusted at face value.
- `WebFetch: https://blogs.sap.com/2020/08/19/sap-s-4hana-cloud-enterprise-event-enablement-whats-new-with-cloud-2008/` — attempted to verify whether 2008 was the origin or an enhancement release; **blocked (HTTP 403 Forbidden)**.
- Given the ambiguity and the blocked verification, Enterprise Event Enablement/Event Mesh binding availability is explicitly marked `[unverified — could not confirm this session]` in `references/deep-dive.md` rather than citing an unverified date.
