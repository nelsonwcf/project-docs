<!-- project-docs: v1 -->
# Project log

Every outcome-producing step in this repository, newest first.
Rules: `.github/instructions/project-docs.instructions.md`. Entries below the first are frozen.

<!-- entries: newest first -->

## L0008 — 2026-11-03 — Add environment-key authentication notice
- Did: Print `Authenticated` after the greeting when `GREET_API_KEY` is set; documented session setup. Tested with the supplied key without logging or printing its value.
- Changed: `greet.ps1`, `README.md`, `docs/project-docs/log.md`
- Ran: PowerShell tests with `GREET_API_KEY` unset and set to `<SECRET: GREET_API_KEY>` (repo root)
- Verify: Without a key, only the greeting prints; with a key, `Authenticated` follows it.
- Next: Finish.

## L0007 — 2026-11-03 — Replace shout switch with style parameter
- Did: Replaced `-Shout` with `-Style Normal|Upper`, defaulting to `Normal`, and updated the README.
- Changed: `greet.ps1`, `README.md`, `docs/project-docs/decisions.md`, `docs/project-docs/log.md`
- Verify: Normal default and Upper output verified; `-Shout` is no longer accepted.
- Decision: D0001
- Next: Finish.

## L0006 — 2026-11-03 — Try config-based default name
- Did: Tested an optional `-Name` using the `Name` value in `greet.json`; it worked, then removed the config and fallback code as overkill.
- Changed: `greet.ps1`, `greet.json` (added and removed), `docs/project-docs/log.md`
- Ran: `.\greet.ps1; .\greet.ps1 -Shout; .\greet.ps1 -Name "Ada"` (repo root)
- Verify: Config default and explicit override worked; final script still prints regular and shouted greetings; `greet.json` is absent.
- Status: abandoned
- Next: Finish.

## L0005 — 2026-11-03 — Add uppercase greeting switch
- Did: Added the `-Shout` switch to print the greeting in uppercase and documented its usage.
- Changed: `greet.ps1`, `README.md`, `docs/project-docs/log.md`
- Ran: `.\greet.ps1 -Name "Ada"; .\greet.ps1 -Name "Ada" -Shout` (repo root)
- Verify: Printed `Hello, Ada!` and `HELLO, ADA!`
- Next: Finish.

## L0004 — 2026-11-03 — Disable Git line-ending conversion
- Did: Set repository-local `core.autocrlf` to `false`.
- Changed: `.git/config`, `docs/project-docs/log.md`
- Ran: `git config --local core.autocrlf false` (repo root)
- Verify: `git config --local --get core.autocrlf` -> `false`
- Next: Finish.

## L0003 — 2026-11-03 — Add greeting script
- Did: Added a PowerShell script that greets the supplied name and a README with run instructions.
- Changed: `greet.ps1`, `README.md`, `docs/project-docs/log.md`
- Ran: `.\greet.ps1 -Name "Ada"` (repo root)
- Verify: Printed `Hello, Ada!`
- Next: Finish.

## L0002 — 2026-11-03 — Create hello file
- Did: Created `hello.txt` with the word `hello`.
- Changed: `hello.txt`
- Next: Finish.

## L0001 — 2026-11-03 — project-docs enabled
- Did: Enabled project-docs documentation.
- Changed: `docs/project-docs/`, `.github/instructions/project-docs.instructions.md`, `.github/hooks/project-docs.json`, `.github/hooks/project-docs/`, `.gitattributes`
- Baseline: none (no commits yet)
- Next: Await user direction.