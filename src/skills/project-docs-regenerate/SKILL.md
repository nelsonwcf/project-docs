---
name: project-docs-regenerate
description: "Rebuild the step-by-step handout for the current repository from docs/project-docs/ and the current code. Reproduction path only, no dead ends. Audience ai (default) is a standalone guide an LLM can follow with a user; human is readable and references the repository; both builds both. Add full to rebuild from scratch instead of updating incrementally. Run only when the user asks."
argument-hint: "[ai | human | both] [full]"
disable-model-invocation: true
---

You were invoked with /project-docs-regenerate.
Your only task in this reply is the procedure below, starting at Step 0.
Do not continue, check or summarize earlier work, even if the context mentions a previous task, a log entry or open files.
Your first action is Step 0 item 1.

# project-docs-regenerate

Builds the handout files in `docs/project-docs/` from the log, the decisions, the knowledge file
and the current code. Follow the steps in order. Do not invent anything: when information is
missing, say so in the handout (step 9). Never commit anything.

Terms used below:

- `<skill>` is the folder that contains this SKILL.md (usually `~/.copilot/skills/project-docs-regenerate`
  in bash, or `$env:USERPROFILE\.copilot\skills\project-docs-regenerate` in PowerShell).
- `<root>` is the repository root (`git rev-parse --show-toplevel`). Run every command from `<root>`.
- Entry formats (log, decisions, knowledge): `<skill>/references/formats.md`.
- Handout formats, headers and the text to put in the handout: `<skill>/references/handout-formats.md`.
  Read both files now.
- This skill is the only thing that writes `walkthrough.ai.md` and `walkthrough.md`.

## Step 0 - Arguments

1. Read the text after the command. Split it into words and ignore case.
2. Audience word: `ai`, `human` or `both`. At most one. Default `ai`.
3. `full`: optional. Default is an incremental update.
4. Any other word, or two audience words: show `Usage: /project-docs-regenerate [ai | human | both] [full]`
   and stop.

## Step 1 - Enabled check

Check that `docs/project-docs/log.md` exists and its first line is exactly
`<!-- project-docs: v1 -->`. bash: `head -n 1 docs/project-docs/log.md`. PowerShell:
`Get-Content docs/project-docs/log.md -TotalCount 1`. If not, say that project-docs is not enabled
in this repository, suggest running `/project-docs`, and stop.

## Step 2 - Mode

The mode is **full** if any of these is true, otherwise **incremental**:

- the user wrote `full`;
- `docs/project-docs/walkthrough.ai.md` does not exist;
- its first line does not match the AI header in `handout-formats.md`, or its `through:` value is
  not an ID that exists in `log.md`.

For an incremental update, `through` is the ID in the AI handout header: the checkpoint.

## Step 3 - Read

1. Read `docs/project-docs/decisions.md` and `knowledge.md` completely.
2. Read the log entries: all of them (full mode), or only entries with an ID above the checkpoint
   (incremental mode). Also note the top entry's ID: that is the new `through` value.
3. Incremental mode also reads the existing `walkthrough.ai.md`.

## Step 4 - Survivor set

An entry becomes part of the reproduction path only if it survives these rules:

1. Drop entries with `Status: abandoned`.
2. Drop every entry named in the `Supersedes:` field of a later entry. In incremental mode, a new
   entry that supersedes an older one also removes that older entry from the existing handout:
   find the steps whose `<!-- src: -->` list names it, then rewrite or remove those steps.
3. Drop entries titled `project-docs enabled`, `project-docs repaired` or `project-docs disabled`.
   They describe the documentation tooling, not the project. Keep the `Baseline:` of the
   `project-docs enabled` entry for step 6.
4. Keep entries that only have `Ran:` (environment steps) even if they changed no file.
5. Implicit supersession (required). Step 5 may show that what a surviving entry added no longer
   exists in the repository (for example a removed switch) although no later entry has
   `Supersedes:` for it. Then treat that entry as superseded, drop it as in rule 2, and record a
   discrepancy. Apply this rule after step 5, then continue with step 6.

## Step 5 - Reconcile with the repository

The repository wins over the log. Record every discrepancy for the report.

1. For every path in the `Changed:` field of a surviving entry (in incremental mode: of the new
   entries and of the steps being rewritten), read the file as it is now. If it no longer exists,
   find what replaced it (`git log --follow --name-status -- <path>`); if nothing, record a discrepancy.
2. Compare versions and commands in `Ran:` with the repository (package manifests, lock files,
   scripts). If the repository disagrees, use the repository value and record a discrepancy.
3. Find files that changed in the repository but appear in no surviving `Changed:` field:
   - uncommitted: `git status --porcelain`
   - committed since the baseline (full mode): `git log --name-only --format= <baseline>..HEAD`
     where `<baseline>` is the commit in the `Baseline:` field of the `project-docs enabled` entry.
   Ignore `docs/project-docs/`, `.github/instructions/project-docs.instructions.md`,
   `.github/hooks/project-docs.json`, `.github/hooks/project-docs/` and `.gitattributes`.
   Each remaining file is a discrepancy: no log entry explains it.

## Step 6 - Order and group into steps

1. Order the surviving entries by dependency: an action that needs a tool, folder or file comes
   after the action that creates it. Use log order as the tie-break (oldest first).
2. Merge micro-steps that form one coherent action. Split a step that mixes unrelated actions.
3. Give each step an ID `S01`, `S02`, ... and list the log IDs it comes from.
4. Incremental mode: keep the ID of every step that still exists. A new step gets the next unused
   number and is placed where its dependencies require, even if that is not at the end. IDs are
   labels, not positions.
5. Step `S00` is always present, first, with `Requires: none`. Choose by the `Baseline:` of the
   `project-docs enabled` entry:
   - `none (no commits yet)` (new repository): `S00 — Create the project folder` (create an empty
     folder, run `git init`; Verify `git rev-parse --is-inside-work-tree` -> `true`).
   - a commit, and no entries with `Origin: reconstructed`: `S00 — Obtain the baseline`: clone the
     repository (`git remote get-url origin`) and check out the baseline commit. Without a remote,
     write `> UNRESOLVED: no remote URL is recorded for the baseline (from <enabled entry ID>)`.
   - a commit, and reconstructed entries exist: `S00 — Create the project folder`, as for a new
     repository; the reconstructed entries rebuild the rest.
   Every later step that runs git or assumes the folder must list `S00` in `Requires:`.

## Step 7 - Write walkthrough.ai.md

Write `docs/project-docs/walkthrough.ai.md` exactly as `handout-formats.md` describes: header,
guide instructions text, outcome, environment, steps, final check. It must be standalone: embed the
files as the "File versions" rule in `handout-formats.md` says, and link to nothing in the
repository. Before you finish, check that the last embedded version of every file equals the file
in the repository.

In incremental mode, change only the steps that are new or affected. Update the header
(`through:` = the top log ID, `generated:` = today, `mode: incremental`).

## Step 8 - Write walkthrough.md (human or both)

Only for `human` or `both`. Derive `docs/project-docs/walkthrough.md` from the AI handout you just
wrote or updated, as `handout-formats.md` describes: same step IDs and order, same commands. If
only `human` was requested and the AI handout's `through:` is behind the top log ID, update the AI
handout first (steps 3 to 7), then derive.

## Step 9 - Missing information

Never invent. Where a step needs information the log, decisions, knowledge file and repository do
not give, write in the handout at that place:

```
> UNRESOLVED: <what is missing> (from L####)
```

Use `(no log entry)` for files found in step 5 part 3; put those notes at the end of the Outcome
section. List every UNRESOLVED item in the report.

## Step 10 - Report

Write at most 12 lines: mode; log entries incorporated (count); number of steps; discrepancies;
UNRESOLVED items; files written; size of each handout (bash: `wc -c <file>`; PowerShell:
`(Get-Item <file>).Length`) and a warning if it is above about 150000 characters.
No log entry is written for a regeneration; the header records it. Nothing is committed. End the
reply with the line `[project-docs: —]`.
