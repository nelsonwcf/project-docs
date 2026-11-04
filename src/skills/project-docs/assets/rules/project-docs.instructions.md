---
name: project-docs rules
description: Documentation rules for this repository. Apply on every task that changes files, runs setup or environment commands, or makes a decision.
applyTo: "**"
---

# project-docs rules
Keep the log, decisions and knowledge files in `docs/project-docs/` current as you work.

## 1. When to write a log entry
Write it in `docs/project-docs/log.md`, in the same turn, when you do one of these. Do not log
reads, explanations, questions, or retries within the same step.

- change any file outside `docs/project-docs/`;
- run a command that changes the environment (install, configure, migrate, deploy), or the
  user reports doing one;
- make a decision (also write a decision entry, section 3);
- try an approach and abandon it (`Status: abandoned`, one or two lines).

## 2. How to write a log entry
1. Read the top entry of `log.md` for the last ID. The new ID is that number plus 1, four digits.
2. Insert the new entry directly below the line `<!-- entries: newest first -->`.
3. Never edit older entries.
4. Date: use the line `Today is YYYY-MM-DD.` from the session context; only if it is absent run
   `date +%F` (bash) or `Get-Date -Format yyyy-MM-dd` (PowerShell). Max 15 lines per entry.
5. `Supersedes:` is required whenever the step changes, replaces or removes something an earlier
   entry added; name that entry's ID. Example: L0007 added a `-Shout` switch and this step
   removes it, so write `Supersedes: L0007`.
6. `Changed:` never lists files under `docs/project-docs/`.
7. `Next:` is the next planned action. When none is planned write `Next: Await user direction.`
   Never a filler such as `Finish.`

`Did:` and `Next:` are required; omit other fields that do not apply. Keep the order.

```
## L0012 — YYYY-MM-DD — <short imperative title>
- Did: <what was done, 1-2 lines>
- Why: <reason, only if not obvious>
- Changed: `path`, `path`
- Ran: `exact command` (repo root | user machine | browser: <console>)
- Verify: <command or check> -> <expected result>
- Decision: D0003
- Supersedes: L0007
- Status: abandoned
- Commit: <short sha>
- Next: <the single next action>
```

## 3. Decisions
When a choice between alternatives is made, add an entry to `decisions.md` directly below
`<!-- entries: newest first -->` and name its ID in the log entry's `Decision:` field.

```
## D0003 — YYYY-MM-DD — <short title>
- Status: active
- Decision: <what was decided>
- Why: <reason>
- Rejected: <alternative> — <why not>
- Log: L0012
```

To change a decision, add a new one and set only the old entry's `Status:` to `superseded by D0003`.

## 4. Knowledge
When you learn something non-obvious about the code, add one line under the right section of
`knowledge.md` (replace that section's `- (none yet)` line if present):
``- <fact>. Source: `path` or `path#L10-L20`. Checked: YYYY-MM-DD``
If you notice a fact there is wrong, fix it in the same turn.

## 5. Exactness, reply marker, limits
- Write exact commands, versions, values and paths. Never write secrets; write `<SECRET: name>`.
- End every reply with exactly one line: `[project-docs: L0012]` listing the log entry IDs you
  wrote this turn, comma-separated (never decision IDs), or `[project-docs: —]` when you wrote none.
- Do not edit `walkthrough.ai.md` or `walkthrough.md`. Do not rewrite or reformat older entries.
- If a message starting with `project-docs:` says the log was not updated, write the missing
  entry now, then finish.
