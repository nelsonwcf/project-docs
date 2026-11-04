#!/usr/bin/env bash
# Automated tests for hook.sh (SPEC 13.2). Creates throwaway git repos in a temp directory.
# Usage: bash tests/hooks/run-tests.sh [--timing]
# Cases 1-18 are the SPEC cases; 19 to 21 are additions (escaped Windows cwd, SPEC 8.4 rule, damaged marker).

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOOK=$here/../../src/skills/project-docs/assets/hooks/project-docs/hook.sh
TEMPLATES=$here/../../src/skills/project-docs/assets/docs
TMP=$(mktemp -d)
trap '[ -n "$TMP" ] && [ -d "$TMP" ] && rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
BADJSON=0
R=''
CWDJ=''
OUT=''
ERR=''

STR='"(?:[^"\\\x00-\x1f]|\\(?:["\\/bfnrt]|u[0-9a-fA-F]{4}))*"'
KV="$STR:$STR"
JSONRE="^\\{($KV(,$KV)*)?\\}\$"

# ---- helpers ---------------------------------------------------------------

check() { # name, command...
  local name=$1
  shift
  if "$@"; then
    PASS=$((PASS + 1))
    echo "PASS  $name"
  else
    FAIL=$((FAIL + 1))
    echo "FAIL  $name"
    echo "      out: ${OUT:0:300}"
    echo "      err: ${ERR:0:300}"
  fi
}

is_empty_obj() { [ "$OUT" = '{}' ]; }
is_block() { [[ $OUT == '{"decision":"block","reason":"project-docs: files changed this turn ('* ]]; }
out_has() { [[ $OUT == *"$1"* ]]; }
out_lacks() { [[ $OUT != *"$1"* ]]; }
# SPEC 8.6: the context text starts with "Today is YYYY-MM-DD." (local date) followed by the fixed sentence.
today_line() { [[ $OUT == "{\"additionalContext\":\"Today is $(date +%F). project-docs is enabled in this repository."* ]]; }

new_dir() { R=$(mktemp -d "$TMP/repo.XXXXXX"); CWDJ=$R; }
new_repo() {
  new_dir
  git -C "$R" init -q
  git -C "$R" config user.email test@example.com
  git -C "$R" config user.name test
  git -C "$R" config core.autocrlf false
}
# enable_repo <n entries 0|2>: writes docs/project-docs from the templates.
enable_repo() {
  mkdir -p "$R/docs/project-docs"
  cp "$TEMPLATES/log.md" "$TEMPLATES/decisions.md" "$TEMPLATES/knowledge.md" "$R/docs/project-docs/"
  if [ "${1:-0}" = 2 ]; then
    printf '\n## L0002 — 2026-11-02 — Second step\n- Did: second\n- Next: third\n\n## L0001 — 2026-11-02 — First step\n- Did: first\n- Next: second\n' >> "$R/docs/project-docs/log.md"
  fi
}
commit_all() { git -C "$R" add -A >/dev/null 2>&1 && git -C "$R" commit -q -m "$1" >/dev/null 2>&1; }
add_log_entry() { printf '\n## L0099 — 2026-11-02 — Test entry\n- Did: x\n- Next: y\n' >> "$R/docs/project-docs/log.md"; }
gitdir() { git -C "$R" rev-parse --absolute-git-dir; }

# hook <event> <json>: runs hook.sh with the repository as working directory.
hook() {
  OUT=$(cd "$R" && printf '%s' "$2" | bash "$HOOK" "$1" 2>"$TMP/stderr")
  ERR=$(cat "$TMP/stderr")
  if ! printf '%s' "$OUT" | grep -Pq "$JSONRE"; then
    BADJSON=$((BADJSON + 1))
    echo "      invalid JSON from $1: ${OUT:0:200}"
  fi
}
p_start() { printf '{"sessionId":"%s","timestamp":1,"cwd":"%s","source":"new","initialPrompt":"hi"}' "$1" "$CWDJ"; }
p_prompt() { printf '{"sessionId":"%s","timestamp":1,"cwd":"%s","prompt":"%s"}' "$1" "$CWDJ" "${2:-do the thing}"; }
p_stop() { printf '{"sessionId":"%s","timestamp":1,"cwd":"%s","transcriptPath":"t","stopReason":"end_turn","stop_hook_active":%s}' "$1" "$CWDJ" "${2:-false}"; }

# repo with one tracked file, enabled, committed
std_repo() {
  new_repo
  enable_repo "${1:-2}"
  printf 'one\n' > "$R/a.txt"
  commit_all init
}

# ---- cases -----------------------------------------------------------------

case01() {
  new_dir
  local ok=0 ev
  for ev in session-start prompt-submit agent-stop; do
    hook "$ev" "$(p_start s1)"
    is_empty_obj || ok=1
  done
  return $ok
}

case02() {
  new_repo
  printf 'x\n' > "$R/a.txt"
  commit_all init
  local ok=0 ev
  for ev in session-start prompt-submit agent-stop; do
    hook "$ev" "$(p_start s1)"
    is_empty_obj || ok=1
  done
  mkdir -p "$R/docs/project-docs"
  printf '# Project log\n' > "$R/docs/project-docs/log.md"   # no marker on line 1
  for ev in session-start prompt-submit agent-stop; do
    hook "$ev" "$(p_start s1)"
    is_empty_obj || ok=1
  done
  return $ok
}

case03() {
  std_repo 2
  hook session-start "$(p_start s1)"
  today_line && out_has 'L0002 ' && out_lacks 'L0001 ' \
    && out_has 'Background only, not a task:' && out_has 'Most recent log entry:' && out_lacks 'resume point'
}

case04() {
  std_repo 0
  hook session-start "$(p_start s1)"
  today_line && out_lacks 'Most recent log entry' && out_lacks 'Background only' && out_lacks '## L'
}

case05() {
  std_repo
  hook prompt-submit "$(p_prompt s1)"
  hook agent-stop "$(p_stop s1)"
  is_empty_obj
}

case06() {
  std_repo
  hook prompt-submit "$(p_prompt s1)"
  printf 'two\n' >> "$R/a.txt"
  hook agent-stop "$(p_stop s1)"
  is_block && out_has '(a.txt)'
}

case07() {
  std_repo
  hook prompt-submit "$(p_prompt s1)"
  printf 'two\n' >> "$R/a.txt"
  add_log_entry
  hook agent-stop "$(p_stop s1)"
  is_empty_obj
}

case08() {
  std_repo
  hook prompt-submit "$(p_prompt s1)"
  printf 'two\n' >> "$R/a.txt"
  hook agent-stop "$(p_stop s1 true)"
  is_empty_obj
}

case09() {
  std_repo
  hook prompt-submit "$(p_prompt s1)"
  printf -- '- a fact\n' >> "$R/docs/project-docs/knowledge.md"
  printf 'x\n' > "$R/docs/project-docs/walkthrough.ai.md"
  hook agent-stop "$(p_stop s1)"
  is_empty_obj
}

case10() {
  std_repo
  hook prompt-submit "$(p_prompt s1)"
  printf 'new\n' > "$R/b.txt"
  hook agent-stop "$(p_stop s1)"
  is_block && out_has '(b.txt)'
}

case11() {
  std_repo
  printf 'edited before the turn\n' >> "$R/a.txt"
  hook prompt-submit "$(p_prompt s1)"
  hook agent-stop "$(p_stop s1)"
  local first=$OUT
  printf 'edited during the turn\n' >> "$R/a.txt"
  hook agent-stop "$(p_stop s1)"
  [ "$first" = '{}' ] && is_block && out_has '(a.txt)'
}

case12() {
  std_repo
  hook prompt-submit "$(p_prompt s1)"
  printf 'two\n' >> "$R/a.txt"
  commit_all "change a"
  hook agent-stop "$(p_stop s1)"
  is_block && out_has '(a.txt)'
}

case13() {
  std_repo
  hook agent-stop "$(p_stop never-seen)"
  is_empty_obj && [[ $ERR == project-docs:* ]]
}

case14() {
  new_repo
  enable_repo 0
  hook session-start "$(p_start s1)"
  local ok=0
  out_has 'project-docs is enabled' || ok=1
  hook prompt-submit "$(p_prompt s1)"
  printf 'new\n' > "$R/a.txt"
  hook agent-stop "$(p_stop s1)"
  is_block && out_has '(a.txt)' && return $ok
  return 1
}

case15() {
  std_repo
  local name=$'dir with space/caf\xc3\xa9 \xe2\x82\xac.txt'
  mkdir -p "$R/dir with space"
  hook prompt-submit "$(p_prompt s1)"
  printf 'x\n' > "$R/$name"
  hook agent-stop "$(p_stop s1)"
  is_block && out_has "($name)"
}

case16() {
  std_repo
  hook prompt-submit "$(p_prompt s1)"
  printf 'two\n' >> "$R/a.txt"
  hook prompt-submit "$(p_prompt s2)"
  hook agent-stop "$(p_stop s1)"
  local first=$OUT
  hook agent-stop "$(p_stop s2)"
  [[ $first == '{"decision":"block"'* ]] && is_empty_obj
}

case17() {
  std_repo
  local dir
  dir="$(gitdir)/project-docs/snapshots"
  mkdir -p "$dir"
  printf 'HEAD x\nLOG y\n' > "$dir/old.txt"
  printf 'HEAD x\nLOG y\n' > "$dir/fresh.txt"
  touch -d '10 days ago' "$dir/old.txt"
  hook session-start "$(p_start s1)"
  [ ! -e "$dir/old.txt" ] && [ -e "$dir/fresh.txt" ]
}

case18() {
  std_repo
  hook agent-stop "$(p_stop never-seen)"          # writes a note to stderr
  local ok=0
  [ "$OUT" = '{}' ] || ok=1
  [[ $ERR == project-docs:* ]] || ok=1
  [ "$BADJSON" = 0 ] || ok=1                       # every output so far was one valid JSON object
  hook prompt-submit "$(p_prompt s1)"
  printf 'two\n' >> "$R/a.txt"
  hook agent-stop "$(p_stop s1)"
  is_block || ok=1
  [ "$BADJSON" = 0 ] || ok=1
  return $ok
}

case19() { # additional: payload cwd with JSON-escaped backslashes and a lowercase drive letter
  case $(uname -s) in MINGW* | MSYS*) ;; *) echo "      (skipped: not Windows)"; return 0 ;; esac
  std_repo
  local win
  win=$(cd "$R" && pwd -W)
  win="$(printf '%s' "${win:0:1}" | tr 'A-Z' 'a-z')${win:1}"
  CWDJ=$(printf '%s' "$win" | sed 's#/#\\\\#g')
  hook prompt-submit "$(p_prompt s1)"
  printf 'two\n' >> "$R/a.txt"
  hook agent-stop "$(p_stop s1)"
  is_block && out_has '(a.txt)'
}

case20() { # additional, SPEC 8.4: a prompt starting with "project-docs:" keeps the snapshot
  std_repo
  hook prompt-submit "$(p_prompt s1)"
  printf 'two\n' >> "$R/a.txt"
  hook agent-stop "$(p_stop s1)"
  local first=$OUT
  hook prompt-submit "$(p_prompt s1 'project-docs: files changed this turn (a.txt) but nothing was logged')"
  hook agent-stop "$(p_stop s1)"
  [[ $first == '{"decision":"block"'* ]] && is_block
}

case21() { # additional, SPEC 9.2: a damaged marker (BOM or CR on line 1) means "not enabled" for the hooks
  local ok=0 ev log
  std_repo
  log=$R/docs/project-docs/log.md
  printf '\xef\xbb\xbf' | cat - "$log" > "$log.new" && mv -f "$log.new" "$log"      # BOM on line 1
  for ev in session-start prompt-submit agent-stop; do
    hook "$ev" "$(p_start s1)"
    is_empty_obj || ok=1
  done
  { printf '<!-- project-docs: v1 -->\r\n'; tail -n +2 "$TEMPLATES/log.md"; } > "$log"   # CR on line 1
  for ev in session-start prompt-submit agent-stop; do
    hook "$ev" "$(p_start s1)"
    is_empty_obj || ok=1
  done
  return $ok
}

# ---- timing ----------------------------------------------------------------

now_ms() { echo $(($(date +%s%N) / 1000000)); }
median_of() { # runs: event json
  local t0 t1 i
  local -a t=()
  for i in 1 2 3 4 5; do
    t0=$(now_ms)
    (cd "$R" && printf '%s' "$2" | bash "$HOOK" "$1" >/dev/null 2>&1)
    t1=$(now_ms)
    t+=($((t1 - t0)))
  done
  printf '%s\n' "${t[@]}" | sort -n | sed -n 3p
}
timing() {
  echo "Building a repository with 10000 tracked files..."
  new_repo
  enable_repo 2
  local d f
  for d in $(seq 1 100); do
    mkdir -p "$R/src/d$d"
    for f in $(seq 1 100); do printf '%s\n' "$d $f" > "$R/src/d$d/f$f.txt"; done
  done
  commit_all big
  echo "tracked files: $(git -C "$R" ls-files | wc -l)"
  echo "median of 5, milliseconds, process start included:"
  echo "  session-start            $(median_of session-start "$(p_start t1)")"
  echo "  prompt-submit (clean)    $(median_of prompt-submit "$(p_prompt t1)")"
  for f in $(seq 1 20); do printf 'x\n' >> "$R/src/d1/f$f.txt"; done
  echo "  prompt-submit (20 dirty) $(median_of prompt-submit "$(p_prompt t1)")"
  add_log_entry
  echo "  agent-stop (20 dirty)    $(median_of agent-stop "$(p_stop t1)")"
}

# ---- run -------------------------------------------------------------------

if [ "${1:-}" = '--timing' ]; then
  timing
  exit 0
fi

echo "hook.sh: $HOOK"
echo "bash $BASH_VERSION, $(git --version)"
check "01 not a git repo -> {}" case01
check "02 not enabled -> {} for all events" case02
check "03 session-start with entries: top entry only" case03
check "04 session-start with no entries" case04
check "05 no change -> {}" case05
check "06 modified tracked file -> block, path listed" case06
check "07 modified file plus log.md changed -> {}" case07
check "08 stop_hook_active true -> {}" case08
check "09 only docs/project-docs/ changed -> {}" case09
check "10 untracked new file -> block" case10
check "11 file modified before and during the turn -> block" case11
check "12 commit during the turn, no log -> block" case12
check "13 no snapshot -> {} with stderr note" case13
check "14 repository with no commits" case14
check "15 path with spaces and non-ASCII characters" case15
check "16 two sessions interleaved" case16
check "17 snapshots older than 7 days removed at session-start" case17
check "18 one JSON object on stdout; stderr does not leak" case18
check "19 (extra) escaped Windows cwd in payload" case19
check "20 (extra) prompt starting with project-docs: keeps snapshot" case20
check "21 (extra) damaged marker (BOM or CR on line 1) -> {}" case21

echo
echo "passed: $PASS  failed: $FAIL  invalid-JSON outputs: $BADJSON"
[ "$FAIL" = 0 ] && [ "$BADJSON" = 0 ]
