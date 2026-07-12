---
name: abap-unit-testing
description: Help with ABAP Unit testing including test class setup, assertions, test doubles, mocking frameworks, dependency injection, CDS test environments, SQL test environments, RAP BO test doubles, and test fixtures. Use when users ask about ABAP unit tests, test classes, test methods, CL_ABAP_UNIT_ASSERT, test doubles, mocking, CDS test environment, SQL test environment, RAP testing, ABAP test injection, test seams, behavior-driven testing, TDD in ABAP, test isolation, or writing automated tests for ABAP code. Triggers include "write a unit test", "create test class", "mock a dependency", "test a CDS view", "test a RAP BO", "test double", "assertion", "test fixture", "test isolation", or "ABAP unit".
---

# ABAP Unit Testing

Guide for effective ABAP Unit tests. This body holds the decision guidance and lookup tables; full skeletons live in references/ — read them when writing the actual test class.

## Choosing the Approach

| Situation | Approach |
|---|---|
| Pure logic, no dependencies | Direct unit test on the class |
| Class depends on other objects | Interface + constructor/setter injection + manual test double |
| Code SELECTs from a CDS view | CDS test environment (`cl_cds_test_environment`) |
| Code SELECTs from tables/views | OSQL test environment (`cl_osql_test_environment`) |
| Code consumes a RAP BO via EML | Transactional buffer double (`cl_botd_txbufdbl_bo_test_env`) |
| Testing RAP handler implementations | Mock EML API (`cl_botd_mockemlapi_bo_test_env`) |
| Untestable legacy code | `TEST-SEAM` / `TEST-INJECTION` — last resort; prefer injection for new code |

Follow AAA (Arrange → Act → Assert). Tests must not depend on persistent data, external systems, or each other.

> Skeletons: test class + fixture methods, constructor injection, manual test double, assertion patterns — read [references/test-class-patterns.md](references/test-class-patterns.md).
> Test environments (CDS/OSQL/RAP BO doubles) full examples — read [references/test-environment-examples.md](references/test-environment-examples.md).

## Test Class Attributes

| Attribute    | Options                               | Purpose                                                |
| ------------ | ------------------------------------- | ------------------------------------------------------ |
| `DURATION`   | `SHORT` / `MEDIUM` / `LONG`           | Expected execution time; `SHORT` < 1s (default for CI) |
| `RISK LEVEL` | `HARMLESS` / `DANGEROUS` / `CRITICAL` | Impact on system data; `HARMLESS` = no DB changes      |

Fixture methods: `class_setup`/`class_teardown` (once per class — create/destroy test environments here), `setup`/`teardown` (per test — fresh CUT instance, `clear_doubles( )`).

## CL_ABAP_UNIT_ASSERT — Key Methods

`assert_equals` · `assert_true` / `assert_false` · `assert_initial` / `assert_not_initial` · `assert_bound` / `assert_not_bound` · `assert_differs` · `assert_table_contains` / `assert_table_not_contains` · `fail`

Less obvious ones:

| Method                  | Purpose                                                       |
| ----------------------- | -------------------------------------------------------------- |
| `assert_char_cp` / `assert_char_np` | Character pattern (mis)match, e.g. `exp = '*error*'` |
| `assert_number_between` | `number = val lower = 1 upper = 10`                            |
| `assert_return_code`    | sy-subrc check after classic calls                             |

## Test Environments (lifecycle in one line each)

- **CDS**: `cl_cds_test_environment=>create( i_for_entity = 'ZI_ENTITY' )` stubs all data sources; `insert_test_data( )` per test, `clear_doubles( )` in `setup`, `destroy( )` in `class_teardown`.
- **OSQL**: `cl_osql_test_environment=>create( i_dependency_list = ... )` — same lifecycle.
- **RAP BO**: buffer double for EML consumers; mock EML API for handler tests.

## Best Practices

- One behavior per test; descriptive names (`test_reject_negative_quantity`, not `test_1`)
- Tests independent of each other and of execution order
- Local test include in ADT; prefix `ltc_` (test class) / `ltd_` (test double)
- **Test**: business logic, validations, edge cases (empty/boundary/null), CDS calculations, RAP handler logic
- **Don't test**: framework-provided managed CRUD, trivial getters/setters, ABAP runtime behavior

## References

- [references/test-class-patterns.md](references/test-class-patterns.md) — test class, DI, test double, assertion patterns
- [references/test-environment-examples.md](references/test-environment-examples.md) — CDS/OSQL/RAP BO environment examples
- [SAP ABAP Cheat Sheets — ABAP Unit Tests](https://github.com/SAP-samples/abap-cheat-sheets/blob/main/14_ABAP_Unit_Tests.md)
- [SAP Help — CDS Test Double Framework](https://help.sap.com/docs/abap-cloud/abap-development-tools-user-guide/cds-test-double-framework)
- [Clean ABAP — Testing](https://github.com/SAP/styleguides/blob/main/clean-abap/CleanABAP.md#testing)
