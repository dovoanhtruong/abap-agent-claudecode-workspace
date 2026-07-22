# Z_API_FWK — Outbound API Guide (SAP → partner)

Everything needed to call an external system through the framework. Source: live `Z_API_FWK` package source (`abap_bmw_dev`, Jul 2026).

## Runtime flow

```
Business code (RAP action / report / batch)
  → NEW zcl_api_fwk( )->execute_api( iv_api_id = '<API_ID>' ... )
      1. SELECT config header + headers(_I) + params(_P) by api_id
         (not found → zcx_api_fwk=>config_not_found; inactive → config_inactive)
      2. destination = cl_http_destination_provider=>create_by_comm_arrangement(
           comm_scenario / service_id / comm_system_id from config )     " init_error on failure
      3. build request: URI, method, query params, headers, payload
      4. lo_client->execute( )                                            " execute_error on failure (log saved first)
      5. 2xx + json → deserialize response into c_response_data
      6. save_log if log_enable ≠ space; client closed on all paths
```

## Prerequisites (once per target system)

1. Communication scenario + system + arrangement for the target endpoint — [Skill: btp-abap-environment].
2. Config row in Fiori app **ZAPI_FWK_CONFIG**: `api_id`, `direction = 'O'`, `active = X`, `comm_scenario`, `service_id`, `comm_system_id`, `method`, `content_type`, `mapping_camel`, `uri_path`, `log_enable`, `api_group`. Optional static HTTP headers → Headers item table; static URL params → Params item table.

Note: `execute_api` does not enforce `direction` (only inbound checks it) — set `'O'` anyway for correct log semantics. `timeout`/`batch_size` exist in the config table but are NOT consumed by `execute_api` (verified Jul 2026); [Inference] they are for caller-side use.

## Call pattern A — typed JSON request/response (the normal case)

```abap
DATA ls_request  TYPE zs_my_request.     " ABAP structure, underscore field names
DATA ls_response TYPE zs_my_response.

TRY.
    NEW zcl_api_fwk( )->execute_api(
      EXPORTING
        iv_api_id              = 'MY_API_ID'
        i_request_payload_data = ls_request       " serialized to JSON per config (camelCase if mapping_camel)
        iv_transaction_number  = |{ lv_document_number }|   " → log trans_num; ALWAYS pass the business key
      IMPORTING
        es_logger              = DATA(ls_logger)  " full request/response evidence (see below)
      CHANGING
        c_response_data        = ls_response ).   " filled only on 2xx + json config (camel→underscore)

  CATCH zcx_api_fwk INTO DATA(lx_api).
    " textids: config_not_found | config_inactive | init_error | execute_error
    " lx_api->previous holds the original HTTP/destination exception; failed call already logged
ENDTRY.
```

## Call pattern B — dynamic URI / headers / params / raw payload

```abap
NEW zcl_api_fwk( )->execute_api(
  EXPORTING
    iv_api_id                = 'MY_API_ID'
    is_dynamic_request_value = VALUE zif_api_fwk_types=>ty_dynamic_request(
        uri_path        = |/orders/{ lv_order_id }/confirm|          " overrides config uri_path
        request_payload = lv_raw_json                                 " pre-built string payload
        header          = VALUE #( ( name = 'x-correlation-id' value = lv_corr ) )
        param           = VALUE #( ( name = 'lang' value = 'EN' ) ) )
    iv_transaction_number    = lv_trans
  IMPORTING
    es_logger                = DATA(ls_logger) ).
```

## Merge & precedence rules (engine behavior, verified)

| Aspect | Rule |
|---|---|
| URI | dynamic `uri_path` wins; else config `uri_path` |
| Method | from config only (`POST/PUT/DELETE/PATCH/HEAD/OPTIONS`, unknown → `GET`) — not dynamically overridable |
| Query params | dynamic params + ALL config `_P` rows appended; URL-escaped via `cl_web_http_utility=>escape_url` |
| Headers | dynamic headers + ALL config `_I` rows; `content-type` header auto-added from config `content_type` if absent |
| Payload | `i_request_payload_data` (when supplied and non-initial) WINS over `is_dynamic_request_value-request_payload` |
| Serialization | only when config `content_type` contains `json` → XCO JSON (+ camelCase if `mapping_camel`); other content types fall back to `|{ data }|` string templating — pass a ready string instead |
| Response deserialize | only when HTTP 2xx AND `c_response_data` supplied AND payload non-empty AND config `content_type` contains `json`; transformation camelCase→underscore is ALWAYS applied — target ABAP structure must use underscore names |

## `es_logger` (`zif_api_fwk_types=>ty_logger`) — your §11 evidence

```
request : uri_path, method, header[], param[], payload
response: http_code, http_message, header[], payload
```

Always returned (also on non-2xx). Use it to: check `es_logger-response-http_code` for business success handling, quote real payloads in Verify Loops, and update BO status. Non-2xx without an HTTP-level exception does NOT raise — check the code yourself.

## Error handling matrix

| Situation | What happens |
|---|---|
| No config row | `zcx_api_fwk` textid `config_not_found` |
| Config inactive | `config_inactive` |
| Destination/client creation failed | `init_error` (previous = root cause) |
| HTTP execute failed (network, TLS, timeout) | log saved first (if enabled), then `execute_error` (previous = root cause) |
| HTTP returned 4xx/5xx | NO exception — inspect `es_logger-response-http_code` |

## Sharp edges (verified against source unless labeled)

- **Binary outbound**: when config `content_type` is in the binary list, the engine does `set_binary( CONV xstring( lv_payload ) )` — a character→byte conversion that treats the payload as a HEX string; it does NOT base64-decode. Binary outbound is effectively untested territory — verify with a real call before relying on it, or use text/JSON content types.
- **Log persistence**: `save_log` uses EML without `COMMIT ENTITIES` (intentional). [Inference] In a plain report/class context add `COMMIT ENTITIES`/`COMMIT WORK` after `execute_api` if log rows don't appear in **ZAPI_FWK_LOG**; inside RAP handlers the BO's own save sequence commits it.
- **Response camel mapping is unconditional** — even with `mapping_camel = false`, response JSON keys are converted camelCase→underscore before writing into `c_response_data`.
- **Correlation**: log `correlation_id` is taken from response header `x-correlation-id` (else `sap-message-id`) — ask the partner to echo one for cross-system tracing.

## Test checklist (feeds the workflow's Verify Loop)

1. Config row visible in **ZAPI_FWK_CONFIG**, `active = X`.
2. Trigger the real call (RAP action / report) → capture `es_logger` values as evidence.
3. Confirm target system received the request (partner log/screenshot) — rule §11: SAP-side success alone is not a PASS.
4. Check **ZAPI_FWK_LOG**: row with expected `trans_num`, HTTP code, payloads (full log) — and the error row exists when you force a failure.
