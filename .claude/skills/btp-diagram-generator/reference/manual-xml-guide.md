# Manual XML Path — Full Authoring Guide (advanced / niche cases only)

Moved verbatim from SKILL.md (token-optimization P2, 2026-07-17). Use this only when the Quick Path (`btp_builder`) doesn't cover what you need (e.g. exotic legend variants, custom flow-protocol pills, novel layouts not yet supported by the builder). Everything below documents the underlying XML primitives the builder generates for you.

## 1. Map requirements to BTP icons

> **There is no `mxgraph.sap.*` stencil family.** SAP BTP icons in draw.io are SVGs embedded as base64 inside `shape=image;image=data:image/svg+xml,<base64>;…` style strings, distributed via the [SAP draw.io shape library XML files](https://github.com/SAP/btp-solution-diagrams/tree/main/assets/shape-libraries-and-editable-presets/draw.io). Generating `shape=mxgraph.sap.foo` produces an empty square in the canvas — you have seen this fail.

For every requested service, obtain its real `style` string by looking it up in [icon-index.json](icon-index.json):

1. **Preferred:** Load [icon-index.json](icon-index.json) (~660 KB, 100 icons). It maps each icon title (e.g. `31068-sap-build-work-zone_sd`) to its `style` string and library cell `width`/`height`. Match by substring against the requested service name.
2. **Source XML libraries** (if you need a non-default size or a metadata field the index doesn't carry) live in [libraries/](libraries/) — one size-M `mxlibrary` per icon set (foundational, integration suite, app-dev, AI, data-analytics, BTP-SaaS, all-in-one).
3. **Style donors:** for compound patterns (subaccount cards, NETWORK boundaries, pill labels, legend cards), consult the curated [examples/](examples/) — 11 official editable diagrams (Task Center L0/L1/L2, Build Work Zone L2, Process Automation L2, Cloud Identity Services L1/L2, Private Link L2, SAP Start L2). Open any of them and copy the exact style string.
4. If a service is genuinely missing from the library, use the styled fallback tile (see §3 below) and **list it in the final response** so the user can replace it.

Default icon geometry by audience level (matches the official examples — see [example-patterns.md §5](example-patterns.md)):

> **SVG intrinsic size warning:** Every icon in the SAP shape library has `width="16" height="16"` on its root `<svg>` element, even in the size-M set. draw.io rasterizes at that intrinsic size then upscales, producing a blurry icon. After extracting a base64 SVG, patch the root `<svg width>` and `<svg height>` to match the target cell size (e.g. 48 for L1) before re-encoding. Keep `viewBox` unchanged. See [example-patterns.md §11](example-patterns.md) for the Python helper.

| Level | Icon size | Label            |
| ----- | --------- | ---------------- |
| L0    | 50×50     | Arial 14 bold    |
| L1    | 48×48     | Arial 14 bold    |
| L2    | 32×32     | Arial 12 regular |

The label goes in the cell's `value=` attribute and renders below the icon (the library style already sets `verticalLabelPosition=bottom`). Always keep the `points=[[0,0,0,0,0],…]` 12-anchor array from the library style so connectors snap cleanly.

## 2. Apply the SAP Fiori Horizon palette

Always use these colors only (never pick arbitrary fills). Source: SAP BTP Solution Diagram guideline — _Foundation (Atoms)_ and _Areas_:

| Token                      | Hex                      | Use                                                           |
| -------------------------- | ------------------------ | ------------------------------------------------------------- |
| SAP/BTP border (Primary)   | `#0070F2`                | BTP container stroke, accent fills, sub-card stroke           |
| SAP/BTP fill               | `#EBF8FF`                | BTP container background                                      |
| Non-SAP border             | `#475E75`                | Non-SAP / external area strokes, generic data-flow connectors |
| Non-SAP fill / Subtle bg   | `#F5F6F7`                | Non-SAP areas, page background, generic pill fill             |
| Title text                 | `#1D2D3E`                | Headings, primary labels                                      |
| Secondary text             | `#556B82`                | Sub-labels, descriptions, footnotes                           |
| Positive (Auth, green)     | `#188918` / bg `#F5FAE5` | Authentication flows (SAML, OIDC) — per guideline             |
| Critical (Warning, orange) | `#C35500` / bg `#FFF8D6` | Warnings                                                      |
| Negative (Error, red)      | `#D20A0A` / bg `#FFEAF4` | Errors                                                        |
| Teal accent                | `#07838F` / bg `#DAFDF5` | Highlight areas                                               |
| Indigo (Authorization)     | `#5D36FF` / bg `#F1ECFF` | Authorization / provisioning (SCIM) flows — per guideline     |
| Pink (Trust)               | `#CC00DC` / bg `#FFF0FA` | Trust flows (mutual trust, federation) — per guideline        |

Font: `Arial` (or `Arial Black` for headings), size 12 for body labels, 14 for service labels, 16 for group titles.

## 3. Apply the atomic structure

Per the SAP atomic design system (Atoms → Molecules → Organisms). The exact style strings, sizes and HTML label patterns to copy live in [example-patterns.md](example-patterns.md) — match those rather than inventing variants.

- **Document title** (every diagram): a floating text cell above the BTP container, blue `#0070F2` bold Arial 16, format `"{Scenario} - SAP BTP Solution Diagram"`.
- **Outer container** (Subaccount / Multi-Cloud): `rounded=1;strokeColor=#0070F2;fillColor=#EBF8FF;arcSize=32;absoluteArcSize=1;strokeWidth=1.5;`. Carries the SAP-logo image tile in the top-left and two stacked labels: bold `Subaccount` (Arial 16) + smaller `Multi-Cloud` (Arial 12).
- **Sub-containers** (white cards inside the BTP boundary — e.g. Cloud Identity Services group): same `#0070F2` stroke, `#FFFFFF` fill, `arcSize=16`. **Always blue stroke, never slate**, when the card sits inside the BTP container. Per the guideline _Areas / Nesting_: alternate fill vs. no-fill between parent and child to keep visual contrast (BTP container has fill `#EBF8FF`, so inner cards use white).
- **Service nodes**: BTP icons (§1) wrapped in a `style="group" connectable="0"` cell whenever they need a separate text label or are co-positioned with another shape. Children use coordinates relative to the group origin.
- **External-system tiles** (e.g. `SAP S/4HANA On-Premise`): a group of (white card `arcSize=14` + ~28×28 icon top-left + bold `font-size:16px` label on the right). Sit outside the BTP container.
- **Users / actors**: a `group` containing the user SVG image and a centered `End User` text label below.
- **Connectors** — copy the right variant from the example patterns reference. Per the guideline _Connectors_ section, line _style_ encodes flow nature and line _color_ encodes flow semantic:
  - **Line style:** solid = direct synchronous request/response · `dashed=1` = indirect / asynchronous · `dashed=1;dashPattern=1 4;` (dotted) = optional · `strokeWidth=3` = **firewalls / network barriers only**.
  - **Semantic color:** Authentication = green `#188918` · Authorization / Provisioning (SCIM) = indigo `#5D36FF` · Mutual trust / federation = pink `#CC00DC` · Generic data = slate `#475E75`.
  - Standard data flow: `endArrow=blockThin;strokeColor=#475E75;endFill=1;endSize=4;startSize=4;strokeWidth=1.5;`
  - Orthogonal: prefix with `edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;`
  - Authentication (SAML/OIDC): same shape, `strokeColor=#188918`
  - Authorization / Provisioning (SCIM): same shape, `strokeColor=#5D36FF`
  - Mutual trust: add `startArrow=blockThin;startFill=1` and `strokeColor=#CC00DC`
  - Async / indirect: add `dashed=1`
  - Optional: add `dashed=1;dashPattern=1 4;` (dotted)
  - Network / firewall boundary line: thick grey vertical separator `strokeColor=#475E75;strokeWidth=3;jumpStyle=gap;` with a small uppercase `NETWORK` label (`#475E75`) beside it. **Reserve `strokeWidth=3` for firewalls/network barriers only** — do not use it for normal data flows.
  - **Always pin exit/entry ports** to avoid diagonal auto-routing: add `exitX=1;exitY=0.5;exitDx=0;exitDy=0;entryX=0;entryY=0.5;entryDx=0;entryDy=0;` (adjust X/Y for the direction). For vertical connectors use `exitY=1` / `entryY=0`. **Remove manual `<mxPoint>` waypoints** unless a deliberate detour is needed — leave `<Array as="points"/>` empty. See [example-patterns.md §8](example-patterns.md) for the full port-pinning reference.
- **Edge labels** are _separate vertex pills_, not inline edge text — small rounded rectangles `arcSize=50`, ~16 px tall, color-matched to the connector (generic `#475E75`/`#F5F6F7`, auth `#188918`/`#F5FAE5`, authz/SCIM `#5D36FF`/`#F1ECFF`, trust `#CC00DC`/`#FFF0FA`).
- **L0**: no legend, no protocol pills, neutral `endArrow=block` or `endArrow=none` connectors.
- **L1**: directional `endArrow=blockThin` connectors, optionally a few colored auth/provisioning flows and pill labels.
- **L2**: add a description block + `Diagram Level: L2` under the title, pill tags on every meaningful edge, and a **legend card** in the top-right (white card, `strokeColor=#eaecee`, with colored 16×16 ellipse swatches for each flow type and a sample arrow per arrow style).

## 4. Generate the draw.io XML

Follow the [draw.io AI generation rules](https://www.drawio.com/doc/faq/ai-drawio-generation):

- Use **uncompressed** XML, full `<mxfile>` wrapper (so file-level vars are usable).
- Always include `<mxCell id="0"/>` and `<mxCell id="1" parent="0"/>`.
- Vertices: `vertex="1"`. Edges: `edge="1"` with `source`/`target`. Mutually exclusive.
- Unique IDs across the diagram.
- Coordinates: top-left `(0,0)`, x→right, y→down. Children inside a group use coordinates _relative_ to the group.
- Match perimeter to shape (e.g. `perimeter=ellipsePerimeter` for ellipses).
- XML-escape labels (`&amp;`, `&lt;`, `&gt;`, `&quot;`). HTML markup inside `value=` is allowed and is the standard way to bold/size text — see the official examples.
- Keep grid spacing on multiples of 10 px (`gridSize="10"`); leave ≥20 px gaps between siblings; sub-containers padded by ~18–24 px.
- It is normal and expected for diagrams to be authored in **negative** coordinate space (e.g. `x="-2200"`); draw.io centers on content.

Page size: **always A4 landscape** — `pageWidth="1169" pageHeight="827"`, even for dense L2. Larger virtual canvas comes from spreading groups across negative coordinates, not from changing the page size. L2 additionally sets `background="none"` on `<mxGraphModel>`.

## 5. Eye-check items after the validator run

(The bundled validator covers root cells, unique IDs, vertex/edge exclusivity, no `mxgraph.sap.*`, edge source/target validity, port pinning, manual waypoints, SVG intrinsic size vs cell geometry, palette colors, and A4 landscape page size.)

- [ ] All labels XML-escaped.
- [ ] No overlapping shapes (≥20px gap).
- [ ] BTP container visually encloses all BTP services; external systems sit outside it.
- [ ] L0 diagrams have no legend and neutral connectors; L2 includes a legend card top-right and a description block under the title.
- [ ] Edge labels are pill _vertex_ cells, not inline `value=` text on the `edge="1"` cell.

For deeper validation, reference [`mxfile.xsd`](https://github.com/jgraph/drawio-mcp/blob/main/shared/mxfile.xsd) and the [style reference checklist](https://github.com/jgraph/drawio-mcp/blob/main/shared/style-reference.md#15-validation-checklist-for-ai-generated-files).
