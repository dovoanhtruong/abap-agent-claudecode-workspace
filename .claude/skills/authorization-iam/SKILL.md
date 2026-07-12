---
name: authorization-iam
description: Help with ABAP authorization and IAM (Identity and Access Management) including authorization objects, authorization checks, IAM apps, business catalogs, business roles, restriction types, CDS access control (DCL), privilege access annotations, and role-based access in ABAP Cloud and on-premise. Use when users ask about authorization, AUTHORITY-CHECK, authorization object, IAM app, business catalog, business role, restriction type, CDS access control, DCL, access control, privilege annotation, role assignment, PFCG role, S_DEVELOP, or securing ABAP applications. Triggers include "authorization check", "create authorization object", "CDS access control", "IAM app", "business catalog", "business role", "PFCG", "restrict access", or "role-based security".
---

# Authorization & IAM

Guide for ABAP authorization design. This skill owns DCL and code-level checks; RAP handler implementations and PFCG click-paths live in [references/rap-authorization-examples.md](references/rap-authorization-examples.md) — read it when implementing.

## Platform Decision First

- **ABAP Cloud (BTP / S/4HANA Cloud)**: role administration via IAM apps + business catalogs + business roles; code checks via `AUTHORITY-CHECK` + RAP authorization handlers + DCL.
- **On-premise / Standard ABAP**: PFCG roles; same `AUTHORITY-CHECK` in code.

What differs between platforms is role *administration*, not the code-level check statement.

## `AUTHORITY-CHECK` — the released mechanism on BOTH platforms

There is no released class-based replacement (a `CL_ABAP_AUTHORIZATION` does not exist) — the `AUTHORITY-CHECK OBJECT` statement itself is released for ABAP for Cloud Development; the result is read from `sy-subrc`:

```abap
AUTHORITY-CHECK OBJECT 'Z_MY_AUTH'
  ID 'ACTVT' FIELD '03'      "Display
  ID 'ZCARR' FIELD lv_carrier.

IF sy-subrc <> 0.
  "Not authorized — in RAP report via failed/reported; classic: message + RETURN
  RAISE EXCEPTION TYPE zcx_not_authorized.
ENDIF.
```

### Activity Values (ACTVT)

| Value | Activity | | Value | Activity |
| ----- | -------- |-| ----- | -------- |
| `01`  | Create   | | `06`  | Delete   |
| `02`  | Change   | | `16`  | Execute  |
| `03`  | Display  | |       |          |

## Custom Authorization Objects

In ADT (or `SU21`): an **Authorization Class** groups objects; an **Authorization Object** holds 1–10 **fields** (each linked to a data element), e.g.:

```
Authorization Object: Z_MY_AUTH
  Fields:
    ACTVT  — Activity (standard field)
    ZCARR  — Carrier (custom, type S_CARR_ID)
```

## CDS Access Control (DCL) — owned here

Row-level authorization for CDS view entities:

```cds
@EndUserText.label: 'Access Control for Travel'
@MappingRole: true
define role ZI_Travel {
  grant select on ZI_Travel
    where ( carrier_id ) =
      aspect pfcg_auth ( Z_MY_AUTH, ZCARR, ACTVT = '03' );
}
```

| Pattern | Use |
|---|---|
| `aspect pfcg_auth ( OBJ, FIELD, ACTVT = ... )` | Standard authorization-object check; `and`-combine for multiple conditions |
| `where inheriting conditions from entity ... association _X` | Child inherits parent's restrictions (composition trees) |
| `where _unrestrictedAccess` | Admin role, no restriction |
| `where CreatedBy = aspect user` | Restrict to own records |

Bypassing DCL (`SELECT ... PRIVILEGED ACCESS`) is legitimate only in contexts with no user (background jobs) — justify it explicitly whenever emitted.

## RAP Authorization (summary)

BDEF declares `authorization master ( instance )` (per-record decision, e.g. by carrier) or `( global )` (operation-level, e.g. may-create). Handlers `get_instance_authorizations` / `get_global_authorizations` run AUTHORITY-CHECK and fill `if_abap_behv=>auth-allowed/unauthorized`. Full implementations: [references/rap-authorization-examples.md](references/rap-authorization-examples.md).

## IAM in ABAP Cloud (authorization-design view)

Chain: **IAM App** (ADT, links service binding + auth objects) → **Business Catalog** (ADT, groups IAM apps) → **Business Role** (Fiori "Maintain Business Roles": catalogs + restriction types + users).

Restriction types give field-level control per role: **Unrestricted** / **Restricted** (specific values, e.g. `ZCARR` limited to `LH`,`AA`) / **No Access**.

Provisioning-side setup (communication users, systems) → [Skill: btp-abap-environment]. On-prem PFCG walkthrough → reference file.

## Output Format

- Platform: [ABAP Cloud / On-Premise]
- Approach: [CDS DCL / AUTHORITY-CHECK / RAP auth handler / IAM]
- Implementation with code, then role configuration steps

## References

- [references/rap-authorization-examples.md](references/rap-authorization-examples.md) — RAP instance/global handler code, PFCG walkthrough
- ABAP Authorization Cheat Sheet: https://github.com/SAP-samples/abap-cheat-sheets
- CDS Access Control: https://help.sap.com/docs/abap-cloud/abap-development-tools-user-guide/access-controls
- IAM Guide: https://help.sap.com/docs/btp/sap-business-technology-platform/identity-and-access-management-iam
