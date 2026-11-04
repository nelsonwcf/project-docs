---
name: project-docs
description: "Enable, check, repair or disable project-docs in the current repository: an incremental step log, a decisions record and a codebase knowledge file under docs/project-docs/, kept current by a rules file and hooks. Run with no argument to enable (detects new or existing repositories and offers to migrate existing notes); with status to check health; with disable to remove the rules and hooks (docs kept); with disable purge to also delete docs/project-docs/."
argument-hint: "[status | disable | disable purge]"
disable-model-invocation: true
---

You were invoked with /project-docs.
Your only task in this reply is the procedure below, starting at Step 0.
Do not continue, check or summarize earlier work, even if the context mentions a previous task, a log entry or open files.
Your first action is Step 0 item 1.

# project-docs

Sets up, checks, repairs or removes project-docs in the current repository. Follow the steps in
order. Do not skip a "STOP and wait" point. Never commit anything: leave all changes in the
working tree.

Terms used below:

- `<skill>` is the folder that contains this SKILL.md; templates and hook files are in `<skill>/assets/`
  (usually `~/.copilot/skills/project-docs` in bash, `$env:USERPROFILE\.copilot\skills\project-docs` in
  PowerShell). If you cannot read files in `<skill>/assets/`, tell the user and stop.
- `<root>` is the repository root; run every command from it. Where shells differ, both forms are given.
- Format of every document: `<skill>/references/formats.md`. Read it before writing any entry.
- Today's date: `date +%F` (bash) or `Get-Date -Format yyyy-MM-dd` (PowerShell).
- Write and change the files in `docs/project-docs/` with your file-editing feature, never with terminal
  commands (no `Set-Content`, `Out-File`, `>` or here-strings: Windows PowerShell 5.1 adds a BOM and CRLF).
  Use the terminal only to copy assets, run git and delete files.

## Step 0 - Preconditions

1. Run `git rev-parse --show-toplevel`. If it fails, the folder is not a git repository. Ask the
   user whether to run `git init`. STOP and wait. If the user declines, stop: hooks need git.
2. Read the text after the command. It must be empty, `status`, `disable` or `disable purge`.
   Anything else: show `Usage: /project-docs [status | disable | disable purge]` and stop.
3. Detect the state.
   - **Damaged marker** (check this first): line 1 of `docs/project-docs/log.md` equals
     `<!-- project-docs: v1 -->` only after removing a leading BOM and/or a trailing CR. Detection
     and fix commands: `<skill>/references/damaged-marker.md`. The hooks treat such a repository
     as not enabled. Say so plainly, offer to remove only those bytes, STOP and wait. After a yes,
     fix them without rewriting the rest of the file and continue. After a no, stop.
   - **Enabled** means `docs/project-docs/log.md` exists and its first line is exactly
     `<!-- project-docs: v1 -->`. Check with `head -n 1 docs/project-docs/log.md` (bash) or
     `Get-Content docs/project-docs/log.md -TotalCount 1` (PowerShell).
   - **enabled-healthy**: enabled, and all of these exist: `.github/instructions/project-docs.instructions.md`,
     `.github/hooks/project-docs.json`, `.github/hooks/project-docs/hook.sh`,
     `.github/hooks/project-docs/hook.ps1`, `.github/hooks/project-docs/VERSION`; and that VERSION
     file has the same text as `<skill>/VERSION` (ignore surrounding whitespace and line endings);
     and `.gitattributes` contains the managed block
     (section "The .gitattributes block") exactly.
   - **enabled-needs-repair**: enabled, but anything above is missing or different.
   - **not-enabled**: otherwise.
4. Route:
   - no argument, not-enabled: go to "Enable".
   - no argument, enabled-needs-repair: go to "Repair".
   - no argument, enabled-healthy: say "project-docs is already enabled", then do "Status".
   - `status`: go to "Status".
   - `disable` or `disable purge`: go to "Disable". If no project-docs file exists, say there is
     nothing to disable and stop.

## Enable (create or migrate)

### E1 - Inventory (read only)

Collect the facts listed in `<skill>/references/migration.md`, section "Inventory". Do not change
any file in this step. Mode is **new** (no commits and no files except `.git`) or **existing**.

### E2 - Plan report

Write a report with these parts, then STOP and wait for the user to confirm or change the plan:

1. Mode (new or existing) and the baseline commit (`git rev-parse --short HEAD`, branch from
2. Files to be created: `docs/project-docs/` (`README.md`, `log.md`, `decisions.md`, `knowledge.md`),
   `.github/instructions/project-docs.instructions.md`, `.github/hooks/project-docs.json`,
   `.github/hooks/project-docs/` (`hook.sh`, `hook.ps1`, `VERSION`), and the managed `.gitattributes` block.
   `VERSION`), and the managed block in `.gitattributes`.
3. Migration mapping: each source file -> target file, saying what is kept word for word and what
   is condensed. Use `<skill>/references/migration.md`, section "Mapping".
4. For an existing repository, the history reconstruction choice: `none` (default), `summary`
   (one reconstructed entry per meaningful period) or `detailed` (one per significant commit
   range). Explain: without reconstruction, the AI handout starts from the baseline commit and is
   standalone only from there.
5. Legacy files proposed for deletion. Only project-docs' own legacy memory-model files and
   confirmed third-party assistant scaffolding, each listed by path. Never user documentation.
6. Conflicts found in instruction files (quote them; those files are never modified), and the
   `.gitattributes` change.

Apply any change the user asks for, show the updated plan, and wait again if it changed.

### E3 - Create the docs

Create `docs/project-docs/` and copy the four templates from `<skill>/assets/docs/` into it. If the
folder already holds files with those names, do not overwrite them: tell the user and stop.

### E4 - Seed knowledge.md

- Existing repository: follow `<skill>/references/migration.md`, section "Knowledge seed". Every
  fact cites its source. Do not guess. Replace `- (none yet)` in a section only when you add a fact.
- New repository: leave every section as `- (none yet)`.

### E5 - Write log.md

Write the entries below the line `<!-- entries: newest first -->`, newest first. IDs are
sequential from L0001 in chronological order, so the oldest entry has the lowest ID.

1. Migrated entries: `Origin: migrated`. Reconstructed entries (if chosen): `Origin: reconstructed`.
   Rules in `<skill>/references/migration.md`.
2. The top entry, last in time, titled `project-docs enabled`:

```
## L<next> — <today> — project-docs enabled
- Did: Enabled project-docs documentation.
- Changed: `docs/project-docs/`, `.github/instructions/project-docs.instructions.md`, `.github/hooks/project-docs.json`, `.github/hooks/project-docs/`, `.gitattributes`
- Baseline: commit `<short sha>` on `<branch>`
- Next: Await user direction.
```

For a repository with no commits write `- Baseline: none (no commits yet)`. For an existing
repository, `Did:` may add "Migrated N entries from <sources>.".

### E6 - Write decisions.md

Add migrated decisions (from ADRs, `docs/decisions/`, locked decisions in a legacy `reference.md`),
newest first, below the entries marker. `Log:` names the migrated log entry, or `—`. The original
ADR files stay where they are; the decision entry names their path in `Why:`.

### E7 - Rules file

Copy `<skill>/assets/rules/project-docs.instructions.md` to
`.github/instructions/project-docs.instructions.md` with a terminal copy (section "Copying files").
Create `.github/instructions/` first if it is missing.

### E8 - Hooks
With a terminal copy, never by retyping, copy:

- `<skill>/assets/hooks/project-docs.json` -> `.github/hooks/project-docs.json`
- every file in `<skill>/assets/hooks/project-docs/` -> `.github/hooks/project-docs/`
  (`hook.sh`, `hook.ps1`, `VERSION`)

Verify each copy as described in "Copying files". If a terminal copy is not possible, write the
file from its content and verify the hash the same way.

### E9 - .gitattributes
Apply the section "The .gitattributes block".

### E10 - Legacy deletion
Only after E3-E9 succeeded, delete exactly the paths the user confirmed in E2, nothing else
(section "Deleting paths").

### E11 - Verify
Check and fix before reporting:

1. Line 1 of `docs/project-docs/log.md`, `decisions.md` and `knowledge.md` is `<!-- project-docs: v1 -->`.
2. Every file listed in E2 part 2 exists.
3. Every hook hash matches (E8).
4. Each managed `.gitattributes` line appears exactly once.

### E12 - Report (at most 10 lines)
State: files created, migrated and deleted; that nothing was committed; and how to confirm the hooks:

- Open a new chat. The session-start context should mention project-docs.
- Run **Chat: Open Customizations** and open the Hooks list: the project-docs hooks must appear.
- The workspace must be trusted for hooks to run.

If `<root>` starts with `/mnt/` (a repository on the Windows disk, seen from WSL), add: hooks may
be slow there; keep repositories on the Linux filesystem.

## Repair

Restore only what is missing or different. Never touch the content of `docs/project-docs/`.

1. List what is missing or outdated: rules file, hook config, hook scripts, hook VERSION,
   `.gitattributes` block.
2. If the rules file exists but differs from `<skill>/assets/rules/project-docs.instructions.md`,
   show the difference and ask whether to replace it. STOP and wait. Leave it alone if the user
   says no.
3. Restore the other items: terminal copy and hash verification as in E7-E9. Replace hook files
   whose VERSION differs.
4. Add a top log entry (next ID, today's date) titled `project-docs repaired`, with
   `Did: Restored <items>.`, `Changed:` the restored paths, and `Next:` copied from the previous
   top entry.
5. Report in at most 6 lines. Nothing is committed.

## Status

Read `<skill>/references/status.md` and follow it. It is read only: change no file.

## Disable

1. List what will be removed: `.github/instructions/project-docs.instructions.md`,
   `.github/hooks/project-docs.json`, `.github/hooks/project-docs/`, the managed block in
   `.gitattributes`, and the runtime state folder `<git-dir>/project-docs/` (get `<git-dir>` with
   `git rev-parse --absolute-git-dir`). With `purge`, also `docs/project-docs/`.
2. STOP and wait for confirmation. For `purge`, also ask a second question that names the folder:
   "Delete docs/project-docs/ including the log, decisions and knowledge? This cannot be undone
   except through git history." STOP and wait for an explicit yes.
3. Without `purge`, first add a top log entry (next ID, today's date) titled `project-docs disabled`,
   with `Did: Removed the project-docs rules, hooks and .gitattributes block; docs kept.`,
   `Changed:` the removed paths, and `Next: Run /project-docs to re-enable, or continue without documentation.`
4. Remove the listed paths (section "Deleting paths"). For `.gitattributes`, delete only the lines
   from `# >>> project-docs` through `# <<< project-docs`, keep everything else, and delete the
   file only if nothing else is left. Then remove `.github/hooks/` or `.github/instructions/` if it
   is now empty; leave it if anything else is in it.
5. Report what was removed. Without `purge`, say that the log was kept and that running
   `/project-docs` again will restore the rules and hooks. Nothing is committed.

## Copying files

Copy with the terminal, not by retyping. Create the destination folder first.

- PowerShell: `New-Item -ItemType Directory -Force -Path .github/hooks/project-docs | Out-Null`
  then `Copy-Item -LiteralPath "<source>" -Destination "<destination>" -Force`
- bash: `mkdir -p .github/hooks/project-docs` then `cp -f "<source>" "<destination>"`

Verify each copy by comparing raw content hashes (the same command in both shells):

```
git hash-object --no-filters "<source>" "<destination>"
```

The two printed hashes must be identical. If they differ, copy again; if they still differ, stop
and report the file.

## Deleting paths

Delete only literal paths from a list the user confirmed; never use a variable that could be empty.
PowerShell: `Remove-Item -LiteralPath "<path>" -Recurse -Force`. bash: `rm -rf -- "<path>"`.

## The .gitattributes block

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

1. If `.gitattributes` does not exist, create it containing exactly the block.
2. If it exists and has the markers, replace the lines between them (markers included) with the block.
3. Otherwise append the block after the last line, with one blank line before it if the file does
   not end with one.
4. Keep every other byte of the file unchanged, including its line endings; write the block with
   the same line ending the file already uses. Edit the file in place; do not rewrite the whole
   file with a command that changes encoding or line endings.
