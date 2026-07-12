# RAP Business Events — Code Examples

Full raising/consumption code. Read this when implementing an event producer or consumer; the SKILL.md body has the concepts and configuration steps.

## Event Definition in BDEF

```
define behavior for ZR_Travel alias Travel
...
{
  create; update; delete;

  "Define business events
  event travel_created parameter ZD_TravelCreatedEvt;
  event travel_accepted;
  event travel_rejected;
}
```

Events without the `parameter` addition have no payload.

## Event Parameter Structure (CDS abstract entity)

```cds
@EndUserText.label: 'Travel Created Event'
define abstract entity ZD_TravelCreatedEvt
{
  travel_id   : /dmo/travel_id;
  agency_id   : /dmo/agency_id;
  customer_id : /dmo/customer_id;
  description : /dmo/description;
  total_price : /dmo/total_price;
  currency    : /dmo/currency_code;
}
```

## Raising in Handler Methods

```abap
METHOD on_travel_accept.
  READ ENTITIES OF zr_travel IN LOCAL MODE
    ENTITY Travel
    ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

  MODIFY ENTITIES OF zr_travel IN LOCAL MODE
    ENTITY Travel
    UPDATE FIELDS ( status )
    WITH VALUE #( FOR travel IN lt_travels
      ( %tky = travel-%tky  status = 'A' ) )
    REPORTED DATA(lt_reported).

  RAISE ENTITY EVENT zr_travel~travel_accepted
    FROM VALUE #( FOR travel IN lt_travels
      ( %key = travel-%key ) ).
ENDMETHOD.
```

## Raising with Parameters

```abap
RAISE ENTITY EVENT zr_travel~travel_created
  FROM VALUE #( FOR travel IN lt_created_travels
    ( %key = travel-%key
      %param = VALUE #(
        travel_id   = travel-travel_id
        agency_id   = travel-agency_id
        customer_id = travel-customer_id
        description = travel-description
        total_price = travel-total_price
        currency    = travel-currency_code ) ) ).
```

## Raising in Saver Methods (additional save)

```abap
METHOD save_modified.
  IF create-travel IS NOT INITIAL.
    RAISE ENTITY EVENT zr_travel~travel_created
      FROM VALUE #( FOR travel IN create-travel
        ( %key = travel-%key
          %param = VALUE #( travel_id = travel-travel_id ) ) ).
  ENDIF.
ENDMETHOD.
```

## Local Event Consumption (same system)

```abap
CLASS zcl_travel_event_handler DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS on_travel_created
      FOR ENTITY EVENT
      travel_created FOR Travel~travel_created.
ENDCLASS.

CLASS zcl_travel_event_handler IMPLEMENTATION.
  METHOD on_travel_created.
    LOOP AT travel_created INTO DATA(ls_event).
      DATA(lv_travel_id) = ls_event-travel_id.
      "e.g., send notification, update related records
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
```

## Consuming External Events in ABAP

```abap
"1. Create an event consumption model in ADT
"   (imports AsyncAPI spec or defines events manually)

"2. Implement the event handler
CLASS zcl_ext_event_handler DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_event_handler.
ENDCLASS.

CLASS zcl_ext_event_handler IMPLEMENTATION.
  METHOD if_event_handler~handle.
    DATA(lv_payload) = io_event->get_text( ).
    "Process the event
  ENDMETHOD.
ENDCLASS.
```
