# Build status

Current phase: **SPEC 1.5 applied, package 0.3.0 (2026-11-04) — next: reinstall from the 0.3.0 zip and repeat the upgrade test (T17b) with Auto, then the smoke run**
Spec version: 1.5 (2026-11-04)

## Phases

Each phase ends with a review stop. Tick items as they are completed.

### P0 — Platform verification and probe kit
- [x] Re-check every `VERIFY` item in `spec/PLATFORM-NOTES.md` against official docs; record results. (Docs resolve V1,V3,V4,V5,V7,V9 only partly; V2,V8 silent; V6,V10 manual.)
- [x] Build `tests/probe/` (SPEC 13.1) for the items docs cannot answer.
- [x] Write `tests/probe/README.md`: how the user runs the probe in a scratch repo on native Windows and in WSL, and what to send back.
- [x] Stop. The user ran the probe (Windows + WSL, 2026-11-02); results recorded in `spec/PLATFORM-NOTES.md` (V1-V5 resolved; V6-V10 open).

### P1 — Shared formats, templates, rules file
- [x] `.gitattributes` for this repo.
- [x] `src/shared/formats.md` (SPEC 6).
- [x] `src/skills/project-docs/assets/docs/` templates: `README.md`, `log.md`, `decisions.md`, `knowledge.md`.
- [x] `src/skills/project-docs/assets/rules/project-docs.instructions.md` (SPEC 7).
- [x] Stop for review (2026-11-02).

### P2 — Hooks and automated tests
- [x] `src/skills/project-docs/assets/hooks/project-docs.json` (SPEC 8.1).
- [x] `hook.sh`, `hook.ps1`, `VERSION` (SPEC 8.2–8.6).
- [x] `tests/hooks/` runners and cases (SPEC 13.2); all pass in Git Bash, Windows PowerShell 5.1 and WSL Debian bash. pwsh 7 is not installed on this machine, so it is untested.
- [x] Measure and record per-event timings in this file.
- [x] Stop for review (2026-11-02).

### P3 — Skill: project-docs
- [x] `src/skills/project-docs/SKILL.md` (SPEC 9), 248 lines.
- [x] `src/skills/project-docs/references/` files referenced by SKILL.md (`migration.md`; `formats.md` is a build output, P5).
- [x] Stop for review (2026-11-02).

### P4 — Skill: project-docs-regenerate
- [x] `src/skills/project-docs-regenerate/SKILL.md` (SPEC 10).
- [x] `src/skills/project-docs-regenerate/references/handout-formats.md` (SPEC 11).
- [x] Stop for review (2026-11-02).

### P5 — Package
- [x] `src/package/INSTALL.md`, `install.sh`, `install.ps1` (SPEC 12).
- [x] `tools/build.sh` with validation (SPEC 12.4); produces `dist/project-docs-skills-<version>.zip`.
- [x] Stop for review (2026-11-02).

### P6 — Manual test plan
- [x] `tests/MANUAL-TEST-PLAN.md` (SPEC 13.3).
- [x] Stop for review (2026-11-02).

## Files produced

**P0**
- `tests/probe/.github/hooks/probe.json` — 3 events; PowerShell registered nested + direct.
- `tests/probe/.github/hooks/probe/probe.sh` — bash probe (smoke-tested in Git Bash).
- `tests/probe/.github/hooks/probe/probe.ps1` — ASCII, CRLF (smoke-tested in Windows PowerShell 5.1).
- `tests/probe/README.md` — run instructions and what to send back.
- `spec/PLATFORM-NOTES.md` — "Resolution log (P0)": V1-V5 resolved from probe; V6-V10 open.
- `tests/probe/results-windows.log`, `tests/probe/results-wsl.log` — probe output supplied by the user (input, not built).

**P1**
- `.gitattributes` — `*.sh`/`*.md`/`*.json`/`VERSION` LF, `*.ps1` CRLF.
- `src/shared/formats.md` — canonical formats (SPEC 6), imperative wording.
- `src/skills/project-docs/assets/docs/{README,log,decisions,knowledge}.md` — templates; log/decisions/knowledge checked against the code blocks in formats.md (identical).
- `src/skills/project-docs/assets/rules/project-docs.instructions.md` — rules file (SPEC 7); body 70 lines or fewer.

**P2**
- `src/skills/project-docs/assets/hooks/project-docs.json` — SPEC 8.1 config (3 events, bash + nested powershell, `timeoutSec` 10).
- `src/skills/project-docs/assets/hooks/project-docs/hook.sh` — bash hook (SPEC 8.2-8.6), LF.
- `src/skills/project-docs/assets/hooks/project-docs/hook.ps1` — PowerShell hook, ASCII, CRLF. Git is run through `System.Diagnostics.Process` to keep `-z` output and UTF-8 paths intact.
- `src/skills/project-docs/assets/hooks/project-docs/VERSION` — `0.1.0`.
- `tests/hooks/run-tests.sh`, `tests/hooks/run-tests.ps1` — the 18 SPEC cases plus 2 extra (19: JSON-escaped Windows cwd; 20: SPEC 8.4 `project-docs:` prompt). `--timing` / `-Timing` builds a 10,003-file repo and reports medians.
- Results 2026-11-02: 20/20 pass in Git Bash (git 2.55), Windows PowerShell 5.1, WSL Debian bash (git 2.47; repos on Linux fs and under `/mnt/c`). Case 19 is skipped (reported as pass) on Linux. `pwsh` 7 not installed here: untested.
- Cross-check: on a repo with spaces, non-ASCII names, rename, delete, untracked and docs changes, `hook.sh` and `hook.ps1` wrote byte-identical snapshots.
- Mutation check: breaking the 7-day cleanup in `hook.sh` made case 17 fail, as it should.

**P3**
- `src/skills/project-docs/SKILL.md` — SPEC 9 (Step 0, Enable E1-E12, Repair, Status, Disable, copy/verify, `.gitattributes` block), 248 of 250 lines. Frontmatter is exactly SPEC 9.1.
- `src/skills/project-docs/references/migration.md` — inventory, mapping, history reconstruction, knowledge seed, conflicts, deletion rules.
- `src/skills/project-docs/VERSION` — `0.1.0` (SKILL.md's health check compares the hook VERSION with it).
- Checked: LF only, no BOM, no Claude Code tool names, copy + `git hash-object --no-filters` verification and `.gitattributes` block tried in a scratch repo (hashes match, `hook.ps1` resolves to `eol: crlf`).
- Not exercised: the skill itself has not been run in Copilot (needs the P5 build for `references/formats.md`, then the P6 manual plan; V6 and V10 still open).

**P4**
- `src/skills/project-docs-regenerate/SKILL.md` — SPEC 10 (arguments, enabled check, mode, read, survivor set, reconcile, order/group, write AI handout, derive human handout, missing information, report), 136 lines. Frontmatter is byte-identical to SPEC 10.1.
- `src/skills/project-docs-regenerate/references/handout-formats.md` — SPEC 11: header, the verbatim guide-instructions text for the AI handout, section and step formats, embedding rules, human handout, one worked step.
- `src/skills/project-docs-regenerate/VERSION` — `0.1.0`.
- Checked: LF only, no BOM, no Claude Code tool names, step heading uses the em dash as in SPEC 11.1.
- Not exercised: the skill has never been run on a real log (needs the P5 build for `references/formats.md`, then the P6 manual plan).

**P5**
- `src/package/INSTALL.md` — SPEC 12.3: unzip, install per environment (Windows, WSL, both), verify, update, uninstall, troubleshooting (not listed, hooks not firing, WSL vs Windows home), the "keep repos on the Linux filesystem in WSL" advice (Q6), and the `COPILOT_HOME` note.
- `src/package/install.sh`, `src/package/install.ps1` — SPEC 12.2: copy to a temp sibling and swap, validate (SKILL.md present, `name` = folder, both VERSIONs = package VERSION), `--uninstall`/`-Uninstall`, WSL / Windows cross-notes, reload hint. `install.ps1` is ASCII + CRLF.
- `tools/build.sh` — SPEC 12.4: copies `src/shared/formats.md` into both skills' `references/` (inside `src/`), validates, stages into `dist/stage/`, zips, lists. Validation: version match (3 VERSION files + 2 hook header comments), frontmatter fields (F1 list only), name regex and = folder, description <= 1024, `disable-model-invocation: true`, SKILL.md <= 250 lines, required files present, no BOM, valid UTF-8, `.sh/.md/.json/VERSION` LF, `.ps1` CRLF + ASCII, JSON parses.
- `.gitignore` — `dist/`.
- `dist/project-docs-skills-0.1.0.zip` — 21 files, built here (not committed).
- Tested: clean build (Git Bash and WSL Debian); 9 deliberate breakages each fail the build with a clear message (extra field, name mismatch, version mismatch, CR in `.sh`, LF in `.ps1`, non-ASCII in `.ps1`, invalid JSON, hook header version, description > 1024); the zip has `/` entry names and expands correctly with PowerShell 5.1 `Expand-Archive` and `unzip`; `install.sh` (Git Bash, WSL) and `install.ps1` (5.1) install, replace (stale file removed, no leftovers), reject a package with a wrong skill name, and uninstall; all with `HOME`/`USERPROFILE` redirected to temp folders, never the real `.copilot`.
- Not tested: the `zip`-command branch of `build.sh` (no `zip` on this machine or in the WSL distro; only the PowerShell fallback ran), PowerShell 7, macOS.

**P6**
- `tests/MANUAL-TEST-PLAN.md` — SPEC 13.3: 28 tests (T01-T27 plus T05b) in sections A-G: install on Windows and WSL; skills listed and not auto-invoked; `/project-docs` on a new repo, an existing repo (history `none` and `summary`), a legacy memory-model repo and a conflicting-instructions repo; status; hooks (session-start context, rules attached, forced log on an unlogged edit, no false alarm, model switch, decisions and knowledge); repair; disable, re-enable and purge; `/project-docs-regenerate` ai, human, both, full, discrepancy detection; following the AI handout in a fresh LLM chat; incremental regeneration after two new entries. Each test names the open PLATFORM-NOTES item it settles (V6, V7, V9, V10, Q6, Q11). Ends with a result sheet and a list of what to send back, plus a hand-made legacy sample (flagged as not the real format).
- Not run: this plan is for the user to execute; nothing in it has been run by me.

**SPEC 1.2 changes (2026-11-03)**
- SPEC 8.6: `hook.sh` and `hook.ps1` session-start text now starts with `Today is YYYY-MM-DD.` (local date: bash `printf '%(%F)T'`, PowerShell `Get-Date` with the invariant culture), then the unchanged sentence, then the entry. The date is also present when the log has no entries.
- SPEC 7 item 6a: the rules file step 2.4 now says to use the `Today is YYYY-MM-DD.` session-context line and to run `date +%F` / `Get-Date -Format yyyy-MM-dd` only if the line is absent. Body is still 70 lines (folded the "do not log reads..." sentence into the section 1 lead-in).
- SPEC 11.1 in `src/skills/project-docs-regenerate/references/handout-formats.md`: (a) new "File versions" rule replaces the old "current content" / "full new content again" pair (single-step file: current content; several steps: per-step git version via `Commit:`/`git log`/`git show`, else current content once and `Files: <path> — already in its final form since S0X`; never an unheld version; last embedded version equals the repository file); (b) guide-instruction point 10 "answer from that step's Notes" (the baseline note is now point 11); (c) the example step embeds two complete files, with no placeholder. The regenerate `SKILL.md` step 7 now points to the File versions rule and asks for the final equality check.
- `tests/hooks/run-tests.sh` / `run-tests.ps1`: cases 03 and 04 also assert the exact `Today is <today>. project-docs is enabled in this repository.` start of the context. Both suites rerun: 20/20 (Git Bash, Windows PowerShell 5.1) and 20/20 (WSL Debian).
- `tests/MANUAL-TEST-PLAN.md`: new "Smoke run (first pass)" section at the top (T01, T03, T04, T06, T08, T09, T21, T24, in that order); T06 now asks for the date from context; T07 expects a date taken from the context line and no date command; T21 expects ten guide points (eleven with S00) and the file-version behaviour.
- Rebuilt `dist/project-docs-skills-0.1.0.zip` (21 files); checked that it contains the new hook text, rules line and File versions rule.

**SPEC 1.3 changes (2026-11-03)** — smoke run T01 failed: `project-docs` was missing from Skills.
- Cause (from the owner): the SKILL.md `description` contained `: ` unquoted, which is invalid YAML, so Copilot dropped the skill silently. `project-docs-regenerate` loaded because its description has no `: `. My earlier `tools/build.sh` did not catch it: it read the line with `sed` and never parsed YAML.
- Fix: `description` is now double-quoted in both `src/skills/project-docs/SKILL.md` and `src/skills/project-docs-regenerate/SKILL.md`. The text is unchanged; both frontmatter blocks are byte-identical to SPEC 9.1 and 10.1 (checked with `diff`). Neither text contains `"` or `\`, so no escaping was needed.
- `tools/build.sh`: `description` and `argument-hint` must each be one double-quoted YAML string with no unescaped `"` inside (an escaped `\"` is allowed). The length check (<= 1024) now counts the text without the surrounding quotes (459 and 382 characters, as before).
- Proof, run in a scratch copy of the tree: (1) the original unquoted description -> build fails; (2) an unescaped `"` inside -> fails; (3) an unquoted `argument-hint` -> fails; (4) a single-quoted description -> fails; (5) an escaped `\"` -> passes; the unmodified tree -> passes (rc 0).
- Rebuilt `dist/project-docs-skills-0.1.0.zip` (21 files); the zipped SKILL.md files carry the quoted descriptions.
- Was not covered by the SPEC 1.3 check (it only names the skills): the rules file's frontmatter (`name`, `description`, `applyTo: "**"`). It is valid YAML today (no `: ` in the description, `applyTo` quoted), but the build would not catch a future mistake there. Proposal below. This is now covered, see the follow-up below.
- Follow-up (user: "Add check", 2026-11-03): `tools/build.sh` now also validates the frontmatter of the rules file (`validate_rules_frontmatter`): it must start with `---` and be closed by `---`, contain `name`, `description` and `applyTo`, and every value must be valid YAML, meaning a double-quoted string without an unescaped `"`, or a plain value that is non-empty, does not start with a YAML indicator (`* & ! | > % @ backtick [ ] { } , # ? : '`) and contains neither `: ` nor ` #`. Unlike the skills, quoting is not demanded: SPEC 7 shows the rules-file `description` unquoted and it is valid; I did not change the rules file.
- While proving it I found and fixed two defects in my own check code: (1) the "frontmatter not closed" test never fired, because the exit status of `awk | tr` inside `$(...)` is that of `tr` (now `set -o pipefail`; this also repairs the same silent gap for SKILL.md); (2) the first indicator test used a bracket expression with `\]` that never matched. Proof in a scratch copy, nine cases: description with `: ` fails; `applyTo: **` fails; description starting with `[` fails; unescaped `"` fails; missing `applyTo` fails; rules frontmatter unclosed fails; SKILL.md frontmatter unclosed fails; a double-quoted description passes; the clean tree passes. The two SPEC 1.3 SKILL.md cases (unquoted description, unquoted argument-hint) still fail the build.
- Rebuilt `dist/project-docs-skills-0.1.0.zip` (21 files, contents unchanged by this step).

**Smoke run results and SPEC 1.4 (2026-11-03)**
- Smoke run on native Windows: 8/8 passed (T01, T03, T04, T06, T08, T09, T21, T24), after the SPEC 1.3 fix for T01. Files: `tests/results/new1-log.md`, `tests/results/walkthrough.ai.md`.
- Recorded in `tests/MANUAL-TEST-PLAN.md`: the eight result-sheet rows (Pass, native Windows, 2026-11-03, with notes), a "Smoke run, 2026-11-03" findings paragraph under the sheet, and test text updated for 1.4 (T01 reload every window; T04 no-BOM check and the `VERSION` line in the `.gitattributes` block; T07 `Changed:`/`Next:`/`Supersedes:`/marker rules; T21 `S00` and implicit supersession). Header and zip name now 0.2.0.
- Recorded in `spec/PLATFORM-NOTES.md`: V6 resolved on native Windows (WSL still open), V10 resolved (Windows), a V1 addition (block confirmed with a real model; the session record is the user's, not stored here), and new facts F10 (SKILL.md frontmatter must be valid YAML), F11 (PowerShell 5.1 terminal writes add a BOM), F12 (`core.autocrlf` converts the hook VERSION file), F13 (reload every open window). Status line updated.
- SPEC 1.4 implemented:
  - 7 rules file: `Supersedes:` required when a step changes, replaces or removes something an earlier entry added (with the `-Shout` example); `Changed:` never lists `docs/project-docs/`; `Next:` falls back to `Next: Await user direction.`, never a filler such as `Finish.`; the marker lists log IDs only. Body is still 70 lines (target 70).
  - 9.2 + 9.6 + 9.3 in `src/skills/project-docs/SKILL.md`: VERSION comparison ignores surrounding whitespace and line endings; the `.gitattributes` block gains `.github/hooks/project-docs/VERSION text eol=lf`; a writing rule says to create and change `docs/project-docs/` files with the file-editing feature, never with `Set-Content`, `Out-File`, `>` or here-strings. The file is exactly 250 lines (limit 250): I merged the E2 items 6/7 and shortened some Terms text to make room.
  - 10.2 step 4 in the regenerate `SKILL.md`: implicit supersession (what a surviving entry added no longer exists in the repository) is required behaviour and is recorded as a discrepancy.
  - 11.1 in the regenerate `SKILL.md` step 6 and `handout-formats.md`: `S00` is always present and first; `Create the project folder` (with `git init`, Verify `git rev-parse --is-inside-work-tree` -> `true`) for new repositories and for existing ones with reconstructed history, `Obtain the baseline` otherwise; later git steps list `S00` in `Requires:`; the baseline note (guide point 11) is only used with `Obtain the baseline`.
  - 12.3 `src/package/INSTALL.md`: reload every open window after installing, including windows opened after the install but before a reload.
- Version bump 0.1.0 -> 0.2.0 (user instruction: the rules file and the `.gitattributes` block changed): both skill `VERSION` files, the hook `VERSION`, and the header comments of `hook.sh` and `hook.ps1`. `tools/build.sh` checks they match; the old `dist/project-docs-skills-0.1.0.zip` was deleted so only 0.2.0 remains. Repositories enabled with 0.1.0 now show enabled-needs-repair; `/project-docs` repairs them (rules file difference is shown and confirmed first).
- Reruns: both hook suites 20/20 (Git Bash, Windows PowerShell 5.1) plus the bash suite 20/20 in WSL Debian; `tools/build.sh` passes (SKILL.md 250 and 148 lines, rules frontmatter valid) and produced `dist/project-docs-skills-0.2.0.zip` (21 files). The zip's `install.sh` installs it with matching versions in a redirected home.
- Not changed on purpose: the installers' closing message still says "reload VS Code (Developer: Reload Window)" as SPEC 12.2 words it; only INSTALL.md carries the "every open window" wording.

**Upgrade-test failure and SPEC 1.5 (2026-11-04)**
- The failure (user report): the upgrade test in `new1` (a 0.1.0 repository) ran `/project-docs` with MAI-Code-1.1-Flash (free tier, Auto only; the machine cannot select models). The model read the skill and then re-verified the previous task instead of repairing. Recorded in PLATFORM-NOTES as F14 (everything must work with the weakest model Auto picks), F15 (a small model continues the previous task) and F16.
- 8.6 hooks: session-start text now ends `... Background only, not a task: act on the entry below only if the user asks to continue earlier work. Most recent log entry:` + newline + entry ("resume point" removed). With no entries the text stops after `(log.md, decisions.md, knowledge.md).` (no dangling "entry below"; as accepted in Q7). `hook.sh` and `hook.ps1` both changed; tests 03 and 04 updated.
- 9.1 task lock: both SKILL.md files now open with four sentences (`You were invoked with /<name>.` / `Your only task in this reply is the procedure below, starting at Step 0.` / `Do not continue, check or summarize earlier work, even if the context mentions a previous task, a log entry or open files.` / `Your first action is Step 0 item 1.`). The regenerate skill's Step 0 is now four numbered items so that "item 1" exists. `tools/build.sh` checks the lock (first body line, the first-action line, a `## Step 0` heading); proved by four breakages in a scratch copy.
- Room in `project-docs` SKILL.md (limit 250; now 249): the Status procedure moved to the new `references/status.md` (SKILL.md keeps the pointer; nothing dropped), and the damaged-marker commands live in the new `references/damaged-marker.md`.
- 9.2 damaged marker (Q16 resolved): Step 0 item 3 detects a BOM and/or CR on line 1 of `log.md`, says plainly that the hooks treat the repository as not enabled, offers to remove only those bytes, STOPs, and on yes fixes only those bytes (bash and PowerShell commands in the reference). It runs before routing, so it also applies to `status` and `disable`. Defect found while building this: `hook.ps1` counted a BOM'd log as enabled (PowerShell string comparison ignores U+FEFF, F16); it now reads bytes and compares ordinally. New hook test 21 (damaged marker: BOM, then CR, all three events -> `{}`) in both runners.
- 12.2 (Q15 resolved): both installers now end with "reload every open VS Code window (Developer: Reload Window in each one)", also in the uninstall message.
- Version 0.2.0 -> 0.3.0 (user instruction): both skill VERSION files, the hook VERSION, both hook header comments; `dist/project-docs-skills-0.3.0.zip` (23 files) replaces 0.2.0. Repositories enabled with 0.2.0 show enabled-needs-repair.
- Manual plan: version 0.3.0; T06 expects the "background only" sentence; new T17b (upgrade of an already enabled repository, with a weak model; the check that failed) and T17c (damaged marker), rows added to the sheet; the smoke-run section says to run T17b after every new package version.
- Reruns: both hook suites 21/21 (Git Bash; Windows PowerShell 5.1) and the bash suite 21/21 in WSL Debian; `tools/build.sh` passes (SKILL.md 249 and 152 lines, rules frontmatter valid, new references required).
- Not verified: that the 0.3.0 wording actually keeps MAI-Code-1.1-Flash on task. That needs T17b on the user's machine.

## Timings

Repository with 10,003 tracked files, median of 5 runs, milliseconds, process start included (2026-11-02, this machine):

| Environment | session-start | prompt-submit (clean) | prompt-submit (20 dirty) | agent-stop (20 dirty) | Budget |
|---|---|---|---|---|---|
| WSL Debian, repo on Linux fs, bash | 13 | 45 | 45 | 46 | bash <= 300: met |
| WSL Debian, repo under `/mnt/c`, bash | 27 | 5315 | 5616 | 4104 | bash <= 300: **missed** (see Q6) |
| Windows, Windows PowerShell 5.1 | 308 | 386 | 436 | 412 | PowerShell <= 1500: met |
| Windows, Git Bash (not a hook host on Windows; informational) | 498 | 392 | 440 | 441 | - |

## Open questions

(Things the spec does not settle. Format: `Q<n> — <phase> — question — options — blocking? yes/no`.)
Q1 — P0 — `probe.ps1` CRLF without `.gitattributes`. Addressed in P1 by this repo's `.gitattributes` (`*.ps1 eol=crlf`).
Q2 — P0 — V7: docs do not confirm `COPILOT_HOME` relocates skills. Option A: installers always use `~/.copilot/skills` (safe default); option B: honor `COPILOT_HOME` once verified — blocking? no. OPEN until P5 (user, 2026-11-02): until then installers use `~/.copilot/skills`.
Q3 — P0 — SPEC v1.1 not on disk. RESOLVED 2026-11-02: v1.1 saved; read in full at start of P1.
Q4 — P0 — Block continuation re-fires userPromptSubmitted; cwd escaping. RESOLVED 2026-11-02 by SPEC 8.2, 8.4, 8.5, section 15: prompt-submit ignores prompts starting with `project-docs:`; parse JSON properly and never compare cwd as text, use `git rev-parse`.
Q5 — P0 — V7/V9 defaults. RESOLVED 2026-11-02: accept defaults; document workspace trust as a precaution; installers use `~/.copilot/skills`.
Q6 — P2 — Budget miss on `/mnt/c` in WSL: `git status` on a 10k-file repo over the 9p mount takes 4-5.6 s, so prompt-submit and agent-stop take 4-5.6 s there (hook `timeoutSec` is 10; the SPEC 8.7 budget is 300 ms). The cost is git itself, not the script. Options: A accept and document "keep repos on the Linux filesystem in WSL" (my suggestion); B raise `timeoutSec` for the bash entries; C ask the user to enable `core.untrackedCache`/fsmonitor in that repo (setup would be changing git config) — blocking? no
Q6-resolution — 2026-11-02: user chose option A (accept; document "keep repos on the Linux filesystem in WSL"). Document it in INSTALL.md (P5) and mention it in the enable report if the repo path starts with /mnt/.
Q7 — P2 — SPEC 8.6 step 4 says "No entries yet -> same text without the entry". I read that as the context text without the sentence "Most recent log entry (resume point):" too, since nothing follows it. Option: keep, or include the sentence — blocking? no
Q8 — P2 — `pwsh` (PowerShell 7) is not installed on this machine, so `hook.ps1` is verified on 5.1 only. Option: run `run-tests.ps1 -Shell pwsh` wherever pwsh exists — blocking? no
Q9 — P2 — Interpretations I made where SPEC 8.5 is silent: (a) when HEAD moved during the turn, the paths in the block reason come from `git diff --name-only <snapshot HEAD> <HEAD>` (or `git ls-tree` if the snapshot had no commits); an empty-commit turn lists `HEAD moved`; (b) git runs with `GIT_OPTIONAL_LOCKS=0` so a hook never takes the index lock; (c) the enabled-marker test is exact (a CRLF-ended first line does not count). Option: confirm, or tell me what to change — blocking? no
Q7-Q9-resolution — 2026-11-02: no objection raised when the user approved P2; treated as accepted. Reopen if wrong.
SPEC-1.2-resolution — 2026-11-02 (owner review): Q7, Q9, Q10, Q12 (a)-(j) and Q13 accepted as interpreted; Q12 (i) guide wording accepted plus the Notes line (implemented 2026-11-03). Q6, Q8, Q11 unchanged.
Q10 — P3 — Interpretations in SKILL.md where SPEC 9 is silent or I deviated slightly; confirm or correct (non-blocking):
  (a) Hook copies are verified with `git hash-object --no-filters <src> <dst>` (SPEC 9.3 step 8 says plain `git hash-object`); with `.gitattributes` eol rules active, a filtered hash of a CRLF/LF file could differ from the source for reasons unrelated to the copy.
  (b) Baseline for a repo with no commits is written `none (no commits yet)`.
  (c) The `.gitattributes` block is written with the file's existing line ending (SPEC 9.6 says preserve the rest byte for byte but not what the block uses).
  (d) Disable removes `.github/hooks/` or `.github/instructions/` when it is empty afterwards (SPEC 9.7: "only if project-docs created them"; I cannot tell who created an empty folder).
  (e) Migrated and reconstructed entries get `Next: (historical entry)` because `Next:` is required in every entry.
  (f) Legacy `roadmap.md` and `notes/` are kept, not deleted, unless the user asks; legacy `status.md` only feeds the `Next:` of the enabled entry.
  (g) `disable` with nothing installed says so and stops; E3 refuses to overwrite existing files in `docs/project-docs/`.
Q11 — P3 — I have not seen the older memory-model skills, so `references/migration.md` detects and maps their files from the SPEC 9.3 description only (names plus the `<!-- memory-model: v1 -->` marker). Option: send me a sample legacy `status.md`/`log.md`/`reference.md`, or accept the generic mapping and test on a real legacy repo in P6 — blocking? no
Q10-Q11-resolution — 2026-11-02: no objection raised when the user said "Start P4"; Q10 treated as accepted, Q11 stays open until P6 (no sample supplied). Reopen if wrong.
Q12 — P4 — Interpretations where SPEC 10/11 are silent; confirm or correct (non-blocking):
  (a) Two audience words (for example `ai human`) are a usage error; use `both`.
  (b) Log entries titled `project-docs enabled/repaired/disabled` are not reproduction steps; only the enabled entry's `Baseline:` is used (for step S00).
  (c) `S00` is added when the enabled entry has a commit baseline and the log has no `Origin: reconstructed` entries; without a remote URL it becomes an UNRESOLVED line.
  (d) `through:` is always the newest log ID, even when that entry was dropped from the steps.
  (e) Incremental mode finds steps made obsolete by a new `Supersedes:` through the `<!-- src: -->` comments; step IDs are labels, so a new step can sit before older ones.
  (f) The log records commands in one shell; the handout gives that command first and adds the other shell's variant only for plain file/folder operations and shell-neutral tools (`git`, `npm`, `pip`, `docker`), marked `(translated)`. Otherwise it adds a note.
  (g) A `Verify:` that the log lacks is proposed and marked `(proposed)`; a missing "If it fails" is written as `not recorded`.
  (h) Files that changed in the repository but appear in no log entry get an `UNRESOLVED ... (no log entry)` note at the end of the Outcome section.
  (i) The 10-line guide-instructions text in `handout-formats.md` is my wording of the SPEC 11.1 bullets (plus a numbered baseline note); please review the wording since every AI handout carries it verbatim.
  (j) The reply ends with `[project-docs: —]` (a regeneration writes no log entry, but the rules file asks for the marker on every reply).
Q2-resolution — P5, 2026-11-02: V7 is still unconfirmed, so per SPEC 12.2 the installers use only `~/.copilot/skills` / `%USERPROFILE%\.copilot\skills` and ignore `COPILOT_HOME`. INSTALL.md says so. Reopen if you verify that `COPILOT_HOME/skills` is honored.
Q13 — P5 — Choices where SPEC 12 leaves room; confirm or correct (non-blocking):
Q13-resolution — 2026-11-02: no objection raised when the user said "Start P6"; Q13 treated as accepted. Reopen if wrong.
Q14 — SPEC 1.2 — The hook behaviour changed (session-start text) but the package version is still 0.1.0, so a repository enabled earlier with the 0.1.0 hooks would count as healthy although its hooks lack the date line. Nothing has been deployed yet (the manual run has not happened), so I did not bump it. Option: keep 0.1.0 until the first real use, or bump all VERSION files to 0.1.1 (one edit per file plus the two hook header comments; `tools/build.sh` checks they match) — blocking? no
Q14-resolution — 2026-11-03: user chose to keep 0.1.0. Any repository enabled with an earlier 0.1.0 hook must be repaired by hand (copy hook.sh and hook.ps1 again) until the first release.
Q15 — SPEC 1.4 — The installers' final message (SPEC 12.2: "reload VS Code (Developer: Reload Window)") does not yet say "every open window", the lesson of smoke run T01. I left it as 12.2 words it and put the wording in INSTALL.md (12.3). Option: change both install scripts' last lines to "reload every open VS Code window" — blocking? no
Q15-resolution — 2026-11-04: SPEC 1.5 (12.2) says to change the installer messages; done.
Q16 — SPEC 1.4 — The Windows PowerShell 5.1 BOM finding (F11) is enforced only by instruction (SKILL.md writing rule). A cheap check would be for `/project-docs status` to report a BOM or CR in `docs/project-docs/*.md`, but SPEC 9.5 does not list it. Option: leave as is, or ask the owner to add it to 9.5 — blocking? no
Q16-resolution — 2026-11-04: SPEC 1.5 (9.2) adds damaged-marker detection with a confirmed fix; done.
Tooling note (not a question): `sed -i` in this Git Bash strips CR characters; after any `sed -i` on `hook.ps1`, `run-tests.ps1` or `install.ps1`, restore CRLF. `tools/build.sh` fails the build if a `.ps1` is not CRLF, so this cannot ship unnoticed.
  (a) `build.sh` writes `references/formats.md` into `src/skills/*/` (as SPEC 12.4 says), so those two files appear in the source tree as build output; they are not gitignored.
  (b) JSON validation uses the first parser found (jq, python3, node, PowerShell) and only warns if none exists.
  (c) The two skills are swapped in one after the other, not as a single atomic operation; a failure mid-way leaves the old copy of the second skill in place and reports an error.
  (d) The zip contains file entries only (no directory entries); entry names are checked for `\`.
  (e) `build.sh` also fails if a SKILL.md exceeds 250 lines (SPEC 9.1 states the limit for project-docs only; applied to both).

## Proposals

(Improvements outside the spec. Not implemented until the spec owner accepts them.)
- `dist/` was listed as gitignored in SPEC 4 but there was no `.gitignore`: I added one containing `dist/` in P5 (CLAUDE.md says the zip is not committed). Tell me if you want it removed.
- Rules file body: 70 lines (SPEC 7 target 70). Within target.
