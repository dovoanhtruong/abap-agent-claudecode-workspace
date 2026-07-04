---
name: rap-query-provider
description: Help with implementing RAP Query Providers (IF_RAP_QUERY_PROVIDER) for Custom Entities in ABAP Cloud. Focuses on handling query options (paging, sorting, filtering) to avoid the "Query not fully covered by implementation" error. Triggers include "IF_RAP_QUERY_PROVIDER", "custom entity class", "select method", "get_sort_elements", "get_paging", "set_total_number_of_records", "Query not fully covered".
---

# RAP Query Provider & Custom Entity Implementation

Guide for implementing custom query providers (`IF_RAP_QUERY_PROVIDER`) for Custom Entities in the ABAP RESTful Application Programming Model (RAP).

---

## ⚠️ The "Query not fully covered by implementation" Error

### Why does this happen?
When using a **Custom Entity** in RAP, the data retrieval logic is entirely delegated to an ABAP class implementing the `IF_RAP_QUERY_PROVIDER` interface. 

OData clients (like Fiori Elements) automatically send request parameters such as **Sorting (`$orderby`)**, **Paging (`$top`, `$skip`)**, and **Filtering (`$filter`)**.
If the client requests an operation (e.g., sorting on a column) but your ABAP `select` method fails to explicitly retrieve and process that request parameter from the `io_request` object, the OData runtime throws a short dump / runtime error:
> **`Query not fully covered by implementation: Call to method if_rap_query_request~get_sort_elements missing.`**

### How to fix it?
To prevent this error, your `select` method **MUST** actively consume the requested query capabilities from `io_request` and apply them to your data retrieval or internal data processing.

---

## 🛠️ Core Request & Response API

To fully cover the OData query capabilities, your implementation class must interact with the following methods:

### 1. Paging (Phân trang)
OData client sends `$top` (page size) and `$skip` (offset).
* Check if paging is requested:
  ```abap
  IF io_request->is_paging_requested( ).
  ```
* Retrieve offset and page size:
  ```abap
  DATA(lo_paging)  = io_request->get_paging( ).
  DATA(lv_offset)  = lo_paging->get_offset( ).
  DATA(lv_page_size) = lo_paging->get_page_size( ).
  ```
* Apply paging to your SQL query or internal table:
  * In SQL: `SELECT ... OFFSET @lv_offset UP TO @lv_page_size ROWS`
  * In ABAP (internal table): Loop with index limits or use `FROM ... TO` in copying.

### 2. Sorting (Sắp xếp)
OData client sends `$orderby`. Fiori Elements lists often sort by key fields or default sorting parameters.
* **MANDATORY CALL**: You must retrieve the sorting elements requested by the client:
  ```abap
  DATA(lt_sort_elements) = io_request->get_sort_elements( ).
  ```
* Apply sorting to your internal table (example):
  ```abap
  IF lt_sort_elements IS NOT INITIAL.
    DATA(lt_ot) = VALUE abap_sortorder_tab(
      FOR sort_el IN lt_sort_elements
      ( name = to_upper( sort_el-element_name )
        descending = sort_el-descending ) ).
    SORT lt_data BY (lt_ot).
  ENDIF.
  ```

### 3. Filtering (Bộ lọc)
OData client sends `$filter`.
* Retrieve filter conditions as ranges (highly recommended for flexible processing):
  ```abap
  DATA(lo_filter) = io_request->get_filter( ).
  DATA(lt_filter_ranges) = lo_filter->get_as_ranges( ).
  ```
* Retrieve filter as a dynamic SQL string (if executing dynamic SQL):
  ```abap
  DATA(lv_sql_filter) = lo_filter->get_as_sql_string( ).
  ```

### 4. Custom Entity Parameters (Tham số đầu vào)
If the Custom Entity defines parameters (e.g., `with parameters P_CompanyCode : abap.char(4)`):
* Retrieve parameter values:
  ```abap
  DATA(lt_parameters) = io_request->get_parameters( ).
  ```

### 5. Returning Data & Total Records (Phản hồi kết quả)
* **Set Data**: Pass the final internal table containing the requested page of data.
  ```abap
  io_response->set_data( lt_data ).
  ```
* **Set Total Number of Records**: OData client often requests the total count (`$count=true`) to display pagination counts or table headers.
  * Check if requested:
    ```abap
    IF io_request->is_total_numb_of_rec_requested( ).
    ```
  * Set total records count (should be the count of the *entire filtered dataset*, NOT just the current page size):
    ```abap
    io_response->set_total_number_of_records( lv_total_count ).
    ```

---

## 📋 Standard Code Template (IF_RAP_QUERY_PROVIDER)

Below is a complete, Clean ABAP-compliant template for your Query Provider class.

```abap
CLASS zcl_invacdoc_query2 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_rap_query_provider.
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_invacdoc_query2 IMPLEMENTATION.

  METHOD if_rap_query_provider~select.
    DATA lt_data TYPE TABLE OF zc_invacdoc2. " Target Custom Entity Type
    DATA(lv_entity_id) = io_request->get_entity_id( ).

    TRY.
        "---------------------------------------------------------------------
        " 1. Retrieve Request parameters (Mandatory calls to prevent runtime dumps)
        "---------------------------------------------------------------------
        " A. Filtering
        DATA(lo_filter) = io_request->get_filter( ).
        DATA(lt_filter_ranges) = lo_filter->get_as_ranges( ).

        " B. Sorting (Mandatory retrieval)
        DATA(lt_sort_elements) = io_request->get_sort_elements( ).

        " C. Paging
        DATA(lo_paging) = io_request->get_paging( ).
        DATA(lv_offset) = lo_paging->get_offset( ).
        DATA(lv_page_size) = lo_paging->get_page_size( ).

        " D. Custom Parameters (if defined on Custom Entity)
        DATA(lt_parameters) = io_request->get_parameters( ).

        "---------------------------------------------------------------------
        " 2. Execute Business Logic & Data Retrieval
        "---------------------------------------------------------------------
        " Extract specific range values from filter (e.g., CompanyCode)
        DATA(lt_company_code_range) = VALUE rs_t_rrange( ).
        READ TABLE lt_filter_ranges WITH KEY name = 'COMPANYCODE' INTO DATA(ls_cc_filter).
        IF sy-subrc = 0.
          lt_company_code_range = ls_cc_filter-range.
        ENDIF.

        " Execute your custom analytical/business logic here
        " ... (Populate lt_data with raw transactional data) ...

        "---------------------------------------------------------------------
        " 3. Apply Post-processing (Sorting & Paging)
        "---------------------------------------------------------------------
        " A. Apply Dynamic Sorting
        IF lt_sort_elements IS NOT INITIAL.
          DATA(lt_sort_order) = VALUE abap_sortorder_tab(
            FOR sort_el IN lt_sort_elements
            ( name = to_upper( sort_el-element_name )
              descending = sort_el-descending ) ).
          SORT lt_data BY (lt_sort_order).
        ELSE.
          " Fallback default sorting
          SORT lt_data BY CompanyCode GLAccount Material PostingDate CreationDateTime.
        ENDIF.

        " B. Calculate Total Records BEFORE Paging is applied
        DATA(lv_total_count) = lines( lt_data ).

        " C. Apply Paging (Offset & Page Size)
        IF lv_page_size > 0.
          " Calculate target row indices for the requested page
          DATA(lv_from) = lv_offset + 1.
          DATA(lv_to)   = lv_offset + lv_page_size.
          
          IF lv_from <= lv_total_count.
            DATA lt_paged_data TYPE TABLE OF zc_invacdoc2.
            
            " Copy only the sliced page into paged table
            APPEND LINES OF lt_data FROM lv_from TO lv_to TO lt_paged_data.
            lt_data = lt_paged_data.
          ELSE.
            CLEAR lt_data.
          ENDIF.
        ENDIF.

        "---------------------------------------------------------------------
        " 4. Set Response Data & Metadata
        "---------------------------------------------------------------------
        " A. Send Page Data
        io_response->set_data( lt_data ).

        " B. Send Total Count (if requested by OData Client)
        IF io_request->is_total_numb_of_rec_requested( ).
          io_response->set_total_number_of_records( lv_total_count ).
        ENDIF.

      CATCH cx_rap_query_provider INTO DATA(lx_exc).
        " Handle exception or raise custom error
        RAISE EXCEPTION TYPE cx_rap_query_provider
          EXPORTING
            previous = lx_exc.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
```

---

## 💡 Best Practices for Custom Entities

1. **Safety Net - Always Call Get Methods**: Even if you don't plan to use sorting or paging in your query, **always call** `io_request->get_sort_elements( )` and `io_request->get_paging( )`. This acts as a safety net to inform the RAP OData framework that your class has "covered" these capabilities.
2. **Total Count calculation**: Ensure that `set_total_number_of_records` receives the size of the **full dataset** matching the filter criteria, not just the page size. Otherwise, UI components like Fiori tables will show incorrect row counts or prevent loading subsequent pages.
3. **Filtering on Keys**: Standard search helps and filter bars pass values inside `lt_filter_ranges`. Always inspect this table to extract parameters when querying database views.
4. **Exception Handling**: Always wrap the select method code in a `TRY...CATCH` block for `cx_rap_query_provider` to ensure robust error handling in the OData pipeline.
