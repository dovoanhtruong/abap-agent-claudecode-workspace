# BDEF Templates

Complete, syntactically correct BDEF templates to copy and adapt. Read this when writing a new behavior definition or projection BDEF from scratch.

## Complete BDEF Structure (Managed, Draft, Root + Child)

```
managed implementation in class zbp_r_root unique;
strict ( 2 );
with draft;

define behavior for ZR_Root alias Root
persistent table zroot_tab
draft table zroot_d
etag master LocalLastChangedAt
lock master
total etag LastChangedAt
authorization master ( global )
late numbering
{
  // Field characteristics
  field ( readonly ) RootUUID, CreatedBy, CreatedAt, LastChangedBy, LastChangedAt;
  field ( mandatory ) Description;
  field ( numbering : managed ) RootUUID;

  // Standard operations
  create;
  update;
  delete;

  // Association to child entity
  association _Child { create; }

  // Actions
  action doSomething result [1] $self;
  static action createFromTemplate parameter ZD_CreateParam result [1] $self;
  internal action recalculate;

  // Validations
  validation validateDescription on save { create; field Description; }

  // Determinations
  determination setDefaults on modify { create; }
  determination calcTotal on modify { field Quantity, Price; }

  // Draft actions
  draft action Resume;
  draft action Edit;
  draft action Activate optimized;
  draft action Discard;
  draft determine action Prepare
  {
    validation validateDescription;
  }

  // Side effects
  side effects
  {
    field Quantity affects field TotalAmount;
    field Price affects field TotalAmount;
    determine action Prepare executed on field Description affects messages;
  }

  // Events
  event created;
  event deleted parameter ZD_DeletedEvent;

  // Mapping
  mapping for zroot_tab corresponding
  {
    RootUUID = root_uuid;
    Description = description;
  }
}

define behavior for ZR_Child alias Child
persistent table zchild_tab
draft table zchild_d
etag master LocalLastChangedAt
lock dependent by _Root
authorization dependent by _Root
{
  field ( readonly ) ChildUUID, RootUUID;
  field ( numbering : managed ) ChildUUID;

  update;
  delete;

  association _Root;

  mapping for zchild_tab corresponding
  {
    ChildUUID = child_uuid;
    RootUUID = root_uuid;
  }
}
```

## Projection BDEF

```
projection;
strict ( 2 );
use draft;

define behavior for ZC_Root alias Root
{
  use create;
  use update;
  use delete;

  use action doSomething;

  use association _Child { create; }
}

define behavior for ZC_Child alias Child
{
  use update;
  use delete;

  use association _Root;
}
```
