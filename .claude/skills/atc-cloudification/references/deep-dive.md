# ATC Cloudification Repository — Deep Dive

**Honest scope note up front**: this is a config/tooling skill, not a language-feature skill — there is no ABAP release-gating to report here, and forcing a "Version Safety" table would be manufactured content. What follows instead is genuinely new: several JSON URLs cited in this skill's own content were checked directly against the live repository this session (not just re-read from its README), and two of them turned out to be broken (already corrected in `references/quick-reference.md`). That, plus decision guidance for picking the right JSON and troubleshooting a 404, is the real content here. Sources/citation trail: [references/sources-deep-dive.md](sources-deep-dive.md).

## Verified Repository State (checked 2026-07-14) — Corrections Already Applied

`references/quick-reference.md` cited two URLs under "New Clean Core Check (Classic APIs)" as if live at `main/src/...`. Direct `curl` against each one this session:

| URL previously cited | Live status | What's actually there | Status |
|---|---|---|---|
| `.../main/src/objectClassifications_3TierModel.json` | **HTTP 404** | Moved to `src/archive/objectClassifications_3TierModel.json` (and a dated snapshot `objectClassifications_3TierModel_18052026.json`) | **Fixed** in `quick-reference.md` |
| `.../main/src/objectClassifications.json` | **HTTP 404** | Moved to `src/archive/objectClassifications.json` | **Fixed** in `quick-reference.md` |
| `.../main/src/objectClassifications_SAP.json` | HTTP 200 — confirmed live | This is the only one of the three still at the top-level `src/` path | No change needed |

A related, lower-severity finding: the Cloudification Repository's own README shows an inline example URL, `.../objectReleaseInfo_PCE2025.json` (no FPS suffix) — also **HTTP 404**. The real files are FPS-suffixed (`objectReleaseInfo_PCE2025_0.json`, `objectReleaseInfo_PCE2025_1.json`), confirmed live, and this skill's own `quick-reference.md` already had that right. **Lesson, not a fix needed here**: the upstream repository's own README prose can lag its actual file listing — verify against the live `src/` directory listing (GitHub Contents API or direct `curl`), don't trust an inline README example as authoritative.

A genuine coverage gap, not a citation error: **there is no `objectReleaseInfo_PCE2024_*.json` at all** — the PCE (SAP Cloud ERP Private) series jumps from `_2023_3` straight to `_2025_0`. A target system on a 2024 FPS release has no dedicated snapshot to point the check at.

## Decision Guidance: Choosing the Right JSON URL

- **SAP Cloud ERP (public)**: always `objectReleaseInfoLatest.json` — there is no other meaningful choice. Public cloud ERP has no customer-selectable release/version to match against; the check target is always "what's released as of now." Confirmed via the GitHub API this session that this file was last updated within the current year — it's an actively-maintained rolling pointer, not a stale snapshot someone forgot to update.
- **SAP Cloud ERP Private / FPS-versioned targets**: match the JSON's FPS suffix to the system's *actual* FPS — don't default to `PCELatest` out of convenience. A too-new snapshot will flag APIs as "not yet released" that are, in fact, already released at the older FPS the target system runs (false positives that waste remediation effort); it can also miss classification changes that only apply from a later FPS onward.
- **Historical/audit questions** ("what was released as of quarter 2302, for a retrospective compliance report?"): per-quarter public-cloud snapshots are preserved under `src/archive/` (e.g. `objectReleaseInfo_2208.json`, `_2302`, `_2308`, `_2402`, `_2408`, `_2502`, `_2508.json`, matching the ABAP release-quarter numbering, e.g. `2208` = ABAP Release 789). These aren't meant for live check-variant configuration — that's what `*Latest.json` is for — only for retrospective/audit comparison against a point in time.

## Troubleshooting: 404 on the Configured JSON URL

Given the drift found above, a 404 on a previously-working ATC check attribute is a real, recurring failure mode in this repository, not a one-off. Before assuming a SAP Note or ATC configuration problem:

1. Re-fetch the exact configured URL directly (`curl -I <url>`, or check the GitHub Contents API for `repos/SAP/abap-atc-cr-cv-s4hc/contents/src`) to confirm the file is still at that path today.
2. If it's gone, check `src/archive/` before assuming it was deleted outright — SAP has relocated files there rather than removing them (see the two 404s found and fixed this session).
3. Only after confirming the file genuinely doesn't exist anywhere in the repo (the missing 2024 PCE series is the confirmed example), treat it as a real coverage gap: fall back to the nearest `*Latest.json`/nearest available FPS year, and tell the user explicitly that exact-FPS coverage isn't available rather than guessing at an unverified filename pattern.

## Decision Trade-offs

- **Don't silently "fix" a URL toward what the README's prose says** — verify against the live directory listing first. The README's own unsuffixed `PCE2025.json` example is the concrete case found this session: following it literally produces a 404, while the skill's existing (suffixed) URLs are correct.
- **A single JSON attribute value is a config decision with real staleness risk** — unlike most of this skill's content (JSON file selection, level mapping), which is genuinely stable reference material, the *exact set of files present* at any given time is not: two files this skill cited were relocated at some point before this research session, with no apparent deprecation notice. Treat "which JSON files currently exist" as worth a live check before a first-time setup, not something to answer purely from this skill's cached tables — especially for a target the user hasn't configured before.
