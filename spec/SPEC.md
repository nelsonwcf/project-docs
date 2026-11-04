# project-docs — Specification

Version 1.5 — 2026-11-04. Owner-maintained. Claude Code builds from this; it does not edit it.
Changes since 1.0 are listed in section 15.

## 1. Purpose

Document everything done in a git repository while working with GitHub Copilot in VS Code, so
the repository always carries:

1. **An incremental log** of every outcome-producing step (`log.md`).
2. **A decisions record**: what was decided and why (`decisions.md`).
3. **Codebase knowledge**: facts discovered from the code, each citing its source (`knowledge.md`).
4. **On request, a consolidated handout**: the step-by-step reproduction path from nothing to
   the current state, in two audiences:
   - `walkthrough.ai.md`: standalone; uploaded into any LLM, it lets that LLM guide a user
     from start to finish.
   - `walkthrough.md`: human-readable; references the repository.

Two personal skills deliver this:

| Skill | Command | Job |
|---|---|---|
| `project-docs` | `/project-docs [status \| disable \| disable purge]` | Enable (create or migrate), check, repair, disable |
| `project-docs-regenerate` | `/project-docs-regenerate [ai \| human \| both] [full]` | Build the handouts |

## 2. Locked decisions

| ID | Decision | Reason |
|---|---|---|
| D01 | Target the VS Code **Copilot harness** (Session Target: Copilot). The Local harness is best effort; the Claude and Codex harnesses are not targeted. | Recommended harness; shared runtime with Copilot CLI and app. |
| D02 | Model-agnostic: Claude Sonnet/Opus, OpenAI models, Auto switching. | The user switches models; state lives in files, not in a model. |
| D03 | Both skills are **personal**, installed in `~/.copilot/skills/`. They are never copied into a repository. | User distributes them as a package; no automatic sharing. |
| D04 | Both skills set `disable-model-invocation: true`. | They run only when the user invokes them. |
| D05 | Documentation is enabled **per repository**, by running `/project-docs` there. Repositories never set up are untouched. | User chooses repo by repo. |
| D06 | Create, migrate, status, repair and disable live in one skill. | Fewer commands; setup auto-detects the state. |
| D07 | Docs live in `docs/project-docs/`. | Never collides with a repo's own `docs/`. |
| D08 | No `status.md` in target repos. The top log entry carries `Next:`. | Copilot compaction is milder; one fewer file to sync. |
| D09 | The log records outcomes, newest first, append-only. Older entries are never edited; reversals are new entries with `Supersedes:`. Dead ends are logged with `Status: abandoned`. | Frozen history; regeneration can filter mechanically. |
| D10 | `decisions.md` is a separate file. | The "why" is not preserved by git or code. |
| D11 | `knowledge.md` facts cite their source path. | Staleness is detectable. |
| D12 | Handouts contain the **reproduction path only**: no dead ends, no superseded steps. | Their job is reproduction, not history. |
| D13 | Audience argument: `ai` (default), `human`, `both`. The AI handout is built first; the human one is derived from it, never from the log. | The two can never disagree on steps. |
| D14 | AI handout is **standalone** (embeds full contents of authored files). Human handout **references the repository**. | User decision. |
| D15 | Handouts are regenerated only on explicit request. Incremental by default (checkpoint), `full` on request. | Cost control. |
| D16 | Always-on rules go in `.github/instructions/project-docs.instructions.md` with `applyTo: "**"`. Setup never modifies `.github/copilot-instructions.md`, `AGENTS.md` or `CLAUDE.md`. | Self-contained; clean removal. Hooks cover the gaps. |
| D17 | Hooks: `sessionStart` (resume context), `userPromptSubmitted` (turn snapshot), `agentStop` (block a turn that changed files without logging). One script per shell (`hook.sh`, `hook.ps1`); only dependency is git. | Enforcement independent of model compliance; no runtime to install. |
| D18 | Setup adds a marked `.gitattributes` block; disable removes only that block. | `.sh` with CRLF breaks bash. |
| D19 | Package: zip with both skills, `INSTALL.md`, `install.sh`, `install.ps1`. | Most likely support issue is a wrong install path. |
| D20 | The user's organization does not restrict hooks or customizations (Policy Diagnostics: all relevant policies "non-applied", 2026-11-02). | Hooks are usable. Design still degrades gracefully without them. |

## 3. Environments

| User setup | Agent terminal | Hooks run in | Personal skills read from |
|---|---|---|---|
| Native Windows, PowerShell terminal | PowerShell | PowerShell | `%USERPROFILE%\.copilot\skills\` |
| Native Windows, Git Bash terminal | Git Bash | **PowerShell** | `%USERPROFILE%\.copilot\skills\` |
| VS Code connected to WSL | bash (Linux) | bash (Linux) | `~/.copilot/skills/` in the distro |

Constraints on everything in `src/`:

- Only dependency: `git` on PATH. No jq, Python, Node.
- Bash scripts: bash 4+, utilities common to Git Bash and Ubuntu (`sed`, `grep`, `awk`, `date`, `mkdir`, `cat`).
- PowerShell scripts: run unchanged on Windows PowerShell 5.1 and PowerShell 7; ASCII-only source.
- Paths written with `/`.
- Repositories may live on the Linux filesystem or under `/mnt/c/` in WSL (slower; must still work).
- The agent may run inside a Copilot worktree (worktree isolation). Use `git rev-parse` for every path to git internals.

## 4. Source layout (this repository)

```
src/
  shared/
    formats.md                         canonical doc formats (SPEC 6); build copies it into both skills
  skills/
    project-docs/
      SKILL.md
      VERSION
      references/
        formats.md                     (build output; do not edit)
        migration.md                   detection + migration mapping detail
      assets/
        docs/README.md log.md decisions.md knowledge.md
        rules/project-docs.instructions.md
        hooks/project-docs.json
        hooks/project-docs/hook.sh hook.ps1 VERSION
    project-docs-regenerate/
      SKILL.md
      VERSION
      references/
        formats.md                     (build output; do not edit)
        handout-formats.md
  package/
    INSTALL.md install.sh install.ps1
tests/
  probe/                               P0 probe kit
  hooks/                               automated hook tests
  MANUAL-TEST-PLAN.md
tools/
  build.sh
dist/                                  (gitignored)
```

Versioning: one version for the whole package (`0.1.0` initially), written to both skill
`VERSION` files, the hook `VERSION` file, the hook script header comment, and the zip name.
`tools/build.sh` checks they match. Do not put a version field in SKILL.md frontmatter (see
PLATFORM-NOTES V8).

## 5. Footprint in an enabled repository

```
docs/project-docs/
  README.md                       what this folder is (for humans)
  log.md                          marker on line 1: <!-- project-docs: v1 -->
  decisions.md
  knowledge.md
  walkthrough.ai.md               only after /project-docs-regenerate
  walkthrough.md                  only after /project-docs-regenerate human|both
.github/instructions/project-docs.instructions.md
.github/hooks/project-docs.json
.github/hooks/project-docs/hook.sh
.github/hooks/project-docs/hook.ps1
.github/hooks/project-docs/VERSION
.gitattributes                    managed block (SPEC 9.6)
```

Runtime state, never committed: `<git-dir>/project-docs/` where `<git-dir>` is
`git rev-parse --git-dir` (per-worktree).

**Enabled** means: `docs/project-docs/log.md` exists and its first line is exactly
`<!-- project-docs: v1 -->`. Hooks and the regenerate skill use only this test.

Setup never commits. It leaves changes in the working tree and tells the user.

## 6. Document formats

Canonical source: `src/shared/formats.md`. Templates in `assets/docs/` must match it. The
rules file restates the log and decision formats inline (the agent will not load references
on ordinary turns).

### 6.1 log.md

```markdown
<!-- project-docs: v1 -->
# Project log

Every outcome-producing step in this repository, newest first.
Rules: `.github/instructions/project-docs.instructions.md`. Entries below the first are frozen.

<!-- entries: newest first -->

## L0002 — 2026-11-02 — Add CSV export endpoint
- Did: Added GET /export.csv returning all orders.
- Why: Finance needs a daily extract.
- Changed: `src/api/export.ts`, `src/api/routes.ts`
- Ran: `npm install csv-stringify@6.5.2` (repo root)
- Verify: `curl -s localhost:3000/export.csv | head -1` -> `id,date,total`
- Decision: D0002
- Next: Add auth check to /export.csv.

## L0001 — 2026-11-02 — project-docs enabled
- Did: Enabled project-docs documentation.
- Changed: `docs/project-docs/`, `.github/instructions/project-docs.instructions.md`, `.github/hooks/project-docs.json`, `.github/hooks/project-docs/`, `.gitattributes`
- Baseline: commit `3f2a9c1` on `main`
- Next: Await user direction.
```

Fields (order fixed; omit optional fields that do not apply):

| Field | Required | Content |
|---|---|---|
| heading | yes | `## L<4-digit seq> — <YYYY-MM-DD> — <short imperative title>` |
| `Did:` | yes | What was done, 1–2 lines. |
| `Why:` | no | Reason, when not obvious and not covered by a decision. |
| `Changed:` | no | Repo paths changed, in backticks. |
| `Ran:` | no | Exact commands, each with where it ran: `(repo root)`, `(user machine)`, `(browser: <service console>)`. Multi-line commands in a fenced block under the field. |
| `Verify:` | no | Command or check -> expected result. |
| `Decision:` | no | `D####` IDs. |
| `Supersedes:` | no | `L####` IDs this step reverts or replaces. |
| `Status:` | no | `abandoned` for dead ends. Absent means done. |
| `Commit:` | no | Short SHA when the step was committed. |
| `Origin:` | no | `migrated` or `reconstructed` (setup only). |
| `Baseline:` | no | Setup entry only. |
| `Next:` | yes | The single next action. Only the top entry's `Next:` is current. |

Rules: entry ≤ 15 lines excluding fenced blocks. Secrets are never written; use
`<SECRET: name>`. Exact versions, values and paths are written as they were used.

### 6.2 decisions.md

```markdown
<!-- project-docs: v1 -->
# Decisions

Decisions that shape this repository, newest first. A decision changes only by a new decision
that supersedes it; the old entry's `Status:` line is the only field ever edited.

<!-- entries: newest first -->

## D0002 — 2026-11-02 — Use csv-stringify for CSV output
- Status: active
- Decision: Generate CSV with csv-stringify, streaming.
- Why: Handles quoting correctly; streams large result sets.
- Rejected: Manual string join — breaks on commas in fields.
- Log: L0002
```

`Status:` is `active` or `superseded by D####`.

### 6.3 knowledge.md

```markdown
<!-- project-docs: v1 -->
# Codebase knowledge

Facts discovered from the code. Each fact cites its source. Before relying on a fact, check
that the source still says so; correct or remove it if not.

## Layout
## Build, run, test
## Configuration
## Architecture
## Conventions
## Gotchas

<!-- fact format: - <fact>. Source: `path` or `path#L10-L20`. Checked: YYYY-MM-DD -->
```

Sections are fixed; empty sections stay with a `- (none yet)` line.

### 6.4 README.md

Under 20 lines, for humans: what each file is, that the handouts are generated by
`/project-docs-regenerate`, and that entries are written by the agent under the rules file.

## 7. Rules file

`assets/rules/project-docs.instructions.md`, copied verbatim to
`.github/instructions/project-docs.instructions.md`.

Frontmatter:

```yaml
---
name: project-docs rules
description: Documentation rules for this repository. Apply on every task that changes files, runs setup or environment commands, or makes a decision.
applyTo: "**"
---
```

Body requirements (target ≤ 70 lines):

1. One-line purpose; points to `docs/project-docs/`.
2. **When to write a log entry**, in the same turn the outcome happens:
   - any change to files outside `docs/project-docs/`;
   - any command that changes the environment (install, configure, migrate, deploy), including
     steps the user did themselves and reported;
   - a decision (also write the decision entry);
   - an approach tried and abandoned (`Status: abandoned`, one or two lines).
   Not logged: reads, explanations, questions, retries within the same step.
3. **How:** read the top entry for the last ID; insert the new entry directly below
   `<!-- entries: newest first -->`; never edit older entries.
   The log entry format inline (from 6.1), compact, plus these field rules stated explicitly:
   - `Supersedes:` is **required** whenever the step changes, replaces or removes something an
     earlier entry added (name that entry's ID). Show one short example in the rules file.
   - `Changed:` never lists files under `docs/project-docs/`.
   - `Next:` is the next planned action; when none is planned, write
     `Next: Await user direction.` Never a filler such as `Finish.`
4. **decisions.md:** when and how (format inline); superseding edits only the old `Status:` line.
5. **knowledge.md:** add a fact when you learn something non-obvious about the code; cite the
   source; when you notice a fact is wrong, fix it in the same turn.
6. **Exactness:** exact commands, versions, values, paths. Never secrets.
6a. **Date:** use the date from the session context line `Today is YYYY-MM-DD.` (injected by
   the session-start hook). Run a date command only when that line is absent. Reason: with
   manual permissions every terminal command needs the user's approval.
7. **Reply marker:** every reply ends with exactly one line:
   `[project-docs: L0012]` (log entry IDs written this turn, comma-separated; never decision
   IDs) or `[project-docs: —]`.
8. **Do not:** edit `walkthrough*.md`; rewrite old entries; reformat files.
9. If a hook message says the log was not updated, write the missing entry and finish.

## 8. Hooks

Copilot hooks format (`version: 1`, camelCase event names). Scripts are self-contained, one
per shell, event passed as the first argument.

### 8.1 `.github/hooks/project-docs.json`

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      { "type": "command",
        "bash": "bash .github/hooks/project-docs/hook.sh session-start",
        "powershell": "powershell -NoProfile -ExecutionPolicy Bypass -File .github/hooks/project-docs/hook.ps1 session-start",
        "timeoutSec": 10 }
    ],
    "userPromptSubmitted": [ "... same shape, argument prompt-submit ..." ],
    "agentStop":           [ "... same shape, argument agent-stop ..." ]
  }
}
```

Confirmed by the probe (2026-11-02): the `powershell` field runs under Windows PowerShell 5.1
(`powershell.exe`, Desktop edition) and the hook process starts in the repository root, on
both Windows and WSL. Use the nested `powershell -NoProfile -ExecutionPolicy Bypass -File`
form shown above: the direct `& script.ps1` form also ran on the test machine, but only
because its LocalMachine execution policy is Unrestricted; default policies would block it.

### 8.2 Common behavior (all events)

1. Read all of stdin as UTF-8 JSON. Extract fields defensively: accept both camelCase and
   snake_case (`sessionId`/`session_id`, `stop_hook_active`/`stopHookActive`, `cwd`).
   Bash: extract with `sed`/`grep` (values are simple strings/booleans); no jq.
2. Resolve repo root: `git -C <cwd or current dir> rev-parse --show-toplevel`. On failure:
   output `{}`, exit 0. Never compare payload `cwd` as text: on Windows it arrives with a
   lowercase drive letter and backslashes (`c:\Users\...`), while git reports `C:/Users/...`.
3. Enabled check (SPEC 5). Not enabled: output `{}`, exit 0.
4. stdout carries exactly one JSON object and nothing else. Diagnostics go to stderr, prefixed
   `project-docs:`.
5. Fail open: any internal error outputs `{}` and exits 0.
6. Output encoding UTF-8 without BOM. PowerShell: set `[Console]::OutputEncoding` and
   `[Console]::InputEncoding` to `UTF8Encoding($false)`, read files with
   `[IO.File]::ReadAllText(path, UTF8Encoding($false))`, write with `[Console]::Out.Write`.
7. Bash JSON output: implement a string escaper (backslash, quote, `\n`, `\r`, `\t`, other
   control characters as `\u00XX`).
8. Session ID for file names: sanitize to `[A-Za-z0-9_-]`, max 64 chars; missing -> `default`.
9. State directory: `<git-dir>/project-docs/snapshots/`, created on demand.
10. Script header comment: `project-docs hook v<version>`.

### 8.3 Turn fingerprint

Computed identically by both scripts:

- `HEAD` SHA (`git rev-parse -q --verify HEAD`; empty if no commits).
- `git status --porcelain=v1 -z --untracked-files=all`, parsed (rename/copy entries carry two
  paths; use the destination).
- Exclude every path under `docs/project-docs/`.
- For each remaining path that exists: content hash via one batched
  `git hash-object --stdin-paths` call. Deleted paths: hash `-`.
- Fingerprint text: line 1 `HEAD <sha>`, then one line per path sorted bytewise:
  `<path>\t<xy status>\t<hash>`.
- Separately: `LOG <hash of docs/project-docs/log.md>`.

### 8.4 `prompt-submit`

1. If the payload `prompt` starts with `project-docs:`, output `{}` and do nothing else. The
   harness submits an `agentStop` block reason as a new user prompt (confirmed by the probe);
   that forced turn must keep the snapshot of the turn that was blocked.
2. Otherwise write `HEAD`, path lines and `LOG` to `snapshots/<session>.txt` (overwrite).
   Output `{}`.

### 8.5 `agent-stop`

1. `stop_hook_active` true -> `{}`.
2. No snapshot for this session -> `{}` (fail open), stderr note.
3. Recompute. Fingerprint (excluding `LOG`) equal to snapshot -> `{}`.
4. `LOG` differs from snapshot -> `{}`.
5. Otherwise block with `{"decision":"block","reason":"..."}` (top level; confirmed by the
   probe on Windows and WSL). The reason appears in the chat as a user message, so it must
   start with `project-docs:` and read as a notice from the hook. Reason text:
   `project-docs: files changed this turn (<up to 5 paths>[, +N more]) but docs/project-docs/log.md was not updated. Add the log entry as described in .github/instructions/project-docs.instructions.md, then finish.`

### 8.6 `session-start`

1. Delete snapshot files older than 7 days.
2. Extract the top log entry: from the first `## L` line after the entries marker to before the
   next `## ` line; cap at 40 lines / 3000 characters.
3. Output `{"additionalContext": "<text>"}`. The text starts with `Today is YYYY-MM-DD.` (the
   local date of the machine running the hook), then:
   `project-docs is enabled in this repository. Follow .github/instructions/project-docs.instructions.md. Docs: docs/project-docs/ (log.md, decisions.md, knowledge.md). Background only, not a task: act on the entry below only if the user asks to continue earlier work. Most recent log entry:` + newline + the entry.
   (Smoke run 2026-11-04: the earlier wording "resume point" made MAI-Code-1.1-Flash continue
   the previous task instead of running an invoked skill.)
4. No entries yet -> same text without the entry.

### 8.7 Budgets

Target on a repository with ~10k tracked files: bash ≤ 300 ms per event; PowerShell ≤ 1.5 s
including startup. Record measurements in `status.md`.

## 9. Skill: project-docs

### 9.1 Frontmatter

```yaml
---
name: project-docs
description: "Enable, check, repair or disable project-docs in the current repository: an incremental step log, a decisions record and a codebase knowledge file under docs/project-docs/, kept current by a rules file and hooks. Run with no argument to enable (detects new or existing repositories and offers to migrate existing notes); with status to check health; with disable to remove the rules and hooks (docs kept); with disable purge to also delete docs/project-docs/."
argument-hint: "[status | disable | disable purge]"
disable-model-invocation: true
---
```

SKILL.md ≤ 250 lines; detail goes to `references/`. Templates and hooks are read from the
skill's own `assets/` folder via relative paths.

**Task lock (both skills).** The first lines of the SKILL.md body, before anything else, say in
substance: "You were invoked with /<skill name>. Your only task in this reply is the procedure
below, starting at Step 0. Do not continue, check or summarize earlier work, even if the
context mentions a previous task, a log entry or open files. Your first action is Step 0
item 1." Write it as plain imperative sentences; the target reader is the weakest model Auto
may choose. (Smoke run 2026-11-04: MAI-Code-1.1-Flash read the skill and then re-verified the
previous task instead.)

### 9.2 Step 0 — Preconditions

1. Workspace root must be a git repository (`git rev-parse --show-toplevel`). If not: ask
   whether to run `git init`. If the user declines, stop: hooks need git.
2. Parse the argument: none, `status`, `disable`, `disable purge`. Anything else: show usage, stop.
3. Detect state:
   - **enabled-healthy**: enabled marker, rules file, hook config, both scripts, hook
     `VERSION` equal to the skill's `VERSION` (compare the text with surrounding whitespace and
     line endings removed), `.gitattributes` block present.
   - **enabled-needs-repair**: enabled marker, anything else missing or outdated.
   - **not-enabled**.
   - **damaged marker** (checked before routing): `docs/project-docs/log.md` exists and its
     line 1 equals the marker only after removing a leading BOM and/or a trailing CR. The
     hooks treat such a repository as not enabled. Say so plainly, offer to remove only those
     bytes, STOP and wait; after a yes, fix them (without rewriting the rest of the file) and
     continue with state detection. After a no, stop.

Routing: no argument + not-enabled -> 9.3; no argument + enabled-needs-repair -> 9.4;
no argument + enabled-healthy -> report "already enabled" and the status summary;
`status` -> 9.5; `disable` -> 9.7.

### 9.3 Enable (create or migrate)

1. **Inventory** (read only; detail in `references/migration.md`):
   - empty repository (no commits and no files except `.git`) -> mode **new**;
   - legacy memory-model files from the old skills: `status.md`, `log.md`, `reference.md`,
     `notes/`, `roadmap.md` at root or `docs/`, detected by `<!-- memory-model: v1 -->` or by
     those names together;
   - other assistant scaffolding: `.claude/state/`, `.claude_state/`, similar;
   - existing history and decisions: `CHANGELOG.md`, `docs/adr/`, `docs/decisions/`,
     `HISTORY.md`;
   - instruction files: `.github/copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md`,
     `.github/instructions/*.md` — read for knowledge and for conflicting rules, never modified;
   - git: commit count, first commit date, current branch, remote URL.
2. **Plan report**, then stop and wait for confirmation. The report states:
   - mode (new / existing) and the baseline commit;
   - files to be created;
   - migration mapping: source -> target, with what is kept verbatim and what is condensed;
   - history reconstruction choice for existing repos: `none` (default), `summary` (one
     reconstructed entry per meaningful period), or `detailed` (one per significant commit
     range). Explain that without reconstruction the AI handout starts from the baseline commit
     and is standalone only from there;
   - legacy files proposed for deletion — only project-docs' own legacy memory-model files and
     confirmed third-party scaffolding, each by path; never user documentation;
   - instruction-file conflicts found (quote them);
   - the `.gitattributes` change.
3. **Create** `docs/project-docs/` from templates.
4. **knowledge.md seed:**
   - existing repo: scan layout, languages, build/run/test commands (package manifests,
     Makefile, scripts, CI workflows), entry points, configuration locations, conventions
     stated in instruction files. Every fact cites its source. Do not guess.
   - new repo: sections with `- (none yet)`.
5. **log.md:** migrated entries (`Origin: migrated`), reconstructed entries
   (`Origin: reconstructed`), oldest lowest, then the top entry `project-docs enabled` with
   `Baseline:` and `Next:`. IDs are sequential from L0001 in chronological order.
6. **decisions.md:** migrated decisions (from ADRs, legacy `reference.md` locked decisions)
   with `Log:` pointing to the migrated entry or `—`. Original ADR files stay; the entry
   references their path.
   Writing rule for steps 3–6 and for every later document edit: create and change the
   content of `docs/project-docs/` files with the file editing tool, not with terminal
   commands. Never `Set-Content`, `Out-File`, `>` redirection or here-strings: Windows
   PowerShell 5.1 adds a BOM and CRLF. The terminal is only for copying assets (steps 7–8),
   git, and deletions. (Smoke run 2026-11-03: a small model's first terminal write added a BOM.)
7. **Rules file:** copy verbatim.
8. **Hooks:** copy `assets/hooks/project-docs.json` and `assets/hooks/project-docs/*` with a
   terminal copy (PowerShell `Copy-Item`, bash `cp`), never by retyping. Verify each copy with
   `git hash-object <source> <destination>`; hashes must match. If the terminal copy is not
   possible, write the file from its content and still verify the hash.
9. **.gitattributes:** apply 9.6.
10. **Legacy deletion:** only paths the user confirmed, after migration succeeded.
11. **Verify:** marker on line 1; all footprint files present; hook hashes match; the new
    `.gitattributes` lines present exactly once.
12. **Report** (≤ 10 lines): files created, migrated, deleted; nothing committed; how to
    confirm hooks: open a new chat — the session-start context should be present — and
    **Chat: Open Customizations > Hooks** lists them; the workspace must be trusted.

### 9.4 Repair

Restore missing or outdated components only: rules file, hook config, hook scripts, hook
`VERSION`, `.gitattributes` block. If the rules file exists but differs from the template, show
the difference and ask before replacing. Never touch `docs/project-docs/` content. Log a
`project-docs repaired` entry.

### 9.5 Status

Report: state, component checklist with versions, entry counts (log, decisions, knowledge
facts), top entry title and `Next:`, handout checkpoints (if present). Read only.

### 9.6 .gitattributes block

```
# >>> project-docs (managed; removed by /project-docs disable)
docs/project-docs/** text eol=lf
.github/instructions/project-docs.instructions.md text eol=lf
.github/hooks/project-docs.json text eol=lf
.github/hooks/project-docs/*.sh text eol=lf
.github/hooks/project-docs/*.ps1 text eol=crlf
.github/hooks/project-docs/VERSION text eol=lf
# <<< project-docs
```

Create the file if missing; otherwise append the block once (replace an existing block between
the markers). Preserve the rest of the file byte for byte, including its line endings.

### 9.7 Disable

1. List what will be removed: rules file, `.github/hooks/project-docs.json`,
   `.github/hooks/project-docs/`, the `.gitattributes` block, `<git-dir>/project-docs/`.
   With `purge`: also `docs/project-docs/`.
2. Stop and wait for confirmation. `purge` requires a second, explicit confirmation naming the
   folder.
3. Remove. Empty `.github/hooks/` or `.github/instructions/` folders left behind are removed
   only if project-docs created them (empty now) — otherwise leave them.
4. Without `purge`, the log is kept and the marker stays; add a top entry
   `project-docs disabled` first so the history records it. Re-enabling later detects an
   existing log and goes to repair.
5. Report.

## 10. Skill: project-docs-regenerate

### 10.1 Frontmatter

```yaml
---
name: project-docs-regenerate
description: "Rebuild the step-by-step handout for the current repository from docs/project-docs/ and the current code. Reproduction path only, no dead ends. Audience ai (default) is a standalone guide an LLM can follow with a user; human is readable and references the repository; both builds both. Add full to rebuild from scratch instead of updating incrementally. Run only when the user asks."
argument-hint: "[ai | human | both] [full]"
disable-model-invocation: true
---
```

Arguments are read from the text after the command, case-insensitive, any order. Defaults:
`ai`, incremental.

### 10.2 Procedure

1. **Enabled check** (SPEC 5). Not enabled: say so, suggest `/project-docs`, stop.
2. **Mode:** `full` if requested, if `walkthrough.ai.md` is missing, or if its checkpoint
   header is unreadable; otherwise incremental.
3. **Read** `decisions.md`, `knowledge.md`, and log entries: all (full) or newer than the
   checkpoint (incremental). Incremental also reads the existing `walkthrough.ai.md`.
4. **Survivor set:** drop entries with `Status: abandoned` and every entry named in a later
   `Supersedes:`. Keep environment steps (`Ran:`) even without file changes. Implicit
   supersession: when step 5 shows that what an entry added no longer exists in the
   repository (for example a removed switch), treat that entry as superseded even without a
   `Supersedes:` line, and record it as a discrepancy. (Smoke run: a model omitted
   `Supersedes:`; the reconcile step caught it — this makes that behavior required.)
5. **Reconcile with the repository:** for every file the surviving steps touch, read its
   current content. The repository wins. Record each discrepancy between log and repository.
   Files changed in the repository but absent from the log are discrepancies too (compare
   against `git status` and, for full mode, `git log --name-only` since baseline).
6. **Order and group** into reproduction steps: dependency order; merge micro-steps that form
   one coherent action; split steps that mix unrelated actions. Each step lists its source log
   IDs.
7. **Write `walkthrough.ai.md`** (SPEC 11.1). Incremental: update only affected steps,
   renumber only if needed, and keep step IDs stable where the step still exists.
8. **If `human` or `both`:** derive `walkthrough.md` from the AI version (SPEC 11.2). If only
   `human` was requested and the AI version is behind the log, refresh the AI version first.
9. **Missing information:** never invent. Mark it in the handout as
   `> UNRESOLVED: <what is missing> (from L####)` and list it in the report.
10. **Report** (≤ 12 lines): mode, entries incorporated, steps, discrepancies, unresolved items,
    handout size (warn above ~150k characters), files written.

No log entry is written for a regeneration; the checkpoint header records it.

## 11. Handout formats

Detail in `references/handout-formats.md` (P4). Requirements:

### 11.1 walkthrough.ai.md

Header line 1:
`<!-- project-docs-regenerate: v1 | audience: ai | through: L0042 | generated: YYYY-MM-DD | mode: full|incremental -->`

Sections in order:

1. **Guide instructions** (addressed to the LLM that receives the document):
   - ask the user's OS/environment first; use the matching command variant;
   - present one step at a time; check `Requires` first;
   - give the `Action` exactly; improvise only when a step fails;
   - have the user run `Verify` and report output; continue only when it matches `Expected`;
   - on failure use `If it fails`; if not covered, troubleshoot without changing the end state;
   - track progress by step ID; resume when the user names a step;
   - `<SECRET: name>`: the user supplies their own value; never invent one;
   - `UNRESOLVED` items: tell the user the document lacks this detail;
   - when the user asks why a step is needed, answer from that step's `Notes`.
2. **Outcome**: what exists at the end.
3. **Environment and prerequisites**: tools with versions, accounts, OS variants covered.
4. **Steps**, each:
   ```
   ### S07 — <title>
   <!-- src: L0012, L0015 -->
   - Goal:
   - Requires: S03, S05 | <tool/account>
   - Action:
   - Files:            (full content of each authored file, fenced, with path; omit if none)
   - Verify: <command or check>
     Expected: <result>
   - If it fails: <symptom> -> <fix>; ...
   - Notes:           (rationale needed to do the step correctly; from decisions.md)
   ```
5. **Final check**: end-to-end verification.

Standalone rules: no links to repo files or other docs.

File versions. Every embedded file must be the content the user needs **at that step**:
- File touched by only one surviving step: embed its current repository content there.
- File touched by several surviving steps: if git holds the version that matches each step
  (the source entries' `Commit:` field, or `git log` for that path), embed that version at each
  step (full content; for files over ~300 lines, an exact old-lines/new-lines edit against the
  previous step's version). If git does not hold the intermediate versions, embed the current
  content once, at the first step that needs the file, and in each later step write
  `Files: <path> — already in its final form since S0X` and describe the change in one line.
  Never embed a version that the log implies but neither git nor the repository holds.
- The last embedded version of every file must equal its current repository content.

Generated files (lockfiles, build
output) are produced by commands, not embedded. Binary assets: name, size, how to obtain.
Step `S00` is always present, by repository mode:
- New repository (`Baseline: none (no commits yet)`): `S00 — Create the project folder`:
  create an empty folder, run `git init` in it, Verify `git rev-parse --is-inside-work-tree`
  -> `true`. Every later step that runs git or assumes the folder requires S00.
- Existing repository without reconstructed history: `S00 — Obtain the baseline` (clone,
  checkout baseline SHA); the guide instructions state that the document is standalone from
  there.
- Existing repository with reconstructed history: `S00 — Create the project folder`, as for
  a new repository; the reconstructed entries rebuild the rest.
(Smoke run T21/T24: the handout for a new repository had no `git init`, and a git step
listed `Requires: none`.)

Examples in `handout-formats.md` show complete content only. No placeholders such as
`// ... full file content here ...`: models imitate examples and would start abbreviating files.

### 11.2 walkthrough.md

Header line 1 as above with `audience: human`. Same step IDs and order as the AI version.
Contains: overview, prerequisites, table of contents, steps in prose with the same commands,
files referenced by repository path (and commit SHA where useful) instead of embedded, fuller
rationale from decisions.md, consolidated troubleshooting section at the end.

## 12. Package and install

### 12.1 Zip contents

```
project-docs-skills-<version>.zip
  project-docs/                  (skill folder)
  project-docs-regenerate/       (skill folder)
  INSTALL.md
  install.sh
  install.ps1
  VERSION
```

Zip entry names use `/` (PowerShell 5.1 `Compress-Archive` writes `\`; do not use it).

### 12.2 install.sh / install.ps1

- Target: `$COPILOT_HOME/skills` if `COPILOT_HOME` is set and V7 confirms it applies to skills;
  otherwise `~/.copilot/skills` (bash) / `$env:USERPROFILE\.copilot\skills` (PowerShell).
- Copy both skill folders from the script's own directory; replace existing copies (copy to a
  temp sibling, then swap).
- Validate after copy: `<target>/<name>/SKILL.md` exists; frontmatter `name` equals the folder
  name; both `VERSION` files equal the package `VERSION`.
- `--uninstall` / `-Uninstall`: remove the two folders only.
- `install.sh` in WSL (`/proc/version` contains `microsoft`): note that native-Windows sessions
  need `install.ps1` too. `install.ps1`: note that WSL sessions need `install.sh` inside WSL.
- End with: reload **every open** VS Code window (**Developer: Reload Window** in each) and
  check **Chat: Open Customizations > Skills**.
- `install.ps1` runs on Windows PowerShell 5.1; documented invocation:
  `powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1`.

### 12.3 INSTALL.md

Per environment (Windows, WSL, both); verify; update (rerun); uninstall; troubleshooting:
skill not listed (wrong home, extra folder level, name mismatch, window not reloaded — every
already-open window must be reloaded, including windows opened after the install but before
a reload, seen in the smoke run), hooks
not firing (workspace trust, Session Target not Copilot), WSL vs Windows home.

### 12.4 tools/build.sh

Runs in Git Bash or Linux. Steps: copy `src/shared/formats.md` into both skills'
`references/`; validate (name regex `^[a-z0-9-]{1,64}$`, name equals folder, description
≤ 1024 chars, only frontmatter fields from PLATFORM-NOTES F1, versions match, `.sh` LF and
`.ps1` CRLF, `.ps1` ASCII-only, JSON files parse — use `git` or PowerShell if needed, no new
dependencies); stage into `dist/stage/`; zip with `zip` if present, otherwise via
`powershell.exe` using `System.IO.Compression` with `/` entry names; list the zip to confirm.

## 13. Tests

### 13.1 Probe kit (P0)

`tests/probe/`: a minimal `.github/hooks/probe.json` plus `probe.sh` / `probe.ps1` that, for
`sessionStart`, `userPromptSubmitted` and `agentStop`, append to
`<git-dir>/probe/events.log`: event, raw stdin, cwd, shell name and version
(`$PSVersionTable.PSVersion` / `$BASH_VERSION`), execution policy (PowerShell), environment
variable names containing `COPILOT`. `agentStop` returns a block once per session (when
`stop_hook_active` is false) with reason `probe: say PROBE-OK and stop`, to confirm the block
format. A `probe.ps1` variant is invoked both ways (nested `powershell -File` and direct) to
answer V2. README: copy into a scratch repo, open in VS Code with Session Target Copilot, send
two prompts, return `events.log`. Run on native Windows and in WSL.

### 13.2 Automated hook tests (P2)

`tests/hooks/run-tests.sh` (tests `hook.sh`) and `tests/hooks/run-tests.ps1` (tests `hook.ps1`)
— same cases, temp git repos, fixture stdin:

1. Not a git repo -> `{}`.
2. Not enabled -> `{}` for all events.
3. session-start with entries -> additionalContext contains the top entry only.
4. session-start with no entries -> additionalContext without entry.
5. prompt-submit then no change then agent-stop -> `{}`.
6. prompt-submit, modify tracked file, agent-stop -> block; reason lists the path.
7. Same as 6 plus log.md changed -> `{}`.
8. Same as 6 with `stop_hook_active: true` -> `{}`.
9. Change only under `docs/project-docs/` -> `{}`.
10. Untracked new file -> block.
11. File already modified before prompt-submit, modified again -> block.
12. Commit during turn, no log -> block.
13. No snapshot -> `{}`.
14. Repo with no commits -> works.
15. Path with spaces and non-ASCII characters -> handled; output is valid JSON.
16. Two sessions interleaved -> independent snapshots.
17. Snapshot older than 7 days removed at session-start.
18. Output is exactly one JSON object; stderr does not leak into stdout.

### 13.3 Manual test plan (P6)

`tests/MANUAL-TEST-PLAN.md`: install (Windows, WSL); skills listed; `/project-docs` on a new
repo; on an existing repo with legacy memory-model files; hooks fire (session-start context,
forced log on an unlogged edit); model switch mid-session keeps logging; `status`; repair
after deleting a hook file; `disable` and `disable purge`; `/project-docs-regenerate`
ai/human/both/full; give `walkthrough.ai.md` to a fresh LLM chat and follow the first three
steps; incremental regeneration after two new entries.

## 14. Out of scope (later tuning)

- `context: fork` for regeneration (needs `github.copilot.chat.skillTool.enabled`).
- Hook opt-out per turn.
- Local-harness-specific hook formats.
- Copilot CLI / Copilot app support (should mostly work; untested).

## 15. Changes

- **1.1 (2026-11-02)** — Probe results applied: 8.1 PowerShell invocation confirmed (nested
  form, Windows PowerShell 5.1); 8.2 payload `cwd` normalization note; 8.4 ignore the hook's
  own block reason when it arrives as a prompt; 8.5 block format confirmed, reason shown to
  the user. Raw logs: `tests/probe/results-windows.log`, `tests/probe/results-wsl.log`.
- **1.2 (2026-11-02)** — Owner review after the build:
  - 7 (item 6a) and 8.6: session-start context starts with `Today is YYYY-MM-DD.`; the rules
    use it instead of running a date command on every log entry.
  - 11.1: file-version rule for files touched by several steps (replaces the contradictory
    "current content" / "full new content again" pair); guide instruction about `Notes`;
    examples must not contain placeholders.
  - Status questions Q7, Q9, Q10, Q12 (a)–(j), Q13: accepted as interpreted. Q12 (i): the
    guide wording is accepted, plus the `Notes` line above.
- **1.3 (2026-11-03)** — Smoke run T01 found `project-docs` silently not loaded: its 9.1
  description contained `: ` unquoted, which is invalid YAML. 9.1 and 10.1 descriptions are now
  double-quoted. `tools/build.sh` must reject frontmatter that is not valid YAML: every
  `description` and `argument-hint` value is double-quoted, with no unescaped `"` inside.
- **1.4 (2026-11-03)** — Smoke run results (8/8 passed on native Windows; findings applied):
  - 7: `Supersedes:` required when a step changes or removes an earlier entry's result (with
    an example); `Changed:` excludes `docs/project-docs/`; `Next:` falls back to
    `Await user direction.`; the reply marker lists log IDs only.
  - 9.2: VERSION comparison ignores whitespace and line endings. 9.6: block covers the hook
    `VERSION` file (git `core.autocrlf=true` would otherwise convert it).
  - 9.3: document content is written with the file editing tool, never terminal writes.
  - 10.2 step 4: implicit supersession detected by reconciliation is required behavior.
  - 11.1: `S00` is always present; new repositories get `Create the project folder` with
    `git init`.
  - 12.3: reload every open window after installing.
- **1.5 (2026-11-04)** — Upgrade test in `new1`: `/project-docs` on a 0.1.0 repository with
  MAI-Code-1.1-Flash (free tier, Auto only) re-verified the previous task instead of repairing.
  - 8.6: session-start text marks the log entry as background, not a task ("resume point"
    removed).
  - 9.1: task-lock opening for both SKILL.md files.
  - 9.2: damaged-marker detection (BOM or CR on log.md line 1) with a confirmed fix (Q16).
  - 12.2: installers say to reload every open window (Q15).
  - Design constraint made explicit: everything must work with the weakest model Auto picks;
    the user's development machine cannot select models.
