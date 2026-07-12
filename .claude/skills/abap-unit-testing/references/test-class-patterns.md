# Test Class & Dependency Injection Patterns

Full skeletons for test classes and manual test doubles. Read this when writing a test class; the SKILL.md body has the decision guidance and assertion reference.

## Test Class Skeleton

```abap
"! Test class for ZCL_MY_CLASS
CLASS ltc_my_class DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_my_class.  "Class Under Test

    CLASS-METHODS class_setup.    "Once before all tests
    CLASS-METHODS class_teardown. "Once after all tests
    METHODS setup.               "Before each test
    METHODS teardown.            "After each test

    METHODS test_calculate_total FOR TESTING.
    METHODS test_empty_input     FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltc_my_class IMPLEMENTATION.

  METHOD class_setup.
    " One-time setup (e.g., create test environments)
  ENDMETHOD.

  METHOD class_teardown.
    " One-time cleanup (e.g., environment->destroy( ))
  ENDMETHOD.

  METHOD setup.
    cut = NEW #( ).   "fresh instance per test
  ENDMETHOD.

  METHOD teardown.
  ENDMETHOD.

  METHOD test_calculate_total.
    " Arrange
    DATA(lv_quantity) = 5.
    DATA(lv_price) = CONV decfloat34( '10.50' ).

    " Act
    DATA(lv_result) = cut->calculate_total(
      iv_quantity = lv_quantity
      iv_price    = lv_price ).

    " Assert
    cl_abap_unit_assert=>assert_equals(
      act = lv_result
      exp = CONV decfloat34( '52.50' )
      msg = 'Total should be quantity * price' ).
  ENDMETHOD.

  METHOD test_empty_input.
    TRY.
        cut->validate_input( '' ).
        cl_abap_unit_assert=>fail( msg = 'Should have raised exception' ).
      CATCH zcx_validation_error INTO DATA(lx_error).
        cl_abap_unit_assert=>assert_bound(
          act = lx_error
          msg = 'Exception should be raised for empty input' ).
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
```

## Constructor Injection Pattern

```abap
" Production interface
INTERFACE zif_data_provider.
  METHODS get_data
    RETURNING VALUE(rt_data) TYPE ztab_data.
ENDINTERFACE.

" Production class with injectable dependency
CLASS zcl_processor DEFINITION.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_provider TYPE REF TO zif_data_provider OPTIONAL.
    METHODS process
      RETURNING VALUE(rv_result) TYPE string.
  PRIVATE SECTION.
    DATA mo_provider TYPE REF TO zif_data_provider.
ENDCLASS.

CLASS zcl_processor IMPLEMENTATION.
  METHOD constructor.
    mo_provider = COND #(
      WHEN io_provider IS BOUND THEN io_provider
      ELSE NEW zcl_default_provider( ) ).
  ENDMETHOD.

  METHOD process.
    DATA(lt_data) = mo_provider->get_data( ).
    " Process data...
  ENDMETHOD.
ENDCLASS.
```

## Manual Test Double

```abap
" Test double implementing the interface
CLASS ltd_data_provider DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES zif_data_provider.
    DATA mt_test_data TYPE ztab_data.
ENDCLASS.

CLASS ltd_data_provider IMPLEMENTATION.
  METHOD zif_data_provider~get_data.
    rt_data = mt_test_data.
  ENDMETHOD.
ENDCLASS.

" Test class using the double
CLASS ltc_processor DEFINITION FINAL FOR TESTING
  DURATION SHORT RISK LEVEL HARMLESS.
  PRIVATE SECTION.
    DATA cut         TYPE REF TO zcl_processor.
    DATA mo_provider TYPE REF TO ltd_data_provider.

    METHODS setup.
    METHODS test_process_with_data FOR TESTING.
ENDCLASS.

CLASS ltc_processor IMPLEMENTATION.
  METHOD setup.
    mo_provider = NEW #( ).
    cut = NEW #( io_provider = mo_provider ).
  ENDMETHOD.

  METHOD test_process_with_data.
    " Arrange — configure test double
    mo_provider->mt_test_data = VALUE #(
      ( key = '1' value = 'A' )
      ( key = '2' value = 'B' ) ).

    " Act
    DATA(lv_result) = cut->process( ).

    " Assert
    cl_abap_unit_assert=>assert_not_initial( act = lv_result ).
  ENDMETHOD.
ENDCLASS.
```

## Common Assertion Patterns

```abap
" Check table has expected number of entries
cl_abap_unit_assert=>assert_equals(
  act = lines( lt_result )
  exp = 3
  msg = 'Expected 3 result entries' ).

" Check exception message
TRY.
    cut->some_method( ).
    cl_abap_unit_assert=>fail( msg = 'Expected exception' ).
  CATCH zcx_my_exception INTO DATA(lx).
    cl_abap_unit_assert=>assert_equals(
      act = lx->get_text( )
      exp = 'Expected error message' ).
ENDTRY.

" Check that table contains a specific key
cl_abap_unit_assert=>assert_table_contains(
  line  = VALUE zstructure( key_field = 'ABC' )
  table = lt_result
  msg   = 'Result should contain entry ABC' ).
```
