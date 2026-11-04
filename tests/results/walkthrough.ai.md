<!-- project-docs-regenerate: v1 | audience: ai | through: L0008 | generated: 2026-11-03 | mode: full -->
# Guide: Greeting script from scratch

## Guide instructions (for the assistant reading this document)
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

## Outcome
The repository contains `hello.txt` and a PowerShell greeting script. The script requires a name, supports normal and uppercase styles, and prints `Authenticated` when `GREET_API_KEY` is set. Run it from the repository root with `.\greet.ps1 -Name "Ada"`.

## Environment and prerequisites
- PowerShell is required to run the script; Git is required for repository-local line-ending configuration.
> UNRESOLVED: the exact PowerShell version was not recorded (from L0003).
> UNRESOLVED: the exact Git version was not recorded (from L0004).

## Steps

### S01 — Create the hello file
<!-- src: L0002 -->
- Goal: Create `hello.txt` containing the word `hello`.
- Requires: none
- Action: Create `hello.txt` at the repository root with exactly this content.
- Files: `hello.txt`
  ```text
  hello
  ```
- Verify: Read `hello.txt` (proposed).
  Expected: `hello`
- If it fails: not recorded

### S02 — Create the greeting script
<!-- src: L0003, L0005, L0007, L0008 -->
- Goal: Provide a name-based greeting with normal or uppercase style and an optional authentication notice.
- Requires: none | PowerShell
- Action: At the repository root, create `greet.ps1` and `README.md` with the exact contents below, then run `.\greet.ps1 -Name "Ada"`.
- Files: `greet.ps1`
  ```powershell
  param(
      [Parameter(Mandatory = $true)]
      [string]$Name,
      [ValidateSet('Normal', 'Upper')]
      [string]$Style = 'Normal'
  )

  $greeting = "Hello, $Name!"
  if ($Style -eq 'Upper') {
      $greeting = $greeting.ToUpperInvariant()
  }

  Write-Output $greeting

  if ($env:GREET_API_KEY) {
      Write-Output 'Authenticated'
  }
  ```
  `README.md`
  ````markdown
  # Greeting script

  Run the script from PowerShell, replacing `Ada` with the name to greet:

  ```powershell
  .\greet.ps1 -Name "Ada"
  ```

  The script prints:

  ```text
  Hello, Ada!
  ```

  Use `-Style Upper` to print the greeting in uppercase. The default style is `Normal`:

  ```powershell
  .\greet.ps1 -Name "Ada" -Style Upper
  ```

  This prints:

  ```text
  HELLO, ADA!
  ```

  If the `GREET_API_KEY` environment variable is set, the script prints `Authenticated`
  after the greeting. For example, set it for the current PowerShell session with:

  ```powershell
  $env:GREET_API_KEY = "your-api-key"
  .\greet.ps1 -Name "Ada"
  ```
  ````
- Verify: `.\greet.ps1 -Name "Ada"`; `.\greet.ps1 -Name "Ada" -Style Upper`; test with `GREET_API_KEY` unset and set.
  Expected: `Hello, Ada!`; `HELLO, ADA!`; with the variable set, `Authenticated` follows the greeting.
- If it fails: not recorded
- Notes: `-Style` was chosen instead of switches because more styles will be added later. `Normal` is the default.

### S03 — Disable Git line-ending conversion
<!-- src: L0004 -->
- Goal: Set the repository-local Git configuration so automatic line-ending conversion is disabled.
- Requires: none | Git
- Action: In PowerShell, from the repository root, run `git config --local core.autocrlf false`.
- Verify: `git config --local --get core.autocrlf`
  Expected: `false`
- If it fails: not recorded

## Final check
- In PowerShell at the repository root, run `Get-Content .\hello.txt`; `.\greet.ps1 -Name "Ada"`; `.\greet.ps1 -Name "Ada" -Style Upper`; and `git config --local --get core.autocrlf`.
  Expected: `hello`; `Hello, Ada!`; `HELLO, ADA!`; `false`.
- With `GREET_API_KEY` unset, the greeting prints without an authentication notice. With it set to `<SECRET: GREET_API_KEY>`, `Authenticated` follows the greeting.
