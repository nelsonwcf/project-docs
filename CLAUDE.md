# project-docs — build repository

This folder is the source for two GitHub Copilot (VS Code) Agent Skills, `project-docs` and
`project-docs-regenerate`, plus their hooks, install scripts and package. The design is fixed
in `spec/`. Your job is to build it, phase by phase, for review.

## Read first, every session

1. `status.md` — current phase, what is done, open questions.
2. `spec/SPEC.md` — the design. Section 2 lists locked decisions.
3. `spec/PLATFORM-NOTES.md` — verified platform facts, sources, and items still to verify.

Do not rely on chat history for continuity; `status.md` is the cursor.

## Working rules

- **Phases.** Work only on the current phase in `status.md`. When it is done: update
  `status.md` (checklist, files produced, open questions), then stop and summarize for review.
  Do not start the next phase until the user says so.
- **Locked decisions are not yours to change.** If something in `spec/SPEC.md` cannot be built
  as written, or is ambiguous, do not improvise: record it under "Open questions" in
  `status.md` with the options you see, and stop. The spec owner revises `spec/SPEC.md`.
- **Platform facts.** Anything marked `VERIFY` in `spec/PLATFORM-NOTES.md` must be confirmed
  (official docs or the probe kit) before code depends on it. Record each result there with
  date and source. Do not invent field names, settings or behaviors.
- **The deliverables are written for other models.** The skills and the rules file will be
  executed by Copilot with Claude Sonnet/Opus or OpenAI models. Inside `src/`:
  - no Claude Code tool names (Read, Edit, Write, Bash…); say "read the file", "edit the file",
    "run in the terminal";
  - imperative, numbered steps; explicit stop-and-wait points;
  - every terminal command given for both PowerShell and bash where they differ;
  - no reliance on a specific model's conventions.
- **Never touch real repositories.** Tests create throwaway git repos in a temp directory.
- **Files and encoding.**
  - UTF-8 without BOM everywhere.
  - `.ps1` files are ASCII-only (Windows PowerShell 5.1 misreads BOM-less non-ASCII).
  - `.sh`, `.md`, `.json`: LF. `.ps1`: CRLF. This repo's `.gitattributes` enforces it (create
    it in phase 1 if missing).
  - Paths in all deliverables use `/`.
- **Scope.** Build only what the spec describes. Ideas for improvements go to
  "Proposals" in `status.md`, not into the code.

## Layout

```
CLAUDE.md                 this file
status.md                 build cursor (phases, open questions, proposals)
spec/SPEC.md              design (owner-maintained)
spec/PLATFORM-NOTES.md    platform facts, sources, VERIFY items
src/                      deliverable sources (see SPEC section 4)
tests/                    automated hook tests, probe kit, manual test plan
tools/                    build and validation scripts
dist/                     built zip (not committed)
```
