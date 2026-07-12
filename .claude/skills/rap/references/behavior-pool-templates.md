# ABAP Behavior Pool (ABP) Templates

Complete handler and saver class skeletons to copy and adapt. Read this when implementing a behavior pool (`zbp_*`) — actions, validations, determinations, feature control, or saver methods.

## Handler Class (lhc_*)

```abap
CLASS lhc_root DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    " Standard operations (unmanaged only)
    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Root.

    " Action implementation
    METHODS doSomething FOR MODIFY
      IMPORTING keys FOR ACTION Root~doSomething RESULT result.

    " Validation
    METHODS validateDescription FOR VALIDATE ON SAVE
      IMPORTING keys FOR Root~validateDescription.

    " Determination
    METHODS setDefaults FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Root~setDefaults.

    " Instance feature control
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Root RESULT result.

    " Instance authorization
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Root RESULT result.

ENDCLASS.

CLASS lhc_root IMPLEMENTATION.

  METHOD doSomething.
    " Read current instance data
    READ ENTITIES OF zr_root IN LOCAL MODE
      ENTITY Root
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(entities)
      FAILED failed.

    " Modify instances
    MODIFY ENTITIES OF zr_root IN LOCAL MODE
      ENTITY Root
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR entity IN entities
        ( %tky = entity-%tky
          Status = 'DONE'
          %control-Status = if_abap_behv=>mk-on ) )
      FAILED failed
      REPORTED reported.

    " Fill result
    result = VALUE #( FOR entity IN entities
      ( %tky = entity-%tky
        %param = entity ) ).
  ENDMETHOD.

  METHOD validateDescription.
    READ ENTITIES OF zr_root IN LOCAL MODE
      ENTITY Root
      FIELDS ( Description ) WITH CORRESPONDING #( keys )
      RESULT DATA(entities).

    LOOP AT entities INTO DATA(entity).
      IF entity-Description IS INITIAL.
        APPEND VALUE #( %tky = entity-%tky ) TO failed-root.
        APPEND VALUE #( %tky = entity-%tky
          %msg = new_message_with_text(
            severity = if_abap_behv_message=>severity-error
            text = 'Description must not be empty' )
          %element-Description = if_abap_behv=>mk-on
        ) TO reported-root.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD setDefaults.
    READ ENTITIES OF zr_root IN LOCAL MODE
      ENTITY Root
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(entities).

    MODIFY ENTITIES OF zr_root IN LOCAL MODE
      ENTITY Root
      UPDATE FIELDS ( Status )
      WITH VALUE #( FOR entity IN entities
        ( %tky = entity-%tky
          Status = 'NEW'
          %control-Status = if_abap_behv=>mk-on ) )
      REPORTED reported.
  ENDMETHOD.

ENDCLASS.
```

## Saver Class (lsc_*)

```abap
CLASS lsc_root DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS finalize REDEFINITION.
    METHODS check_before_save REDEFINITION.
    METHODS save_modified REDEFINITION.
    METHODS cleanup REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lsc_root IMPLEMENTATION.
  METHOD finalize.
    " Final calculations before save
  ENDMETHOD.

  METHOD check_before_save.
    " Final consistency checks
  ENDMETHOD.

  METHOD save_modified.
    " Only needed for 'with additional save' or 'with unmanaged save'.
    " This is also where business events are raised — see the
    " rap-business-events skill for event definition/binding/consumption.
  ENDMETHOD.

  METHOD cleanup.
    " Clear transactional buffer
  ENDMETHOD.

  METHOD cleanup_finalize.
    " Rollback finalize changes on failure
  ENDMETHOD.
ENDCLASS.
```
