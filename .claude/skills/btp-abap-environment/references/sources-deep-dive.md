# Sources — Deep-Dive Research Trail (`btp-abap-environment`)

Research conducted 2026-07-14 for the ABAP dev skill enrichment initiative (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`, Phase 2 batch 2 round 2). `sap-docs-extend-mcp` was confirmed down for this entire session — used direct `curl` against the public SAP-samples cheat-sheet GitHub repo, plus live `curl`/`WebFetch` checks against URLs this skill cites.

## Primary sources retrieved

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/17_SAP_LUW.md` (458 lines) — the exact file named. Read in full. Source for the Controlled SAP LUW section, the "SAP LUW in ABAP Cloud and RAP" section (confirms classic bundling techniques unavailable, local update is the ABAP Cloud default, `COMMIT ENTITIES`/`ROLLBACK ENTITIES` semantics), and the `CL_BCS_MAIL_MESSAGE`/`send_async` classified-API example.
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines) — grepped case-insensitively for `cl_http_destination_provider`, `cl_web_http_client`, `communication arrangement`, `communication scenario`, `communication system`, `communication user`, `destination service`, and `CL_ABAP_TX`/`IF_ABAP_TX`/`controlled sap luw`/`transactional contract`.
- GitHub Contents API — confirmed no dedicated "HTTP client"/"communication" cheat sheet exists under any name in the repo.

## Verified release-number claim

| Finding | Line | Release (quarter) |
|---|---|---|
| `CL_ABAP_TX` (Controlled SAP LUW explicit phase control via `modify( )`/`save( )`) | 838-839 | 792 (2305 / 2023 Q2) |

## Verified negative findings (absence checked, not assumed)

- `cl_http_destination_provider`, `cl_web_http_client_manager`, `communication arrangement`, `communication scenario`, `communication system`, `communication user`: **zero matches** anywhere in `33_ABAP_Release_News.md` (both sections, 8,016 lines total). Consistent with `released-abap-classes`' own M8 finding for the same two HTTP classes.
- `controlled sap luw`, `transactional contract`, `IF_ABAP_TX`: zero matches as literal search terms — only `CL_ABAP_TX` itself (the class name) is mentioned.

## Live URL checks and correction applied

| URL | Status | Note |
|---|---|---|
| `https://help.sap.com/docs/btp/sap-business-technology-platform/abap-environment` | 200 | Already cited in SKILL.md — no change needed |
| `https://help.sap.com/docs/btp/sap-business-technology-platform/communication-management` | 200 | Already cited in SKILL.md — no change needed |
| `https://developers.sap.com/group.abap-env-get-started.html` | **404** | Was cited in SKILL.md — confirmed dead via `curl -I` (no `-L`), not a redirect artifact. **Manager independently re-verified this 404 and applied the fix**: replaced with `https://developers.sap.com/tutorials/abap-environment-trial-onboarding.html` (confirmed 200, title "Create an SAP BTP ABAP Environment Trial User \| SAP Tutorials") — the closest live equivalent found; no exact "whole mission" page could be located as a drop-in replacement. |
| `https://developers.sap.com/tutorials/abap-environment-communication-arrangement.html` | 200 | Found as an exact topical match for the "Inbound Communication" gap (title: "Maintain a Communication Arrangement for Inbound Communication"). Content not extracted — client-rendered SPA, `curl` returns only a shell and `WebFetch` returned HTTP 403. Liveness and topical relevance verified; step content not — reported honestly rather than reconstructed from the title alone. |

## Cross-reference note (not a citation, a consistency check)

`references/deep-dive.md`'s framing that `cl_http_destination_provider`/`cl_web_http_client_manager` have no verified cloud-specific release gate is stated as consistent with `released-abap-classes/references/deep-dive.md`'s own finding for the same two classes — that file was read (not re-fetched) to confirm the claim lines up rather than silently duplicating or contradicting it.
