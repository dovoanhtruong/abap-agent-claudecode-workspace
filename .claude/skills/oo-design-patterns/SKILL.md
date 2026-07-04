---
name: oo-design-patterns
description: Help with Object-Oriented Design Patterns (GoF) implemented in ABAP. Use when users ask about design patterns, Singleton, Factory, Observer, Strategy, Decorator, Builder, State, Command, Adapter, Facade, Composite, Iterator, Proxy, or OOP best practices. Triggers include "design pattern", "singleton", "factory", "observer", "strategy", "mẫu thiết kế", "oop abap".
---

# OO Design Patterns in ABAP

Guide for implementing standard Object-Oriented Design Patterns (Gang of Four) using modern ABAP constructs.

## Workflow

1. **Understand the problem domain**: What is the structural, creational, or behavioral issue the user is trying to solve?
2. **Select the appropriate pattern**:
   - Creational: Singleton, Factory, Builder
   - Structural: Adapter, Decorator, Facade, Composite
   - Behavioral: Strategy, Observer, Command, State
3. **Implement using modern ABAP**: Emphasize interfaces, composition over inheritance, and clean ABAP principles.

## Creational Patterns

### Singleton

Ensures a class has only one instance and provides a global point of access to it.

```abap
CLASS zcl_singleton DEFINITION PUBLIC CREATE PRIVATE.
  PUBLIC SECTION.
    CLASS-METHODS get_instance
      RETURNING VALUE(ro_instance) TYPE REF TO zcl_singleton.
  PRIVATE SECTION.
    CLASS-DATA mo_instance TYPE REF TO zcl_singleton.
ENDCLASS.

CLASS zcl_singleton IMPLEMENTATION.
  METHOD get_instance.
    IF mo_instance IS NOT BOUND.
      mo_instance = NEW #( ).
    ENDIF.
    ro_instance = mo_instance.
  ENDMETHOD.
ENDCLASS.
```

### Factory Method

Defines an interface for creating an object, but lets subclasses decide which class to instantiate.

```abap
INTERFACE zif_document.
  METHODS print.
ENDINTERFACE.

CLASS zcl_pdf_document DEFINITION PUBLIC.
  PUBLIC SECTION. INTERFACES zif_document.
ENDCLASS.

CLASS zcl_document_factory DEFINITION PUBLIC.
  PUBLIC SECTION.
    CLASS-METHODS create_document
      IMPORTING type TYPE string
      RETURNING VALUE(ro_doc) TYPE REF TO zif_document.
ENDCLASS.

CLASS zcl_document_factory IMPLEMENTATION.
  METHOD create_document.
    ro_doc = COND #( 
      WHEN type = 'PDF' THEN NEW zcl_pdf_document( )
      WHEN type = 'DOC' THEN NEW zcl_word_document( ) 
    ).
  ENDMETHOD.
ENDCLASS.
```

## Behavioral Patterns

### Strategy

Defines a family of algorithms, encapsulates each one, and makes them interchangeable.

```abap
INTERFACE zif_tax_strategy.
  METHODS calculate_tax 
    IMPORTING amount TYPE decfloat34 
    RETURNING VALUE(tax) TYPE decfloat34.
ENDINTERFACE.

CLASS zcl_us_tax DEFINITION PUBLIC.
  PUBLIC SECTION. INTERFACES zif_tax_strategy.
ENDCLASS.

CLASS zcl_order DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS constructor IMPORTING io_tax_strategy TYPE REF TO zif_tax_strategy.
    METHODS get_total RETURNING VALUE(total) TYPE decfloat34.
  PRIVATE SECTION.
    DATA mo_tax_strategy TYPE REF TO zif_tax_strategy.
ENDCLASS.

CLASS zcl_order IMPLEMENTATION.
  METHOD constructor.
    mo_tax_strategy = io_tax_strategy.
  ENDMETHOD.
  METHOD get_total.
    " Calculate base total then apply strategy
    total = base_total + mo_tax_strategy->calculate_tax( base_total ).
  ENDMETHOD.
ENDCLASS.
```

### Observer

Defines a one-to-many dependency so that when one object changes state, all its dependents are notified.

```abap
INTERFACE zif_observer.
  METHODS update IMPORTING state TYPE string.
ENDINTERFACE.

CLASS zcl_subject DEFINITION PUBLIC.
  PUBLIC SECTION.
    METHODS attach IMPORTING io_observer TYPE REF TO zif_observer.
    METHODS notify.
    METHODS set_state IMPORTING state TYPE string.
  PRIVATE SECTION.
    DATA mt_observers TYPE TABLE OF REF TO zif_observer.
    DATA mv_state TYPE string.
ENDCLASS.

CLASS zcl_subject IMPLEMENTATION.
  METHOD attach.
    APPEND io_observer TO mt_observers.
  ENDMETHOD.
  METHOD notify.
    LOOP AT mt_observers INTO DATA(lo_observer).
      lo_observer->update( mv_state ).
    ENDLOOP.
  ENDMETHOD.
  METHOD set_state.
    mv_state = state.
    notify( ).
  ENDMETHOD.
ENDCLASS.
```

## Structural Patterns

### Decorator

Attaches additional responsibilities to an object dynamically.

```abap
INTERFACE zif_component.
  METHODS operation RETURNING VALUE(result) TYPE string.
ENDINTERFACE.

CLASS zcl_decorator DEFINITION PUBLIC ABSTRACT.
  PUBLIC SECTION.
    INTERFACES zif_component.
    METHODS constructor IMPORTING io_component TYPE REF TO zif_component.
  PROTECTED SECTION.
    DATA mo_component TYPE REF TO zif_component.
ENDCLASS.

CLASS zcl_decorator IMPLEMENTATION.
  METHOD constructor. mo_component = io_component. ENDMETHOD.
  METHOD zif_component~operation. result = mo_component->operation( ). ENDMETHOD.
ENDCLASS.

CLASS zcl_concrete_decorator DEFINITION INHERITING FROM zcl_decorator PUBLIC.
  PUBLIC SECTION.
    METHODS zif_component~operation REDEFINITION.
ENDCLASS.

CLASS zcl_concrete_decorator IMPLEMENTATION.
  METHOD zif_component~operation.
    result = super->zif_component~operation( ) && ` + Extra Behavior`.
  ENDMETHOD.
ENDCLASS.
```

## References
- SAP ABAP Cheat Sheets — OO Design Patterns (Branch: oo_patterns)
