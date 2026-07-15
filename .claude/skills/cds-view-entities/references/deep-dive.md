# CDS View Entities (RAP Composition) — Deep Dive

Read this for the BDEF-side ETag/lock declarations that pair with the admin-field annotations SKILL.md already documents, draft-table requirements the base skill doesn't mention at all, and a release-history refinement of the association-vs-composition call. This file stays inside this skill's post-split scope (RAP composition mechanics) — general CDS authoring is [Skill: cds-analytical-views]'s territory and isn't duplicated here. Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

## Version Safety

| Feature | Introduced | If unavailable |
|---|---|---|
| `ROOT` addition + `COMPOSITION`/`TO PARENT` association types — the entire composition-tree vocabulary this skill teaches | Release 775 (1902 / 2019 Q1) | Not a realistic risk on any current ABAP Cloud target, but confirms composition trees as taught here (these exact keywords) postdate RAP's own earliest releases — an inherited pre-2019 BO on a very old system may use a different pattern |
| `link action`/`unlink action`/`inverse function` (non-standard operations for regular, non-composition associations) | Release 914 (2502 / 2025 Q1) | Regular associations stay a read-only relationship; for programmatic link/unlink behavior on an independent (non-composition) entity, implement it as a RAP action on the owning entity instead |
| RAP BO subentities usable as RAP authorization master (previously root-entity-only) | Release 796 (2405 / 2024 Q2) | The authorization master must be the root entity |
| Stricter association `ON`-condition rules shared by CDS custom entities (same DDL engine as view entities) | Release 916 (2508 / 2025 Q3) | Same finding as [Skill: rap-query-provider]'s deep-dive — relevant if a composition-tree-adjacent custom entity's associations suddenly fail to activate after a patch |

**Baseline — don't hedge on these regardless of target release**: `etag master`/`etag dependent by`/`total etag`, `lock master`/`lock dependent by`, and draft-table mechanics (`draft table`, `DRAFTUUID`, the `%admin` include) never appear anywhere in `33_ABAP_Release_News.md`'s Cloud-development section — the same reasoning this workspace's other deep-dives apply to `VALUE`/`COND`/etc.: they predate the quarterly release-tracking window entirely and are unconditionally available on any real target.

## BDEF-Side ETag and Lock Declarations (pairs with SKILL.md's Admin Field table)

SKILL.md's Admin Field Pattern table shows the CDS-side annotations (`@Semantics.systemDateTime.localInstanceLastChangedAt`, etc.) but not the BDEF declarations that actually wire them into optimistic concurrency control and draft resumability:

```
"In the root entity's behavior definition
lock master;
etag master LocalLastChangedAt;
total etag LastChangedAt;      "mandatory for draft-enabled BOs only

"In a child entity's behavior definition
lock dependent by _Parent;
etag dependent by _Parent;     "when the child defers to the parent's ETag
```

- `etag master <field>` — the field (matching the CDS `@Semantics.systemDateTime.localInstanceLastChangedAt` field, typed `utclong`/`timestamp`/`timestampl`) managed RAP BOs update automatically. An OData modify request must send this value back; a mismatch means someone else changed the instance first (optimistic concurrency control).
- `total etag <field>` — separate from `etag master`, used specifically for a draft instance's resumability check against its corresponding active instance. The source recommends using a **different** field than `etag master` for this.
- `lock master` goes on the root entity; every child entity must be `lock dependent by <association to the parent>` — pairs with `etag dependent by` on the same association.
- **Draft resumability mechanism** (not in SKILL.md at all): creating a draft exclusively locks the active instance for a configurable timespan, even across session termination. Once that lock expires, an *optimistic* lock phase begins — the draft can still be resumed as long as the active instance's `total etag` still matches what the draft recorded when it was created. This is the concrete reason `total etag` exists as a field distinct from the per-modify `etag master`.

## Draft Table Requirements (genuinely new topic — not in SKILL.md)

A draft-enabled BO needs a `draft table`, and it's not just "the same fields under a different table name":

- Must reflect the same fields as the underlying CDS entity, using the CDS view's **alias** names, with compatible types, plus a client field.
- Must additionally include `"%admin": include sych_bdl_draft_admin_inc;` — technical fields the RAP transactional engine needs for draft handling.
- **Late numbering specifically** needs one more key field: `DRAFTUUID` (16-character byte-like type) — not required for early-numbered draft BOs.
- Never access the draft table directly via ABAP SQL for read or modify — go through the RAP BO/EML, same rule as the persistent table.

Given how easy these are to get subtly wrong by hand, generate the draft table via ADT's "Enable Draft" quick fix rather than authoring it field-by-field.

## Composition vs. Association — Verified Reinforcement

Two concrete, sourced facts sharpen SKILL.md's decision table rather than restate it:

1. **Cascade delete is automatic, and composition-specific**: "Delete operations on RAP BO instances of the parent entity in managed RAP BOs also delete associated child entity instances that are in a composition relationship." This is the concrete mechanical reason composition is the right choice for genuine parent-child lifecycle dependency — a managed BO doesn't need hand-written cleanup logic for it, the framework cascades because the relationship is a composition, not because a determination was added to remember to do it.
2. **Behaviors are mandatory on the root, optional on children**: "You must specify an entity behavior definition for the root entity. Defining behaviors for child entities is optional." A child entity that's purely structural (no independent actions/validations, just fields exposed through the parent) doesn't need its own BDEF at all.
3. **2025 Q1 blurs the line slightly**: with `link action`/`unlink action`/`inverse function` now available for plain (non-composition) associations, a relationship needing *some* programmatic link/unlink behavior but explicitly not wanting automatic cascade-delete or default create-by-association no longer forces a choice between "composition with unwanted cascade behavior" and "an association with no programmatic behavior at all." Reserve composition for genuine lifecycle dependency — cascade delete is the tell; reach for a plain association + non-standard operations when the entities are independent but still need controlled linking.

## Authorization Master and Composition Design

Since release 796 (2405 / 2024 Q2), the RAP authorization master doesn't have to be the tree's root entity — a subentity can be designated instead. This is a composition-tree design decision (which node in the tree owns the authorization check) even though writing the actual DCL role stays [Skill: authorization-iam]'s job — worth knowing when the "true" business object of authorization interest in a tree isn't the technical root.

## Decision Trade-offs

- Don't add `total etag` to a non-draft-enabled BO — the source and SKILL.md's own table agree it's mandatory only for draft; a plain managed BO only needs `etag master`.
- The draft-table admin include and `DRAFTUUID` requirement are exactly the kind of DDIC-level detail that's easy to get wrong by hand — prefer the ADT quick fix over authoring it manually.
