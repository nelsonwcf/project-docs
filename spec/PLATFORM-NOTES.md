# Platform notes

Facts the design depends on. `F` = confirmed from official docs (date, source). `V` = still to
verify; code must not depend on a `V` item until it is resolved here.

Record format for resolutions: `Resolved YYYY-MM-DD — <result> — <source or probe run>`.

## Confirmed (2026-11-02)

**F1 — SKILL.md frontmatter (VS Code).** Fields: `name` (required; lowercase letters, numbers,
hyphens; must equal the folder name; ≤ 64 chars; invalid names fail to load silently),
`description` (required; ≤ 1024 chars), `argument-hint`, `user-invocable` (default true),
`disable-model-invocation` (default false; true = slash command only), `context: fork`
(feature-flagged). Paths inside skills: relative to SKILL.md, `/` separators.
Source: https://code.visualstudio.com/docs/agent-customization/agent-skills

**F2 — Skill locations.** Copilot harness: project `.github/skills/`, personal
`~/.copilot/skills/`. Also recognized: `.claude/skills/`, `.agents/skills/`,
`~/.claude/skills/`, `~/.agents/skills/`. `chat.agentSkillsLocations` is not read by the
Copilot harness. Text after a slash command is passed as extra context.
Source: same as F1.

**F3 — Instructions.** Copilot harness: always-on `.github/copilot-instructions.md` or
`AGENTS.md`; targeted `.github/instructions/**/*.instructions.md` with `name`, `description`,
`applyTo`. `applyTo` attaches the file when the agent creates or modifies a matching file;
`description` enables on-demand loading. Sources are additive; no precedence order.
Source: https://code.visualstudio.com/docs/agent-customization/custom-instructions

**F4 — Hooks (Copilot harness).** Shared with Copilot CLI and app. Repository hooks:
`.github/hooks/*.json`. User hooks: `~/.copilot/hooks/` (or `$COPILOT_HOME/hooks/`). Format
`{"version": 1, "hooks": {...}}`. Command fields: `type`, `bash`, `powershell`, `command`
(fallback copied to both), `cwd`, `env`, `timeoutSec` (default 30). Events include
`sessionStart`, `userPromptSubmitted`, `preToolUse`, `postToolUse`, `preCompact`,
`agentStop`, `subagentStart`, `subagentStop`, `sessionEnd`. Multiple sources run together.
VS Code hooks are Preview. Local-harness settings (`chat.useHooks`,
`chat.hookFilesLocations`) do not configure the Copilot harness.
Sources: https://code.visualstudio.com/docs/agent-customization/hooks ;
https://docs.github.com/en/copilot/reference/hooks-reference

**F5 — Hook payloads.** camelCase event name -> camelCase fields; PascalCase alias -> snake_case
fields. `sessionStart`: `sessionId`, `timestamp`, `cwd`, `source` (`startup|resume|new`),
`initialPrompt?`; output `additionalContext` (multiple hooks joined with blank lines).
`userPromptSubmitted`: `sessionId`, `timestamp`, `cwd`, `prompt`; command-hook output ignored.
`agentStop`: `sessionId`, `timestamp`, `cwd`, `transcriptPath`, `stopReason` (`end_turn`),
`stop_hook_active` (snake_case even in camelCase format). `agentStop` output "can block and
force continuation". Agent-scoped stop hooks: blocks ignored after eight consecutive.
Source: GitHub hooks reference (above).

**F6 — Harness and remotes.** Selecting a Claude or OpenAI model in a Copilot harness session
does not change the harness. When VS Code is connected to WSL/SSH, the Copilot harness runs on
the remote machine; the Agent Host reads user customizations from `~/.copilot`, `~/.claude` on
that machine. Prompt files (`.prompt.md`) are not loaded outside the Local harness.
Sources: https://code.visualstudio.com/docs/agents/concepts/agent-harnesses ;
https://code.visualstudio.com/docs/agents/concepts/agent-host

**F7 — Compaction.** VS Code compacts automatically when the context fills; `/compact` manual.
Copilot hooks have `preCompact` (notification only). Not used by this design.

**F8 — Policy.** Relevant controls: `ChatAllowManagedHooksOnly`,
`ChatStrictPluginOnlyCustomization`, `ChatHooks` (Local only). Checked by the user with
**Developer: Policy Diagnostics**: all non-applied (2026-11-02).
Source: https://code.visualstudio.com/docs/enterprise/manage-ai-settings

**F9 — Known issue.** Plugin-installed skills under WSL/SSH remotes receive Windows host paths
(microsoft/vscode #305168, #316192). Personal skills installed inside the WSL home are not
affected by that bug, but see V6.

## To verify

**V1 — agentStop block output.** Exact JSON for a block (expected
`{"decision":"block","reason":"..."}` at top level, not under `hookSpecificOutput`). Cap on
consecutive blocks for repository (non-agent-scoped) hooks. Docs section "agentStop /
subagentStop decision control" in the GitHub hooks reference was not read in full. Confirm
from docs, then by probe.

**V2 — PowerShell host for the `powershell` field on Windows.** Which executable runs it
(Windows PowerShell 5.1 or `pwsh`), whether the execution policy blocks `& script.ps1`, and
whether a nested `powershell -NoProfile -ExecutionPolicy Bypass -File` is needed. Probe.

**V3 — Hook working directory.** Is the process cwd the repository root (or worktree root)?
Is payload `cwd` the same? Probe.

**V4 — Event timing in VS Code.** `sessionStart` fires once per new chat (and on resume?);
`userPromptSubmitted` fires before the agent's first tool call of the turn; `agentStop` fires
once per turn end. Probe.

**V5 — Payload casing in the VS Code Copilot harness** with camelCase event names matches F5.
Probe (raw stdin is logged).

**V6 — Skill assets readable.** In a WSL remote session, the agent can read files in
`~/.copilot/skills/project-docs/assets/` and copy them into the workspace (terminal `cp`).
Same on native Windows from `%USERPROFILE%`. Manual test during P3 review.

**V7 — `COPILOT_HOME`.** Does it relocate personal skills (`$COPILOT_HOME/skills`) for the
VS Code Copilot harness? Docs.

**V8 — Unknown frontmatter fields.** Are unrecognized SKILL.md frontmatter fields ignored or
do they prevent loading? Until resolved: use only F1 fields.

**V9 — Workspace trust.** Do repository hooks require a trusted workspace in VS Code? Docs
mention "workspace admission" for agent-scoped hooks. Docs, then probe.

**V10 — `applyTo` in the Copilot harness.** Confirm the instructions file is attached in
Copilot harness sessions on edit turns (Chat response **References**). Manual test.

## Resolution log (P0)

Doc check 2026-11-02 (GitHub hooks reference, VS Code hooks page, VS Code agent-skills page),
then probe runs 2026-11-02 on native Windows (VS Code, Copilot harness, Windows PowerShell 5.1,
Windows 11) and WSL2 (Ubuntu, bash 5.2.37). Raw logs: `tests/probe/results-windows.log`,
`tests/probe/results-wsl.log`. Windows run: 3 chats / 4 prompts (new chat, same-chat second
prompt, second new chat, resume of the first chat). WSL run: 1 chat / 1 prompt only.

**V1 — Resolved 2026-11-02 — `agentStop` block is top-level `{"decision":"block","reason":"..."}`, exit 0; the harness accepts it and continues the turn.** Evidence: the log shows the block output, then within ~1 s a new `userPromptSubmitted` whose `prompt` is the `reason` text, then a second `agentStop` with `stop_hook_active: true`. Windows and WSL identical. The `reason` is delivered to the agent as a new user prompt. Not tested: the cap of 8 consecutive blocks (docs: "After 8 consecutive `block` continuations, the CLI overrides the hook and ends the turn anyway"); whether a given model obeyed the reason (not observable in the log). Sources: probe logs; https://docs.github.com/en/copilot/reference/hooks-reference

**V2 — Resolved 2026-11-02 — on Windows the `powershell` field runs Windows PowerShell 5.1 (`C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe`, edition Desktop), not `pwsh`.** Both registration styles ran for every event. Execution policy: LocalMachine=Unrestricted on this machine, so the direct `& ./script.ps1` form worked here; that depends on machine policy and is not safe to rely on. Nested form with `-ExecutionPolicy Bypass` ran with Process=Bypass. Use the nested form (SPEC 8.1). On Windows the `bash` field is not used (no bash entries in the Windows log), even when the agent terminal is Git Bash. Not tested: a machine with `pwsh` installed or a stricter policy. Source: `results-windows.log`.

**V3 — Resolved 2026-11-02 — process cwd = repository root; payload `cwd` = the same folder.** Windows: `pwd` `C:\Users\nelson\probe-scratch`, `cwd` in JSON `c:\\Users\\nelson\\probe-scratch` (lowercase drive letter, each backslash doubled by JSON escaping; scripts must unescape the doubled backslashes before use). WSL: both `/home/nelson/probe-scratch`. Relative paths in the config (`.github/hooks/...`) resolved correctly. Not tested: a Copilot worktree, a repo opened in a subfolder. Source: both logs.

**V4 — Resolved 2026-11-02 — event order and timing as follows.**
- `sessionStart` fires when the **first prompt of a chat is sent**, not when the chat is opened; payload `source` is `new` and `initialPrompt` holds that prompt. Reopening an existing chat and sending a prompt fires `sessionStart` again with `source: "resume"` and the original `sessionId`.
- Order per turn: `sessionStart` (first prompt only) -> `userPromptSubmitted` (~1 s later) -> `agentStop` (once per turn end, `stopReason: end_turn`). Later prompts in the same chat: `userPromptSubmitted` then `agentStop`, no `sessionStart`.
- After a block, a further `userPromptSubmitted` fires with the block reason as `prompt`, then `agentStop` with `stop_hook_active: true`. A `userPromptSubmitted` hook therefore overwrites its snapshot at that point (see Q4 in `status.md`).
- Not directly observed: that `userPromptSubmitted` precedes the agent's first tool call (tool calls are not logged); it does precede the turn's `agentStop`.
Source: both logs.

**V5 — Resolved 2026-11-02 — camelCase event names deliver camelCase fields on stdin as UTF-8 JSON without BOM, matching F5.** Observed fields: `sessionStart`: `sessionId`, `timestamp` (Unix ms), `cwd`, `source`, `initialPrompt`. `userPromptSubmitted`: `sessionId`, `timestamp`, `cwd`, `prompt`. `agentStop`: `sessionId`, `timestamp`, `cwd`, `transcriptPath`, `stopReason`, `stop_hook_active` (snake_case, boolean unquoted). `transcriptPath` is `<COPILOT_HOME or ~/.copilot>/session-state/<sessionId>/events.jsonl`. Session IDs are GUIDs. Source: both logs.

**V6 — Resolved on native Windows 2026-11-03 — the agent can read the skill's `assets/` folder in `%USERPROFILE%\.copilot\skills\project-docs\` and copy its files into the workspace; the verification hashes of the copies matched the sources.** Smoke run T04 (`/project-docs` on a new repository), user report; log of that repository: `tests/results/new1-log.md`. **Still open for WSL** (manual plan T02 / T05b: the agent reading `~/.copilot/skills/.../assets/` inside the distribution).

**V7 — Open (partially informed).** Docs: `COPILOT_HOME` is documented for hooks only. Probe: `COPILOT_HOME`, `COPILOT_HOOK_DIR`, `COPILOT_PROJECT_DIR` are present in the hook environment on both platforms (names only logged; values not captured), so the host sets `COPILOT_HOME`; that does not show it relocates personal skills. Installers keep `~/.copilot/skills` (see Q2). Resolve by: user sets `COPILOT_HOME` to a scratch folder, places a skill under `<it>/skills/`, and checks Chat: Open Customizations > Skills. `COPILOT_PROJECT_DIR` is a possible root cross-check, but the hook scripts use `git rev-parse` per SPEC 3.

**V8 — Open (docs silent).** Use only F1 fields until tested.

**V9 — Open.** Hooks ran in the scratch workspace, but whether the workspace was trusted at the time was not reported, so the log does not answer it. Docs: agent-scoped hooks require workspace admission. INSTALL.md and the setup report keep the "workspace must be trusted" wording as a precaution. To resolve: open a fresh scratch repo in Restricted Mode and see whether the probe log appears.

**V10 — Resolved 2026-11-03 — in the Copilot harness the `applyTo: "**"` instructions file was attached and followed: log entries were written in the same turn, and replies carried the marker, including `[project-docs: —]` on a read-only turn.** Smoke run T08 and T09, user report; `tests/results/new1-log.md` shows the resulting entries. Native Windows only so far.

## To verify (status)

V1 resolved. V2 resolved. V3 resolved. V4 resolved. V5 resolved. V6 resolved on Windows (WSL open). V7 open. V8 open. V9 open. V10 resolved (Windows).

## Smoke run findings (2026-11-03, native Windows)

Run by the user with the 0.1.0 package (8 of 8 tests passed after the fixes below); results in `tests/MANUAL-TEST-PLAN.md` (result sheet) and files in `tests/results/`.

**V1 (addition) — the `agentStop` block works with a real model in the VS Code Copilot harness.** T08: the session record shows the hook's `project-docs: files changed this turn ...` message reaching the agent as a user message after an unlogged edit, and the agent then writing the log entry. Source: user report of the session record (the transcript itself is not stored in this repository). Still untested: the cap of 8 consecutive blocks.

**F10 — SKILL.md frontmatter must be valid YAML.** An unquoted `description` containing `: ` made Copilot drop the skill silently (the skill was absent from **Chat: Open Customizations > Skills**; a sibling skill without `: ` loaded). Source: smoke run T01. Fixed by quoting (SPEC 1.3).

**F11 — Windows PowerShell 5.1 terminal writes add a BOM and CRLF.** A small model wrote a `docs/project-docs/` file with a terminal command and the file gained a BOM. Documents must be written with the file-editing tool (SPEC 9.3). Source: smoke run T04.

**F12 — `core.autocrlf=true` converts any text file git considers text, including the hook `VERSION` file**, so a version comparison that is not whitespace/line-ending tolerant reports a false mismatch. Fixed by tolerant comparison (SPEC 9.2) and by adding `VERSION` to the managed `.gitattributes` block (SPEC 9.6). Source: smoke run T04.

**F13 — Already-open VS Code windows keep their old skill list after an install**, including windows opened after the install but before a reload; every open window must be reloaded. Source: smoke run T01 (SPEC 12.3).

## Upgrade test findings (2026-11-04, native Windows)

**F14 — Design constraint: everything must work with the weakest model that Auto picks.** The user's development machine is on the free tier and cannot select models (Auto only); other users may also get a small model. The deliverables (the two SKILL.md files, the rules file, the hook messages, the references) are therefore written for the weakest model Auto may choose: short imperative sentences, explicit first action, explicit stop points, no reliance on inference. Every new behaviour is tested with a weak model, and a pass with a strong model proves nothing. Source: owner decision recorded in SPEC 1.5; upgrade test below.

**F15 — A small model can continue the previous task instead of running an invoked skill.** Upgrade test in `new1` (a repository enabled with the 0.1.0 hooks): `/project-docs` with MAI-Code-1.1-Flash (Auto) read the skill and then re-verified the previous task, because the session context carried the latest log entry labelled as a "resume point" and the skill opened with a description rather than an instruction. Fixed by SPEC 1.5: the context text says the entry is background only, not a task (8.6), and both SKILL.md files open with a task lock (9.1). Source: upgrade test, user report.

**F16 — PowerShell `-ceq` / `-cne` compare strings culture-aware, so a leading U+FEFF (BOM) is ignored.** `hook.ps1` compared the log's first line with the marker using `-cne`; a log starting with a BOM then still counted as enabled in PowerShell but not in bash. Fixed in 0.3.0 by reading the file as bytes and comparing with `[string]::Equals(..., [StringComparison]::Ordinal)`. Source: new hook test 21 (damaged marker), found while implementing SPEC 1.5 / 9.2.
