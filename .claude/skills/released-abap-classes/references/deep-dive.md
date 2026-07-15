# Released ABAP Classes — Deep Dive

The base skill is a curated lookup table across 24 unrelated functional categories pointing into a ~9,700-line verbatim reference file — a dense "deep-dive" in the `modern-abap-syntax`/`rap` pilot sense doesn't fit all 24 shallowly. **This deep-dive goes deep on exactly four**: **JSON/XML parsing, HTTP calls, UUID, and Date/Time** — chosen because they are the categories this workspace's actual RAP/OData workflows hit repeatedly (payload (de)serialization, outbound API calls, entity key generation, timestamp fields on CDS views). The other 20 categories are left as the base skill's flat lookup table; nothing below duplicates the full reference file's code — it adds the decision criteria and version framing that file doesn't have. Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

## Version Safety on ABAP Cloud Targets

| Finding | Introduced (ABAP for Cloud Development) | Practical impact |
|---|---|---|
| iXML Library wrapper API for ABAP Cloud (`cl_ixml_core( )=>create`) | Release 772 (1805) | Before this, no released iXML access at all in ABAP for Cloud Development — sXML/`CL_SXML_*` or XCO_CP_JSON were the only options for structured-document processing |
| New `CL_ABAP_TSTMP` methods `MOVE_TRUNC`/`MOVE_TO_SHORT_TRUNC`/`ADD_TO_SHORT_TRUNC`/`SUBTRACTSECS_TO_SHORT_TRUNC` (truncate instead of commercially round fractional seconds) | Release 793 (2308) | Without them, converting a long UTC timestamp (`utclong`/`timestampl`) to a short one via the older methods (`MOVE`, `MOVE_TO_SHORT`, `ADD_TO_SHORT`, `SUBTRACTSECS_TO_SHORT`) rounds commercially — which can silently shift a truncated timestamp forward by up to a second; the older methods still work, just be aware of the rounding behavior if the target release predates 793 |

**Everything else covered below has no verified cloud-specific release-gating claim** — `33_ABAP_Release_News.md`'s "ABAP for Cloud Development" section (the same digest that supplied every version-gate in the `modern-abap-syntax`/`rap` pilots) has **zero matches** for `XCO_CP_JSON`, `CL_WEB_HTTP_CLIENT_MANAGER`, `CL_HTTP_DESTINATION_PROVIDER`, `XCO_CP_TIME`, `CL_ABAP_CONTEXT_INFO`, `/UI2/CL_JSON`, `CL_ABAP_UTCLONG`, `CL_ABAP_DATFM`, or `CL_ABAP_TIMEFM`. `CL_SYSTEM_UUID` has exactly one hit in the entire file, and it's in the **Standard ABAP** section at classic release 710 (pre-dates the Cloud section's documented window entirely, same "baseline" framing as `modern-abap-syntax`'s core-constructs finding). Practical reading: none of these are a genuine version risk on any real ABAP Cloud target for this workspace (BTP ABAP Environment, S/4HANA Cloud) — but this is an absence of tracked release news, not a positive "always available" guarantee against a very old/unconfirmed on-premise target running the cloud language version. If a TS depends on one of these against an unconfirmed old target, verify directly in ADT (API State tab), don't infer availability from this silence.

## JSON/XML — Which Class to Reach For

Three genuinely different tools exist; the reference file shows all three but doesn't say when to pick which:

| Tool | Reach for it when |
|---|---|
| `XCO_CP_JSON` | Structure/table ↔ JSON string round-trips with field-name transformation built in (`->apply( xco_cp_json=>transformation->pascal_case_to_underscore )` etc.) — the default choice for a RAP/OData payload shape that needs camelCase↔ABAP-underscore mapping without hand-written field renaming |
| `/UI2/CL_JSON` | Quick serialize/deserialize with no transformation needs, or when working alongside existing code that already uses it (it's the older, more ubiquitous utility — many SAP-delivered examples and blogs still default to it) |
| `CL_SXML_*` (sXML) / `CL_IXML_*` (iXML) | Sequential/streaming processing of large XML documents, or genuine XML (not JSON) — sXML also handles JSON but at a lower level (reader/writer streams) than XCO's object-based builder; reach for it only when XCO_CP_JSON's structure-based model doesn't fit (e.g., processing XML you don't have a matching ABAP structure for) |

```abap
"XCO_CP_JSON: structure -> JSON with camelCase output
DATA(json_builder) = xco_cp_json=>data->builder( ).
json_builder->begin_object(
  )->add_member( 'CarrierId' )->add_string( 'DL'
  )->end_object( ).
DATA(json_out) = json_builder->get_data( )->to_string( ).

"JSON (camelCase/PascalCase) -> ABAP structure, converting naming convention
xco_cp_json=>data->from_string( json_out )->apply( VALUE #(
  ( xco_cp_json=>transformation->pascal_case_to_underscore ) ) )->write_to( REF #( target_struc ) ).
```

Decision cue: don't reach for sXML/iXML by default just because "it's more powerful" — for a typical RAP entity ↔ JSON payload mapping, `XCO_CP_JSON`'s transformation pipeline is less code and less error-prone than hand-rolling a sXML reader/writer loop.

## HTTP Calls — the demo-code trap

The reference file's HTTP examples (email-via-GitHub-API, Markdown-to-HTML POST) both use `cl_http_destination_provider=>create_by_url( ... )`. **The source's own warning**: *"the example uses the `create_by_url` method, which is only suitable for public services or testing purposes."* For anything hitting a real backend, use `create_by_comm_arrangement(...)` instead — that pattern (and the full destination/client-manager code) is owned by **[Skill: btp-abap-environment]**, not duplicated here.

```abap
TRY.
    DATA(client) = cl_web_http_client_manager=>create_by_http_destination(
                     cl_http_destination_provider=>create_by_url( 'https://api.example.com' ) ).
    DATA(response) = client->execute( if_web_http_client=>get ).
    DATA(status) = response->get_status( ).
    IF status-code <> 200.
      "Handle non-2xx explicitly — don't assume execute( ) raising nothing means success
    ENDIF.
  CATCH cx_web_http_client_error cx_http_dest_provider_error INTO DATA(error).
ENDTRY.
```

Decision cue: the reference file's own demo examples catch broad `cx_root` — fine for a throwaway console demo, not for production code. Catch the specific `cx_web_http_client_error`/`cx_http_dest_provider_error` pair (as shown in the SKILL.md's own quick-reference) so a genuine unexpected error isn't silently swallowed alongside expected HTTP-layer failures. Always check `status-code` explicitly — `execute( )` returning without raising an exception does not mean the call got a 2xx; a 404/500 is a normal HTTP response, not an ABAP exception.

## UUID — Format Choice, Not Just Which Class

Both `CL_SYSTEM_UUID` and `XCO_CP`/`XCO_CP_UUID` generate RFC4122-compliant UUIDs; the real decision is **which representation**, not which class:

| Format | Use for |
|---|---|
| `x16` (16-byte binary, `sysuuid_x16`) | Storing as a RAP entity's UUID-typed key field — this is the internal binary form DDIC UUID key fields expect |
| `c36` (`429A229A-8802-1EDF-B7E2-E25DF99B0E73`, hyphenated) | Displaying to a user, or exchanging with an external system that expects RFC4122 canonical text form |
| `c32` (hex, no hyphens) | Compact external representation without the display-only hyphens |
| `c22`/`c26` (Base64/Base32) | Rare — shorter string encodings, only when a specific external protocol demands them |

```abap
"CL_SYSTEM_UUID: generate binary, convert to display form
DATA(uuid_x16) = cl_system_uuid=>create_uuid_x16_static( ).
cl_system_uuid=>convert_uuid_x16_static( EXPORTING uuid = uuid_x16 IMPORTING uuid_c36 = DATA(uuid_display) ).

"XCO: generate directly in the format you need
DATA(uuid_for_key) = xco_cp=>uuid( )->value.                                    "x16
DATA(uuid_for_display) = xco_cp=>uuid( )->as( xco_cp_uuid=>format->c36 )->value. "c36 string
```

Decision cue: for a RAP BO's primary key, this category is usually moot — `numbering:managed` in the Behavior Definition generates the key UUID for you framework-side (see `[Skill: rap]`'s numbering-strategy decision tree). Reach for these classes directly when you need a UUID for something the framework doesn't generate one for: a correlation ID for an outbound API call, an idempotency key, a Z-table's non-key tracking field.

## Date/Time — a Restriction, Not Just a Class Choice

**Verified restriction, not a style preference**: the official cheat sheet explicitly states *"In ABAP for Cloud Development, do not use the date and time-related system fields such as `sy-datum` and `sy-uzeit`... User-related time and date values can be retrieved using the XCO library."* This is a hard restriction (also independently confirmed in the `abap-cloud` skill's deep-dive via the executable example that lists `sy-datum`/`sy-uzeit`/`sy-timlo` among invalid statements in ABAP for Cloud Development) — not merely "XCO is nicer."

| Need | Use |
|---|---|
| Quick current UTC date/time, no arithmetic | `CL_ABAP_CONTEXT_INFO=>get_system_date( )` / `get_system_time( )` — simplest call, UTC only, no user-timezone awareness |
| User-timezone-aware date/time, formatting, or add/subtract arithmetic on a date or time value | `XCO_CP_TIME`/`XCO_CP` (`xco_cp=>sy->date/time/moment( xco_cp_time=>time_zone->user )->add(...)`/`->as(...)`) — the richer object model, reach for it the moment you need more than a raw UTC snapshot |
| Arithmetic on a stored `utclong` timestamp field | `CL_ABAP_UTCLONG` (`diff`, `read`) plus the built-ins `utclong_current( )`/`utclong_add( )` |
| Arithmetic/conversion on a stored `timestamp`/`timestampl` field (packed, not `utclong`) | `CL_ABAP_TSTMP` — mind the 793/2308 TRUNC-vs-round distinction above when converting long→short |
| External-format ↔ internal `d`/`t` conversion (e.g., rendering a date per user locale) | `CL_ABAP_DATFM`/`CL_ABAP_TIMEFM` |

Decision cue: don't default to `CL_ABAP_CONTEXT_INFO` for everything just because it's the shortest call — it has no arithmetic and is UTC-only. The moment a requirement says "in the user's time zone" or "add N days," move to `XCO_CP_TIME`.
