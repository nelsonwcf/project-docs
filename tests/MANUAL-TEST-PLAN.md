(**Developer: Reload Window** in each one, including windows opened after the install).

Version 0.3.0 of the project-docs skills. Run this by hand in VS Code with GitHub Copilot. The
automated tests (`tests/hooks/`, `tools/build.sh`) already cover the hook scripts, the installers and the
package; this plan covers what only a real Copilot session can show.

Work through the tests in order: later tests use the repositories created by earlier ones. Tick
the result box and write notes in the sheet at the end. Never run this plan in a real project:
use the scratch repositories it creates.

## Smoke run (first pass)

Run these eight tests first, in this order. If they all pass the package works end to end on one
machine; do the rest of the plan afterwards. A failure here: stop and send the result, the later tests assume these pass.

| Order | Test | What it proves |
|---|---|---|
| 1 | T01 | Install on native Windows; both skills are listed |
| 2 | T03 | The slash commands exist and are never started by the agent on its own |
| 3 | T04 | `/project-docs` enables a new repository (plan, stop, create, verify) |
| 4 | T06 | The session-start hook injects the date and the latest log entry |
| 5 | T08 | An unlogged edit is blocked once and then logged |
| 6 | T09 | A read-only turn is left alone |
| 7 | T21 | `/project-docs-regenerate` builds a valid AI handout |
| 8 | T24 | A fresh LLM chat can follow that handout |

After any new package version, also run T17b (upgrade of an already enabled repository): it is the check that a weak model starts the skill instead of continuing earlier work.

T04, T06, T08 and T09 use the repository created in T04. T21 needs a repository with eight or
more log entries (section F, "Build the fixture"); the smoke run may use the fixture only for
T21 and T24. On WSL use T02 instead of T01.

## Before you start

1. Build the package (Git Bash, WSL or Linux): `bash tools/build.sh`. The zip is
   `dist/project-docs-skills-0.3.0.zip`.
2. Note the environment in the result sheet: VS Code version, Copilot Chat extension version,
   Windows version, WSL distribution, the models you can pick.
3. Create a scratch folder for the test repositories:
   - PowerShell: `mkdir $HOME\pd-tests; cd $HOME\pd-tests`
   - bash (WSL, Linux filesystem): `mkdir -p ~/pd-tests && cd ~/pd-tests`
4. In every chat use **Session Target: Copilot**, and trust the workspace unless the test says otherwise.

How to read a test: **Do** = what you do. **Expect** = what must happen. **Settles** = the open
platform item in `spec/PLATFORM-NOTES.md` that the result answers.

---

## A. Install

### T01 - Install on native Windows

**Do:** unzip the package; in the unzipped folder run
`powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1`. Reload **every** open VS Code window
(**Developer: Reload Window** in each one, including windows opened after the install).
**Expect:** the installer prints `Installed project-docs skills 0.3.0` and the two folders under
`%USERPROFILE%\.copilot\skills`. In **Chat: Open Customizations > Skills** both
`project-docs` and `project-docs-regenerate` are listed.

### T02 - Install in WSL

**Do:** connect VS Code to WSL; in a WSL terminal in the unzipped folder run `bash install.sh`. Reload the window.
**Expect:** the same output for `~/.copilot/skills`, plus the WSL note about `install.ps1`. Both skills are listed in a WSL-connected window.

### T03 - Slash commands and no auto-invocation

**Do:** in a chat type `/` and look at the list. Select `/project-docs`: note the argument hint.
Then, in a new chat in any repository, ask: `Please set up project documentation for this repository.`
**Expect:** both commands appear; the hint of `/project-docs` is `[status | disable | disable purge]`
and of the other `[ai | human | both] [full]`. In the second part the agent does **not** load
the skill by itself (`disable-model-invocation`).

---

## B. New repository

### T04 - Enable on an empty repository

**Do:** create an empty repo and open it in VS Code:
- PowerShell: `mkdir $HOME\pd-tests\new1; cd $HOME\pd-tests\new1; git init`
- bash: `mkdir ~/pd-tests/new1 && cd ~/pd-tests/new1 && git init`

In a chat run `/project-docs`.
**Expect:**
1. The agent reads files under the skill's `assets/` folder and later copies them (settles **V6** for this OS; repeat on the other OS in T05b).
2. It stops with a plan report: mode **new**, baseline `none (no commits yet)`, the file list, the `.gitattributes` change. It writes nothing until you answer.
3. After you confirm ("go"), it creates `docs/project-docs/` (4 files), the rules file, the hook config and three hook files, and `.gitattributes`.
4. The final report is at most 10 lines, says nothing was committed, and explains how to confirm the hooks.
5. Checks (run them yourself):
   - `git status --short` shows the new files, `git log` is still empty.
   - `head -n 1 docs/project-docs/log.md` is `<!-- project-docs: v1 -->`.
   - `L0001` is the top entry, `project-docs enabled`, with `Baseline:` and `Next:`.
   - `git hash-object --no-filters <skill>/assets/hooks/project-docs/hook.ps1 .github/hooks/project-docs/hook.ps1` prints two identical hashes (`<skill>` is `~/.copilot/skills/project-docs`).
   - `git ls-files --eol` (after `git add -A`) shows `.ps1` as `w/crlf` and `.sh` as `w/lf`.
   - No BOM: the first bytes of `docs/project-docs/log.md` are not `EF BB BF` (PowerShell: `Format-Hex -Path docs/project-docs/log.md -Count 3`; bash: `head -c3 docs/project-docs/log.md | od -An -tx1`). A small model once wrote a BOM through a terminal command.
   - `.gitattributes` contains the block including the line `.github/hooks/project-docs/VERSION text eol=lf`, and `git ls-files --eol` shows that VERSION file as `w/lf` even with `core.autocrlf=true`.

### T05 - Status, and running the command again

**Do:** run `/project-docs status`, then `/project-docs` again.
**Expect:** status shows enabled-healthy, a component checklist with versions, entry counts
(log 1, decisions 0, facts 0), the top entry title and `Next:`. The second command says it is
already enabled and prints the status. Nothing changes (`git status` identical).

### T05b - Same on the other OS

**Do:** repeat T04 in a repository on the other environment (native Windows <-> WSL).
**Expect:** the same results. Record whether the skill's assets were readable (**V6**).

---

## C. Hooks and rules (use the `new1` repository)

### T06 - Session-start context

**Do:** commit the setup (`git add -A; git commit -m setup`) so the tree is clean. Open a **new** chat and send: `What is today's date according to your session context, and what is the most recent entry in the project log? Answer without opening any file or running any command.`
**Expect:** the agent answers from context: today's date (it matches your computer's date) and
L0001 with its `Next:`, because the session-start hook added a line `Today is YYYY-MM-DD.`, a sentence saying the entry is background only, not a task, and then the entry. In **Chat: Open Customizations > Hooks** the three project-docs hooks are listed.
**Also check:** `.git/project-docs/snapshots/` exists after the first prompt.
**Settles:** hooks run in the Copilot harness for this repository.

### T07 - Rules are attached and followed (V10)

**Do:** in a new chat send: `Create hello.txt containing "hello" and tell me what you did.`
**Expect:**
1. In the response **References** the file `project-docs.instructions.md` is listed (**V10**).
2. The agent adds a log entry `L0002` directly below `<!-- entries: newest first -->` with `Did:`, `Changed:` (`hello.txt`) and `Next:`; the L0001 entry is untouched.
3. The reply ends with exactly one line `[project-docs: L0002]`.
4. The entry date is today's date and the agent ran **no** date command (no terminal approval was requested for it); the date came from the `Today is ...` context line.
5. The entry's `Changed:` does not list any file under `docs/project-docs/`; `Next:` is a real next action or `Await user direction.`, never a filler such as `Finish.`.
6. When a later request removes or replaces something an earlier entry added, the new entry has `Supersedes:` naming that entry. The marker lists log IDs only, never decision IDs.

### T08 - Forced log on an unlogged edit

**Do:** new chat: `Append the line "second" to hello.txt. Do not write any log entry; I will do it later.`
**Expect:**
1. When the agent finishes, a message starting with `project-docs: files changed this turn (hello.txt) but docs/project-docs/log.md was not updated...` appears in the chat as a user message.
2. The agent then writes entry L0003 and finishes; there is no second block.
3. `.git/project-docs/snapshots/<session>.txt` has an older modified time than the log entry (the forced message did not overwrite it).
4. The reply marker is `[project-docs: L0003]`.
**Settles:** the block works with a real model, and the loop ends.

### T09 - No false alarm

**Do:** new chat: `Explain what hello.txt contains. Do not change anything.`
**Expect:** no log entry, no block message, reply ends with `[project-docs: —]`.

### T10 - Model switch keeps the rules

**Do:** in one chat make a change with model A (for example a Claude model): `Create b.txt with "b".` Switch the model in the picker to a different family (for example an OpenAI model), then send `Create c.txt with "c".` Switch to **Auto** and send `Create d.txt with "d".`
**Expect:** three consecutive entries with IDs in sequence (no gaps, no duplicates), each with
the correct `Changed:` file and a reply marker. If any model skips the log, the hook message must make it write the entry. Record the models used.

### T11 - Decisions and knowledge

**Do:** new chat: `We need to choose between JSON and YAML for settings. Decide on JSON, explain why, and record it.` Then: `Change your mind: use YAML instead, and record that.`
**Expect:** a decision entry `D0001` (Status active, Decision, Why, Rejected, Log) and a log entry naming it in `Decision:`. After the second request a new `D0002` is added and **only** the `Status:` line of `D0001` changes (to `superseded by D0002`). Check with `git diff docs/project-docs/decisions.md`.
Then ask `What command runs the tests in this repository?` in a repo that has a test command, or tell the agent a non-obvious fact about the code, and check that a knowledge line with `Source:` and `Checked:` appears in the right section.

### T12 - Workspace trust (V9)

**Do:** copy the `new1` folder to `new1-untrusted`. Open it in a new window and choose **Restricted Mode** / do not trust. Send a prompt that edits a file.
**Expect:** note whether the hooks ran: look for `.git/project-docs/snapshots/` and whether the block message appears. Write the result down; the documented default is "trust required".
**Settles:** **V9**.

### T13 - Repository under /mnt/c in WSL (Q6)

**Do:** in WSL, copy `new1` to `/mnt/c/Users/<you>/pd-tests/new1-mntc` and repeat T07.
**Expect:** it works. Note how long the turn feels longer than in T07. The enable report should mention keeping repositories on the Linux filesystem. Hook runs longer than 10 s would show as a missing hook effect: record it.

---

## D. Existing repositories and migration

### T14 - Existing repository, no legacy files

**Do:** clone a small public repository with a build file and a README (any project with a `package.json`, `pyproject.toml` or `Makefile`):
`git clone <url> $HOME/pd-tests/existing1` (PowerShell) or `~/pd-tests/existing1` (bash). Open it and run `/project-docs`.
**Expect:** the plan report says mode **existing**, gives the baseline SHA and branch, asks for the history choice (`none` default) and explains the consequence for the AI handout. Answer `none`, confirm.
Then check `knowledge.md`: every fact has `Source:` with a real path, `Checked:` today, nothing is invented (spot-check five facts against the files). The top log entry is `project-docs enabled` with `Baseline:`. User files are untouched (`git status` shows only the new files).
**Repeat** in a second clone with the history choice `summary`: reconstructed entries have `Origin: reconstructed`, increasing IDs from the oldest period, and no invented `Ran:` commands.

### T15 - Legacy memory-model files (settles Q11)

**Do:** make a repository containing files from the older memory skills. Best: use a real repository
that has `status.md`, `log.md`, `reference.md` (with `<!-- memory-model: v1 -->`) and optionally `notes/` and `roadmap.md`. If you have none, build the sample in the appendix. Commit them, then run `/project-docs`.
**Expect:**
1. The plan lists each legacy file with its target (legacy log entries -> migrated entries, locked decisions -> `decisions.md`, facts -> `knowledge.md`, status -> `Next:`), what stays, and which files are proposed for deletion (only the memory-model files, each by path).
2. `README.md`, `CHANGELOG.md`, ADRs and instruction files are never in the deletion list.
3. Nothing is deleted until you confirm; after you do, only the confirmed paths are gone.
4. Migrated entries have `Origin: migrated`, original dates, IDs from L0001 oldest-first; the `project-docs enabled` entry has the highest ID.
**Send back:** a copy (or a description) of the real legacy files so `migration.md` can match their true format.

### T16 - Conflicting instruction file

**Do:** in a repo, add `AGENTS.md` containing `Never end replies with an extra status line.` and `Do not create files under docs/.` Run `/project-docs`.
**Expect:** the plan quotes both lines as conflicts and asks how to proceed; `AGENTS.md` is not modified (`git diff AGENTS.md` empty).

---

## E. Repair and disable

### T17 - Repair

**Do:** in `new1` delete `.github/hooks/project-docs/hook.sh`, and change the text in `.github/hooks/project-docs/VERSION` to `0.0.1`. Also add a blank line to the rules file. Run `/project-docs status`, then `/project-docs`.
**Expect:** status reports enabled-needs-repair and lists the missing script, the outdated VERSION and the rules difference. `/project-docs` shows the rules-file difference and **asks** before replacing it; answer `no` first, then run again and answer `yes`. The hook files are restored with matching hashes, a `project-docs repaired` entry is added at the top (its `Next:` copied from the previous top entry), and the content of the earlier entries is unchanged.

### T17b - Upgrade a repository enabled with the previous package (failed once on 2026-11-04)

**Do:** take a repository enabled with the previous package version (for example `new1` from the smoke run, which holds the 0.1.0 hooks). Install the new package (T01), reload every open window, open a **new** chat, and run `/project-docs` with no argument. Use a weak model: leave the picker on **Auto** if you cannot choose, and try the cheapest model if you can.
**Expect:**
1. The agent's first action is Step 0 item 1 (`git rev-parse --show-toplevel`). It does **not** re-verify, summarize or continue the previous task, even though the session context shows the latest log entry (the context text says it is background only).
2. It reports enabled-needs-repair, lists what is outdated (hook files, VERSION, `.gitattributes` block, rules file), shows the rules-file difference and asks before replacing it.
3. After you answer, the files are restored, the hash checks match, and a `project-docs repaired` entry is on top.
**Record:** the model that ran (Auto may pick a different one each time) and, on failure, the first three tool calls the agent made.

### T17c - Damaged marker

**Do:** in a scratch enabled repository put a BOM in front of line 1 of `docs/project-docs/log.md` (PowerShell: `[IO.File]::WriteAllBytes($p, [byte[]](0xEF,0xBB,0xBF) + [IO.File]::ReadAllBytes($p))` with `$p` the full path; bash: `printf '\xef\xbb\xbf' | cat - docs/project-docs/log.md > t && mv t docs/project-docs/log.md`). Open a new chat: the session-start context must be missing (the hooks treat the repository as not enabled). Run `/project-docs status`.
**Expect:** the agent says the marker is damaged and that the hooks ignore the repository, offers to remove only the BOM/CR bytes, and waits. After a yes it fixes only those bytes (`git diff` shows only line 1 changed), then continues with state detection. After a no it stops and changes nothing. Repeat with a CR at the end of line 1.

### T18 - Disable (docs kept) and re-enable

**Do:** put an extra line `*.tmp -text` in `.gitattributes` above the managed block (keep a copy). Run `/project-docs disable`.
**Expect:** a list of what will be removed; nothing happens until you confirm. After confirming: a `project-docs disabled` entry is added first; then the rules file, hook config, hook folder, the managed `.gitattributes` block and `.git/project-docs/` are gone. Your extra `.gitattributes` line is untouched. `docs/project-docs/` remains and `log.md` still starts with the marker. `.github/hooks/` and `.github/instructions/` are removed only if empty.
Then run `/project-docs`: it takes the **repair** path (marker present, components missing), restores everything and logs `project-docs repaired`.

### T19 - Disable purge

**Do:** run `/project-docs disable purge`. At the second question answer `no`.
**Expect:** nothing is removed. Run it again and answer `yes` to both: `docs/project-docs/` is gone as well, no log entry is written, and `.gitattributes` keeps your extra line.

---

## F. Handouts (use a repository with at least eight log entries)

Build the fixture in a fresh enabled repository (for example `app1`) by asking the agent to:
(1) create a small program (a script with a README) and install or configure one dependency;
(2) change a file; (3) try an approach, then abandon it (`Status: abandoned`); (4) replace one earlier
step with a better one (an entry with `Supersedes:`); (5) record one decision. Include one value
that is a secret (the agent must write `<SECRET: name>`).

### T20 - Not enabled

**Do:** in a repository without project-docs run `/project-docs-regenerate`.
**Expect:** it says project-docs is not enabled, suggests `/project-docs`, and writes nothing.

### T21 - AI handout (default) and full

**Do:** in `app1` run `/project-docs-regenerate`.
**Expect:**
1. `docs/project-docs/walkthrough.ai.md` exists; line 1 is `<!-- project-docs-regenerate: v1 | audience: ai | through: L00NN | generated: <today> | mode: full -->` with `through` equal to the top log ID.
2. The guide instructions (ten numbered points, eleven when there is a step S00), Outcome, Environment, Steps, Final check are present in that order.
3. No step for the abandoned entry or the superseded one; no step for the `project-docs enabled` entry.
   Step `S00 — Create the project folder` (run `git init`, Verify `git rev-parse --is-inside-work-tree` -> `true`) is the first step of a handout for a new repository, and every later step that uses git lists `S00` in `Requires:`. If a model forgot `Supersedes:` for a removed feature, the reconcile step still drops that entry and the report lists a discrepancy.
4. Each step has `<!-- src: -->`, Goal, Requires, Action, Verify with Expected; authored files are embedded as they must be at that step (a file touched by several steps follows the "File versions" rule, and the last embedded version of each file equals the file in the repository), with no abbreviation or `...` placeholder inside a file; the secret appears only as `<SECRET: name>`.
5. No link to a repository file or to other documents.
6. The report is at most 12 lines and ends with `[project-docs: —]`; no log entry was added; nothing committed.
7. Run again with `full`: same result, `mode: full`.

### T22 - Discrepancy detection

**Do:** edit one logged file by hand without logging it, and create one unlogged file. Run `/project-docs-regenerate full`.
**Expect:** the handout embeds the **current** content of the edited file; the report lists the unlogged file as a discrepancy and the handout carries `> UNRESOLVED: ... (no log entry)` at the end of the Outcome section.

### T23 - Human and both

**Do:** `/project-docs-regenerate human`, then `/project-docs-regenerate both`.
**Expect:** `walkthrough.md` has header `audience: human`; the same step IDs in the same order as the AI handout; files referenced by path (not embedded); decision rationale in full; contents list and a troubleshooting section. If the AI handout was behind the log, it was refreshed first.

### T24 - Follow the AI handout in a fresh chat

**Do:** open a chat with **no access to the repository** (for example a new chat in a different LLM service, or Copilot Chat in an empty window). Attach or paste `walkthrough.ai.md` and write: `Guide me through this.` Follow the first three steps.
**Expect:** the assistant asks for your operating system and shell first; presents one step at a time; checks `Requires`; asks you to run `Verify` and paste the output; does not invent values for `<SECRET: ...>`; says so when it meets an `UNRESOLVED` line. Try one deliberate failure (give a wrong output) and check it uses `If it fails`. Repeat with a second model family if possible.

### T25 - Incremental regeneration

**Do:** note the step IDs in `walkthrough.ai.md`. Ask the agent for two more changes (one new feature, one that supersedes an existing step). Run `/project-docs-regenerate`.
**Expect:** mode `incremental`; `through:` moved to the new top ID; step IDs that still exist keep their numbers; the new step has the next unused number; the superseded step is removed or rewritten; unrelated steps are unchanged (`git diff docs/project-docs/walkthrough.ai.md` shows only the affected parts).

---

## G. Last checks

### T26 - COPILOT_HOME (V7, optional)

**Do:** set `COPILOT_HOME` to an empty scratch folder, copy the two installed skill folders into `<that folder>/skills/`, remove them from `~/.copilot/skills`, restart VS Code, and open **Skills**.
**Expect/Settles:** whether the skills are found at `$COPILOT_HOME/skills`. Restore afterwards.

### T27 - Regression run

**Do:** run `bash tests/hooks/run-tests.sh`, `powershell -NoProfile -ExecutionPolicy Bypass -File tests/hooks/run-tests.ps1`, and `bash tools/build.sh`. If PowerShell 7 is installed, also `pwsh -NoProfile -File tests/hooks/run-tests.ps1 -Shell pwsh`.
**Expect:** all pass.

---

## Result sheet

| Test | Pass / Fail / Skipped | Notes (models used, anything unexpected) |
|---|---|---|
| T01 install Windows | Pass (native Windows, 2026-11-03) | First attempt FAILED: `project-docs` was missing from Skills because its `description` had an unquoted `: ` (invalid YAML), fixed by SPEC 1.3. Passed after the fix and a reload of **every** open window. |
| T02 install WSL | | |
| T03 commands, no auto-invoke | Pass (native Windows, 2026-11-03) | |
| T04 enable new repo | Pass (native Windows, 2026-11-03) | **V6 resolved on Windows**: the agent read the skill assets and copied them; hashes matched. A small model first wrote a document with a terminal command and added a BOM; the git `core.autocrlf=true` setting converts the hook `VERSION` file. Both led to SPEC 1.4 changes. |
| T05 status / re-run | | |
| T05b other OS (V6) | | |
| T06 session-start context | Pass (native Windows, 2026-11-03) | |
| T07 rules attached (V10) | | |
| T08 forced log | Pass (native Windows, 2026-11-03) | Block confirmed in the session record (reported by the user; transcript not in `tests/results/`). |
| T09 no false alarm | Pass (native Windows, 2026-11-03) | Reply ended with the marker on a read-only turn (with T08: **V10 resolved**). |
| T10 model switch | | |
| T11 decisions, knowledge | | |
| T12 workspace trust (V9) | | |
| T13 /mnt/c (Q6) | | |
| T14 existing repo | | |
| T15 legacy files (Q11) | | |
| T16 instruction conflict | | |
| T17 repair | | |
| T17b upgrade from previous package | | |
| T17c damaged marker | | |
| T18 disable / re-enable | | |
| T19 disable purge | | |
| T20 regenerate, not enabled | | |
| T21 AI handout | Pass (native Windows, 2026-11-03) | Output in `tests/results/walkthrough.ai.md`, log in `tests/results/new1-log.md`. Found: no `git init` step and a git step with `Requires: none` (-> SPEC 1.4 `S00`); a model omitted `Supersedes:` and the reconcile step caught it (-> required behaviour). |
| T22 discrepancies | | |
| T23 human, both | | |
| T24 fresh-chat follow-through | Pass (native Windows, 2026-11-03) | |
| T25 incremental | | |
| T26 COPILOT_HOME (V7) | | |
| T27 regression | | |

### Smoke run, 2026-11-03 (native Windows, VS Code, Copilot harness): 8 of 8 passed

Tests run: T01, T03, T04, T06, T08, T09, T21, T24. Settled by this run: **V6** on Windows (not yet in WSL), **V10** (rules attached and followed, including the marker on a read-only turn), and the T08 block in the session record. Files kept in `tests/results/`: `new1-log.md` (the log of the T04 to T09 repository) and `walkthrough.ai.md` (the T21 handout). Findings that changed the package (SPEC 1.3 and 1.4, package 0.2.0): unquoted `description` (T01), BOM from a terminal write and CRLF in the hook `VERSION` file (T04), no `S00`/`git init` and a `Requires: none` on a git step (T21/T24), log entries that listed `docs/project-docs/` files in `Changed:`, used the filler `Next: Finish.`, and omitted `Supersedes:` (T21 log), and windows opened after the install but before a reload not seeing the skill (T01). Still to run: everything else in the plan; after the 0.2.0 install repeat the smoke run.

**What to send back:** the filled sheet; for every failure the chat transcript or screenshot and the
state of `docs/project-docs/` and `.git/project-docs/`; the `events.log`-style facts for V6, V7, V9 and V10; and the legacy files from T15.

## Appendix - sample legacy files for T15 (hand-made)

This sample is **not** taken from the older skills and may differ from their real format. Use it
only if you have no real legacy repository. Create these files in a git repository and commit.

`status.md`:
```
<!-- memory-model: v1 -->
# Status
Current: building the importer.
Next: add retry logic to the importer.
```

`log.md`:
```
<!-- memory-model: v1 -->
# Log
## 2026-10-01 - Project created
Created the repository and a README.
## 2026-10-03 - Importer skeleton
Added src/importer.py reading CSV files. Ran: pip install pandas==2.2.2
```

`reference.md`:
```
<!-- memory-model: v1 -->
# Reference
## Decisions
- Use pandas for CSV parsing (locked).
## Facts
- Run tests with: pytest -q
```
