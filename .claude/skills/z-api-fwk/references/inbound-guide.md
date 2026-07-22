# Z_API_FWK — Inbound API Guide (partner → SAP)

Everything needed to build, configure, and debug an inbound API on the framework. Source: live `Z_API_FWK` package source (`abap_bmw_dev`, Jul 2026).

## Runtime flow

```
Partner (Postman / external system)
  → HTTP request to service Z_API_INBOUND_HTTP        (ONE endpoint for ALL inbound APIs)
    header: x-api-id = <API_ID>                        (routing key — mandatory)
  → ZCL_API_INBOUND_HTTP (if_http_service_extension~handle_request)
  → NEW zcl_api_fwk( )->execute_inbound( io_request / io_response )
      1. read payload   (binary content-type → base64-encode; else get_text)
      2. read x-api-id  (missing → 400, stop)
      3. SELECT SINGLE zi_api_config_h WHERE ApiId = x-api-id   (validation matrix below)
      4. validate handler class via XCO (exists + implements ZIF_API_INBOUND_HANDLER)
      5. CREATE OBJECT (dynamic) → handler->handle_request( ... )
      6. set status/reason + Content-Type on response
      7. save_log if config log_enable ≠ space
```

Auth: the endpoint is exposed through communication scenario `ZCS_API_FWK` — the partner calls with a communication-arrangement user. Setting that up is [Skill: btp-abap-environment] territory.

## Build steps for a new inbound API

1. **DDIC request/response types** — abstract types/structures for the payloads ([Skill: naming-convention]).
2. **Handler class** `ZCL_IB_<NAME>` implementing `ZIF_API_INBOUND_HANDLER` (template below).
3. **Config row** in Fiori app **ZAPI_FWK_CONFIG**: `api_id`, `direction = 'I'`, `active = X`, `inbound_class = ZCL_IB_<NAME>`, `log_enable` (`X` full / `B` basic), `api_group`, description. Comm-scenario/method/uri fields are outbound-only — leave empty.
4. **Test** — unit tests on the handler (mock payload strings), then a real call (Postman) with header `x-api-id` against the `Z_API_INBOUND_HTTP` endpoint URL from the communication arrangement.

## Handler contract

```abap
INTERFACE zif_api_inbound_handler PUBLIC.
  METHODS handle_request
    IMPORTING
      iv_api_id           TYPE string
      iv_request_payload  TYPE string                              " raw text, or base64 when binary (see below)
      it_headers          TYPE zif_api_fwk_types=>tt_name_value OPTIONAL  " all HTTP request headers (name/value)
      it_params           TYPE zif_api_fwk_types=>tt_name_value OPTIONAL  " URL query/form fields (name/value)
    EXPORTING
      ev_response_payload TYPE string
      ev_http_status      TYPE i
    RAISING
      zcx_api_fwk.
ENDINTERFACE.
```

The handler owns the business result entirely: set `ev_http_status` explicitly for every path (200/201 success, 4xx business rejection with a JSON error body). Existing examples in the package: `ZCL_TEST_INBOUND_HANDLE_CLASS`, `ZCL_IB_RECEIVE_PDF_TEST`.

## Handler template

```abap
CLASS zcl_ib_my_api DEFINITION
  PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_api_inbound_handler.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_request,
             " request fields (underscore names when using camel mapping)
           END OF ty_request.
    TYPES: BEGIN OF ty_response,
             success TYPE abap_bool,
             message TYPE string,
           END OF ty_response.
ENDCLASS.

CLASS zcl_ib_my_api IMPLEMENTATION.
  METHOD zif_api_inbound_handler~handle_request.
    DATA ls_request  TYPE ty_request.
    DATA ls_response TYPE ty_response.

    TRY.
        " 1. Parse (JSON partner payload → ABAP; camel flag if partner sends camelCase)
        zcl_api_fwk=>json_to_abap( EXPORTING iv_json          = iv_request_payload
                                             iv_mapping_camel = abap_true
                                   CHANGING  c_abap           = ls_request ).

        " 2. Validate — business rejection is a 4xx set HERE, not an exception
        IF ls_request IS INITIAL.
          ev_http_status      = 400.
          ev_response_payload = zcl_api_fwk=>abap_to_json(
            ia_abap = VALUE ty_response( success = abap_false message = 'Empty/invalid payload' )
            iv_mapping_camel = abap_true ).
          RETURN.
        ENDIF.

        " 3. Business logic — EML / released APIs only (rule §3), never direct table writes

        " 4. Success response
        ev_http_status      = 200.
        ev_response_payload = zcl_api_fwk=>abap_to_json( ia_abap = ls_response iv_mapping_camel = abap_true ).

      CATCH cx_root INTO DATA(lx_error).
        " Option A (explicit, preferred): map to a controlled 500 yourself
        ev_http_status      = 500.
        ev_response_payload = zcl_api_fwk=>abap_to_json(
          ia_abap = VALUE ty_response( success = abap_false message = lx_error->get_text( ) )
          iv_mapping_camel = abap_true ).
        " Option B: RAISE EXCEPTION TYPE zcx_api_fwk — framework returns 500 {"error": <get_text()>}
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
```

Framework behavior if an exception escapes the handler: `zcx_api_fwk` → 500 with `{"error": "<exception text>"}`; any other `cx_root` → 500 with a **generic** message ("Internal processing error…") — details deliberately not leaked to the partner.

## Framework validation matrix (before the handler runs)

| Condition | HTTP | Message (`ZMC_API_FWK`) |
|---|---|---|
| Header `x-api-id` missing | 400 | 010 |
| No config row for the api_id | 404 | 000 |
| Config `active = false` | 500 | 001 |
| Config `direction ≠ 'I'` | 405 | 007 |
| Config `inbound_class` empty | 500 | 008 |
| Class doesn't exist or doesn't implement `ZIF_API_INBOUND_HANDLER` (XCO check) | 500 | 006 |
| `CREATE OBJECT` failed | 500 | 009 |

All error bodies are `{"error": "<message>"}` JSON.

## Payload & response mechanics

- **Binary uploads**: when the request `content-type` contains one of xlsx / xls / pdf / docx / zip / x-zip-compressed / octet-stream / image/, the framework reads binary and **base64-encodes** it — `iv_request_payload` arrives as a base64 string. Decode in the handler (e.g. `cl_web_http_utility=>decode_x_base64`). Everything else arrives as plain text via `get_text( )`.
- **Response Content-Type**: framework sets `application/json` when your `ev_response_payload` contains `{` or `[`, else `text/plain`. Reason phrase mapped from `ev_http_status` (200-299 OK, 400, 401, 403, 404, 405, 500).
- **Headers/params**: `it_headers` = every request header; `it_params` = form/query fields — read what you need by `name`.

## Logging notes (inbound specifics)

- Log written after the response is finalized; request `uri_path` is logged as the literal `'INBOUND'`.
- The standard dispatcher does not pass `iv_transaction_number`, so inbound `trans_num` is empty — put your business key in the response payload / log via your own design if traceability by document number is required.
- `log_enable = 'B'` skips payloads and header/param items (log header row only).

## Test checklist (feeds the workflow's Verify Loop)

1. Unit test: handler with representative + broken payload strings (no HTTP involved).
2. Postman: success case → expect handler's 2xx + response body.
3. Postman: missing `x-api-id` → 400; unknown id → 404; config inactive → 500 (proves config wiring, not just class).
4. Check **ZAPI_FWK_LOG** app: log row exists with the expected HTTP code (evidence for rule §11).
