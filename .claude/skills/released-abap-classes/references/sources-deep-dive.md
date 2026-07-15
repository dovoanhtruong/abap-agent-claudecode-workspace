# Sources — Deep-Dive Research Trail

Research conducted 2026-07-14 for the ABAP dev skill enrichment initiative (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`, Phase 2). `sap-docs-extend-mcp` confirmed down for this entire session per the task brief — did not attempt it. Fell back to `curl`-fetching the official SAP-samples cheat sheets directly (public GitHub repo, no auth).

## Scope decision

This skill's `SKILL.md` spans 24 unrelated functional categories over a ~9,700-line reference file (`references/Released_ABAP_Classes.md`, already present, not re-fetched). Went deep on 4 categories only — **JSON/XML, HTTP calls, UUID, Date/Time** — chosen because they recur in this workspace's RAP/OData-building workflows (payload mapping, outbound API calls, entity keys, timestamp fields), not because the other 20 lack value. No attempt was made to touch all 24 shallowly.

## Primary sources retrieved

- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/22_Released_ABAP_Classes.md` (10,378 lines) — read the following sections in full: "Excursions" (lines 66-108, the `I_APIsForCloudDevelopment`/`I_APIsWithCloudDevSuccessor` CDS-view discovery pattern — already present verbatim in this skill's own `references/Released_ABAP_Classes.md` at lines 64-105, confirmed via `grep`, so **not** re-presented as new content), "Creating and Transforming UUIDs" (269-398), "Time and Date" (1785-2059), "XML/JSON" (2690-2839), "Calling Services" (4464-4721).
- `https://raw.githubusercontent.com/SAP-samples/abap-cheat-sheets/main/33_ABAP_Release_News.md` (8,016 lines) — grepped case-insensitively for every class name in scope (`XCO_CP_JSON`, `CL_WEB_HTTP_CLIENT_MANAGER`, `CL_HTTP_DESTINATION_PROVIDER`, `CL_SYSTEM_UUID`, `XCO_CP_TIME`, `CL_ABAP_CONTEXT_INFO`, `/UI2/CL_JSON`, `CL_ABAP_UTCLONG`, `CL_ABAP_TSTMP`, `CL_ABAP_DATFM`, `CL_ABAP_TIMEFM`, `CL_SXML`, `CL_IXML`). Release-number mapping used the corrected header regex from the `modern-abap-syntax`/`rap` pilots' post-publication fix (`Release (\S+?)(?:\s*\((\d+)\))?\s*</summary>`, matches quarter-less headers too) — verified no intervening `<summary>` header exists between each finding's line and its mapped header via a targeted `awk` range check before finalizing each attribution.

## Verified release-number claims

| Finding | Nearest header (exact text found in source) | Section |
|---|---|---|
| iXML Library wrapper API for ABAP Cloud (`cl_ixml_core( )=>create`) | `Release 772 (1805)` | Line 2260, ABAP for Cloud Development section (before line 2925 — confirmed by line-number position) |
| `CL_ABAP_TSTMP` new methods `MOVE_TRUNC`/`MOVE_TO_SHORT_TRUNC`/`ADD_TO_SHORT_TRUNC`/`SUBTRACTSECS_TO_SHORT_TRUNC` (Cloud section entry) | `Release 793 (2308)` | Line 773, ABAP for Cloud Development section |

Note: the identical `CL_ABAP_TSTMP` TRUNC-methods entry also appears at line 3613 mapped to `Release 758` (no quarter) — that occurrence is in the file's **Standard ABAP** section (line 3613 > 2925, the documented Cloud/Standard section boundary), i.e. the same feature's classic-ABAP release date. The deep-dive cites only the Cloud-section occurrence (793/2308) since this skill scopes to ABAP for Cloud Development.

Neither release number above carries a calendar-quarter gloss (no "20XX QN" label attached) — deliberately, since no quarter-label conversion was attempted for these two findings, avoiding the risk found and corrected in the Phase 1 pilots' own quarter glosses (see `modern-abap-syntax`'s and `rap`'s `sources-deep-dive.md` for that correction).

## Negative findings (absence checked and confirmed)

- `CL_SYSTEM_UUID`: exactly one match in the entire 8,016-line release-news file, at line 6122, mapped to `Release 710` (no quarter) — and line 6122 is in the **Standard ABAP** section (>2925). No Cloud-section entry exists for this class at all. Same interpretation as `modern-abap-syntax`'s "predates the window" finding for VALUE/COND/etc: release 710 is classic NetWeaver-era (pre-2017), so the class unconditionally predates the entire Cloud-section documented window (earliest Cloud header found across both pilots: 767/1702).
- Zero matches anywhere in `33_ABAP_Release_News.md` for: `XCO_CP_JSON`, `CL_WEB_HTTP_CLIENT_MANAGER`, `CL_HTTP_DESTINATION_PROVIDER`, `XCO_CP_TIME`, `CL_ABAP_CONTEXT_INFO`, `/UI2/CL_JSON`, `CL_ABAP_UTCLONG`, `CL_ABAP_DATFM`, `CL_ABAP_TIMEFM`. Also zero matches for the literal string `XCO` anywhere in the file (checked separately) — the XCO library's own version history is not tracked in this release-news digest at all, only in the classes cheat sheet itself. This absence is reported in the deep-dive's Version Safety section as "no verified cloud-specific gating claim available," not as a claim that these are unconditionally safe on every possible target.

## Cross-checks against this skill's existing content (to avoid restating, not just re-deriving)

- Read the live `SKILL.md` and the full `references/Released_ABAP_Classes.md` (9,708 lines) before drafting. Confirmed the HTTP quick-reference's existing `cx_web_http_client_error`/`cx_http_dest_provider_error` catch pair (already correct) — the deep-dive's decision cue reinforces it against the reference file's own demo code (which catches broad `cx_root`), rather than introducing a new exception pair.
- Confirmed via `grep` that `create_by_comm_arrangement` is not present anywhere in this skill's files, only in `.claude/skills/btp-abap-environment/SKILL.md` and referenced (as a pointer, not duplicated) from `.claude/skills/odata/SKILL.md` — the deep-dive's HTTP section follows the same established pointer convention (Phase 0 dedup item A4) rather than re-duplicating that code here.
