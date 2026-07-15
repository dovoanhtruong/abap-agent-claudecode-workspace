# OData Service Development — Deep Dive

Read this for version-gating on the BDL/SDL constructs that actually shape OData behavior, the concurrency-control (ETag) topic missing from the base skill entirely, service-binding decision criteria beyond the existing protocol table, and troubleshooting additions. Nothing below repeats the base SKILL.md's service-definition/binding recipe or the OData Client Proxy code — read that first. Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

## Version Safety on ABAP Cloud Targets

The OData protocol-level feature history ($apply, deep create/update semantics, the OData Client Proxy factory methods) is **not tracked** in the ABAP Keyword Documentation release-news digest at all — it documents ABAP language/CDS/BDL syntax, not the SAP Gateway/RAP-runtime protocol layer. Don't invent a release number for those; verify directly in ADT (API State) if a TS depends on one against an unconfirmed target. What **is** verifiable — the BDL/SDL constructs that drive real OData-visible behavior:

| Feature | Introduced | Practical impact if unavailable |
|---|---|---|
| `EXTEND SERVICE` (service definition extensions) | Release 789 (2208 / 2022 Q3) | Add the extra `expose` entries directly in the base service definition instead of a separate extension |
| `PROVIDER CONTRACTS` statement for service definitions | Release 789 (2208 / 2022 Q3) | No stricter syntax check on which binding types are valid for the service — rely on manual review instead |
| Repeatable RAP actions/functions (`repeatable`, extra `%cid` component) | Release 789 (2208 / 2022 Q3) | The same action/function can only be called once per RAP BO instance within a single ABAP EML or OData request — a Fiori app batching several calls to the same custom action in one `$batch` request will fail on the second call |
| `static default factory` action (evaluated by OData as the standard create action) | Release 790 (2211 / 2022 Q4) | No implicit default create action for OData to fall back on — the UI must call a named factory action explicitly |
| `with managed instance filter` on projection/interface BDEFs (evaluated for EML **and** OData requests) | Release 793 (2308 / 2023 Q3) | The instance filter only applies to ABAP-side EML consumers, not to OData Web clients — a filter meant to hide certain instances from the Fiori app silently doesn't |
| Draft Action `Activate` `optimized` addition | Release 793 (2308 / 2023 Q3) | Omit it — draft activation still works, just without the recommended speed-up |
| Draft Action `AdditionalSave` | Release 793 (2308 / 2023 Q3) | No custom saving strategy hook for draft instances — the standard draft save sequence is the only option |
| `with draft` (draft support itself) | Release 781 (2008 / 2020 Q3) | The BO cannot be draft-enabled at all — Fiori Elements object pages needing draft won't work |
| RAP Collaborative Draft (`with collaborative draft`) | Release 916 (2508 / 2025 Q3) | Very recent — don't assume multi-user concurrent draft editing works; standard draft still enforces one editor at a time via the exclusive lock |
| CDS service definitions exposing AMDP procedure implementations (`EXPOSE METHOD`) | Release 914 (2502 / 2025 Q1) | Niche/advanced — not available for exposing a raw AMDP procedure as a business-service operation on an older target |

## Concurrency Control (ETag) — Missing From the Base Skill

Not mentioned anywhere in the current `SKILL.md`. This is exactly what makes OData `PATCH`/`PUT` concurrency-safe, and it's a BDL construct, not an OData-layer bolt-on:

```abap
//ETag for optimistic concurrency control
etag master some_etag_field
etag dependent by _Assoc
total etag some_total_etag_field
```

- **Optimistic concurrency (`etag`)**: the `etag` field logs the last-change timestamp/value of an instance. For a modify operation to be accepted, the **OData client must send an `If-Match` header with the ETag value it last read**, compared against the stored value — a mismatch means someone else changed the record since, and the request is rejected rather than silently overwriting.
- **Managed BOs get this for free**: mark the ETag field with `@Semantics.systemDateTime.localInstanceLastChangedAt: true` (type `utclong`/`timestamp`/`timestampl`, recommended read-only in the BDEF) and the framework maintains it automatically. **Unmanaged BOs need custom ETag handling** in the save sequence — there's no framework default to fall back on.
- **`total etag`** is mandatory only for draft-enabled BOs — it's what lets a resumed draft instance be compared against its active counterpart to decide whether resuming is still safe (the active instance is exclusively locked while a draft exists; once that lock expires, `total etag` governs the optimistic phase). Required annotation: `@Semantics.systemDateTime.lastChangedAt: true`. Use a **different field** for `total etag` than for `etag master`.
- This pairs with (not replaces) pessimistic locking (`lock master`/`lock dependent by`) — see [Skill: rap] for the locking side; this deep-dive only covers the OData-visible ETag half.

Decision cue: don't skip the ETag annotation on a managed BO just because it "still works without it" — without `@Semantics.systemDateTime.localInstanceLastChangedAt`, the OData layer has no optimistic-concurrency protection at all, and two Fiori users editing the same record back-to-back will silently overwrite each other instead of one getting a conflict.

## Service Binding Type — Decision Criteria Beyond the Protocol Table

The base SKILL.md's table covers *what* each binding type is; here's *when* to reach for which:

- **Bind the same service definition twice** (one `OData V4 - UI` + one `OData V4 - Web API` binding object) when the same RAP BO needs both an interactive Fiori app and a machine-to-machine (A2X) consumer — don't create two separate service definitions for this; the CDS/BDEF layer stays single-source-of-truth and only the binding differs.
- **`InA - UI`** is the right choice specifically when the exposed entity is a genuine analytical artifact — a CDS view with `PROVIDER CONTRACT ANALYTICAL_QUERY` (see [Skill: cds-analytical-views]'s CDS Analytical Projection View note, 786/2111+) — not a regular list-report projection view. Binding a plain aggregated CDS view entity as `InA - UI` doesn't give you SAC/Analysis-for-Office-style multi-dimensional consumption; the underlying view has to be modeled for it.
- **V4 over V2 for anything new** (already in the base table) — the one case worth a second look is an existing Fiori Elements template/library version that was scaffolded against V2 and hasn't been re-generated; verify the floorplan actually supports V4 before assuming a drop-in protocol swap is free.

## `external` Alias — a Second, Distinct Naming Knob

The base SKILL.md says "Alias names become OData entity set names" for the service definition's `expose ... as Alias` — that's the SDL-layer alias. There's a **separate, BDEF-layer** alias mechanism:

```abap
define behavior for some_entity alias root
  external some_external_name
```

`external some_external_name` sets the name exposed specifically in the **OData metadata**, independent of the `alias` used inside the ABP/BDEF-derived-types layer. Reach for it when the BDEF-internal alias (used in handler method signatures) needs to differ from what the OData consumer should see — e.g., keeping a stable, business-friendly external name while refactoring the internal alias.

## Troubleshooting Additions

| Error / Issue | Solution |
|---|---|
| `412 Precondition Failed` on a modify request | Stale ETag — the record changed since the client last read it (or the client never sent `If-Match`). Re-fetch and retry; never suppress this by skipping the ETag check. |
| Draft instance can't be edited by a second user even though "collaborative draft" was expected | Confirm target release ≥ 916 (2508 / 2025 Q3, see version table) — standard (non-collaborative) draft always enforces single-editor exclusive locking; collaborative multi-user draft is a distinct, much newer opt-in (`with collaborative draft`). |
| Same custom action fails on the 2nd call within one `$batch` request | Action/function isn't marked `repeatable` (789/2208+, see version table) — without it, a RAP BO entity instance can only have that action/function invoked once per EML/OData request. |
| A Fiori-created record doesn't call the action you expected on "New" | Check whether a `static default factory` action is defined and whether the target release supports it (790/2211+) — without it there's no implicit default create action for OData to select. |

## OData Client Proxy — Version History (Negative Finding)

Could not find any release-news entry for `/iwbep/cl_cp_client_proxy_fact` or "client proxy" in general across the entire release-news digest (both Cloud and Standard ABAP sections) — no verifiable introduction release. Don't state a version claim for it; if a TS needs to confirm availability on an old/unconfirmed target, check ADT's API State tab directly rather than inferring from this silence.
