---
name: cds-view-entities
description: Help with CDS (Core Data Services) view entity development including data modeling, annotations, associations, compositions, aggregate expressions, built-in functions, and input parameters. Use when users ask about CDS views, CDS view entities, CDS annotations, CDS associations, CDS compositions, CDS metadata extensions, data modeling in ABAP, define view entity, define root view entity, semantic annotations, UI annotations, or building CDS data models for RAP or analytical scenarios. Triggers include "create a CDS view", "define view entity", "add an association", "CDS annotation", "composition", "CDS hierarchy", "CDS aggregate", "CDS functions", or "data model". For CDS access control / DCL use authorization-iam.
---

# CDS View Entities

Guide for building semantic data models with ABAP CDS view entities in ABAP Cloud. This body keeps the decision tables and RAP-specific patterns; full syntax templates live in [references/cds-syntax-guide.md](references/cds-syntax-guide.md) — read it when actually writing a view (basic/root/child/projection templates, expressions & built-in functions, joins, input parameters, UI annotations/metadata extensions).

## Ground Rules

- Use CDS view entities (`define view entity`) — never legacy `define view` (DDIC-based) for new objects.
- Naming per [Skill: naming-convention]: `ZR_*` interface/BO views, `ZC_*` consumption/projection views, `ZI_*` reuse views.
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

## Other Key Semantics

```cds
@Semantics.amount.currencyCode: 'CurrencyCode'
net_amount as NetAmount,          // currency field itself has no annotation

@Semantics.quantity.unitOfMeasure: 'QuantityUnit'
quantity as Quantity,
```

Amount/quantity fields without these annotations render wrong in Fiori and break aggregation — always pair them with their reference field.

## Access Control (DCL)

Every view needs `@AccessControl.authorizationCheck:` (`#CHECK` + a DCL role, or `#NOT_REQUIRED` with justification). Writing the DCL itself — `pfcg_auth`, `inherit`, `aspect user` patterns — is owned by [Skill: authorization-iam].

## CDS Table Entities

```cds
define table entity ztab_salesorder {
  key client    : abap.clnt;
  key order_uuid: sysuuid_x16;
      order_id  : abap.numc(10);
}
```

> CDS table entities can serve as alternatives to classic DDIC database tables and can be used as `persistent table` in RAP BDEFs. Release-dependent feature — before emitting one, verify `define table entity` is supported on the target system's release; if unsure, default to a classic DDIC table.

## Output Format

- Provide complete CDS source code when creating new views (start from the templates in `references/cds-syntax-guide.md`)
- Include all relevant annotations; always expose associations used in consumption
- Follow `ZR_`/`ZC_`/`ZI_` naming

## References

- [references/cds-syntax-guide.md](references/cds-syntax-guide.md) — syntax templates: view definitions, expressions, functions, joins, parameters, UI annotations
- [SAP ABAP Cheat Sheets — CDS View Entities](https://github.com/SAP-samples/abap-cheat-sheets/blob/main/15_CDS_View_Entities.md)
- [SAP Help — ABAP Data Models Guide](https://help.sap.com/docs/abap-cloud/abap-data-models/abap-data-models)
- [SAP Help — CDS Annotations](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/ABENCDS_ANNOTATIONS.html)
