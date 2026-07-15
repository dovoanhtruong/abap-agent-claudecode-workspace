---
name: abap-cloud
description: Explain ABAP Cloud development concepts — the official 3-tier extensibility model, ABAP Cloud language version restrictions, clean core principles, key user vs developer extensibility, and how to discover released APIs. Use when users ask conceptual questions about ABAP Cloud, clean core, tier 1/2/3, restricted ABAP language scope, embedded Steampunk, or "is X allowed in ABAP Cloud". Triggers include "ABAP Cloud restrictions", "clean core", "tier model", "ABAP language version", "Steampunk", "extensibility model". For migrating existing classic code (wrappers, replacements) use abap-cloud-migration instead; for configuring ATC cloud-readiness check variants use atc-cloudification; for BTP system provisioning/connectivity use btp-abap-environment.
---

# ABAP Cloud / Clean Core

Conceptual guide for the ABAP Cloud programming model, the official 3-tier extensibility model, and clean core principles.

## ABAP Language Versions

| Language Version               | Scope                                                         | Available In                                       |
| ------------------------------ | ------------------------------------------------------------- | -------------------------------------------------- |
| **ABAP for Cloud Development** | Only released APIs and objects; restricted syntax; no SAP GUI | BTP ABAP Environment, S/4HANA Cloud, S/4HANA (embedded Steampunk) |
| **Standard ABAP**              | Full ABAP syntax; all repository objects accessible           | On-premise, private cloud                          |

### Key Restrictions in ABAP for Cloud Development

- Only released SAP APIs (C1 contract) can be used
- No direct database access to SAP tables (use released CDS views instead)
- No classic dynpro, selection screens, or SAP GUI-dependent statements
- No `CALL TRANSACTION`, no `SUBMIT` (use background jobs via `CL_APJ_RT_API` or RAP actions)
- `AUTHORITY-CHECK OBJECT` IS available (released statement) — combine with RAP authorization handlers and CDS access control (DCL); see the authorization-iam skill
- No classic BAdIs or user exits (new BAdIs via released enhancement spots only)
- No `EXEC SQL` / native SQL (use ABAP SQL or AMDP)
- No unreleased function modules; no `INCLUDE` programs
- No `WRITE` / classic list output — use `if_oo_adt_classrun` for console output

## 3-Tier Extensibility Model (official SAP numbering)

| Tier | Name | What it means |
|---|---|---|
| **Tier 1** | **ABAP Cloud (cloud-ready development)** | The default for all new development. ABAP for Cloud Development language version, released APIs only, RAP-based. Works identically on BTP, S/4HANA Cloud Public Edition, and on-premise/private with cloud language version. |
| **Tier 2** | **Cloud API enablement** | Bridge tier for missing released APIs: build a wrapper around an unreleased SAP object in Standard ABAP, release the wrapper yourself with a C1 contract, consume it from Tier 1. Retire the wrapper when SAP releases a proper API. Not available on S/4HANA Cloud Public Edition (no unreleased-object access there). |
| **Tier 3** | **Legacy development (classic ABAP)** | Full classic ABAP, all repository objects, classic enhancements. On-premise/private cloud only. Avoid for new development. |

> Common confusion this table exists to prevent: **key user extensibility is NOT one of these tiers.** It is a separate, no-code extensibility track (custom fields/logic via Fiori apps) that sits alongside developer extensibility. Older material sometimes numbers "Tier 1 = key user" — that is not SAP's official ABAP Cloud tier model.

### Wrapper pattern (Tier 2) in one paragraph

Wrap the unreleased API in a Z-class/interface written in Standard ABAP, expose only clean typed signatures, release the wrapper with a C1 contract in ADT, consume it from Tier 1 code. For the full step-by-step wrapper walkthrough, replacement tables, and migration workflow, use the **abap-cloud-migration** skill — that skill owns the how-to; this one owns the concept.

## Released API Discovery

| Method                          | Description                                                   |
| ------------------------------- | ------------------------------------------------------------- |
| **ADT: Released Object Search** | In ADT, search with `api:` prefix (e.g., `api:cl_*`)          |
| **Cloudification API Viewer**   | Browse at https://sap.github.io/abap-atc-cr-cv-s4hc/          |
| **ATC Cloud Readiness Check**   | Run ATC checks to identify unreleased API usage (setup: atc-cloudification skill) |
| **released-abap-classes skill** | Lookup table of common released classes by use case           |
| **find-released-cds-view skill**| Map a business field/table to its released CDS view           |
| **XCO Library**                 | `XCO_CP_*` classes provide cloud-ready alternatives           |

## Common Unreleased → Released Replacements (illustrative, not exhaustive)

| Unreleased (Classic)        | Released Alternative (ABAP Cloud)                 |
| --------------------------- | ------------------------------------------------- |
| `sy-uname`                  | `cl_abap_context_info=>get_user_technical_name()` |
| `CALL TRANSACTION`          | RAP action or Fiori navigation                     |
| Direct SAP table `SELECT`   | Released CDS view (I\_\* views)                   |

These 3 rows are only a taste of the pattern (unreleased construct → released alternative). The **full** replacement tables (Database Access, Function Modules → Released Classes, Language Constructs — 28 rows total) live in **[Skill: abap-cloud-migration]** — go there for anything beyond a quick illustration.

## Deep Dive

For concrete "is X allowed" edge cases beyond the headline restrictions (e.g. `cl_salv_table`, `READ REPORT`, `GET REFERENCE OF`), the non-obvious "a C1-released class can still warn" type-compatibility trap, and verified C0/C1 release-contract history, read [references/deep-dive.md](references/deep-dive.md).

## References

- SAP Cloudification Repository: https://github.com/SAP/abap-atc-cr-cv-s4hc
- ABAP Cloud Cheat Sheet: https://github.com/SAP-samples/abap-cheat-sheets
- Clean Core Guidelines: https://help.sap.com/docs/abap-cloud
