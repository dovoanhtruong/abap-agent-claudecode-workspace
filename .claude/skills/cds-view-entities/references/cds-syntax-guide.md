# CDS View Entity Syntax Guide (RAP Composition)

Copy-paste syntax templates for RAP composition-tree modeling. Read the section you need when actually writing a view — the SKILL.md body has the decision tables. For a plain/basic view entity template (no composition) and everything else (expressions, aggregates, input parameters, joins, UI annotations), see [Skill: cds-analytical-views]'s reference instead.

## Root View Entity (for RAP)

```cds
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Sales Order Root'
define root view entity ZR_SalesOrder
  as select from zsalesorder
  composition [0..*] of ZR_SalesOrderItem as _Item
{
  key order_uuid         as OrderUUID,
      order_id           as OrderId,
      customer_id        as CustomerId,
      order_date         as OrderDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      net_amount         as NetAmount,
      currency_code      as CurrencyCode,
      status             as Status,

      @Semantics.user.createdBy: true
      created_by         as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at         as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at    as LastChangedAt,

      _Item
}
```

## Child View Entity

```cds
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Sales Order Item'
define view entity ZR_SalesOrderItem
  as select from zsalesorder_item
  association to parent ZR_SalesOrder as _Order
    on $projection.OrderUUID = _Order.OrderUUID
{
  key item_uuid       as ItemUUID,
      order_uuid      as OrderUUID,
      product_id      as ProductId,
      quantity         as Quantity,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      unit_price       as UnitPrice,
      currency_code    as CurrencyCode,

      @Semantics.user.createdBy: true
      created_by       as CreatedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      last_changed_at  as LastChangedAt,

      _Order
}
```

## Projection View (Consumption Layer)

```cds
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Sales Order Projection'
@Metadata.allowExtensions: true
define view entity ZC_SalesOrder
  as projection on ZR_SalesOrder
{
  key OrderUUID,
      OrderId,
      CustomerId,
      OrderDate,
      NetAmount,
      CurrencyCode,
      Status,

      _Item : redirected to composition child ZC_SalesOrderItem
}
```

## Association Syntax

```cds
define view entity ZI_SalesOrder
  as select from zsalesorder
  association [0..1] to ZI_Customer as _Customer
    on $projection.CustomerId = _Customer.CustomerId
  association [0..*] to ZI_SalesOrderItem as _Item
    on $projection.OrderId = _Item.OrderId
{
  key order_id    as OrderId,
      customer_id as CustomerId,

      // Expose associations — required for consumption via ABAP SQL or OData
      _Customer,
      _Item
}
```

### Using Associations in ABAP SQL

```abap
" Path expression — triggers LEFT OUTER JOIN by default
SELECT FROM zi_salesorder
  FIELDS OrderId,
         \_Customer-CustomerName,
         \_Item-ProductId
  WHERE OrderId = @lv_order_id
  INTO TABLE @DATA(lt_result).

" Filtering associations
SELECT FROM zi_salesorder
  FIELDS OrderId, \_Item[ ProductId = 'PROD01' ]-Quantity
  WHERE OrderId = @lv_order_id
  INTO TABLE @DATA(lt_filtered).
```

## Everything Else

Expressions/built-in functions, aggregate expressions, input parameters, joins, and UI annotations/metadata extensions are covered in [Skill: cds-analytical-views]'s reference — they apply identically whether or not the view sits in a RAP composition tree, so they're not duplicated here.
