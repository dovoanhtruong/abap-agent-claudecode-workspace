---
name: cds-view-entities
description: Help with CDS view entity modeling for RAP business objects — composition trees, admin fields, association/composition decisions, draft/ETag-supporting fields, root/child/projection view entities. Use when users ask about RAP data modeling, composition trees, define root view entity, define child view entity, admin fields, association vs composition, or building the CDS layer of a transactional app. Triggers include "create a CDS view for RAP", "composition tree", "root view entity", "admin fields", "association vs composition". For general-purpose/analytical CDS view authoring outside RAP (aggregates, input parameters, joins, plain reporting views) use cds-analytical-views; for CDS access control / DCL use authorization-iam. Use even for small single-prompt RAP-view tasks — Vietnamese triggers: "tạo root/child view", "thêm association/composition", "thêm admin field", "sửa view RAP".
---

# CDS View Entities (RAP Composition Modeling)

Guide for building the CDS data-modeling layer of a RAP business object — composition trees, admin fields, association/composition decisions. For general/analytical CDS view authoring (aggregates, input parameters, joins, plain reporting views with no RAP involvement) see [Skill: cds-analytical-views] instead — that's the skill `/sap-dev-create-report` exercises. Full copy-paste templates for this skill's scope live in [references/cds-syntax-guide.md](references/cds-syntax-guide.md).

## Ground Rules

- Use CDS view entities (`define view entity`) — never legacy `define view` (DDIC-based) for new objects.
- Naming per [Skill: naming-convention]: `ZR_*` interface/BO views, `ZC_*` consumption/projection views.
- Read SAP data only via released `I_*` CDS views, never physical SAP tables (workspace rule §3).
- Put UI annotations in a metadata extension (`@Metadata.allowExtensions: true` + `annotate view`), not in the view body — keeps the data model stable while UI iterates.

## Association vs Composition (decision table)

| Type                      | Syntax                                                  | Use Case                                              |
| ------------------------- | ------------------------------------------------------- | ----------------------------------------------------- |
| **Regular association**   | `association [0..1] to ZI_Customer as _Customer on ...` | Independent entities (e.g., master data lookup)       |
| **Composition**           | `composition [0..*] of ZR_Child as _Child`              | Parent-child with lifecycle dependency (RAP BO trees) |
| **To-parent association** | `association to parent ZR_Parent as _Parent on ...`     | Child → parent back-reference in compositions         |

Expose associations in the field list (`_Customer,`) or they are unusable from ABAP SQL/OData. Prefer associations over joins — lazily resolved, support path expressions.

### Typical RAP Composition Tree

```
ZR_Root (define root view entity)
├── composition [0..*] of ZR_Child1 as _Child1
└── composition [0..*] of ZR_Child2 as _Child2
    └── composition [0..*] of ZR_GrandChild as _GrandChild

ZR_Child1/2 (association to parent ZR_Root as _Root)
ZR_GrandChild (association to parent ZR_Child2 as _Parent)
```

## Admin Field Pattern (Managed RAP BO)

Every entity in a managed RAP BO should include admin fields — this exact five-field pattern (note `LocalLastChangedAt` ≠ `LastChangedAt`; mixing them up breaks draft etag handling):

| Field                | Type      | Annotation                                                   | Purpose                         |
| -------------------- | --------- | ------------------------------------------------------------ | ------------------------------- |
| `CreatedBy`          | `syuname` | `@Semantics.user.createdBy: true`                            | Who created                     |
| `CreatedAt`          | `utclong` | `@Semantics.systemDateTime.createdAt: true`                  | When created                    |
| `LastChangedBy`      | `syuname` | `@Semantics.user.localInstanceLastChangedBy: true`           | Who last changed                |
| `LocalLastChangedAt` | `utclong` | `@Semantics.systemDateTime.localInstanceLastChangedAt: true` | ETag for optimistic concurrency |
| `LastChangedAt`      | `utclong` | `@Semantics.systemDateTime.lastChangedAt: true`              | Total ETag for draft            |

Amount/quantity semantic annotation pairing (`@Semantics.amount.currencyCode`/`@Semantics.quantity.unitOfMeasure`) and CDS table entities as a persistence alternative are covered in [Skill: cds-analytical-views] — both apply equally whether or not RAP is involved, so they live there to avoid a duplicate copy; a RAP root/child view's amount/quantity fields still need the same pairing.

## Access Control (DCL)

Every view needs `@AccessControl.authorizationCheck:` (`#CHECK` + a DCL role, or `#NOT_REQUIRED` with justification). Writing the DCL itself — `pfcg_auth`, `inherit`, `aspect user` patterns — is owned by [Skill: authorization-iam].

## Output Format

- Provide complete CDS source code when creating new views (start from the templates in `references/cds-syntax-guide.md`)
- Include all relevant annotations; always expose associations used in consumption
- Follow `ZR_`/`ZC_` naming

## Deep Dive

For the BDEF-side ETag/lock declarations (`etag master`, `lock dependent by`, `total etag`) that pair with the admin-field annotations above, draft-table requirements (`DRAFTUUID`, the `%admin` include), and a release-history refinement of the association-vs-composition call, read [references/deep-dive.md](references/deep-dive.md).

## References

- [references/cds-syntax-guide.md](references/cds-syntax-guide.md) — syntax templates: root/child/projection view definitions, association syntax
- [Skill: cds-analytical-views] — expressions, aggregates, input parameters, joins, table entities, UI annotations
- [SAP ABAP Cheat Sheets — CDS View Entities](https://github.com/SAP-samples/abap-cheat-sheets/blob/main/15_CDS_View_Entities.md)
- [SAP Help — ABAP Data Models Guide](https://help.sap.com/docs/abap-cloud/abap-data-models/abap-data-models)
- [SAP Help — CDS Annotations](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/ABENCDS_ANNOTATIONS.html)
