# BAdI Walkthroughs — Full Code

Read this when actually creating or implementing a BAdI; the SKILL.md body has the recipes and decision tables.

## Creating a Custom BAdI

### Step 2: Define the BAdI Interface

```abap
INTERFACE zif_badi_travel_validate
  PUBLIC.
  METHODS validate
    IMPORTING
      is_travel       TYPE zstravel
    CHANGING
      ct_messages     TYPE bapiret2_t
    RAISING
      cx_badi_not_implemented.
ENDINTERFACE.
```

### Step 4: Fallback Class (optional)

```abap
CLASS zcl_badi_travel_fallback DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_badi_travel_validate.
ENDCLASS.

CLASS zcl_badi_travel_fallback IMPLEMENTATION.
  METHOD zif_badi_travel_validate~validate.
    "Default behavior when no implementation is active
  ENDMETHOD.
ENDCLASS.
```

### Step 5: Call the BAdI

```abap
DATA lo_badi TYPE REF TO zif_badi_travel_validate.

GET BADI lo_badi.

"Call BAdI — loops through all active implementations
CALL BADI lo_badi->validate
  EXPORTING is_travel   = ls_travel
  CHANGING  ct_messages = lt_messages.
```

### With Filters

```abap
"In Enhancement Spot: add filter type COUNTRY (type LAND1)

GET BADI lo_badi
  FILTERS country = ls_travel-country.

CALL BADI lo_badi->validate
  EXPORTING is_travel   = ls_travel
  CHANGING  ct_messages = lt_messages.
```

## Implementing an Existing BAdI

### BAdI Implementation Class

```abap
CLASS zcl_badi_impl_travel_check DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_badi_travel_validate.
ENDCLASS.

CLASS zcl_badi_impl_travel_check IMPLEMENTATION.
  METHOD zif_badi_travel_validate~validate.
    "Custom validation logic
    IF is_travel-begin_date < cl_abap_context_info=>get_system_date( ).
      APPEND VALUE #(
        type       = 'E'
        id         = 'Z_TRAVEL'
        number     = '001'
        message_v1 = 'Travel begin date must be in the future'
      ) TO ct_messages.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

## Dynamic BAdI Calls

```abap
DATA lo_badi TYPE REF TO cl_badi_base.
DATA(lv_badi_name) = 'ZBADI_MY_BADI'.

GET BADI lo_badi TYPE (lv_badi_name).

CALL BADI lo_badi->('VALIDATE')
  EXPORTING is_data = ls_data.
```

## Classic-Only: Explicit Enhancement Points/Sections

> Standard ABAP only — NOT available in ABAP Cloud. On a Clean Core workspace these apply only to legacy on-prem/private-cloud maintenance, and never to modifying Standard objects (workspace rule §2).

```abap
"In SAP standard code:
ENHANCEMENT-POINT z_enh_point SPOTS z_enh_spot.

"In your enhancement implementation:
ENHANCEMENT z_my_enhancement.
  "Your custom code here
ENDENHANCEMENT.
```

```abap
"SAP code with replaceable section:
ENHANCEMENT-SECTION z_section SPOTS z_enh_spot.
  lv_result = lv_a + lv_b.   "Default code (can be replaced)
END-ENHANCEMENT-SECTION.

"Your replacement:
ENHANCEMENT z_my_section_impl.
  lv_result = lv_a * lv_b.
ENDENHANCEMENT.
```
