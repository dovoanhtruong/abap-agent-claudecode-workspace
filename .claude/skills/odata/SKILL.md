---
name: odata
version: 1.0
description: Help with OData service development in ABAP — V2/V4 via RAP service definitions and bindings, exposing a RAP BO, consuming external OData services (client proxy), troubleshooting OData /IWBEP/ errors. Use even for quick service asks — "create OData service", "expose RAP BO", "service binding", "OData V4", "consume external OData", "publish service", "tạo service binding/definition", "lỗi OData", "gọi API/OData ngoài". For FS API-requirement analysis use fs-integration-api-analyzer; for RAP BO modeling use rap; for communication arrangements use btp-abap-environment.
---

# OData Service Development

Guide for creating and consuming OData services in ABAP Cloud — RAP-based service exposure and external consumption.

## RAP-Based OData Services (Recommended)

### Architecture Flow

```
CDS View Entity → Behavior Definition → Service Definition → Service Binding
                                                                    ↓
                                                              OData V4/V2 Endpoint
```

### Service Definition

Exposes CDS entities and their behaviors as a named service:

```cds
@EndUserText.label: 'Travel Service'
define service ZUI_TRAVEL_O4 {
  expose ZC_Travel as Travel;
  expose ZC_Booking as Booking;
  expose I_Currency as Currency;
  expose I_Country as Country;
}
```

#### Key Rules

- Expose projection CDS views (C\_ prefix by convention), not root views
- Include value help CDS views (I\_\* views) the UI needs
- Alias names become OData entity set names
- One service definition can be bound to multiple protocols

### Service Binding

Binds a service definition to a specific OData protocol and provides a URL:

| Binding Type         | Protocol | Use Case                           |
| -------------------- | -------- | ---------------------------------- |
| `OData V4 - UI`      | V4       | SAP Fiori Elements apps            |
| `OData V2 - UI`      | V2       | Legacy Fiori apps, older frontends |
| `OData V4 - Web API` | V4       | API consumption (A2X scenarios)    |
| `OData V2 - Web API` | V2       | API consumption (legacy)           |
| `InA - UI`           | InA      | Analytical scenarios               |

### Creating a Service Binding

1. In ADT: **New → Other ABAP Repository Object → Business Services → Service Binding**
2. Select the service definition
3. Choose binding type (e.g., OData V4 - UI)
4. Activate
5. Click **Publish** to register the service
6. Click **Preview** to open the Fiori Elements preview

## OData V4 vs V2

| Feature               | OData V4                      | OData V2                        |
| --------------------- | ----------------------------- | ------------------------------- |
| **Protocol**          | JSON by default               | XML (Atom) default, JSON option |
| **Batch**             | `$batch` with JSON            | `$batch` with multipart         |
| **Deep operations**   | Deep create/update supported  | Limited                         |
| **Actions/Functions** | Bound and unbound             | Function imports                |
| **Filtering**         | `$filter` with `lambda`       | `$filter` basic                 |
| **Draft**             | Full support                  | Supported via extensions        |
| **Aggregation**       | `$apply` transformation       | Not natively supported          |
| **Recommendation**    | Preferred for new development | Maintain existing only          |

> **SEGW (classic OData V2) is out of scope for this workspace** — it is Standard ABAP only, unavailable in ABAP Cloud, and its DPC pattern encourages direct physical-table reads (violates workspace rule §3). For any new service, expose a RAP BO via service definition + binding as above. If asked about maintaining a legacy SEGW service, say explicitly that it must be handled in a classic (Tier 3) context outside this workspace's rules.

## Consuming External OData Services

### Getting the HTTP Client

The canonical HTTP-client-via-communication-arrangement pattern (`cl_http_destination_provider=>create_by_comm_arrangement(...)` → `cl_web_http_client_manager=>create_by_http_destination(...)`) is owned by [Skill: btp-abap-environment] — read it there rather than duplicating the code here. Once you have `lo_client`, set the OData resource path on `get_http_request( )` as usual, or use the OData Client Proxy below for a typed alternative.

### Using OData Client Proxy (V2/V4)

```abap
"Create OData client proxy for V4
DATA(lo_proxy) = /iwbep/cl_cp_client_proxy_fact=>create_v4_remote_proxy(
  iv_service_definition_name = 'Z_MY_ODATA_CDEF'
  io_http_client             = lo_client
  iv_relative_service_root   = '/sap/opu/odata4/sap/api_service/0001/' ).

"Build and execute read request
DATA(lo_request) = lo_proxy->create_resource_for_entity_set( 'ENTITYSETNAME' )->create_request_for_read( ).
lo_request->set_top( 10 ).
DATA(lo_response) = lo_request->execute( ).

"Get business data
DATA lt_data TYPE STANDARD TABLE OF z_entity_type.
lo_response->get_business_data( IMPORTING et_business_data = lt_data ).
```

## OData/UI Annotations

UI and value-help annotations (`@UI.*`, `@Consumption.valueHelpDefinition`) live on the CDS side — [Skill: cds-analytical-views] owns their syntax and the metadata-extension pattern.

## Troubleshooting

| Error / Issue                  | Solution                                           |
| ------------------------------ | -------------------------------------------------- |
| `/IWBEP/CX_MGW_BUSI_EXCEPTION` | Check DPC implementation, validate input data      |
| `/IWBEP/CX_MGW_TECH_EXCEPTION` | Check data model consistency, regenerate artifacts |
| 403 Forbidden                  | Check ICF node activation, authorization           |
| 404 Not Found                  | Verify service is registered and activated         |
| `$metadata` returns empty      | Publish service binding, check activation          |
| Draft not working              | Verify draft table exists, BDEF has `with draft`   |
| Deep create fails              | Check composition in CDS and BDEF                  |
| `CX_WEB_HTTP_CLIENT_ERROR`     | Check communication arrangement, SSL certificates  |

## Output Format

When helping with OData topics, structure responses as:

```markdown
## OData Service Guidance

### Approach

- Type: [RAP-based / SEGW-based / Consumption]
- Protocol: [OData V4 / OData V2]

### Implementation

[Step-by-step with code examples]

### Testing

[How to test the service]
```

## Deep Dive

For version-gating on the BDL/SDL constructs that shape real OData behavior (repeatable actions, draft additions, service extensions), the concurrency-control (ETag) topic missing above, service-binding decision criteria beyond the protocol table, and troubleshooting additions, read [references/deep-dive.md](references/deep-dive.md).

## References

- SAP OData V4 Documentation: https://help.sap.com/docs/abap-cloud/abap-rap/odata-service
- RAP Service Binding: https://help.sap.com/docs/abap-cloud/abap-rap/service-binding
- OData Client Proxy: https://help.sap.com/docs/abap-cloud/abap-rap/odata-client-proxy
