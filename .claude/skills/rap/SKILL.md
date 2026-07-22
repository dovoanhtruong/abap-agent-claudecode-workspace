---
name: rap
description: Help with RAP (RESTful ABAP Programming Model) development — BDEF/BDL, EML, behavior pools, managed/unmanaged/draft-enabled BOs, actions, validations, determinations, side effects, handler/saver classes, CRUD, building transactional Fiori apps with ABAP Cloud. Use for any RAP ask, even a small single-prompt fix — "create a RAP BO", "write a behavior definition", "EML syntax", "managed vs unmanaged", "enable draft", "RAP handler method", "thêm action", "sửa behavior definition", "viết validation/determination", "xử lý draft", "sửa handler". For event bindings/Event Mesh use rap-business-events; for IF_RAP_QUERY_PROVIDER custom entities use rap-query-provider; for OData publishing use odata.
---

# RAP (RESTful ABAP Programming Model)

Guide for building transactional applications with RAP in ABAP Cloud. The body keeps the decision tables and hallucination-prone syntax references; full copy-paste templates live in `references/` — read them when actually writing the object, not before.

## RAP Architecture Layers

| Layer                       | Artifacts                                     | Purpose                                                                 |
| --------------------------- | --------------------------------------------- | ----------------------------------------------------------------------- |
| **Data Modeling**           | Database tables, CDS root/child view entities | Data persistence and semantic data model                                |
| **Behavior Definition**     | BDEF (`.bdef`)                                | Declares transactional behavior (operations, characteristics) using BDL |
| **Behavior Implementation** | ABAP behavior pool (`BP_*`)                   | Implements business logic in handler/saver classes                      |
| **Projection**              | CDS projection views, projection BDEF         | Adapts BO for specific service consumers                                |
| **Business Service**        | Service definition, service binding           | Exposes BO as OData service                                             |

## Implementation Types

- **Managed (greenfield)**: framework owns the transactional buffer and standard CRUD; you code only actions/validations/determinations. Header: `managed implementation in class zbp_r_entity unique; strict ( 2 );`
- **Unmanaged (brownfield)**: you provide the buffer and implement all operations — for embedding existing business logic. Header: `unmanaged implementation in class zbp_r_entity unique; strict ( 2 );`
- Managed save can be extended (`with additional save`) or replaced (`with unmanaged save`).

## Key BDL Elements

| Element                 | Syntax                                    | Purpose                                                                |
| ----------------------- | ----------------------------------------- | ---------------------------------------------------------------------- |
| **Managed numbering**   | `field ( numbering : managed ) KeyField;` | Framework assigns UUID keys automatically                              |
| **Early numbering**     | `early numbering`                         | Custom key assignment in interaction phase via `FOR NUMBERING` handler |
| **Late numbering**      | `late numbering`                          | Key assignment in save sequence via `adjust_numbers` saver method      |
| **Lock master**         | `lock master`                             | Root entity controls pessimistic locking                               |
| **Lock dependent**      | `lock dependent by _Assoc`                | Child entity delegates locking to parent                               |
| **ETag**                | `etag master FieldName`                   | Optimistic concurrency control                                         |
| **Total ETag**          | `total etag FieldName`                    | Required for draft-enabled BOs (root only)                             |
| **Draft**               | `with draft;`                             | Enables draft handling for entire BO                                   |
| **Strict mode**         | `strict ( 2 );`                           | Enables additional BDL syntax checks (always use for new BOs)          |

> Full copy-paste templates — complete managed+draft root/child BDEF, projection BDEF, actions/validations/determinations/side-effects syntax: read [references/bdef-templates.md](references/bdef-templates.md) when writing a BDEF.
> Handler (`lhc_*`) and saver (`lsc_*`) class skeletons with worked action/validation/determination implementations: read [references/behavior-pool-templates.md](references/behavior-pool-templates.md) when writing a behavior pool.
> Business events (`event` in BDEF, `RAISE ENTITY EVENT`, event binding): [Skill: rap-business-events] owns this.

## EML Quick Reference

EML is the ABAP language for programmatically interacting with RAP BOs. Key operations: `MODIFY ENTITY` (create/update/delete/execute action), `READ ENTITIES`, `COMMIT ENTITIES`, `ROLLBACK ENTITIES`.

- **Create**: `MODIFY ENTITY ... CREATE FIELDS ( ... ) WITH VALUE #( ( %cid = '...' ... ) )`
- **Read**: `READ ENTITIES OF ... ALL FIELDS WITH VALUE #( ( key = val ) ) RESULT DATA(result)`
- **Update**: `MODIFY ENTITY ... UPDATE FIELDS ( ... ) WITH VALUE #( ( %tky = ... ) )`
- **Delete**: `MODIFY ENTITY ... DELETE FROM VALUE #( ( %tky = ... ) )`
- **Execute Action**: `MODIFY ENTITY ... EXECUTE actionName FROM VALUE #( ( %tky = ... ) )`
- **Deep Create**: Use `CREATE BY \_Assoc` with `%cid_ref` and `%target`

> For full EML syntax with code examples, read [references/eml-quick-reference.md](references/eml-quick-reference.md).

## Draft Handling

- Enabled via `with draft;` in BDEF header; requires a separate `draft table` per entity
- Draft table must include `"%admin": include sych_bdl_draft_admin_inc;`
- Draft actions (`Edit`, `Activate`, `Discard`, `Resume`, `Prepare`) are implicitly provided
- Use `%is_draft` (or `%tky`, which includes it) to distinguish draft vs. active instances

## RAP Save Sequence

| Phase          | Methods Called                                                      | Purpose                  |
| -------------- | ------------------------------------------------------------------- | ------------------------ |
| **Early Save** | `finalize` → `check_before_save` → (on failure: `cleanup_finalize`) | Ensure data consistency  |
| **Late Save**  | `adjust_numbers` → `save` / `save_modified` → `cleanup`             | Persist data to database |

- Early save failures return to the interaction phase; late save is the point of no return — either commit succeeds or runtime error.

## Key BDEF Derived Type Components

| Component   | Purpose                                                             |
| ----------- | ------------------------------------------------------------------- |
| `%cid`      | Content ID — unique preliminary identifier for new instances        |
| `%cid_ref`  | Reference to a `%cid` in the same EML request                       |
| `%key`      | Primary key fields                                                  |
| `%tky`      | Transactional key (`%key` + `%is_draft` + `%pid`) — **recommended** |
| `%data`     | All key and data fields                                             |
| `%control`  | Flags indicating which fields are provided/requested                |
| `%is_draft` | Draft indicator (draft-enabled BOs only)                            |
| `%pid`      | Preliminary ID (late numbering only)                                |
| `%target`   | Target instances for create-by-association                          |
| `%param`    | Action/function parameter values                                    |

## Best Practices

- Always use `strict ( 2 );` for new BOs
- Prefer `%tky` over `%key` — it survives draft/late-numbering transitions
- Always fill `%cid` in create operations even if not referenced later
- Use `IN LOCAL MODE` in handler methods to bypass feature controls and authorization checks
- Validations = consistency checks on save; determinations = derived/calculated fields on modify
- Keep handler methods focused; use ABP auxiliary classes for shared logic
- For managed BOs, only implement handler methods for non-standard operations

## Deep Dive

For managed-vs-unmanaged decision criteria, the numbering-strategy decision tree, determination trigger timing (`on modify` vs `on save` vs `determine action` — genuinely not covered above), which of these BDL constructs are release-gated (several "foundational-feeling" ones like `with additional save`/`numbering:managed`/`determine action` are newer than RAP itself), and a real (non-stub) unmanaged-save class body, read [references/deep-dive.md](references/deep-dive.md) — only when the sections above aren't enough for the case at hand.

## References

- [SAP ABAP Cheat Sheets — RAP BDL](https://github.com/SAP-samples/abap-cheat-sheets/blob/main/36_RAP_Behavior_Definition_Language.md)
- [SAP ABAP Cheat Sheets — EML](https://github.com/SAP-samples/abap-cheat-sheets/blob/main/08_EML_ABAP_for_RAP.md)
- [SAP Help — RAP Development Guide](https://help.sap.com/docs/abap-cloud/abap-rap/abap-restful-application-programming-model)
- [SAP Help — BDL Reference](https://help.sap.com/doc/abapdocu_cp_index_htm/CLOUD/en-US/ABENBDL.html)
- [ABAP Flight Reference Scenario](https://github.com/SAP-samples/abap-platform-refscen-flight)
