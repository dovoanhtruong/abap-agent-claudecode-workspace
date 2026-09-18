# Authoring the `.xlsx` Template

The template is the layout *and* the mapping spec. Build it with a Python/openpyxl script rather than by hand: the script is reviewable, re-runnable after a layout change, and diffable — a binary edited in Excel is none of those. Read `tag-reference.md` first; this file is about producing the file.

Tooling verified on this machine: **openpyxl 3.1.5**, **Pillow is not installed**. Consequence: `ws.add_image()` is unavailable, so never bake a static picture into the template — put a `${image:...}` tag in a merged box and let the engine insert the picture at runtime.

## Step 1 — pin the data contract before drawing anything

Whatever the input is (a JSON sample, an ABAP structure, a mockup screenshot, an existing Excel file), first write down the sheet's namespace:

- the flat scalar fields (camelCase, `[a-zA-Z0-9_]+`),
- **exactly one** item array and its fields,
- whether the array needs row variants (`row_type`) and which columns auto-merge.

If the input is an image or a PDF mockup, transcribe it to a grid table first (`[Skill: fs-vision-extractor]`) — region, cell range, label, source field — and get that table confirmed. Do not guess a field name; a tag that does not match the payload renders as empty and the bug only shows up at runtime.

If the input is an existing Excel file, read it with openpyxl and list its cells, merges, widths and number formats, then rebuild it as a script. `references/assets/*.xlsx` are three real production templates worth reading for conventions.

## Step 2 — decide the sheet split

One element of the sheets array = one output sheet, all cloned from template sheet 1. So the template describes **one document**, and the ABAP loop decides how many of them come out.

| Requirement | Design |
|---|---|
| one document per selected record (invoice, order) | loop the records in ABAP, one sheet each, `sheetName` = the document id |
| one consolidated list | one sheet, all rows in the single item array |
| two unrelated tables | two sheets — *not* two arrays in one sheet (the engine only tracks one array name per sheet) |
| grouped list with subtotals | one sheet, one flat array, `row_type` per row |

## Step 3 — lay out the sheet

Copy `references/assets/build_template.py` and reshape it. The structure that file demonstrates:

1. **Style constants at the top** — fonts, fills, borders, number formats, column table. Keep every visual decision there so the layout code stays readable.
2. **Header block** — logo merge box with `${image:logo}`, company block, title, label/value grid. Keep labels and values in separate cells so a numeric value keeps its own number format.
3. **Table header row** — static, styled, frozen via `ws.freeze_panes`.
4. **Template block** — the contiguous rows carrying `${table:...}` / `${rowType:...}`.
5. **Footer** — grand totals from scalars, below the block (it shifts down automatically).
6. **Page setup** — `print_area`, landscape, fit-to-width.

### Rules that are easy to get wrong

- **Number formats belong on the template cell.** The cloned style carries them to every generated row. Send the value as a JSON number and the cell formats it; send it pre-formatted as a string and you get left-aligned text.
- **Style merged followers explicitly.** openpyxl only styles the top-left cell of a merge, but the engine clones cell styles one at a time — un-styled follower cells lose their borders after expansion. Use the `style_span()` helper.
- **Merge before tagging an image/QR.** The picture is anchored from the tag cell to the end of its merge range; an un-merged tag cell yields a tiny picture.
- **Keep the template block contiguous.** Any row between the first and last tagged row is part of the block and is deleted after expansion — including a blank spacer row.
- **Always keep one DEFAULT row** (a template row with no `${rowType:}`) unless every possible `row_type` value is declared. Items matching no variant are dropped without an error.
- **Static text inside a template row is cloned too.** `${rowType:L2}Subtotal` renders as `Subtotal` on every L2 row — that is the idiom for labelling variant rows.
- **Avoid formulas.** Cells whose formula errored, or whose formula contains `IMAGE`, are blanked by the engine, and formulas are not re-pointed when rows are inserted. Compute in ABAP instead.
- **Colour by value via conditional formatting**, not by hand — the engine copies conditional formatting rules and expands their ranges over the generated rows. (`material_report_styled.xlsx` uses this for criticality columns.)
- **Diacritics are fine in text**, not in tag names.

## Step 4 — verify before handing over

```bash
python3 build_my_template.py my_template.xlsx
python3 verify_template.py my_template.xlsx sample_payload.json
```

`sample_payload.json` is one serialized `tt_sheets` payload — either taken from a real action run or hand-written to match the ABAP structure. The linter checks: unknown tag syntax, more than one array per sheet, gaps in the template block, a missing DEFAULT row, tags with no matching payload field, `row_type` values the template does not declare, `|merge` columns whose sample data never repeats, sheet-name length and forbidden characters, and whole-cell scalar tags whose sample value is a numeric string (silent `Number()` coercion).

Exit code is non-zero when there is at least one ERROR. **A template is not "done" until this run is clean**, and the run output is the evidence to cite (rule §8).

Then re-open the produced file and read the tags back:

```python
from openpyxl import load_workbook
ws = load_workbook("my_template.xlsx").worksheets[0]
for row in ws.iter_rows():
    for c in row:
        if isinstance(c.value, str) and "${" in c.value:
            print(c.coordinate, repr(c.value))
```

Rendering itself is browser-side and cannot be reproduced locally — never claim the output "looks right" without a real export from the Fiori app (rule §11).

## Step 5 — register it

Upload through the Excel Library Fiori app under the `excel_id` the ABAP action returns (**max 12 characters**). Each upload creates a new `version` in `ZTB_EX_LIB_I`; both the HTTP endpoint and the backend read `MAX( version )`, so a re-upload takes effect immediately and no old version is ever served. There is no rollback other than uploading the previous file again — keep the generator script in the project repo, it *is* the source of truth.
