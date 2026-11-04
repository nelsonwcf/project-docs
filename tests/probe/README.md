# Probe kit (P0)

Answers the platform questions that documentation cannot (PLATFORM-NOTES V1-V5, V9). It only
logs; the one thing it changes is that `agentStop` blocks once per session so the block format
can be confirmed. Run it in a **scratch repository**, never a real one.

## What is in the kit

```
.github/hooks/probe.json            hook config (3 events; PowerShell registered twice)
.github/hooks/probe/probe.sh        bash probe
.github/hooks/probe/probe.ps1       PowerShell probe (ASCII, CRLF)
```

The PowerShell side is registered twice per event: `nested` (`powershell -File ...`) and
`direct` (`& ./.github/hooks/probe/probe.ps1 ...`). Comparing the two log blocks answers V2.
Only `nested` blocks at `agentStop`.

Log file: `<git-dir>/probe/events.log` (inside `.git`, never committed).

## Run it - once on native Windows, once in WSL

Repeat for each environment. In WSL, open the scratch repo with VS Code connected to WSL, in
the Linux filesystem (for example `~/probe-scratch`).

1. Create the scratch repo and copy the kit in. Replace `<kit>` with the path of this folder
   (`tests/probe`).

   PowerShell:
   ```powershell
   mkdir $HOME\probe-scratch; cd $HOME\probe-scratch
   git init
   Copy-Item -Recurse "<kit>\.github" .
   git add -A; git commit -m "probe scratch"
   ```

   bash:
   ```bash
   mkdir ~/probe-scratch && cd ~/probe-scratch
   git init
   cp -r "<kit>/.github" .
   git add -A && git commit -m "probe scratch"
   ```
2. Open the folder in VS Code. Trust the workspace when asked. Note whether you were asked.
3. Open Chat. Set **Session Target: Copilot**. Pick any model.
4. Send prompt 1: `Create a file hello.txt containing the word hello.`
   Expected: the agent works, then is sent back once with the text `probe: say PROBE-OK and stop`
   and replies with PROBE-OK or similar.
5. Send prompt 2: `Append the word world to hello.txt.` (same chat).
6. Start a **new chat** (Session Target: Copilot) and send: `Say hi.` Then close and reopen
   VS Code, reopen that earlier chat, and send `Say hi again.` (tests sessionStart on new vs resume).
7. Optional: **Chat: Open Customizations > Hooks** - note whether the probe hooks are listed.
8. Collect the log:

   PowerShell: `Get-Content .git\probe\events.log`
   bash: `cat .git/probe/events.log`

## What to send back

For each environment (Windows, WSL):

- The whole `events.log` file.
- Whether the trust prompt appeared (step 2) and whether hooks ran without trusting.
- Whether the agent visibly reacted to the `agentStop` block (step 4).
- Which terminal the agent used (PowerShell / Git Bash / bash).
- Windows only: if only one of `nested` / `direct` shows up in the log, say which. A missing
  one is a valid result (it failed to run).
- Any error shown in the Output panel under **GitHub Copilot Chat** mentioning hooks.

## What each log field answers

| Question | Look at |
|---|---|
| V1 block format works; what the model saw | step 4 reaction; `output:` of agentStop; second agentStop has `stop_hook_active` true |
| V2 PowerShell host | `shell:` line (`exe=`, edition) and `execution-policy:` for nested vs direct |
| V3 working directory | `pwd:` and `toplevel:` versus `cwd` in `stdin:` |
| V4 event timing | order and count of `=== ` blocks across the prompts and chats |
| V5 payload casing | key names in `stdin:` |
| V9 trust | whether blocks appear without trusting the workspace |
