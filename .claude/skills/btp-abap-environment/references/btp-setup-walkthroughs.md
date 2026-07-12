# BTP ABAP Environment — Setup Walkthroughs

Click-path and provisioning detail. Read this when actually performing setup; the SKILL.md body has the concepts.

## Prerequisites

| Requirement         | Description                                           |
| ------------------- | ----------------------------------------------------- |
| **SAP BTP Account** | Global account with entitlements for ABAP Environment |
| **Subaccount**      | Cloud Foundry-enabled subaccount                      |
| **ADT**             | Eclipse with ABAP Development Tools installed         |
| **User**            | Platform user with Space Developer role               |
| **Entitlements**    | `abap/standard` or `abap/saas_oem` service plan       |

## Service Instance Creation

1. BTP Cockpit → Subaccount → Cloud Foundry → Spaces
2. Create service instance — Service: **ABAP Environment**, Plan: **standard**
3. Parameters (JSON):

```json
{
  "admin_email": "admin@example.com",
  "description": "Development ABAP System",
  "is_development_allowed": true,
  "sapsystemname": "DEV",
  "size_of_runtime": 1,
  "size_of_persistence": 4
}
```

4. Create a service key for ADT connectivity.

## Connecting ADT

1. Eclipse/ADT: **File → New → ABAP Cloud Project**
2. Select **SAP BTP ABAP Environment**
3. Enter the service key (JSON) or service instance URL
4. Authenticate via browser (SAP Identity Authentication)

## Software Components

| Component | Description                                                                   |
| --------- | ----------------------------------------------------------------------------- |
| `ZLOCAL`  | Local development — not transportable (like `$TMP`)                           |
| Custom    | Transportable — managed via gCTS / Manage Software Components app             |

Create via **Manage Software Components** Fiori app → Create → then **Clone** to make it available in ADT. Typical package layout:

```
Z_MY_COMPONENT (Software Component)
└── Z_MY_APP (Structure Package)
    ├── Z_MY_APP_MODEL (CDS views, tables)
    ├── Z_MY_APP_BIZ (business logic, RAP BOs)
    └── Z_MY_APP_SRV (service definitions, bindings)
```

## Communication Scenario Definition (ADT)

| Property                 | Value                          |
| ------------------------ | ------------------------------ |
| **Scenario ID**          | `Z_MY_COMM_SCENARIO`           |
| **Scenario Type**        | Managed by Customer            |
| **Inbound Services**     | List of inbound OData services |
| **Outbound Services**    | List of outbound HTTP services |
| **Allowed Auth Methods** | Basic, OAuth 2.0, x.509        |

## Inbound Communication Setup

1. Create the OData service (RAP service binding)
2. Add the binding to a communication scenario as inbound service
3. In the **Communication Arrangements** Fiori app: select scenario, create/assign communication system, create communication user (Basic) or configure OAuth
4. External systems can now call the service

## Useful Fiori Apps

| App                                | Purpose                                 |
| ---------------------------------- | --------------------------------------- |
| **Manage Software Components**     | Create, clone, pull software components |
| **Communication Arrangements**     | Configure inbound/outbound integrations |
| **Communication Systems**          | Register external systems               |
| **Maintain Business Roles**        | Create and assign roles                 |
| **Application Jobs**               | Schedule and monitor background jobs    |
| **Custom Business Configurations** | Maintain configuration tables           |
