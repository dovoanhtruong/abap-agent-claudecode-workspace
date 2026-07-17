---
description: Micro-workflow cho task SAP đơn lẻ (không cần chạy nguyên workflow lớn) — classify yêu cầu theo 4 loại (mutation nhỏ / đọc-tra cứu / tư vấn / review code), nạp đúng skill theo bảng routing §15, áp governance tối thiểu (TR+Package nếu mutation, activation-guard sau mỗi thay đổi), rồi thực hiện. Dùng khi giao 1 việc nhỏ, sửa nhanh 1 object, hỏi cách làm, tra cứu, hoặc nhờ review 1 đoạn code.
argument-hint: <mô tả task đơn lẻ>
---

> **Claude Code note:** `[Skill: X]` below means invoke the `x` skill via the Skill tool (auto-discovered from `.claude/skills/x/`). Where a step needs an MCP tool not yet loaded, use `ToolSearch` first (`sap-dev-rule.md` §9).

[ROLE & OBJECTIVE]
Handle ONE small, self-contained SAP task end-to-end with the workspace's full skill/governance machinery, WITHOUT the ceremony of the big workflows (no multi-phase ledger, no verify-loop, no TS). This command is the deterministic entry point for `sap-dev-rule.md` §15's routing table.

[INPUT]
- Task: $ARGUMENTS
- If $ARGUMENTS is empty: ask the user for the task in one line — do not guess.

[EXECUTION — 4 steps, keep it light]

**Step 1 — Classify & declare.** Match the task against §15's four shapes (object mutation / system-or-content lookup / how-to consulting / snippet review). Multi-shape tasks take the union. Then print the mandatory declaration line FIRST:
`Skills: [<skill-1>, <skill-2>, …]` — or `Skills: none — <reason>` if genuinely nothing matches (rare; say why).
If classification reveals this is actually a multi-object build, a full FS→TS analysis, or a formal review — STOP and point the user to the proper workflow (`/sap-dev-create-*`, `/sap-dev-fs-analytic*`, `/sap-dev-code-review`, `/sap-dev-bug-fix`) instead of running a compressed imitation of it here.

**Step 2 — Consult before acting.** Invoke each declared skill and actually read what it prescribes for this task type BEFORE producing anything. Skill content wins over background knowledge. Read a skill's `references/` deep files only when genuinely producing that object type (progressive disclosure — don't bulk-load).

**Step 3 — Execute with the governance floor (per shape):**
- *Mutation*: confirm TR + Package up front (§2 — ask, never assume, never touch a TR itself); name per [Skill: naming-convention] (explicit user-given name wins); make the change via the session's SAP MCP tool; then [Skill: activation-guard] all 3 gates (§5) — activation log incl. warnings assessed, confirmed active, dependents unbroken. One object at a time; a second object = go back to Step 1's scope check.
- *Lookup*: read-only (§2). Cite where each fact came from (view source, MCP result, skill reference). Business data stays untouched.
- *Consulting*: answer FROM the consulted skill; cite version-gates from its deep-dive when the target release matters; anything the skill doesn't cover is `[unverified]`, said explicitly (§8).
- *Snippet review*: [Skill: abap] lint/Clean-ABAP pass + the domain skill; findings cite line + evidence, facts separated from severity judgment; no auto-rewrite of the user's code unless asked.

**Step 4 — Report.** [Skill: caveman] narration (§10): what was done, evidence (activation log / source cited / skill section referenced), and any open risk or `[assumption]`. For mutations: Activated and Correct are two separate claims (§8) — state both, with the evidence for each. No walkthrough file, no ledger — if the result matters beyond this chat, say ONE line suggesting where it would be persisted and let the user decide.

[SCOPE GUARDS]
- All of `sap-dev-rule.md` still applies — this command lowers ceremony, never the rules (§2 consent/Z-Y-only/TR, §5 activation-guard, §6 iron laws, §8 reporting language are all in force).
- File outputs (if any) follow §4: they belong to ONE named project (`projects/<project>/<standard-subfolder>/`). If the task produces a file and the project is unknown, ask which project (or point to `/sap-project-init`) before writing. A micro task with no file output needs no project. When a project IS known, read its `projects/<project>/project.md` for default system/package/TR before asking the user for them.
- No object/logic invention beyond what the user asked (§6). Missing info → one focused question ([Skill: grill-me] style, max 1 round for a micro task), not an assumption.
- If ≥3 fix attempts fail on the same object, stop and escalate per §7 — a micro task that fights back is not micro anymore.
