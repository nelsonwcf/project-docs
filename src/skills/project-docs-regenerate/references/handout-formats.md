# Handout formats

Used by SKILL.md steps 2, 7 and 8. Two files are produced in `docs/project-docs/`:

- `walkthrough.ai.md`: standalone guide that an LLM follows with a user, from nothing to the
  current state.
- `walkthrough.md`: human-readable version of the same steps. It refers to the repository.

Both contain the reproduction path only: no dead ends, no superseded steps, no history.

## Header (line 1 of both files)

```
<!-- project-docs-regenerate: v1 | audience: ai | through: L0042 | generated: 2026-11-02 | mode: full -->
```

- `audience:` is `ai` or `human`.
- `through:` is the ID of the top (newest) log entry at the time of generation, even when that
  entry was dropped from the steps.
- `generated:` is today's date. `mode:` is `full` or `incremental`.
- The header must be exactly one line, and line 1 of the file.

## walkthrough.ai.md

Sections, in this order, with these headings.

### 1. Title and guide instructions

```
<!-- header line -->
# Guide: <project name> from scratch

## Guide instructions (for the assistant reading this document)
```

Under the second heading, write the following text word for word (it is addressed to the
assistant that receives the document). Replace `<BASELINE NOTE>` with the sentence described
below the text, or delete that line unless step S00 is `S00 — Obtain the baseline`.

```
You are guiding a user through the steps in this document, from nothing to the finished result.
1. Before anything else, ask the user which operating system and shell they use (for example
   Windows PowerShell, Git Bash, macOS zsh, Linux bash, WSL). Use the matching command variant
   from then on.
2. Present one step at a time. Before presenting a step, check its Requires line: every listed
   step must be done and every listed tool or account must be available.
3. Give the Action exactly as written. Change it only when the step fails.
4. After each Action, ask the user to run the Verify check and paste the output. Continue only
   when the output matches Expected. Otherwise use the "If it fails" line of the step.
5. If a failure is not covered, troubleshoot with the user, but do not change the end state the
   document describes. Return to the written step once it works.
6. Keep track of progress by step ID (S01, S02, ...). If the user names a step, resume there
   after checking its Requires line.
7. Text like <SECRET: name> marks a value the user must supply from their own account or
   machine. Never invent one and never ask the user to paste a real secret into the chat.
8. A line starting with "UNRESOLVED" means this document lacks that detail. Tell the user so,
   and ask them for the missing information instead of guessing.
9. File contents in this document are exact. Tell the user to create each file with precisely
   that content.
10. When the user asks why a step is needed, answer from that step's Notes line.
<BASELINE NOTE>
```

`<BASELINE NOTE>` (only with step S00): `11. This document is standalone only from the baseline in step S00. Work done before that commit is not described here.`

### 2. Outcome

`## Outcome`: a short paragraph and a list of what exists at the end (the application or tool,
the main folders, how to run it). Derive it from `knowledge.md` and the current repository.

### 3. Environment and prerequisites

`## Environment and prerequisites`: tools with exact versions (from `Ran:` fields, manifests and
lock files), accounts or services needed, and the operating systems and shells the commands cover.
Do not list a tool no step uses.

### 4. Steps

`## Steps`, then one block per step, in execution order:

```
### S07 — <title>
<!-- src: L0012, L0015 -->
- Goal: <one sentence>
- Requires: S03, S05 | <tool or account>
- Action: <what to do, with the exact commands>
- Files: <path, then the file content for this step in a fenced block; omit the line when none>
- Verify: <command or check>
  Expected: <result>
- If it fails: <symptom> -> <fix>; <symptom> -> <fix>
- Notes: <rationale needed to do the step correctly, from decisions.md; omit when none>
```

Field rules:

- `<!-- src: -->` lists the log IDs the step came from. Keep it exact; incremental updates rely on it.
- `Requires:` names step IDs and tools. S00 has `none`; any step that runs git or assumes the project folder names `S00`.
- `Action:` gives every command exactly as logged (`Ran:`), with where it runs (repo root, user
  machine, a browser console and which one). Put multi-line commands in a fenced block.
- Command variants: the log records a command as it ran, in one shell. Give that command first,
  labelled with its shell when known (for example `PowerShell:`). Add the other shell's variant
  only for plain file and folder operations and for tools that run the same everywhere (`git`,
  `npm`, `pip`, `docker`), and label it `(translated)`. For anything else add
  `Notes: logged in <shell>; translate for other shells`.
- `Files:` embeds the content of every file the step creates or changes, authored files only,
  as the file must be **at that step** (see "File versions" below). Fence rule: use a fence
  longer than any backtick run inside the file (four backticks if the file contains three). Name
  the language after the opening fence when it is obvious.
- File versions. The user needs the content that belongs to the step, not always the final one.
  - A file touched by only one surviving step: embed its current repository content there.
  - A file touched by several surviving steps: check whether git holds the version that matches
    each step. The versions are the commits in the source entries' `Commit:` fields, or the commits
    from `git log --format=%h -- <path>`; read one with `git show <sha>:<path>`.
    - If git holds them, embed that version at each step (full content). For a file longer than
      about 300 lines, embed an exact edit instead: the old lines and the new lines, against the
      previous step's version.
    - If git does not hold the intermediate versions, embed the current content once, at the first
      step that needs the file. In each later step write
      `Files: <path> — already in its final form since S0X` and describe the change in one line.
    - Never embed a version that the log implies but neither git nor the repository holds.
  - The last embedded version of every file must equal its current repository content. Check this
    before finishing.
- Generated files (lock files, build output, `node_modules`, caches) are never embedded: the
  command that produces them is the Action.
- Binary assets (images, fonts, archives): give the name, the size and how to obtain them. Do not embed.
- `Verify:` uses the log's `Verify:` field when present. Otherwise propose a simple check (file
  exists, command prints a version) and mark it `(proposed)`.
- `If it fails:` only symptoms and fixes that are known from the log, decisions, knowledge file or
  the repository. If none are known, write `If it fails: not recorded`.
- Secrets: keep `<SECRET: name>` placeholders exactly. Never write a real value.
- Step `S00` is always present and always the first step (`Requires: none`). Which one:
  - New repository (the enabled entry says `Baseline: none (no commits yet)`):
    `S00 — Create the project folder`. Action = create an empty folder and run `git init` in it;
    Verify = `git rev-parse --is-inside-work-tree`, Expected = `true`.
  - Existing repository without reconstructed history: `S00 — Obtain the baseline`. Action =
    clone the remote and check out the baseline commit; Verify = `git rev-parse --short HEAD`
    equals the baseline. The guide instructions then carry the baseline note (point 11).
  - Existing repository with reconstructed history: `S00 — Create the project folder`, as for a
    new repository; the reconstructed entries rebuild the rest.
  Every later step that runs git or assumes the folder lists `S00` in `Requires:`.

### 5. Final check

`## Final check`: the commands that prove the whole result works (build, run, tests), taken from
the last `Verify:` fields and `knowledge.md`, each with its Expected result.

### Standalone rules

- Do not link to repository files, to other documents, or to `log.md`/`decisions.md`. Say
  everything inside this file.
- Do not mention `project-docs` or this build process, and do not use log entry IDs except in `src` comments and UNRESOLVED lines.

## walkthrough.md (human)

Derived from the finished `walkthrough.ai.md`. Same header form with `audience: human`. Sections:

1. `# <project name>: how it was built` and a short overview (what it is and what you get).
2. `## Prerequisites`: the same tools and versions as the AI handout, in prose or a list.
3. `## Contents`: a list of the steps with their IDs and titles.
4. `## Steps`: one section per step, `### S07 — <title>`, in the same order and with the same IDs as
   the AI handout. In prose: why the step exists, the commands (identical to the AI handout),
   what to check afterwards and what to expect.
5. `## Troubleshooting`: every "If it fails" item, grouped by topic, with the step ID.

Differences from the AI handout:

- Files are **referenced by repository path** (for example `src/api/export.ts`), not embedded.
  Add the commit (`Commit:` field of the source entries, short SHA) where it helps.
- Rationale from `decisions.md` is written out in full (what was decided, why, what was rejected),
  not shortened to a note.
- No guide instructions for an assistant.
- `> UNRESOLVED:` lines are kept.

## Example step (AI handout)

````
### S04 — Add the CSV export endpoint
<!-- src: L0002 -->
- Goal: Serve all orders as CSV at GET /export.csv.
- Requires: S03, Node.js 20
- Action: In the repository root run `npm install csv-stringify@6.5.2`, then create
  `src/api/export.ts` and register it in `src/api/routes.ts`.
- Files: `src/api/export.ts`
  ```ts
  import { Request, Response } from 'express';
  import { stringify } from 'csv-stringify';
  import { listOrders } from '../db/orders';

  export async function exportCsv(_req: Request, res: Response): Promise<void> {
    res.setHeader('Content-Type', 'text/csv');
    const out = stringify({ header: true, columns: ['id', 'date', 'total'] });
    out.pipe(res);
    for (const order of await listOrders()) {
      out.write([order.id, order.date, order.total]);
    }
    out.end();
  }
  ```
  `src/api/routes.ts`
  ```ts
  import { Router } from 'express';
  import { exportCsv } from './export';

  export const routes = Router();

  routes.get('/export.csv', exportCsv);
  ```
- Verify: `curl -s localhost:3000/export.csv | head -1`
  Expected: `id,date,total`
- If it fails: connection refused -> start the server first (see S03)
- Notes: CSV is generated with csv-stringify, streaming, because it handles quoting correctly and
  streams large results. A manual string join was rejected: it breaks on commas in fields.
````
