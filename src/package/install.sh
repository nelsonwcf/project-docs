#!/usr/bin/env bash
# Installs the project-docs and project-docs-regenerate skills for GitHub Copilot in VS Code.
# Usage:  bash install.sh             install or update
#         bash install.sh --uninstall remove the two skill folders
# Target: ~/.copilot/skills (COPILOT_HOME is not used for skills; see INSTALL.md).

set -u
SKILLS=(project-docs project-docs-regenerate)
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
TARGET=${HOME:-}/.copilot/skills

fail() { echo "ERROR: $*" >&2; exit 1; }

case ${1:-} in
  '' | --install) MODE=install ;;
  --uninstall) MODE=uninstall ;;
  -h | --help) sed -n '2,5p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) fail "unknown option '$1'. Use: bash install.sh [--uninstall]" ;;
esac

[ -n "${HOME:-}" ] || fail 'HOME is not set'

safe_remove() { # remove a skill folder that lives directly under $TARGET
  local p=$1
  case $p in
    "$TARGET"/project-docs | "$TARGET"/project-docs-regenerate | "$TARGET"/.pd-tmp.* | "$TARGET"/.pd-old.*) ;;
    *) fail "refusing to remove unexpected path: $p" ;;
  esac
  [ -e "$p" ] && rm -rf -- "$p"
  return 0
}

wsl_note() {
  if [ -r /proc/version ] && grep -qi microsoft /proc/version; then
    echo
    echo 'Note: this is WSL. VS Code sessions on native Windows read skills from'
    echo '%USERPROFILE%\.copilot\skills; run install.ps1 from Windows PowerShell there as well.'
  fi
}

if [ "$MODE" = uninstall ]; then
  for s in "${SKILLS[@]}"; do
    if [ -e "$TARGET/$s" ]; then
      safe_remove "$TARGET/$s"
      echo "Removed $TARGET/$s"
    else
      echo "Not installed: $TARGET/$s"
    fi
  done
  wsl_note
  echo 'Reload every open VS Code window (Developer: Reload Window in each one).'
  exit 0
fi

# ---- install ---------------------------------------------------------------

[ -f "$HERE/VERSION" ] || fail "VERSION not found next to install.sh ($HERE). Run the script from the unzipped package."
PKGVER=$(tr -d '\r\n ' < "$HERE/VERSION")
for s in "${SKILLS[@]}"; do
  [ -f "$HERE/$s/SKILL.md" ] || fail "$HERE/$s/SKILL.md not found. Run the script from the unzipped package."
done

mkdir -p "$TARGET" || fail "cannot create $TARGET"
TMP=$TARGET/.pd-tmp.$$
safe_remove "$TMP"
mkdir -p "$TMP" || fail "cannot create $TMP"
for s in "${SKILLS[@]}"; do
  cp -R "$HERE/$s" "$TMP/$s" || { safe_remove "$TMP"; fail "copy of $s failed"; }
done

# Swap: move the old copies aside, move the new ones in, then delete the old ones.
for s in "${SKILLS[@]}"; do
  if [ -e "$TARGET/$s" ]; then
    mv "$TARGET/$s" "$TARGET/.pd-old.$s.$$" || { safe_remove "$TMP"; fail "cannot replace $TARGET/$s"; }
  fi
  mv "$TMP/$s" "$TARGET/$s" || fail "cannot move $s into $TARGET"
done
safe_remove "$TMP"
for s in "${SKILLS[@]}"; do
  [ -e "$TARGET/.pd-old.$s.$$" ] && rm -rf -- "${TARGET:?}/.pd-old.$s.$$"
done

# ---- validate --------------------------------------------------------------

bad=0
for s in "${SKILLS[@]}"; do
  f=$TARGET/$s/SKILL.md
  if [ ! -f "$f" ]; then echo "FAIL: $f is missing" >&2; bad=1; continue; fi
  name=$(sed -n '2,/^---\r\{0,1\}$/{s/^name:[[:space:]]*//p;}' "$f" | tr -d '\r"' | head -n 1)
  [ "$name" = "$s" ] || { echo "FAIL: $f has name '$name', expected '$s'" >&2; bad=1; }
  v=$(tr -d '\r\n ' < "$TARGET/$s/VERSION" 2> /dev/null)
  [ "$v" = "$PKGVER" ] || { echo "FAIL: $TARGET/$s/VERSION is '$v', expected '$PKGVER'" >&2; bad=1; }
done
[ "$bad" = 0 ] || fail 'validation failed; see messages above'

echo "Installed project-docs skills $PKGVER into $TARGET:"
for s in "${SKILLS[@]}"; do echo "  $TARGET/$s"; done
wsl_note
echo
echo 'Next: reload every open VS Code window (Developer: Reload Window in each one), then open'
echo 'Chat: Open Customizations > Skills and check that both skills are listed.'
