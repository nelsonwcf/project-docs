#!/usr/bin/env bash
# project-docs probe v1 (bash). Logs hook events to <git-dir>/probe/events.log.
# Usage: probe.sh <event>
event="${1:-unknown}"
raw="$(cat)"
gd="$(git rev-parse --absolute-git-dir 2>/dev/null)"
if [ -z "$gd" ]; then gd="${TMPDIR:-/tmp}"; fi
dir="$gd/probe"
mkdir -p "$dir"
log="$dir/events.log"

sid="$(printf '%s' "$raw" | sed -n 's/.*"[sS]ession_\{0,1\}[iI]d"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1 | tr -c 'A-Za-z0-9_\n-' '_' | cut -c1-64)"
[ -z "$sid" ] && sid="default"

out='{}'
if [ "$event" = "agentStop" ]; then
  active=false
  if printf '%s' "$raw" | grep -Eq '"stop_?[hH]ook_?[aA]ctive"[[:space:]]*:[[:space:]]*true'; then active=true; fi
  marker="$dir/blocked-$sid"
  if [ "$active" = false ] && [ ! -e "$marker" ]; then
    : > "$marker"
    out='{"decision":"block","reason":"probe: say PROBE-OK and stop"}'
  fi
fi

{
  echo "=== $(date -u +%Y-%m-%dT%H:%M:%SZ) event=$event label=bash"
  echo "shell: bash $BASH_VERSION"
  echo "uname: $(uname -a)"
  echo "pwd: $(pwd)"
  echo "toplevel: $(git rev-parse --show-toplevel 2>/dev/null)"
  echo "git-dir: $gd"
  echo "env-names: $(env | sed -n 's/^\([^=]*COPILOT[^=]*\)=.*/\1/p' | tr '\n' ' ')"
  echo "stdin: $raw"
  echo "output: $out"
} >> "$log"

printf '%s' "$out"
exit 0
