---
name: modern-abap-syntax
description: Help with modern ABAP syntax for Cloud Development including constructor expressions, inline declarations, string processing, dynamic programming, and built-in functions. Use when users ask about ABAP syntax, VALUE, COND, SWITCH, REDUCE, FILTER, FOR loops, string templates, Field Symbols, Date and Time functions, built-in functions, or numeric operations. Triggers include "constructor expression", "string template", "REDUCE", "VALUE", "inline declaration", "cú pháp abap", "abap syntax".
---

# Modern ABAP Syntax

Guide for writing modern, efficient ABAP code focusing on ABAP for Cloud Development constructs.

## Workflow

1. **Determine the user's goal**:
   - Refactoring old procedural ABAP into modern functional ABAP
   - Working with internal tables using constructor expressions
   - String concatenation and manipulation
   - Dynamic programming with field symbols and data references

2. **Guide implementation** using the correct modern language construct.

## Quick Reference

### Inline Declarations

```abap
" Variables
DATA(text) = `Hello World`.
DATA(number) = 42.

" Field Symbols
ASSIGN component 'NAME' OF STRUCTURE struct TO FIELD-SYMBOL(<value>).
LOOP AT itab ASSIGNING FIELD-SYMBOL(<line>).
```

### Constructor Expressions

#### VALUE (Initialization)

```abap
" Initialize structures
DATA(struct) = VALUE zstruct( id = 1 name = 'Test' ).

" Initialize internal tables
DATA(itab) = VALUE ztab( 
  ( id = 1 name = 'One' ) 
  ( id = 2 name = 'Two' ) 
).

" Appending to existing table
itab = VALUE #( BASE itab ( id = 3 name = 'Three' ) ).
```

#### COND and SWITCH (Conditionals)

```abap
" COND (If-Else equivalent)
DATA(status_text) = COND string(
  WHEN status = 'N' THEN `New`
  WHEN status = 'P' THEN `Processing`
  ELSE `Unknown`
).

" SWITCH (Case equivalent)
DATA(priority) = SWITCH i( status
  WHEN 'N' THEN 1
  WHEN 'P' THEN 2
  ELSE 3
).
```

#### EXACT, REF, and CAST

```abap
" EXACT (Lossless assignment)
DATA(exact_val) = EXACT i( '123' ).

" REF (Data reference)
DATA(dref) = REF #( itab ).

" CAST (Downcast/Upcast)
DATA(interface_ref) = CAST zif_my_interface( class_instance ).
```

### Internal Table Operations

#### FOR Iteration (Table Comprehension)

```abap
" Simple mapping
DATA(names) = VALUE string_table( FOR row IN itab ( row-name ) ).

" With WHERE condition
DATA(active_names) = VALUE string_table( 
  FOR row IN itab WHERE ( status = 'A' ) 
  ( row-name ) 
).
```

#### REDUCE (Aggregation)

```abap
" Summing values
DATA(total) = REDUCE i( 
  INIT sum = 0
  FOR row IN itab WHERE ( status = 'A' )
  NEXT sum = sum + row-amount 
).
```

#### FILTER (Filtering tables)

```abap
" Requires SORTED or HASHED table key
DATA(active_only) = FILTER #( itab USING KEY status_key WHERE status = 'A' ).
```

#### LINE_EXISTS and Table Indexing

```abap
IF line_exists( itab[ id = 123 ] ).
  DATA(line) = itab[ id = 123 ].
ENDIF.

" Safe read with OPTIONAL
DATA(line_safe) = VALUE #( itab[ id = 123 ] OPTIONAL ).
```

### String Processing

```abap
" String Templates
DATA(msg) = |Hello { name }, your balance is { amount NUMBER = USER }|.

" Embedded formatting
DATA(date_str) = |{ sy-datum DATE = ISO }|.
DATA(alpha) = |{ customer_id ALPHA = OUT }|.

" String expressions
DATA(concat) = `Prefix` && `Suffix`.
```

### Built-In Functions

```abap
" String functions
DATA(upper) = to_upper( text ).
DATA(lower) = to_lower( text ).
DATA(len) = strlen( text ).
DATA(pos) = find( val = text sub = 'AB' ).
DATA(replaced) = replace( val = text sub = 'X' with = 'Y' ).

" Table functions
DATA(count) = lines( itab ).
```

### Dynamic Programming

```abap
" Assign component dynamically
ASSIGN COMPONENT 'FIELD_NAME' OF STRUCTURE struct TO FIELD-SYMBOL(<field>).
IF sy-subrc = 0.
  <field> = 'New Value'.
ENDIF.

" Create data dynamically (RTTC)
DATA dref TYPE REF TO data.
CREATE DATA dref TYPE (type_name).
ASSIGN dref->* TO FIELD-SYMBOL(<dyn_data>).
```

## References
- SAP ABAP Cheat Sheets — Constructor Expressions, Internal Tables, String Processing, Dynamic Programming.
