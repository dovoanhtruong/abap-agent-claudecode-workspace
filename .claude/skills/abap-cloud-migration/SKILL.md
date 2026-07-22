---
name: abap-cloud-migration
description: Help with migrating classic ABAP custom code to ABAP Cloud — custom code adaptation, identifying unreleased-API replacements, wrapper classes for unreleased objects, ATC Cloud Readiness checks, incompatible language constructs, step-by-step migration workflows. Triggers: "migrate to ABAP Cloud", "cloud readiness check", "unreleased API", "replace with released API", "custom code adaptation", "wrapper for unreleased", "move to tier 1", "ABAP Cloud compatibility", "S/4HANA cloud migration". For tier-model/clean-core concepts use abap-cloud; for configuring the ATC check variant itself use atc-cloudification.
---

# ABAP Cloud Migration Patterns

Guide for systematically migrating classic ABAP custom code to ABAP Cloud (Tier 1) compliance.

## Workflow

1. **Assess current state**: Run ATC Cloud Readiness checks on existing code
2. **Categorize findings**: Group by finding type (unreleased API, language construct, etc.)
3. **Plan migration**: Prioritize by impact and determine replacement strategy
4. **Implement replacements**: Apply released API replacements or create wrappers
5. **Validate**: Re-run ATC checks and test functionality

## Migration Assessment

### Running ATC Cloud Readiness Checks

1. In ADT: Right-click package → **Run As** → **ABAP Test Cockpit**
2. Use check variant `ABAP_CLOUD_READINESS` or a custom variant with cloud-relevant checks
3. Review findings in the ATC Results view

### Typical Finding Categories and Remediations

ATC cloud-readiness findings are identified by **check name** within the variant (e.g. "Usage of Released APIs", "Usage of APIs", "ABAP Language Version", "Allowed Object Types in Cloud Development") plus the referenced unreleased object — there is no published table of short message IDs, so never cite one; quote the actual check name and object from the ATC result. Remediation by the *kind* of object flagged:

| Flagged object/construct kind          | Action                            |
| -------------------------------------- | --------------------------------- |
| Number range object (`NROB`-type TADIR) | Use `CL_NUMBERRANGE_RUNTIME`      |
| Direct BAPI call                        | Use released RAP API or wrapper   |
| Dynpro/screen usage                     | Replace with Fiori/UI5            |
| Unreleased function module call         | Find released replacement or wrap |
| Unreleased class usage                  | Find released replacement or wrap |
| Direct DB table access (not released)   | Use released CDS view entity      |
| Incompatible language construct         | Refactor to modern ABAP (cloud language version) |

## Common API Replacements

### Database Access

| Classic Pattern           | ABAP Cloud Replacement        |
| ------------------------- | ----------------------------- |
| `SELECT FROM mara`        | `SELECT FROM i_product`       |
| `SELECT FROM bkpf / bseg` | `SELECT FROM i_journalentry`  |
| `SELECT FROM vbak / vbap` | `SELECT FROM i_salesorder`    |
| `SELECT FROM ekko / ekpo` | `SELECT FROM i_purchaseorder` |
| `SELECT FROM kna1`        | `SELECT FROM i_customer`      |
| `SELECT FROM lfa1`        | `SELECT FROM i_supplier`      |
| `SELECT FROM t001`        | `SELECT FROM i_companycode`   |
| Direct table access       | Use `I_*` released CDS views  |

### Function Modules → Released Classes

| Classic FM                              | Released Replacement                                 |
| --------------------------------------- | ---------------------------------------------------- |
| `GUID_CREATE`                           | `cl_system_uuid=>create_uuid_x16_static( )`          |
| `CONVERSION_EXIT_ALPHA_INPUT`           | `cl_abap_format=>alpha_input( )`                     |
| `CONVERSION_EXIT_ALPHA_OUTPUT`          | `cl_abap_format=>alpha_output( )`                    |
| `POPUP_TO_CONFIRM`                      | Not available — use Fiori UI                         |
| `NUMBER_GET_NEXT`                       | `cl_numberrange_runtime=>number_get( )`              |
| `BAPI_TRANSACTION_COMMIT`               | Handled by RAP framework (no explicit commit)        |
| `SO_NEW_DOCUMENT_ATT_SEND_API1`         | `cl_bcs_mail_message` (send emails)                  |
| `READ_TEXT` / `SAVE_TEXT`               | Not released — wrap or use custom persistence        |
| `JOB_OPEN` / `JOB_CLOSE` / `JOB_SUBMIT` | `cl_apj_rt_api` (Application Jobs)                   |
| `ENQUEUE_*` / `DEQUEUE_*`               | RAP draft / managed locking or `CL_ABAP_LOCK_OBJECT` |

### Language Constructs

| Incompatible Construct                   | Cloud-Compatible Alternative                   |
| ---------------------------------------- | ---------------------------------------------- |
| `CALL TRANSACTION`                       | Not available — use API or RAP                 |
| `SUBMIT ... AND RETURN`                  | Not available — use Application Jobs           |
| `WRITE` / `SKIP` / `ULINE` (list output) | Not available — use Fiori UI for output        |
| `CALL SCREEN` / `CALL SELECTION-SCREEN`  | Not available — use Fiori/UI5                  |
| `MESSAGE ... RAISING`                    | `RAISE EXCEPTION TYPE ...`                     |
| `CALL FUNCTION ... IN UPDATE TASK`       | RAP saver class / managed save                 |
| `EXEC SQL` (Native SQL)                  | ABAP SQL or AMDP                               |
| `GENERATE SUBROUTINE POOL`               | Not available — use strategy/factory pattern   |
| `DESCRIBE FIELD ... TYPE`                | RTTI: `cl_abap_typedescr=>describe_by_data( )` |
| `GET/SET PARAMETER ID`                   | Not available — use method parameters          |

## Wrapper Pattern (Tier 2) — summary

When no released API exists: (1) define a clean Z-interface with typed signatures + class-based exceptions, (2) implement it in a Standard-ABAP class that calls the unreleased API internally, (3) release the wrapper in ADT (API State tab → C1 contract → "Use in ABAP Cloud"), (4) consume it from Tier 1, (5) retire it when SAP releases a proper API.

> Full worked example (READ_TEXT/SAVE_TEXT wrapper, all 4 steps with code): read [references/wrapper-walkthrough.md](references/wrapper-walkthrough.md) when actually building one. Tier concepts → [Skill: abap-cloud].

## Migration Strategy by Object Type

### Reports / Programs

```
Classic Report → Application Job class + CDS view + Fiori app
1. Extract data logic → CDS view entities
2. Extract business logic → ABAP Cloud class
3. Create Application Job catalog entry (CL_APJ_DT_CREATE_CONTENT)
4. Schedule via Fiori app "Application Jobs"
```

### Dynpro Transactions

```
Dynpro Transaction → RAP BO + Fiori Elements app
1. Identify CRUD operations → RAP behavior definition
2. Map screen fields → CDS view entity
3. Create service definition/binding
4. Generate Fiori Elements app
```

### BAPIs

```
BAPI → RAP BO with custom actions
1. Map BAPI parameters → CDS abstract entities
2. Implement as RAP actions or factory actions
3. Expose via OData service binding
```

### RFC Function Modules

```
RFC FM → Released API class or RAP service
1. If simple logic → Released ABAP class
2. If CRUD → RAP BO with service binding
3. If complex → Wrapper class (Tier 2)
```

## Finding Released Replacements

### In ADT

1. **Released Object Search**: `Ctrl+Shift+A` → Filter by "Released" APIs
2. **API State Filter**: In Project Explorer, filter by C1 release state
3. **ABAP Element Info**: Hover over unreleased object → see suggestion if available

### Using the Released Objects App

Fiori app **Released Objects** (`F5865`):

- Search by classic object name
- Filter by release state (C1, C2)
- View successor information

### Programmatic Check

```abap
"Check if an object is released for ABAP Cloud
SELECT SINGLE *
  FROM i_apistateofrepositoryobject
  WHERE ObjectType     = 'CLAS'
    AND ObjectName     = 'CL_NUMBERRANGE_RUNTIME'
    AND ReleaseState   = 'RELEASED'
  INTO @DATA(ls_state).
```

## Step-by-Step Migration Checklist

1. [ ] Run ATC Cloud Readiness check on the package/objects
2. [ ] Export findings and categorize by type
3. [ ] For each unreleased API usage:
   - [ ] Search for released replacement (CDS view `I_ApiStateOfRepositoryObject`)
   - [ ] If found: replace directly
   - [ ] If not found: create Tier 2 wrapper
4. [ ] For each incompatible language construct:
   - [ ] Refactor to cloud-compatible alternative
5. [ ] For Dynpro/ALV/list-based UIs:
   - [ ] Plan Fiori replacement (separate project)
6. [ ] Move migrated objects to ABAP Cloud language version package
7. [ ] Re-run ATC checks — all findings must be resolved
8. [ ] Execute regression tests

## Output Format

When helping with migration topics, structure responses as:

```markdown
## Migration Guidance

### Current Code Analysis

- Unreleased APIs found: [list]
- Incompatible constructs: [list]
- Estimated effort: [low / medium / high]

### Replacement Strategy

[For each finding: original → replacement with code]

### Wrapper Requirements

[Objects needing Tier 2 wrappers]
```

## Deep Dive

For a longer, verified list of concretely invalid/deprecated constructs (sourced from SAP's own official demo of broken Cloud-restricted code), a "released API but still risky" type-compatibility trap, and a decision bridge to `atc-cloudification`'s Clean Core level table, read [references/deep-dive.md](references/deep-dive.md).

## References

- Custom Code Migration Guide: https://help.sap.com/docs/abap-cloud/abap-development-tools-user-guide/custom-code-migration
- ABAP Cloud API Release Info: https://help.sap.com/docs/abap-cloud/abap-rap/released-abap-objects
- Wrapper Pattern: https://github.com/SAP-samples/abap-cheat-sheets/blob/main/19_ABAP_Cloud.md
- ATC Cloud Readiness: https://help.sap.com/docs/abap-cloud/abap-development-tools-user-guide/checking-abap-cloud-readiness
