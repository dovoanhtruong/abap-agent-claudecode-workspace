# Sources — Deep-Dive Research Trail (`atc-cloudification` skill)

Research conducted 2026-07-14 for Phase 2 of the ABAP dev skill enrichment initiative (`artifacts/scratchpads/scratchpad_abap-dev-skill-enrichment.md`). `sap-docs-extend-mcp` was unreachable for the entire session (`Server sap-docs-extend-mcp unavailable`).

**Method note, different from the other two skills researched alongside this one**: this skill isn't a language-feature skill, so the `33_ABAP_Release_News.md` cheat sheet (the primary source for `abap`/`abap-cloud-migration`) had essentially nothing relevant — grepped it for "cloudification", "clean core", "ATC check", "released api" and got zero hits in the Cloud-Development section. Pivoted entirely to directly verifying the actual Cloudification Repository this skill configures against — that's where the genuine new value turned out to be.

## Primary sources retrieved

- `https://raw.githubusercontent.com/SAP/abap-atc-cr-cv-s4hc/main/README.md` — the Cloudification Repository's own current README, fetched in full.
- `https://api.github.com/repos/SAP/abap-atc-cr-cv-s4hc/contents/src` — GitHub Contents API, live directory listing of the repository's `src/` folder.
- `https://api.github.com/repos/SAP/abap-atc-cr-cv-s4hc/contents/src/archive` — live directory listing of `src/archive/`.
- Direct `curl -o /dev/null -w "%{http_code}"` probes against 5 specific URLs (see findings table) to get an authoritative live/dead answer for each, rather than inferring from directory listings alone.
- `https://api.github.com/repos/SAP/abap-atc-cr-cv-s4hc/commits?path=src/objectReleaseInfoLatest.json&per_page=1` — commit history for one file, to confirm it's an actively-maintained rolling pointer and not stale.

## Verified findings (all via direct HTTP status checks this session, not inferred from documentation prose)

| URL | HTTP status | Conclusion |
|---|---|---|
| `.../main/src/objectClassifications_3TierModel.json` | 404 | Not live at this path — confirmed present instead in `src/archive/` via the Contents API |
| `.../main/src/objectClassifications.json` | 404 | Same — confirmed present in `src/archive/` |
| `.../main/src/objectClassifications_SAP.json` | 200 | Live, correct as currently cited by this skill |
| `.../main/src/objectReleaseInfo_PCE2025.json` (no FPS suffix — the exact string the upstream README's own inline example uses) | 404 | The upstream repository's own README prose is stale relative to its actual file listing |
| `.../main/src/objectReleaseInfo_PCE2024_0.json` | 404 | No 2024-series PCE file exists at all (confirmed against the full `src/` Contents API listing, which jumps from `_2023_3` to `_2025_0`) |

- `objectReleaseInfo_PCE2025_0.json` / `_PCE2025_1.json` (the suffixed forms this skill's `quick-reference.md` already cites) — confirmed present via the Contents API listing (not separately curl-probed, but directly enumerated).
- `objectReleaseInfoLatest.json` — confirmed present; its most recent commit (via the commits API) was dated within the current year relative to this research session, supporting the "continuously updated rolling pointer" framing used in the deep-dive.
- `src/archive/` directory listing includes per-quarter public-cloud-ERP snapshots named `objectReleaseInfo_2208.json` through `_2508.json`, matching the ABAP release-quarter numbering scheme documented in `33_ABAP_Release_News.md` (e.g. `2208` corresponds to ABAP Release 789) — used as the basis for the "historical/audit" JSON guidance in the deep-dive.

## Manager re-verification (2026-07-14, before integrating into live content)

Independently re-ran the two `curl` probes for `objectClassifications_3TierModel.json` and `objectClassifications.json` (both `main/src/` and `src/archive/` paths) before editing `quick-reference.md` — confirmed the same 404/200 results as this draft reported. Applied the fix directly to `references/quick-reference.md` (both broken rows now point at `src/archive/` with an inline note); `SKILL.md` itself only cites `objectClassifications_SAP.json`, which was never broken, so no change was needed there.

## Explicitly not pursued / unverifiable this session

- Did not confirm exactly *when* `objectClassifications_3TierModel.json`/`objectClassifications.json` were moved to `archive/`, or whether SAP announced this move anywhere (no changelog was fetched) — the deep-dive states only that they are currently 404 at the old path, not a timeline for the move.
- Did not attempt to verify whether a `objectReleaseInfo_PCE2026_*` series exists yet relative to the session's stated current date (2026-07-14) beyond a couple of direct 404 probes (`PCE2026_0`, `PCE2025_2` — both 404) — not built into the deep-dive as a claim, since a negative result here doesn't rule out a differently-named file existing.
