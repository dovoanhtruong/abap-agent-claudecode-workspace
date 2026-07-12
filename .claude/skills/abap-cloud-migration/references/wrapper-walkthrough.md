# Tier-2 Wrapper Pattern — Full Walkthrough

Read this when actually building a wrapper for an unreleased API. Example wraps `READ_TEXT`/`SAVE_TEXT` (unreleased FMs).

## Step 1: Wrapper Interface (Tier 2, released for Cloud)

```abap
"Released for use in ABAP Cloud (C1 contract)
INTERFACE zif_text_handler
  PUBLIC.
  METHODS read_text
    IMPORTING iv_id          TYPE thead-tdid
              iv_name        TYPE thead-tdname
              iv_object      TYPE thead-tdobject
              iv_language    TYPE sy-langu DEFAULT sy-langu
    RETURNING VALUE(rt_text) TYPE tline_tab
    RAISING   zcx_text_error.

  METHODS save_text
    IMPORTING iv_id       TYPE thead-tdid
              iv_name     TYPE thead-tdname
              iv_object   TYPE thead-tdobject
              iv_language TYPE sy-langu DEFAULT sy-langu
              it_text     TYPE tline_tab
    RAISING   zcx_text_error.
ENDINTERFACE.
```

## Step 2: Wrapper Class (Tier 2, released for Cloud)

```abap
"Implementation uses unreleased FMs internally — OK in Tier 2
CLASS zcl_text_handler DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_text_handler.
ENDCLASS.

CLASS zcl_text_handler IMPLEMENTATION.
  METHOD zif_text_handler~read_text.
    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        id       = iv_id
        name     = iv_name
        object   = iv_object
        language = iv_language
      TABLES
        lines    = rt_text
      EXCEPTIONS
        OTHERS   = 1.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_text_error.
    ENDIF.
  ENDMETHOD.

  METHOD zif_text_handler~save_text.
    DATA ls_header TYPE thead.
    ls_header-tdid     = iv_id.
    ls_header-tdname   = iv_name.
    ls_header-tdobject = iv_object.
    ls_header-tdspras  = iv_language.

    CALL FUNCTION 'SAVE_TEXT'
      EXPORTING header = ls_header
      TABLES    lines  = it_text
      EXCEPTIONS OTHERS = 1.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE zcx_text_error.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

## Step 3: Release the Wrapper

In ADT, wrapper class properties:

1. **API State** tab
2. Add **Use System-Internally (C1)** contract
3. Set visibility to **Use in ABAP Cloud**

## Step 4: Consume from Tier 1

```abap
"Tier 1 (ABAP Cloud) code — uses released wrapper
DATA(lo_text) = NEW zcl_text_handler( ).
DATA(lt_text) = lo_text->zif_text_handler~read_text(
  iv_id     = 'ST'
  iv_name   = lv_doc_name
  iv_object = 'VBBK' ).
```

## Design rules

- Expose clean, typed signatures — never leak the unreleased API's structures unnecessarily.
- Class-based exceptions, not sy-subrc, at the wrapper boundary.
- Plan to retire the wrapper when SAP releases a proper API (that's the point of Tier 2).
