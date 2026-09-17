---
name: rap-business-events
version: 1.0
description: Help with RAP business events and enterprise eventing including event definitions in behavior definitions, raising events from RAP handler methods, event bindings, SAP Event Mesh integration, event consumption, and event-driven patterns in ABAP Cloud. Use when users ask about RAP business events, enterprise events, event mesh, eventing, raising events, event binding, event definition, event consumption, event-driven, asynchronous processing, event topics, or publish-subscribe in ABAP. Triggers include "RAP event", "business event", "raise event", "event mesh", "event binding", "enterprise eventing", "publish event", "consume event". For general RAP modeling (BDEF, handlers, EML) use rap.
---

# RAP Business Events & Enterprise Eventing

Guide for event-driven integration with RAP business events and SAP Event Mesh in ABAP Cloud. Concepts and configuration live here; full code examples in [references/event-code-examples.md](references/event-code-examples.md) — read it when implementing a producer or consumer.

## Concepts

| Concept               | Description                                                       |
| --------------------- | ----------------------------------------------------------------- |
| **Business Event**    | Declared in BDEF (`event <name> [parameter ZD_...];`); raised on business-meaningful state changes |
| **Event Raising**     | `RAISE ENTITY EVENT zr_bo~event_name FROM VALUE #( ... )` in handler/saver methods |
| **Event Binding**     | ADT object mapping a RAP event to an enterprise event topic for external delivery |
| **Event Consumption** | Local handler class (`FOR ENTITY EVENT`) or external subscribers via Event Mesh |

Events with payload use a CDS **abstract entity** as parameter type (clear, versionable contract).

## Event Processing Flow

```
1. Handler/saver executes RAISE ENTITY EVENT (event is queued, NOT sent)
2. RAP framework commits the transaction
3. Only after successful COMMIT:
   a. Local event handlers are called
   b. Enterprise events are published to Event Mesh
```

This commit coupling is the point: an event never announces a change that was rolled back.

## Enterprise Event Enablement (configuration)

1. Create the **Event Binding** in ADT (New → Other → Event Binding): maps `ZR_Travel` + `travel_created` → topic `<namespace>/<business-object>/<event>/<version>` (e.g. `z.custom/travel/created/v1`).
2. Create a **Communication Arrangement** for scenario `SAP_COM_0092` (Enterprise Event Enablement).
3. Configure the Event Mesh service instance in BTP.
4. Maintain the channel in the **Enterprise Event Enablement** Fiori app and activate the topic.

External consumers subscribe via Event Mesh webhooks, SAP Integration Suite, or AMQP/REST. Inbound external events are consumed in ABAP via an **event consumption model** (ADT, from AsyncAPI spec).

## Best Practices

1. Define events for business-meaningful state changes, not technical operations.
2. Include sufficient data in the payload so consumers don't need callbacks (event-carried state transfer) — but keep the contract stable; version topics (`/v1`, `/v2`) for changes.
3. Raise events only after validation — the commit coupling handles rollback, but don't queue events for data you already know is invalid.
4. Consumers must be idempotent — delivery can repeat.

## Deep Dive

For the raising-vs-consumption release gap (roughly 3 quarters apart), two producer/consumer patterns not shown in `event-code-examples.md`, new event types (derived events, side-effect events), and decision criteria for local-only vs. enterprise Event Mesh publishing, read [references/deep-dive.md](references/deep-dive.md).

## References

- [references/event-code-examples.md](references/event-code-examples.md) — BDEF event definition, raising (handler/saver, with/without parameters), local + external consumption code
- RAP Business Events / EML Cheat Sheet: https://github.com/SAP-samples/abap-cheat-sheets/blob/main/08_EML_ABAP_for_RAP.md (corrected 2026-07-14 — the previously-cited filename `08_RAP_Business_Events.md` does not exist in the repo, verified 404)
- Enterprise Event Enablement: https://help.sap.com/docs/abap-cloud/abap-rap/enterprise-event-enablement
- SAP Event Mesh: https://help.sap.com/docs/event-mesh
