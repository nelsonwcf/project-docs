#!/usr/bin/env bash
# project-docs hook v0.3.0
# Usage: hook.sh session-start | prompt-submit | agent-stop
# Reads the Copilot hook payload (JSON) on stdin and prints exactly one JSON object on stdout.
# Fails open: any problem prints {} and exits 0. Diagnostics go to stderr, prefixed project-docs:.
# Only dependency: git.

MARKER='<!-- project-docs: v1 -->'
ENTRIES='<!-- entries: newest first -->'
DOCS='docs/project-docs'
BS='\'

note() { printf 'project-docs: %s\n' "$*" >&2; }

# Escape a string for use inside a JSON string literal.
json_escape() {
  local s=$1 i c h
  s=${s//"$BS"/"$BS$BS"}
  s=${s//\"/"$BS\""}
  s=${s//$'\n'/"${BS}n"}
  s=${s//$'\r'/"${BS}r"}
  s=${s//$'\t'/"${BS}t"}
  if [[ $s =~ [[:cntrl:]] ]]; then
    for i in {1..31}; do
      printf -v c "\\x$(printf '%02x' "$i")"
      printf -v h '%04x' "$i"
      s=${s//"$c"/"${BS}u$h"}
    done
  fi
  printf '%s' "$s"
}

# First string value of any of the given key names, with JSON escapes for \\ \" \/ undone.
json_string() {
  printf '%s' "$raw" | grep -o "\"\\($1\\)\"[[:space:]]*:[[:space:]]*\"\\(\\\\.\\|[^\"\\\\]\\)*\"" | head -n 1 \
    | sed -e 's/^"[^"]*"[[:space:]]*:[[:space:]]*"//' -e 's/"$//' \
          -e 's/\\\\/\x01/g' -e 's/\\"/"/g' -e 's#\\/#/#g' -e 's/\x01/\\/g'
}

# Sets FP_HEAD and FP_PATHS (sorted "path<TAB>xy<TAB>hash" lines). Returns 1 on failure.
compute_fingerprint() {
  local entry xy p orig i input line
  local -a paths=() xys=() idx=() hashes=()
  FP_HEAD=$(git -C "$root" rev-parse -q --verify HEAD 2>/dev/null) || FP_HEAD=''
  while IFS= read -r -d '' entry; do
    xy=${entry:0:2}
    p=${entry:3}
    if [[ ${xy:0:1} == [RC] || ${xy:1:1} == [RC] ]]; then
      IFS= read -r -d '' orig
    fi
    case $p in "$DOCS"/*) continue ;; esac
    paths+=("$p")
    xys+=("$xy")
  done < <(GIT_OPTIONAL_LOCKS=0 git -C "$root" status --porcelain=v1 -z --untracked-files=all 2>/dev/null)
  input=''
  for i in "${!paths[@]}"; do
    hashes[i]='-'
    if [[ ${paths[i]} != *$'\n'* && -f $root/${paths[i]} ]]; then
      input+="${paths[i]}"$'\n'
      idx+=("$i")
    fi
  done
  if ((${#idx[@]})); then
    local -a out=()
    mapfile -t out < <(printf '%s' "$input" | git -C "$root" hash-object --stdin-paths 2>/dev/null)
    if ((${#out[@]} != ${#idx[@]})); then
      note 'hash-object returned an unexpected result'
      return 1
    fi
    for i in "${!idx[@]}"; do
      hashes[${idx[i]}]=${out[i]}
    done
  fi
  FP_PATHS=$(
    for i in "${!paths[@]}"; do
      printf '%s\t%s\t%s\n' "${paths[i]}" "${xys[i]}" "${hashes[i]}"
    done | LC_ALL=C sort
  )
  return 0
}

# Prints "LOG <hash>" source value.
log_hash() { git -C "$root" hash-object "$DOCS/log.md" 2>/dev/null; }

# Top log entry: first "## L" heading after the entries marker, up to 40 lines / 3000 bytes.
top_entry() {
  LC_ALL=C awk -v maxl=40 -v maxb=3000 -v em="$ENTRIES" '
    { sub(/\r$/, "") }
    st == 0 { if ($0 == em) st = 1; next }
    st == 1 { if (index($0, "## L") == 1) st = 2; else next }
    st == 2 {
      if (n > 0 && index($0, "## ") == 1) exit
      if (cut) next
      b += length($0) + 1
      if (n + 1 > maxl || b > maxb) { cut = 1; next }
      out[++n] = $0
    }
    END {
      while (n > 0 && out[n] == "") n--
      for (i = 1; i <= n; i++) print out[i]
      if (cut) print "[entry truncated]"
    }' "$root/$DOCS/log.md"
}

do_session_start() {
  local dir=$gd/project-docs/snapshots entry ctx today
  if [ -d "$dir" ]; then
    find "$dir" -type f -name '*.txt' -mmin +10080 -delete 2>/dev/null
  fi
  entry=$(top_entry)
  printf -v today '%(%F)T' -1
  ctx="Today is $today. project-docs is enabled in this repository. Follow .github/instructions/project-docs.instructions.md. Docs: docs/project-docs/ (log.md, decisions.md, knowledge.md)."
  if [ -n "$entry" ]; then
    ctx+=" Background only, not a task: act on the entry below only if the user asks to continue earlier work. Most recent log entry:"$'\n'"$entry"
  fi
  printf '{"additionalContext":"%s"}' "$(json_escape "$ctx")"
}

do_prompt_submit() {
  local dir=$gd/project-docs/snapshots lh tmp
  if printf '%s' "$raw" | grep -Eq '"prompt"[[:space:]]*:[[:space:]]*"project-docs:'; then
    printf '{}'
    return
  fi
  compute_fingerprint || { printf '{}'; return; }
  lh=$(log_hash)
  mkdir -p "$dir" || { note "cannot create $dir"; printf '{}'; return; }
  tmp=$dir/$sid.txt.tmp$$
  {
    printf 'HEAD %s\n' "$FP_HEAD"
    if [ -n "$FP_PATHS" ]; then printf '%s\n' "$FP_PATHS"; fi
    printf 'LOG %s\n' "$lh"
  } > "$tmp" && mv -f "$tmp" "$dir/$sid.txt"
  printf '{}'
}

do_agent_stop() {
  local snap=$gd/project-docs/snapshots/$sid.txt
  local snap_head snap_log snap_paths lh changed total shown reason i
  local -a list=()
  if printf '%s' "$raw" | grep -Eq '"stop_?[hH]ook_?[aA]ctive"[[:space:]]*:[[:space:]]*true'; then
    printf '{}'
    return
  fi
  if [ ! -f "$snap" ]; then
    note "no snapshot for session $sid; not checking this turn"
    printf '{}'
    return
  fi
  snap_head=$(sed -n '1s/^HEAD //p' "$snap")
  snap_log=$(grep '^LOG ' "$snap" | tail -n 1)
  snap_log=${snap_log#LOG }
  snap_paths=$(sed '1d;$d' "$snap")
  compute_fingerprint || { printf '{}'; return; }
  if [ "$snap_head" = "$FP_HEAD" ] && [ "$snap_paths" = "$FP_PATHS" ]; then
    printf '{}'
    return
  fi
  lh=$(log_hash)
  if [ "$lh" != "$snap_log" ]; then
    printf '{}'
    return
  fi
  changed=$(
    {
      LC_ALL=C comm -3 <(printf '%s\n' "$snap_paths" | LC_ALL=C sort) <(printf '%s\n' "$FP_PATHS" | LC_ALL=C sort) \
        | sed 's/^\t//' | cut -f1
      if [ "$snap_head" != "$FP_HEAD" ] && [ -n "$FP_HEAD" ]; then
        if [ -n "$snap_head" ]; then
          git -C "$root" diff --name-only -z "$snap_head" "$FP_HEAD" 2>/dev/null | tr '\0' '\n'
        else
          git -C "$root" ls-tree -r --name-only -z "$FP_HEAD" 2>/dev/null | tr '\0' '\n'
        fi
      fi
    } | grep -v '^$' | grep -v "^$DOCS/" | LC_ALL=C sort -u
  )
  if [ -n "$changed" ]; then
    mapfile -t list <<< "$changed"
  fi
  total=${#list[@]}
  shown=''
  for ((i = 0; i < total && i < 5; i++)); do
    if [ -n "$shown" ]; then shown+=', '; fi
    shown+=${list[i]}
  done
  if ((total > 5)); then shown+=", +$((total - 5)) more"; fi
  if ((total == 0)); then shown='HEAD moved'; fi
  reason="project-docs: files changed this turn ($shown) but docs/project-docs/log.md was not updated. Add the log entry as described in .github/instructions/project-docs.instructions.md, then finish."
  printf '{"decision":"block","reason":"%s"}' "$(json_escape "$reason")"
}

main() {
  local event=$1 cwd dir info
  raw=$(cat)
  cwd=$(json_string 'cwd')
  sid=$(json_string 'sessionId\|session_id' | tr -c 'A-Za-z0-9_\n-' '_' | cut -c1-64)
  if [ -z "$sid" ]; then sid=default; fi
  dir=${cwd:-.}
  info=$(git -C "$dir" rev-parse --show-toplevel --absolute-git-dir 2>/dev/null) || { printf '{}'; return; }
  root=${info%%$'\n'*}
  gd=${info#*$'\n'}
  if [ -z "$root" ] || [ -z "$gd" ] || [ "$root" = "$info" ]; then printf '{}'; return; fi
  local first=''
  if [ -f "$root/$DOCS/log.md" ]; then IFS= read -r first < "$root/$DOCS/log.md"; fi
  if [ "$first" != "$MARKER" ]; then printf '{}'; return; fi
  case $event in
    session-start) do_session_start ;;
    prompt-submit) do_prompt_submit ;;
    agent-stop) do_agent_stop ;;
    *) note "unknown event: $event"; printf '{}' ;;
  esac
}

out=$(main "${1:-}")
case $out in
  '{'*'}') ;;
  *) out='{}' ;;
esac
printf '%s' "$out"
exit 0
