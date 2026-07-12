---
name: btp-abap-environment
description: Help with SAP BTP ABAP Environment setup and development including service instance creation, ADT connectivity, communication arrangements, communication scenarios, inbound/outbound services, destination configuration, and software components. Use when users ask about BTP ABAP Environment, SAP BTP ABAP, Steampunk provisioning, ABAP environment service instance, ADT connection to BTP, communication arrangement, communication scenario, communication system, outbound communication, inbound communication, destination service, software component, or ABAP system on BTP. Triggers include "set up BTP ABAP", "connect ADT to BTP", "communication arrangement", "communication scenario", "create service instance", "ABAP on BTP", "outbound service". For authorization/IAM design use authorization-iam; for ABAP Cloud language restrictions use abap-cloud.
---

# SAP BTP ABAP Environment

Concepts and the canonical outbound-HTTP pattern live here; provisioning click-paths, software-component setup, and Fiori-app lists are in [references/btp-setup-walkthroughs.md](references/btp-setup-walkthroughs.md) — read it when actually performing setup.

## System Architecture

```
SAP BTP Subaccount
└── Cloud Foundry Space
    └── ABAP Environment Service Instance
        ├── ABAP System (development/production)
        ├── Software Components (ZLOCAL, custom)
        ├── Communication Arrangements (integrations)
        └── Business Services (OData, RFC)
```

## Communication Management (the concept table)

| Artifact                      | Purpose                                                      |
| ----------------------------- | ------------------------------------------------------------ |
| **Communication Scenario**    | Template defining inbound/outbound services and auth methods (ADT object, `Z_*`) |
| **Communication System**      | Represents the external system (host, port, credentials)     |
| **Communication Arrangement** | Binds scenario + system + user, activating the integration   |
| **Communication User**        | Technical user for inbound communication                     |

Mental model: the **scenario** is code/design-time, the **system** and **arrangement** are admin/runtime configuration — a deployment can swap targets without touching code.

## Outbound Communication (canonical pattern)

```abap
"Get HTTP destination from communication arrangement
DATA(lo_dest) = cl_http_destination_provider=>create_by_comm_arrangement(
  comm_scenario  = 'Z_MY_COMM_SCENARIO'
  service_id     = 'Z_MY_OUTBOUND_SERVICE' ).

"Create HTTP client
DATA(lo_client) = cl_web_http_client_manager=>create_by_http_destination( lo_dest ).

"Execute request
DATA(lo_request) = lo_client->get_http_request( ).
lo_request->set_uri_path( '/api/resource' ).
lo_request->set_header_field( i_name = 'Content-Type' i_value = 'application/json' ).

DATA(lo_response) = lo_client->execute( if_web_http_client=>get ).
DATA(lv_status) = lo_response->get_status( ).
DATA(lv_body) = lo_response->get_text( ).

lo_client->close( ).
```

Never hardcode URLs/credentials — the communication arrangement owns them.

## Inbound Communication (summary)

Expose a RAP service binding through a communication scenario's inbound service, then activate it with a communication arrangement + communication user. Step-by-step in the reference file.

## IAM (pointer)

Access chain: `IAM App → Business Catalog → Business Role → Business User`. Creating IAM apps, catalogs, roles, and restriction design is owned by [Skill: authorization-iam].

## Project Scaffolding (pointer)

Building the actual RAP application (table → CDS → BDEF → service binding) is owned by the workflows `/sap-dev-create-report` and `/sap-dev-create-transactional-app` — don't improvise a parallel scaffold here.

## References

- [references/btp-setup-walkthroughs.md](references/btp-setup-walkthroughs.md) — provisioning, ADT connection, software components, scenario definition, inbound setup, Fiori apps
- SAP BTP ABAP Environment: https://help.sap.com/docs/btp/sap-business-technology-platform/abap-environment
- Communication Management: https://help.sap.com/docs/btp/sap-business-technology-platform/communication-management
- Getting Started Tutorial: https://developers.sap.com/group.abap-env-get-started.html
