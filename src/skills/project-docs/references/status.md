# Status report

Used by the "Status" section of SKILL.md. This is read only: change no file.

Report:

1. State: enabled-healthy, enabled-needs-repair (with the list of problems) or not-enabled.
2. Checklist of components with versions: rules file (and whether it matches the template), hook
   config, `hook.sh`, `hook.ps1`, hook VERSION versus `<skill>/VERSION`, `.gitattributes` block.
3. Entry counts: log entries (lines starting `## L`), decisions (lines starting `## D`),
   knowledge facts (lines starting `- ` in `knowledge.md`, not counting `- (none yet)`).
   bash: `grep -c '^## L' docs/project-docs/log.md`.
   PowerShell: `(Select-String -Path docs/project-docs/log.md -Pattern '^## L').Count`.
4. Title and `Next:` of the top log entry.
5. Handout checkpoints: the first line of `docs/project-docs/walkthrough.ai.md` and
   `walkthrough.md` if they exist.
