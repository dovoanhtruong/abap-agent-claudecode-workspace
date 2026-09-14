# XDP Text Skeleton — project standard frame

Copy this frame for every new form; replace only `FORM_NAME`, the body table, and the data bindings. All measurements implement SKILL.md §1–§3 — do not change them per form. This is a **text skeleton**: element names, hierarchy, and measurements are the contract; minor XFA attribute details may need touch-up in ADT/LiveCycle Designer on first activation.

## 1. Frame — A4 portrait

```xml
<?xml version="1.0" encoding="UTF-8"?>
<xdp:xdp xmlns:xdp="http://ns.adobe.com/xdp/">
<template xmlns="http://www.xfa.org/schema/xfa-template/3.3/">
  <subform name="FORM_NAME" layout="tb" locale="ambient" restoreState="auto">

    <!-- ======================= MASTER PAGE ======================= -->
    <pageSet>
      <pageArea name="pmMain" id="pmMain">
        <medium stock="a4" short="210mm" long="297mm"/>
        <!-- flowed content: below Top area, above Footer band -->
        <contentArea name="caMain" x="15mm" y="35mm" w="185mm" h="244mm"/>

        <!-- TOP: logo + company info, every page -->
        <subform name="sfTop" x="15mm" y="10mm" w="185mm" h="25mm">
          <field name="imgLogo" x="0mm" y="0mm" w="20mm" h="20mm">
            <ui><imageEdit/></ui>
          </field>
          <draw name="txtCompanyName" x="24mm" y="0mm" w="161mm" h="5mm">
            <font typeface="Roboto" size="10pt" weight="bold"/>
            <value><text>Công ty ...</text></value>
          </draw>
          <draw name="txtCompanyAddress" x="24mm" y="5mm" w="161mm" h="4.5mm">
            <font typeface="Roboto" size="9pt"/>
            <value><text>Số ..., Phường ..., TP..., Việt Nam</text></value>
          </draw>
          <draw name="txtCompanyTax" x="24mm" y="9.5mm" w="161mm" h="4.5mm">
            <font typeface="Roboto" size="9pt"/>
            <value><text>MST: ...</text></value>
          </draw>
        </subform>

        <!-- FOOTER: page number right, optional print date left, every page -->
        <subform name="sfFooter" x="15mm" y="279mm" w="185mm" h="8mm">
          <draw name="txtPrintDate" x="0mm" y="1mm" w="60mm" h="4mm">
            <font typeface="Roboto" size="8pt"/><para hAlign="left"/>
          </draw>
          <field name="txtPageNo" x="125mm" y="1mm" w="60mm" h="4mm">
            <ui><textEdit/></ui>
            <font typeface="Roboto" size="8pt"/><para hAlign="right"/>
            <event activity="layout:ready" name="event__layoutready">
              <script contentType="application/x-formcalc">
                $ = concat("Trang ", xfa.layout.page($), "/", xfa.layout.pageCount())
              </script>
            </event>
          </field>
        </subform>
      </pageArea>
    </pageSet>

    <!-- ======================= FLOWED CONTENT ======================= -->
    <subform name="sfContent" layout="tb" w="185mm">

      <!-- HEADER: first page only (flows once) -->
      <subform name="sfHeader" layout="tb" w="185mm" h="15mm">
        <draw name="txtTitle" w="185mm" h="8mm">
          <font typeface="Roboto" size="14pt" weight="bold"/>
          <para hAlign="center"/>
          <value><text>BÁO CÁO ...</text></value>   <!-- UPPERCASE -->
        </draw>
        <field name="txtHeaderDetail" w="185mm" h="5mm">
          <ui><textEdit/></ui>
          <font typeface="Roboto" size="10pt" posture="italic"/>
          <para hAlign="center"/>
          <bind match="dataRef" ref="$record.HEADER.DATE_RANGE"/>
        </field>
      </subform>

      <!-- BODY: the only per-form part. Column layout is free; frame rules are not. -->
      <subform name="sfBody" layout="tb" w="185mm">

        <!-- table header row: repeats on every page break -->
        <subform name="rowTableHeader" layout="row" w="185mm">
          <occur initial="1" min="1" max="1"/>
          <break beforeTarget="" after="auto"/>  <!-- set overflow leader to this row -->
          <!-- one draw per column: 10pt bold center, 10% grey fill, 0.5pt borders -->
          <draw name="txtColHeader1" w="30mm" h="6mm">
            <font typeface="Roboto" size="10pt" weight="bold"/>
            <para hAlign="center" vAlign="middle"/>
            <border><edge thickness="0.5pt"/><fill><color value="230,230,230"/></fill></border>
            <value><text>Tài khoản</text></value>
          </draw>
          <!-- ... remaining columns ... -->
        </subform>

        <!-- optional GROUP level: bound to the group node -->
        <subform name="sfGroup" layout="tb" w="185mm">
          <occur min="0" max="-1"/>
          <bind match="dataRef" ref="$record.GROUPS.GROUP[*]"/>

          <subform name="rowGroupHeader" layout="row" w="185mm">
            <!-- merged descriptive cell, 11pt bold left; amount cells right -->
          </subform>

          <subform name="rowItem" layout="row" w="185mm">
            <occur min="0" max="-1"/>
            <bind match="dataRef" ref="ITEMS.ITEM[*]"/>
            <!-- cells: Roboto 11pt; numbers right / text left / dates center;
                 0.5pt borders; padding 1mm v / 1.5mm h -->
          </subform>

          <subform name="rowSubTotal" layout="row" w="185mm">
            <occur min="0" max="1"/>   <!-- conditional presence, see §3 below -->
            <!-- 11pt bold -->
          </subform>
        </subform>

        <subform name="rowGrandTotal" layout="row" w="185mm">
          <occur min="0" max="1"/>
          <!-- 11pt bold; only when data exists -->
        </subform>
      </subform>

      <!-- SIGNATURE: optional; never splits across pages -->
      <subform name="sfSignature" layout="tb" w="185mm" h="35mm">
        <occur min="0" max="1"/>
        <keep intact="contentArea"/>
        <!-- top margin >= 10mm gap after body -->
        <subform name="sfSignLeft" x="10mm" y="10mm" w="60mm" h="25mm">
          <draw name="txtSignRole1" w="60mm" h="5mm">
            <font typeface="Roboto" size="11pt" weight="bold"/><para hAlign="center"/>
            <value><text>Người lập</text></value>
          </draw>
          <draw name="txtSignNote1" w="60mm" h="4mm">
            <font typeface="Roboto" size="9pt" posture="italic"/><para hAlign="center"/>
            <value><text>(Ký, họ tên)</text></value>
          </draw>
          <!-- ~20mm empty signing space below -->
        </subform>
        <subform name="sfSignRight" x="115mm" y="10mm" w="60mm" h="25mm">
          <!-- same structure: e.g. Kế toán trưởng -->
        </subform>
      </subform>

    </subform>
  </subform>
</template>
</xdp:xdp>
```

## 2. Landscape deltas (everything else identical)

| Element | Portrait | Landscape |
|---|---|---|
| `<medium>` | `short="210mm" long="297mm"` | `short="210mm" long="297mm" orientation="landscape"` |
| `caMain` | `x="15mm" y="35mm" w="185mm" h="244mm"` | `x="10mm" y="35mm" w="277mm" h="157mm"` |
| `sfTop` | `x="15mm" y="10mm" w="185mm"` | `x="10mm" y="10mm" w="277mm"` |
| `sfFooter` | `x="15mm" y="279mm" w="185mm"` | `x="10mm" y="192mm" w="277mm"` |
| `txtPageNo` x-offset | `125mm` | `217mm` |
| Content subform widths | `185mm` | `277mm` |
| `sfSignRight` x | `115mm` | `207mm` |

## 3. Standard FormCalc snippets

```text
// Page numbering (layout:ready on txtPageNo — already in the frame)
$ = concat("Trang ", xfa.layout.page($), "/", xfa.layout.pageCount())

// Grand total over all items (calculate event on the total amount field)
$ = Sum(sfBody.sfGroup[*].rowItem[*].numAmount)

// Subtotal within one group
$ = Sum(sfGroup.rowItem[*].numAmount)

// Conditional presence: hide subtotal row when the group has no items
// (initialize event on rowSubTotal)
if (Count(sfGroup.rowItem[*]) == 0) then
  $.presence = "hidden"
endif
```

## 4. Font declaration reminder

Default form font is set once on the root subform's `<font typeface="Roboto" size="11pt"/>`; every element above only overrides size/weight/posture, never typeface. If ADS lacks Roboto, replace the typeface globally with `Arial` — never per element.
