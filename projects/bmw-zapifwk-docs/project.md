# Project: bmw-zapifwk-docs

| Field | Value |
|---|---|
| Customer / Engagement | BMW (internal source) — deliverable fully anonymized for public community publication |
| Description | Community article introducing the Z_API_FWK custom API framework: architecture, inbound/outbound flows, error handling, Fiori Config/Log apps, usage guide, diagrams + anonymized UI mockups |
| SAP system (MCP tool) | mcp__abap_bmw_dev__SAP — DEV client 080 (read-only for this project) |
| Default Package | N/A — documentation only, no SAP objects created |
| Current TR | N/A — documentation only |
| Status | active |
| Created | 2026-09-08 |

## Objects & Status
<!-- Documentation project — no SAP objects owned. Source objects read (never modified) listed for traceability. -->
| Object | Type | Status | Notes |
|---|---|---|---|
| Z_API_FWK | DEVC | read-only | Source package for the article |

## Key documents
- `walkthroughs/z-api-fwk-article.html` — the article (single self-contained HTML, EN, anonymized); published Artifact: https://claude.ai/code/artifact/78b766ea-5a5d-4382-b27b-a80e6d314915 (2026-09-08, v3: PNG mockups + enlarged diagrams)
- `walkthroughs/mockups/*.png` — 5 anonymized Fiori mockups rendered headless (Chrome, 1840px / 520px wide, 2x): flp-tiles, config-object-page, log-list-report, log-detail-payload, log-detail-headers
- `scratchpads/mockups/` — mockup HTML sources (`shot-1..5.html`) + `extract.js` / `embed.js` render pipeline (edit HTML → re-render PNG → re-embed)
- `scratchpads/diagrams/` — SVG diagram sources (`fig-1..4-*.svg`) + `swap.js` (swap into article, emit `check-N.html` render-check pages)
- `walkthroughs/z-api-fwk-overview.html` — short version (intro, structure, without/with comparison, benefits); published Artifact: https://claude.ai/code/artifact/6ae96871-db23-41ce-bbed-0ff6ee232666 (2026-09-08, v2: + log detail screen); source template + build in `scratchpads/overview/`
- `walkthroughs/linkedin/` — LinkedIn publishing kit (2026-09-08): `z-api-fwk-carousel.pdf` (12 slides 1080×1080 light), `z-api-fwk-article.md` (detail article → Markdown, 18 image refs), `images/` (5 diagrams light, 8 code, 5 tables, 5 mockups), `posts.md` (post + first-comment texts), `README.md`. Build pipeline: `scratchpads/linkedin/build.js` + `md.js` + headless Chrome (`chrome --headless=new --screenshot` / `--print-to-pdf`).
