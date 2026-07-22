---
name: btp-diagram-generator
description: Generate SAP BTP solution architecture diagrams as native draw.io (.drawio) files per the official SAP BTP Solution Diagram guidelines (Fiori Horizon design system), opened via a configured draw.io MCP server. USE WHEN: user asks to create/draw/design/sketch a BTP diagram, BTP architecture/landscape/solution/reference-architecture diagram, or to visualize SAP BTP services (CAP, Build, Integration Suite, SAC, AI Core, HANA Cloud, Cloud Foundry, Kyma, Workzone…) and their interdependencies in draw.io/diagrams.net. DO NOT USE FOR: non-BTP architecture diagrams, generic flowcharts, sequence/UML diagrams, or diagrams that should remain in Mermaid/PlantUML.
---

# BTP Solution Diagram Generator

Produces a `.drawio` file in the workspace that conforms to the [SAP BTP Solution Diagram guidelines](https://sap.github.io/btp-solution-diagrams/) and opens it through whichever [draw.io MCP server](https://www.drawio.com/doc/faq/ai-drawio-generation) is configured.

## ⚡ Quick Path (use this first)

For the vast majority of diagrams, **do not hand-write XML**. Use the `btp_builder` Python package — it owns icon lookup, SAP palette, port pinning, label HTML, A4 sizing, SVG upscaling, and validation. A typical L1 diagram is ~20 lines.

```python
# scripts/examples/task_center_arch.py — runnable end-to-end
import sys
from pathlib import Path
# Add the skill's scripts/ dir to sys.path so `btp_builder` imports work
# regardless of where the skill is installed (repo, ~/.claude/skills/, etc.)
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from btp_builder import BtpDiagram

d = BtpDiagram(level="L1", title="Task Center Reference Architecture")

btp = d.btp_container(x=260, y=80, w=560, h=440)
sub = d.subaccount(parent=btp, label="Subaccount",
                   x=btp.x + 24, y=btp.y + 110, w=520, h=170)

wz = d.service("work zone",   in_=sub, x=sub.x + 60, y=sub.y + 60)
tc = d.service("task center", right_of=wz)
ci = d.service("cloud identity", below=tc)

eu = d.user("End User", x=60, y=btp.y + 100)
ac = d.app_client("Application Clients\n(Mobile or Desktop)", below=eu)

s4    = d.external("SAP S/4HANA\nOn-Premise Solutions",
                   x=btp.right_edge() + 40, y=btp.y + 70, kind="sap")
third = d.external("3rd Party\nApplications", below=s4, kind="non-sap")
cloud = d.external("SAP Cloud\nApplications", below=third, kind="sap")
idp   = d.idp("3rd-party Identity Provider",
              x=ci.center_x() - 140, y=btp.bottom_edge() + 60)

d.connect(eu, ac, direction="down")
d.connect(ac, wz, direction="right")
d.connect(wz, tc, kind="dblhd")
d.connect(tc, ci, kind="dblhd", direction="down")
d.connect(tc, s4); d.connect(tc, third); d.connect(tc, cloud)
d.connect(idp, ci, kind="dashed", direction="up")

d.save("btp-task-center-architecture.drawio")  # validates → raises on errors
```

Run via `uv run python <script>.py` from the workspace root. `save()` validates first and raises `ValueError` with the full error list if anything is off; warnings are printed.

### Quick-Path API surface

| Call                                                        | Returns   | Notes                                                                                                                                                       |
| ----------------------------------------------------------- | --------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BtpDiagram(level, title)`                                  | builder   | level ∈ `L0`/`L1`/`L2`. Drives icon size + label weight.                                                                                                    |
| `.btp_container(x,y,w,h, sub_label, env_label, with_logo)`  | `NodeRef` | Light-blue outer frame + SAP corner logo + Subaccount/Multi-Cloud labels.                                                                                   |
| `.subaccount(parent, label, ...)`                           | `NodeRef` | White card inside the BTP container.                                                                                                                        |
| `.inner_card(parent, label, ...)`                           | `NodeRef` | Generic white sub-card (e.g. CIS service group).                                                                                                            |
| `.service(name, in_=, right_of=, left_of=, below=, above=)` | `NodeRef` | `name` is fuzzy-matched via [reference/icon-aliases.json](reference/icon-aliases.json) (e.g. `"task center"`, `"cpi"`, `"hana cloud"`).                     |
| `.user(label, kind="sap")`                                  | `NodeRef` | kind ∈ `sap` / `non-sap` / `highlight`.                                                                                                                     |
| `.app_client(label, ...)`                                   | `NodeRef` | Generic mobile/desktop tile.                                                                                                                                |
| `.external(label, kind="sap"/"non-sap", ...)`               | `NodeRef` | Right-side external system tile.                                                                                                                            |
| `.idp(label, ...)`                                          | `NodeRef` | 3rd-party Identity Provider tile.                                                                                                                           |
| `.connect(src, tgt, kind, direction)`                       | edge id   | `kind` ∈ `std`/`dblhd`/`dashed`/`optional`/`auth`/`scim`/`trust`/`neutral`. `direction` auto-pins ports — override with `"right"`/`"left"`/`"up"`/`"down"`. |
| `.save(path, validate=True)`                                | `Path`    | Writes XML. Validates inline (raises on errors).                                                                                                            |

Positional kwargs (`right_of`, `left_of`, `below`, `above`, `in_`) auto-place nodes — only set explicit `x,y` for the first anchor in each row/column.

### Icon name discovery

```python
from btp_builder import list_aliases, list_icons, lookup_icon
print(list(list_aliases())[:30])     # short names → canonical keys
print(lookup_icon("integration suite", "L1")["key"])
```

If `lookup_icon` raises `IconNotFound`, fall back to a styled tile (`external(label, kind="sap")`) and call it out in the final response.

### Open the diagram

```sh
uv run python .claude/skills/btp-diagram-generator/scripts/open_diagram.py btp-task-center-architecture.drawio
```

Falls back to printing a `https://app.diagrams.net/?…#create=...` URL if no system opener is found. If a draw.io MCP tool is available in the runtime, prefer that — only call MCP tools that actually appear in the tool list.

---

## Manual XML path (advanced / niche cases only)

Use this only when the Quick Path doesn't cover what you need (e.g. exotic legend variants, custom flow-protocol pills, novel layouts not yet supported by the builder). The full authoring guide — icon lookup mechanics (no `mxgraph.sap.*` family exists; real base64-SVG style strings; SVG intrinsic-size/blur fix), the complete Fiori Horizon palette table, atomic structure (containers/cards/tiles/connectors/pills per level), draw.io XML generation rules, and the post-validator eye-check list — lives in [reference/manual-xml-guide.md](reference/manual-xml-guide.md). Read it ONLY when actually hand-authoring XML; the Quick Path builder already applies all of it.

## When to use

Trigger on requests like "Draw a BTP architecture for …", "Generate a BTP solution diagram showing CAP + HANA Cloud + Build Workzone", "Create a draw.io of our SAP BTP integration landscape", "L0 / L1 / L2 BTP diagram for <use case>". If the request is a generic flowchart, sequence diagram, or non-SAP architecture, do not use this skill — generate Mermaid or use a plain draw.io workflow instead.

## Inputs to gather (ask once, concisely)

Before generating, confirm what is missing. Default to L1 if unspecified.

| Input                    | Default              | Notes                                                                                                                                                                  |
| ------------------------ | -------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Audience level           | L1                   | L0 = business overview (no legend, neutral connectors); L1 = technical (services + main flows); L2 = detailed (data flows, protocols, components)                      |
| BTP services / SaaS apps | (must ask)           | e.g. CAP, Build Code, Integration Suite (CPI/Event Mesh/API Mgmt), HANA Cloud, SAC, AI Core, Joule, Build Workzone, Identity Authentication, Destination, Connectivity |
| Non-BTP systems          | (optional)           | e.g. S/4HANA Cloud, SuccessFactors, Ariba, third-party SaaS, on-prem systems, end users                                                                                |
| Environment / runtime    | Cloud Foundry        | Cloud Foundry, Kyma, ABAP Environment                                                                                                                                  |
| Region / multi-region?   | single               | Affects grouping containers                                                                                                                                            |
| Primary flows            | (must ask)           | What connects to what, direction, purpose                                                                                                                              |
| Output filename          | `btp-diagram.drawio` | Saved to workspace root unless user specifies                                                                                                                          |

If the user gives a one-line prompt with enough services and a clear flow, proceed without asking — surface assumptions in the final response.

## Workflow

### 1-4. Map icons → palette → structure → XML

Quick Path: the builder does all four — skip to step 5. Hand-authoring XML: follow [reference/manual-xml-guide.md](reference/manual-xml-guide.md) §1-§4 (icon style-string lookup via [reference/icon-index.json](reference/icon-index.json), Fiori Horizon palette, atomic structure incl. connector/pill recipes, draw.io XML rules incl. A4-landscape page sizing).

### 5. Write the file

Save to the path the user requested (default: workspace root, `btp-diagram.drawio`). Do not overwrite an existing file without confirming.

### 6. Open via the MCP server

Detect which draw.io MCP integration is available, in this order — use the first that is configured:

1. **MCP Tool Server** (`@drawio/mcp` / `npx @drawio/mcp`): call its "open diagram" tool with the generated XML to launch the editor in the browser.
2. **MCP App Server** (`mcp.draw.io/mcp` remote): call its render tool to embed the interactive viewer inline in chat.
3. **Neither configured**: skip silently and instead print a `https://app.diagrams.net/?pv=0&grid=0#create=...` URL built per the FAQ (URI-encode JSON `{"type":"xml","compressed":true,"data":"<base64-deflate-raw>"}`). If you cannot compress in-context, print the file path and instruct the user to open it in their installed draw.io.

Never invent an MCP tool name — only call tools that actually appear in the available tool list.

### 7. Validate before delivering

Run the bundled validator first; fix blurry icons if it warns:

```sh
python3 .claude/skills/btp-diagram-generator/scripts/validate_diagram.py <file.drawio>
python3 .claude/skills/btp-diagram-generator/scripts/upscale_svg_icons.py <file.drawio> --size 48 --in-place
```

The validator covers root cells, unique IDs, vertex/edge exclusivity, no `mxgraph.sap.*`, edge source/target validity, port pinning, waypoints, SVG intrinsic size, palette colors, and A4 page size. The remaining 5 eye-check items (XML escaping, overlaps, container enclosure, per-level legend rules, pill-vertex edge labels) are listed in [reference/manual-xml-guide.md §5](reference/manual-xml-guide.md).

## Final response template

When done, respond with:

1. The saved file path as a workspace-relative markdown link.
2. Whether the diagram was opened in the MCP editor (and how), or the fallback URL/instructions.
3. A short bullet list of **assumptions made** and any **icons that fell back** to generic tiles, so the user can correct them.
4. If the diagram opened in a draw.io workspace using **dark theme**, mention that SAP labels (`#1D2D3E`) are intentionally dark per the Fiori Horizon spec and will appear faint on dark canvas — switch draw.io to light theme or export to PNG/SVG to verify.
5. One sentence on how to iterate (e.g. "ask me to add X service or change the audience level to L2").

## Bundled assets & scripts

Assets in `reference/` (the Quick-Path builder reads the first three for you):

- [icon-index.json](reference/icon-index.json) — `{title → {style, width, height}}`, all 100 BTP icons + 3 user icons. **Primary icon-style lookup.**
- [icon-aliases.json](reference/icon-aliases.json) — 132 short-name aliases driving `BtpDiagram.service()` fuzzy lookup.
- [styles.json](reference/styles.json) — named SAP style strings + port-pin fragments + per-level icon sizes.
- [example-patterns.md](reference/example-patterns.md) — ready-to-copy style/label/connector/pill recipes. **Consult when hand-authoring — do not improvise styles.**
- [manual-xml-guide.md](reference/manual-xml-guide.md) — full manual-XML authoring guide (§1 icons, §2 palette, §3 atomic structure, §4 XML rules, §5 eye-checks).
- [examples/](reference/examples/) — 11 official editable diagrams (compound-pattern style donors) · [libraries/](reference/libraries/) — 7 official `mxlibrary` XMLs · [svg/](reference/svg/) — 129 raw icon SVGs · [templates/](reference/templates/) — empty L0/L1/L2 skeletons · [sap-logo.b64.txt](reference/sap-logo.b64.txt) — corner logo · [sap-btp-palette.json](reference/sap-btp-palette.json) — palette tokens for draw.io config.

Scripts in `scripts/` (`uv run python`, no third-party deps):

- [btp_builder/](scripts/btp_builder/) — **the Quick-Path package** (`from btp_builder import BtpDiagram`).
- [examples/task_center_arch.py](scripts/examples/task_center_arch.py) — runnable canonical example.
- [open_diagram.py](scripts/open_diagram.py) — OS opener with `app.diagrams.net` URL fallback.
- [validate_diagram.py](scripts/validate_diagram.py) — §7 checklist enforcement (`--strict-palette`, `--strict-waypoints`; importable `validate_xml`/`validate_path`).
- [upscale_svg_icons.py](scripts/upscale_svg_icons.py) — fixes icon blur (`--size 32/48/50`, `--in-place`); builder applies automatically.
