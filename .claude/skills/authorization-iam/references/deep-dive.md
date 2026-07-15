# Authorization & IAM — Deep Dive

Read this for release-gating on the DCL/RAP-authorization additions, the three-way decision between the different "bypass authorization" mechanisms, and a worked example that actually chains DCL + IAM admin objects end-to-end — none of which the SKILL.md body or `references/rap-authorization-examples.md` currently cover. Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

## Version Safety on ABAP Cloud Targets

**The foundational mechanisms are all baseline-safe** — `AUTHORITY-CHECK OBJECT`, custom Authorization Objects/Fields, basic `aspect pfcg_auth(...)`, and basic `where inheriting conditions from entity ... association _X` all predate the earliest release documented in the Cloud release-news window. No real ABAP Cloud target (BTP ABAP Environment, S/4HANA Cloud) needs a version check for any of these.

What genuinely IS newer and worth checking before designing a TS around it:

| Feature | Introduced | If unavailable |
|---|---|---|
| DCL: `INHERITING CONDITIONS FROM SUPER` variant | Release 777 (1908 / 2019 Q3) | Use the existing entity-based `INHERITING CONDITIONS FROM ENTITY` form instead |
| RAP: `define authorization context` in a BDEF (scoped bypass of specific authorization objects) + `with privileged mode disabling` (supersedes the deprecated `with privileged mode`) | Release 789 (2208 / 2022 Q3) | No scoped bypass mechanism — the only options are per-operation `AUTHORITY-CHECK` logic or the blanket EML `PRIVILEGED` mode |
| DCL: identifier syntax for `ASPECT PFCG_AUTH(...)` params (no quotes needed) + SACF condition-set enable/disable via `pfcg_auth` | Release 785 (2108 / 2021 Q3) | Use string-literal syntax (`'THESCENARIO'`) instead of the bare identifier form — cosmetic only, not a capability loss |
| DCL: role-based inheritance `REPLACING` section + generic element replacement for `INHERIT role FOR GRANT SELECT` | Release 785 (2108 / 2021 Q3) | Entity-based inheritance (`INHERITING CONDITIONS FROM ENTITY`) still works; role-based inheritance replacement isn't available |
| `CL_ABAP_TX` (explicit Controlled-SAP-LUW phase control — relevant when an authorization-context-scoped bypass needs to align with a specific save phase) | Release 792 (2305 / 2023 Q2) | Rely on RAP's implicit phase management; don't try to force an explicit phase switch |
| RAP: `authorization:global`/`authorization:instance` at **action level** (overrides the entity-level `authorization master` for that action) | Release 792 (2305 / 2023 Q2) | Control authorization only at entity level; an action can't opt out of/into a different check than its entity's default |
| RAP: Authorization Context for Disable — `save:early`/`save:late` options (skip an authorization context's checks in specific save-sequence phases only) | Release 791 (2302 / 2023 Q1) | The disable addition still works but can't be scoped to early vs. late save phases specifically |
| DCL: `PRIVILEGED ACCESS` addition to disable CDS access control for a full ABAP SQL `SELECT` (syntax refinement of the older `WITH PRIVILEGED ACCESS`, itself baseline since 769/1708/2017 Q3) | Refinement at 791 (2302 / 2023 Q1); `OPTIONS` keyword recommended in front of it from 796 (2405 / 2024 Q2) | The base bypass capability itself is baseline-safe; only the exact keyword form depends on target release — match whichever form your target's ATC/syntax check accepts |
| RAP: `authorization:update` action addition (delegates an action's authorization control to the entity's update-operation control) | Release 785 (2108 / 2021 Q3) | Give the action its own explicit `authorization:instance`/`authorization:global` instead of delegating |
| RAP: Subentities as Authorization Master (a non-root BO entity can itself be the authorization master) | Release 796 (2405 / 2024 Q2) | Authorization master must be the root entity; a subentity's checks have to derive from the root |
| RAP: `authorization master ( none )` (explicitly marks authorization-dependent operations as `authorization:none`) | Release 913 (2411 / 2024 Q4) | Omit authorization control explicitly per operation instead of using this shorthand |
| RAP: Dedicated Authorizations for Create-by-Association (separate authorization control for create-by-association vs. the default "inherits update check from the authorization master") | Release 916 (2508 / 2025 Q3) | Create-by-association always uses the update check of the related authorization master entity — cannot be differentiated |

Don't assume any of the RAP-BDL rows above are available on an older/unconfirmed target — several (913/2411, 916/2508) are recent enough that a mid-2024-or-earlier system won't have them.

## Decision Criteria: Three Different "Bypass Authorization" Mechanisms

The SKILL.md body only mentions `SELECT ... PRIVILEGED ACCESS`. There are actually three distinct bypass mechanisms operating at different layers — picking the wrong one either over-bypasses (design smell / real security gap) or doesn't compile in the layer you need it:

| Mechanism | Layer | Scope | Justified when |
|---|---|---|---|
| `SELECT ... PRIVILEGED ACCESS` (ABAP SQL addition, baseline since 769/1708) | Any ABAP SQL statement | Disables **all** CDS access control (DCL) for that one `SELECT`, no finer scoping | A background job / batch report with no user context reading a CDS entity that has DCL — there is no PFCG-authorized user to check against. **Never** use it as a workaround for "the current user's authorization check keeps failing" in a user-driven flow — that's a design smell, not a bypass case. |
| RAP `define authorization context ... for disable` (789/2208+, `save:early`/`save:late` scoping from 791/2302) | One RAP BDEF | Skips only the **specific authorization objects listed in that context**, and (791+) only in the save phase(s) named | A determination/validation in the save sequence needs to write a system-generated field (e.g., an audit timestamp, a computed status) that the acting user isn't personally authorized to set directly — the authorization gap is deliberate and narrow, not "authorization is inconvenient here." This is the mechanism to reach for **first** when only part of a BO's own internal processing needs to skip a check — it's strictly narrower than the next option. |
| EML `PRIVILEGED` mode / `with privileged mode disabling` (context-scoped variant, 789/2208+) | One EML call site | Bypasses **all** authorization checks (global + instance) for that RAP BO invocation | Framework-internal or cross-BO orchestration code that must act on a BO on behalf of the system, not a specific user's authorization (e.g., a determination on BO A creating a related instance on BO B where BO B's own authorization check is meaningless in that automated context) — same "no real user decision being overridden" bar as the SQL-level bypass. |

Decision rule: reach for the narrowest mechanism that solves the actual problem — RAP's own scoped `authorization context ... for disable` before the blanket EML `PRIVILEGED` mode, and either of those before a blanket `SELECT ... PRIVILEGED ACCESS` in a user-facing code path. If none of the three feels "narrow enough" for what you're trying to do, that's usually a sign the authorization design itself needs rethinking (e.g., a missing `authorization:none` operation-level marker, or an action that should declare its own `authorization:instance` instead of inheriting the entity's), not a signal to reach for a broader bypass.

**Note on exact RAP BDEF grammar**: the ABAP Release News digest only describes `define authorization context` / `for disable` / `save:early`/`save:late` / `with privileged mode disabling` in prose — the official BDL cheat sheet (`36_RAP_Behavior_Definition_Language.md`) doesn't include a worked syntax example for this specific header option, only a pointer to `ABENBDL_BDEF_HEADER` in the ABAP Keyword Documentation. Verify the exact brace/keyword-order syntax there (or via ADT code completion) before writing this in a real BDEF — don't rely on a from-memory syntax reconstruction.

## Worked Example: Chaining DCL Row-Level Read Control with the IAM Admin Model

This is the concrete end-to-end flow the SKILL.md body only summarizes as one line ("Chain: IAM App → Business Catalog → Business Role → Business User"). Adapted from an official SAP-samples executable tutorial (`25_Authorization_Checks.md`'s own "Executable Example" section), condensed to the actual object sequence — using the same `Z_MY_AUTH`/`ZCARR` naming already established in this skill's SKILL.md/`rap-authorization-examples.md` for consistency:

1. **Authorization Field** (ADT: *New → Other ABAP Repository Object → Authorization Field*) — e.g. `ZCARR`, linked to data element `S_CARR_ID`.
2. **Authorization Object** (ADT, same wizard, filter *Authorization Object*) — `Z_MY_AUTH`, add field `ZCARR`, check the *Activity Field* box for `ACTVT`, list permitted activities (01/02/03/06).
3. **IAM App** (ADT, filter *IAM app*) — name it, choose application type *External app* (ADT appends `_EXT` to the technical name), open the *Authorizations* tab, add `Z_MY_AUTH`, and under the field's *Instances* section restrict `ZCARR`'s allowed value range (e.g., `From: LH`) if the app itself should only ever be usable for a subset of values — this is a coarser, app-level restriction layered *underneath* whatever a business role later restricts further. Save, activate, **Publish Locally**.
4. **Business Catalog** (ADT, filter *Business catalog*) — add the IAM app under its *Apps* tab, **Publish Locally** (can take a while).
5. **Business Role** (Fiori *Maintain Business Roles* app, not ADT) — add the business catalog under *Business Catalogs*, assign users under *Business Users*, and this is where the **restriction type** (Unrestricted / Restricted-to-specific-values / No Access) actually gets set per field — the IAM app's own value restriction (step 3) is a ceiling, the business role's restriction type is what a specific role actually grants within that ceiling.
6. **CDS Access Control (DCL)** — a `define role` entity wired via `aspect pfcg_auth(Z_MY_AUTH, ZCARR, ACTVT = '03')` on the CDS view carrying `@AccessControl.authorizationCheck: #CHECK` (or `#MANDATORY`) — this is the code-level artifact this skill already documents; steps 1-5 are what makes the authorization object it references actually resolve to something for a real logged-in business user.

The point of walking all six together: a `Z_MY_AUTH`/`ZCARR` reference in a DCL `aspect pfcg_auth(...)` clause is inert until an IAM app exposes it, a business catalog groups that IAM app, and a business role assigns the catalog (with a concrete restriction type) to a user — skipping any one of steps 3-5 means the DCL check will simply deny everyone, which is a common "my access control compiles but nobody can see any data" support case.

## Decision Criteria: Why Combine DCL Read-Filtering with RAP Instance Authorization (Not Either Alone)

`rap-authorization-examples.md` already shows the RAP instance-authorization handler in isolation. The reason to pair it with a DCL role on the same entity's CDS view (rather than relying on the RAP handler alone) is defense-in-depth across two different attack/error surfaces:

- **DCL row-level filtering** happens automatically for read access in managed scenarios (the SKILL.md body's own line) — a user who fails the `aspect pfcg_auth` condition never sees the row at all, in any UI, report, or ad-hoc SQL query against the CDS view. It does **not**, by itself, block a write attempt against a row the user *can* see but shouldn't modify.
- **RAP instance authorization** (`get_instance_authorizations`) is what actually blocks an update/delete attempt at the handler level — but it only runs for RAP-mediated modify operations; it doesn't retroactively hide the row from a plain `SELECT`.

A child entity in a composition tree should inherit the parent's DCL restriction rather than redefine it — this is what `where inheriting conditions from entity` (already named in the SKILL.md's pattern table) is for, worked out concretely:

```cds
"Parent — the restriction condition lives here
@AccessControl.authorizationCheck: #CHECK
@MappingRole: true
define role ZI_Travel {
  grant select on ZI_Travel
    where ( carrier_id ) = aspect pfcg_auth( Z_MY_AUTH, ZCARR, ACTVT = '03' );
}

"Child — inherits the parent's condition through the composition association,
"rather than re-declaring the same aspect pfcg_auth clause a second time
@AccessControl.authorizationCheck: #CHECK
@MappingRole: true
define role ZI_Booking {
  grant select on ZI_Booking
    where inheriting conditions from entity ZI_Travel
      association _Travel;
}
```

Decision rule: redeclare `aspect pfcg_auth(...)` on a child only if the child genuinely needs a **different**/additional restriction beyond the parent's — otherwise `inheriting conditions from entity` is both less code and (more importantly) keeps the restriction defined in exactly one place, so a later change to the authorization object/field only needs to happen at the parent.

## Decision Trade-off (extends SKILL.md's "what differs between platforms" framing)

The SKILL.md body correctly says code-level checks (`AUTHORITY-CHECK`, DCL) are identical between ABAP Cloud and on-premise — what the walkthrough above makes concrete is that the **administrative chain length** differs sharply: on-premise, a PFCG role directly bundles transaction/tile + authorization-object field values in one object; ABAP Cloud requires the full IAM App → Business Catalog → Business Role chain (3 objects, 2 of them ADT-authored and transportable, 1 of them Fiori-app-authored and typically *not* individually transported the same way — verify your project's transport strategy for business roles specifically). Budget for this when estimating a TS that adds a brand-new authorization object on an ABAP Cloud target — it's not "add the object and done," it's the full chain.
