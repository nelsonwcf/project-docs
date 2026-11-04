# Installing the project-docs skills

This package adds two personal skills to GitHub Copilot in VS Code:

- `/project-docs` - enable, check, repair or disable project-docs in a repository.
- `/project-docs-regenerate` - build the step-by-step handout from the project's log.

Both are installed in your user folder `.copilot/skills`. They are never copied into a repository.

Requirements: VS Code with GitHub Copilot, `git` on PATH, and (for the hooks to run) a trusted
workspace with **Session Target: Copilot** in the chat.

## 1. Unzip the package

Unzip `project-docs-skills-<version>.zip` into any folder. Keep the contents together: the
installer reads the two skill folders and `VERSION` next to itself.

- PowerShell: `Expand-Archive -LiteralPath .\project-docs-skills-<version>.zip -DestinationPath .\project-docs-skills`
- bash: `unzip project-docs-skills-<version>.zip -d project-docs-skills`

Then open a terminal in the unzipped folder.

## 2. Install

Which command you need depends on where VS Code runs the chat.

| You use VS Code... | Skills are read from | Run |
|---|---|---|
| on native Windows | `%USERPROFILE%\.copilot\skills` | `install.ps1` (PowerShell) |
| connected to WSL | `~/.copilot/skills` inside the Linux distribution | `install.sh` inside WSL |
| both | both places | both commands |

### Windows

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

### WSL (or Linux, macOS)

Open a terminal inside WSL (or connect VS Code to WSL and use its terminal), go to the unzipped
folder, and run:

```bash
bash install.sh
```

The Windows disk is visible in WSL under `/mnt/c/...`, so you can run it from there.

## 3. Verify

1. Reload **every** open VS Code window: run **Developer: Reload Window** in each one. This includes
   windows you opened after the install but before reloading; a window loaded earlier keeps the old skill list.
2. Run **Chat: Open Customizations** and open the **Skills** list. Both `project-docs` and
   `project-docs-regenerate` must be listed.
3. Open a git repository, choose **Session Target: Copilot**, and type `/project-docs status`.

## 4. Update

Unzip the newer package and run the same install command again. The old copies are replaced; nothing
else in `.copilot/skills` is touched. Then reload every open window. In each repository where project-docs
is enabled, run `/project-docs`: it detects outdated hooks and repairs them.

## 5. Uninstall

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

```bash
bash install.sh --uninstall
```

This removes only the two skill folders. Repositories where project-docs was enabled keep their
docs, rules and hooks; remove those with `/project-docs disable` before uninstalling.

## Using it

- In a repository, run `/project-docs` once to enable documentation. Nothing is committed for you.
- Check health any time with `/project-docs status`.
- Build the handout with `/project-docs-regenerate` (add `human`, `both` or `full` as needed).
- In WSL, keep repositories on the Linux filesystem (for example `~/code/...`), not under
  `/mnt/c/...`: git is much slower there and the hooks can take several seconds per turn.

## Troubleshooting

**The skills are not listed.**
- Wrong home folder. Native Windows reads `%USERPROFILE%\.copilot\skills`; WSL reads `~/.copilot/skills`
  inside the distribution. Run the installer that matches where the chat runs (see the table above).
- Extra folder level. The layout must be `.copilot/skills/project-docs/SKILL.md`, not
  `.copilot/skills/project-docs-skills/project-docs/SKILL.md`. Run the installer instead of copying by hand.
- Name mismatch. The folder name and the `name:` line inside `SKILL.md` must be identical; a mismatch
  makes the skill silently fail to load.
- A window was not reloaded. Reload **every** open window (**Developer: Reload Window**), including windows
  opened after the install but before a reload: each window reads the skills when it loads.
- `COPILOT_HOME` is set. The installers ignore it and always use the `.copilot/skills` folder in your
  user folder, because it is not confirmed that Copilot reads skills from `COPILOT_HOME`.

**The hooks do not fire** (no project-docs context at the start of a new chat, no reminder after an
unlogged edit).
- The workspace is not trusted. Trust the folder when VS Code asks.
- Session Target is not **Copilot**. Hooks apply to the Copilot harness.
- The repository was enabled with an older package. Run `/project-docs` again to repair it.
- Check **Chat: Open Customizations**, **Hooks**: the project-docs hooks should be listed.

**The installer says it cannot find `VERSION` or `SKILL.md`.** Run it from the unzipped folder, not
from inside the zip file.

**Windows blocks the script.** Use the full command shown above, with
`-ExecutionPolicy Bypass`, instead of double-clicking the file.

**Windows and WSL show different results.** They are two separate homes. Install in both if you use both.
