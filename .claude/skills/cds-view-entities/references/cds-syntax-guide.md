# CDS View Entity Syntax Guide

Copy-paste syntax templates and expression reference. Read the section you need when actually writing a view — the SKILL.md body has the decision tables.

## Basic View Entity

```cds
@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Sales Order'
define view entity ZI_SalesOrder
  as select from zsalesorder
{
  key order_id       as OrderId,
      customer_id    as CustomerId,
      order_date     as OrderDate,
      net_amount     as NetAmount,
      currency_code  as CurrencyCode,
      status         as Status,
      created_by     as CreatedBy,
      created_at     as CreatedAt,
      last_changed_at as LastChangedAt
}
```

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

## Expressions & Built-in Functions

```cds
// Cast
cast( amount as abap.dec(15,2) ) as ConvertedAmount,

// Simple CASE
case status
  when 'N' then 'New'
  when 'A' then 'Approved'
  else 'Unknown'
end as StatusText,

// Searched CASE
case when net_amount > 10000 then 'High'
     when net_amount > 1000  then 'Medium'
     else 'Low'
end as PriorityCategory,

// Arithmetic
quantity * unit_price as TotalPrice,

// Strings
concat( first_name, concat( ' ', last_name ) ) as FullName,
substring( postal_code, 1, 2 )                 as Region,
length( description )                          as DescLength,
upper( country_code )                          as CountryUpper,

// Date & time
dats_days_between( start_date, end_date ) as DurationDays,
dats_add_days( order_date, 30 )           as DueDate,
tstmp_current_utctimestamp()              as CurrentTimestamp,

// Session variables
$session.user            as CurrentUser,
$session.system_date     as SystemDate,
$session.system_language as SystemLanguage,
```

## Aggregate Expressions

```cds
define view entity ZI_OrderSummary
  as select from zsalesorder
{
  key customer_id as CustomerId,
      count(*)                      as OrderCount,
      sum( net_amount )             as TotalAmount,
      avg( net_amount as abap.dec(15,2) ) as AvgAmount,
      min( order_date )             as FirstOrderDate,
      max( order_date )             as LastOrderDate
}
group by customer_id
```

## Input Parameters

```cds
define view entity ZI_SalesOrderByDate
  with parameters
    p_date : abap.dats
  as select from zsalesorder
{
  key order_id   as OrderId,
      order_date as OrderDate,
      net_amount as NetAmount
}
where order_date >= $parameters.p_date
```

```abap
SELECT FROM zi_salesorderbydate( p_date = @lv_date )
  FIELDS OrderId, OrderDate, NetAmount
  INTO TABLE @DATA(lt_orders).
```

## Joins

```cds
define view entity ZI_OrderWithCustomer
  as select from zsalesorder as so
  inner join zcustomer as cust
    on so.customer_id = cust.customer_id
{
  key so.order_id      as OrderId,
      cust.customer_name as CustomerName,
      so.net_amount     as NetAmount
}
```

| Join Type   | Keyword            | Behavior                       |
| ----------- | ------------------ | ------------------------------ |
| Inner       | `inner join`       | Only matching rows             |
| Left Outer  | `left outer join`  | All from left + matching right |
| Right Outer | `right outer join` | All from right + matching left |
| Cross       | `cross join`       | Cartesian product              |

Prefer associations over joins when possible — associations are lazily resolved and support path expressions.

## UI Annotations & Metadata Extensions

```cds
@UI.headerInfo: {
  typeName: 'Sales Order',
  typeNamePlural: 'Sales Orders',
  title: { type: #STANDARD, value: 'OrderId' }
}
```

Metadata extension (recommended home for UI annotations — requires `@Metadata.allowExtensions: true` on the view):

```cds
@Metadata.layer: #CUSTOMER
annotate view ZC_SalesOrder with
{
  @UI.facet: [{
    id: 'GeneralInfo',
    type: #IDENTIFICATION_REFERENCE,
    label: 'General Information',
    position: 10
  }]

  @UI.lineItem: [{ position: 10, importance: #HIGH }]
  @UI.identification: [{ position: 10 }]
  OrderId;

  @UI.lineItem: [{ position: 20 }]
  @UI.identification: [{ position: 20 }]
  @UI.selectionField: [{ position: 10 }]
  CustomerId;
}
```
