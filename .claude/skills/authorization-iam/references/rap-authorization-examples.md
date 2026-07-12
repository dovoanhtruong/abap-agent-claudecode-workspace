# RAP Authorization — Handler Implementations

Read this when implementing instance/global authorization in a behavior pool. Code checks use `AUTHORITY-CHECK` (the released mechanism — there is no `CL_ABAP_AUTHORIZATION` class).

## Instance Authorization

```abap
"In behavior definition:
define behavior for ZR_Travel alias Travel
  authorization master ( instance )
{
  ...
}
```

```abap
METHOD get_instance_authorizations.
  READ ENTITIES OF zr_travel IN LOCAL MODE
    ENTITY Travel
    FIELDS ( carrier_id )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travels).

  LOOP AT lt_travels INTO DATA(ls_travel).
    DATA(lv_actvt) = COND char2(
      WHEN requested_authorizations-%update = if_abap_behv=>mk-on THEN '02'
      WHEN requested_authorizations-%delete = if_abap_behv=>mk-on THEN '06'
      ELSE '03' ).

    AUTHORITY-CHECK OBJECT 'Z_MY_AUTH'
      ID 'ZCARR' FIELD ls_travel-carrier_id
      ID 'ACTVT' FIELD lv_actvt.
    DATA(lv_authorized) = xsdbool( sy-subrc = 0 ).

    APPEND VALUE #(
      %tky = ls_travel-%tky
      %update = COND #( WHEN lv_authorized = abap_true THEN if_abap_behv=>auth-allowed
                        ELSE if_abap_behv=>auth-unauthorized )
      %delete = COND #( WHEN lv_authorized = abap_true THEN if_abap_behv=>auth-allowed
                        ELSE if_abap_behv=>auth-unauthorized )
    ) TO result.
  ENDLOOP.
ENDMETHOD.
```

## Global Authorization

```abap
"In behavior definition:
define behavior for ZR_Travel alias Travel
  authorization master ( global )
{
  ...
}
```

```abap
METHOD get_global_authorizations.
  AUTHORITY-CHECK OBJECT 'Z_MY_AUTH'
    ID 'ACTVT' FIELD '01'.  "Create

  IF sy-subrc = 0.
    result-%create = if_abap_behv=>auth-allowed.
  ELSE.
    result-%create = if_abap_behv=>auth-unauthorized.
  ENDIF.
ENDMETHOD.
```

## On-Premise: PFCG Roles

1. Open `PFCG` transaction
2. Enter role name (e.g., `Z_TRAVEL_DISPLAY`)
3. **Menu tab**: Add transaction codes, Fiori tiles, or apps
4. **Authorizations tab**: Maintain authorization objects/field values, generate the profile
5. **User tab**: Assign users

Composite roles bundle single roles:

```
Z_TRAVEL_COMPOSITE (Composite Role)
├── Z_TRAVEL_DISPLAY (display only)
├── Z_TRAVEL_EDIT (create/change)
└── Z_TRAVEL_ADMIN (full access)
```
