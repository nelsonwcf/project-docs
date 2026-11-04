# Migration reference for /project-docs

Used by the "Enable" steps in SKILL.md. Everything in "Inventory" is read only.

## Inventory

Run from the repository root. Collect each item; report what you found in the plan.

1. **Mode.** `git rev-parse --verify HEAD` fails (no commits) and the folder holds only `.git`
   -> mode **new**. List the folder with `ls -A` (bash) or `Get-ChildItem -Force` (PowerShell).
   Anything else -> mode **existing**.
2. **Legacy memory-model files** (from the older memory skills). Look for `status.md`, `log.md`,
   `reference.md`, `roadmap.md` and the folder `notes/`, at the root and under `docs/`. A location
   counts as legacy when either:
   - one of its files contains the line `<!-- memory-model: v1 -->`
     (bash: `grep -l -F -- '<!-- memory-model: v1 -->' status.md log.md reference.md roadmap.md`;
     PowerShell: `Select-String -SimpleMatch -Pattern '<!-- memory-model: v1 -->' -Path status.md,log.md,reference.md,roadmap.md`), or
   - at least two of `status.md`, `log.md`, `reference.md` sit side by side.
   A lone `log.md`, `status.md` or `roadmap.md` is the user's own document: do not treat it as legacy.
   Never confuse the legacy `log.md` with `docs/project-docs/log.md`.
3. **Other assistant scaffolding**: `.claude/state/`, `.claude_state/`, and similar folders whose
   only purpose is an assistant's saved memory or state. Read them for knowledge. Propose deletion
   only for folders that clearly hold nothing else, and only with the user's confirmation.
4. **Existing history and decisions**: `CHANGELOG.md`, `HISTORY.md`, `docs/adr/`,
   `docs/decisions/`. These are user documentation: read them, never delete them.
5. **Instruction files**: `.github/copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md`,
   `.github/instructions/*.md`. Read them for knowledge and for conflicts. Never modify them.
6. **Git facts** (the same commands in both shells):
   - commit count: `git rev-list --count HEAD`
   - first commit date: `git log --reverse --format=%as` (first line)
   - branch: `git branch --show-current`
   - remote: `git remote get-url origin` (may fail: say "none")
   - baseline: `git rev-parse --short HEAD`

## Mapping

Decide for each source what happens to it, and show the table in the plan report. Keep meaning,
dates and exact commands; condense prose. Never invent a command, version or date.

| Source | Target | Rule |
|---|---|---|
| Legacy `log.md` entries | `log.md` entries, `Origin: migrated` | One entry per legacy entry, oldest lowest ID. Keep its date. Fill `Did:`, and `Changed:`, `Ran:`, `Verify:` only when the legacy entry states them. `Next:` is required: use `(historical entry)` unless the legacy entry names one. |
| Legacy `reference.md`: locked decisions | `decisions.md` | One decision per item, `Status: active`, `Log: —`. |
| Legacy `reference.md`: facts, commands, layout | `knowledge.md` | Verify each fact against the repository and cite the repository file. If no repository file confirms it, write `Source: migrated from <legacy path> (unverified)`. |
| Legacy `status.md` | `Next:` of the `project-docs enabled` entry | Use its clearest next step. If it has none, write `Await user direction.` |
| Legacy `roadmap.md`, `notes/` | Kept in place | Not deleted unless the user asks in the plan step. Condense durable facts from notes into `knowledge.md`. |
| ADR files | `decisions.md` | One decision per ADR (see below). The ADR file stays. |
| `CHANGELOG.md`, `HISTORY.md` | Source for reconstructed entries, if chosen | The file stays. |
| Instruction files | Source for `knowledge.md` (conventions, build commands) | The files stay. |
| Other scaffolding | Source for `knowledge.md` | Delete only if confirmed. |

**ADRs.** Number decisions oldest first (D0001 is the oldest). Date: the ADR's own date, else the
date the file was added (`git log --diff-filter=A --follow --format=%as -- <file>`, last line).
`Decision:` from the ADR's decision section; `Why:` from its context and consequences, condensed,
plus `Source ADR: <path>`; `Rejected:` from its alternatives (omit if none). `Status:` is `active`,
or `superseded by D####` when the ADR says it is superseded and the replacing ADR is migrated too.

**Log IDs.** Number all log entries from L0001 in chronological order across migrated and
reconstructed entries. The `project-docs enabled` entry comes last, so it has the highest ID.

## History reconstruction (existing repositories)

Ask the user to choose; the default is `none`.

- **none**: no reconstructed entries. The AI handout starts from the baseline commit.
- **summary**: one entry per meaningful period. Build the list with
  `git log --format='%as %h %s' --reverse` and group commits by tag, release or month. Per entry:
  date = the last commit of the period; `Did:` = what the commits accomplished, from the subjects;
  `Changed:` = the top-level folders touched; `Commit:` = the last commit of the period;
  `Origin: reconstructed`; `Next: (historical entry)`.
- **detailed**: one entry per significant commit range (a merge, a tag, or a commit touching many
  files). Same fields. Use `git show --stat --format='%as %h %s' <sha>` to see what changed.

Rules: use `Ran:` only for commands that a manifest, script or commit message states. If a
reconstructed range would need information you cannot find, record only what you can see. If a
choice would produce more than about 30 entries, propose `summary` instead in the plan.

## Knowledge seed (existing repositories)

Fill the six sections of `knowledge.md` from what you can see. Aim for the useful facts, not
completeness (about 30 facts at most). Each fact is one line:

```
- <fact>. Source: `path` or `path#L10-L20`. Checked: <today>
```

Where to look:

- **Layout**: top-level folders and what they hold (`git ls-files` summarised, not pasted).
- **Build, run, test**: package manifests (`package.json`, `pyproject.toml`, `Cargo.toml`,
  `go.mod`, `pom.xml`, `*.csproj`), `Makefile`, `scripts/`, CI files in `.github/workflows/`.
  Write the exact command and the file that defines it.
- **Configuration**: config files, environment variables read by the code, `.env.example`.
- **Architecture**: entry points and main modules, only when the code makes them clear.
- **Conventions**: rules stated in instruction files and linter or formatter configuration.
- **Gotchas**: warnings stated in README or comments (`TODO`, `WARNING`, `NOTE`).

Do not guess. If you are not sure, leave the fact out.

## Instruction-file conflicts

A conflict is a rule in `.github/copilot-instructions.md`, `AGENTS.md`, `CLAUDE.md` or
`.github/instructions/*.md` that contradicts the project-docs rules. Examples: do not create files
under `docs/`; never end a reply with an extra line; keep a different log or changelog in another
place; commit after every change. Quote each conflicting line with its file in the plan report and
ask the user how to proceed. Do not edit those files.

## What may be deleted

Only paths the user confirmed in the plan, after migration succeeded:

- the legacy memory-model files and folders from "Inventory" item 2 (except those kept by the table),
- third-party assistant scaffolding folders confirmed in item 3.

Never delete user documentation: `README`, `CHANGELOG.md`, `HISTORY.md`, ADRs, instruction files,
or anything under `docs/` that is not a legacy memory-model file.
