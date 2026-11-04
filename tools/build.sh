#!/usr/bin/env bash
# Builds dist/project-docs-skills-<version>.zip from src/ (SPEC 12.4).
# Run in Git Bash or Linux:  bash tools/build.sh
# Steps: copy the shared formats file into both skills, validate everything, stage into
# dist/stage/, zip (with `zip`, else with Windows PowerShell), list the zip to confirm.
# Exits 1 and builds nothing if validation fails.

set -u
export WSLENV="${WSLENV:+$WSLENV:}PD_STAGE:PD_ZIP:PD_JSON"
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SRC=$ROOT/src
DIST=$ROOT/dist
STAGE=$DIST/stage
SKILLS=(project-docs project-docs-regenerate)
ERRORS=0

err() { echo "ERROR: $*" >&2; ERRORS=$((ERRORS + 1)); }
info() { echo "$*"; }

crs_in() { tr -cd '\r' < "$1" | wc -c | tr -d ' '; }
lines_in() { wc -l < "$1" | tr -d ' '; }
trim_file() { tr -d '\r\n ' < "$1"; }

# ---- version ---------------------------------------------------------------

VERSION=$(trim_file "$SRC/skills/project-docs/VERSION" 2>/dev/null)
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "ERROR: src/skills/project-docs/VERSION must hold a version like 0.1.0 (found: '$VERSION')" >&2
  exit 1
fi
info "Package version: $VERSION"

check_versions() {
  local f v
  for f in "$SRC/skills/project-docs/VERSION" "$SRC/skills/project-docs-regenerate/VERSION" \
           "$SRC/skills/project-docs/assets/hooks/project-docs/VERSION"; do
    if [ ! -f "$f" ]; then err "missing $f"; continue; fi
    v=$(trim_file "$f")
    [ "$v" = "$VERSION" ] || err "version mismatch in ${f#"$ROOT"/}: '$v' (expected '$VERSION')"
  done
  for f in "$SRC/skills/project-docs/assets/hooks/project-docs/hook.sh" \
           "$SRC/skills/project-docs/assets/hooks/project-docs/hook.ps1"; do
    if [ ! -f "$f" ]; then err "missing $f"; continue; fi
    [ "$(sed -n 's/\r$//;/^# project-docs hook v/p' "$f" | head -n 1)" = "# project-docs hook v$VERSION" ] || \
      err "header comment '# project-docs hook v$VERSION' not found in ${f#"$ROOT"/}"
  done
}

# ---- shared file -----------------------------------------------------------

copy_formats() {
  local s
  [ -f "$SRC/shared/formats.md" ] || { err "missing src/shared/formats.md"; return; }
  for s in "${SKILLS[@]}"; do
    mkdir -p "$SRC/skills/$s/references"
    cp -f "$SRC/shared/formats.md" "$SRC/skills/$s/references/formats.md"
  done
}

# ---- skill validation ------------------------------------------------------

validate_skill() {
  local s=$1 f first fm key line name desc nlines
  f=$SRC/skills/$s/SKILL.md
  if [ ! -f "$f" ]; then err "missing $s/SKILL.md"; return; fi
  first=$(sed -n 1p "$f" | tr -d '\r')
  [ "$first" = '---' ] || { err "$s/SKILL.md must start with a --- frontmatter line"; return; }
  fm=$(set -o pipefail; awk 'NR == 1 { next } /^---\r?$/ { found = 1; exit } { print } END { if (!found) exit 1 }' "$f" | tr -d '\r') \
    || { err "$s/SKILL.md frontmatter is not closed by ---"; return; }
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    case $line in
      ' '* | $'\t'*) err "$s/SKILL.md frontmatter: continuation lines are not supported: '${line:0:40}'"; continue ;;
    esac
    key=${line%%:*}
    case $key in
      name | description | argument-hint | user-invocable | disable-model-invocation | context) ;;
      *) err "$s/SKILL.md frontmatter: field '$key' is not in the allowed list (PLATFORM-NOTES F1)" ;;
    esac
  done <<< "$fm"
  name=$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | tr -d '"'"'")
  desc=$(printf '%s\n' "$fm" | sed -n 's/^description:[[:space:]]*//p')
  hint=$(printf '%s\n' "$fm" | sed -n 's/^argument-hint:[[:space:]]*//p')
  # Valid YAML (SPEC 1.3): description and argument-hint are double-quoted, no unescaped " inside.
  # An unquoted value containing ": " makes the whole skill silently fail to load.
  quoted_ok() { [[ $1 =~ ^\"([^\"\\]|\\.)*\"$ ]]; }
  if [ -n "$desc" ]; then
    quoted_ok "$desc" || err "$s/SKILL.md description must be one double-quoted YAML string with no unescaped \" inside"
    desc=${desc#\"}
    desc=${desc%\"}
  fi
  if [ -n "$hint" ]; then
    quoted_ok "$hint" || err "$s/SKILL.md argument-hint must be one double-quoted YAML string with no unescaped \" inside"
  fi
  [[ $name =~ ^[a-z0-9-]{1,64}$ ]] || err "$s/SKILL.md name '$name' does not match ^[a-z0-9-]{1,64}\$"
  [ "$name" = "$s" ] || err "$s/SKILL.md name '$name' does not equal the folder name '$s'"
  [ -n "$desc" ] || err "$s/SKILL.md has no description"
  [ "${#desc}" -le 1024 ] || err "$s/SKILL.md description is ${#desc} characters (limit 1024)"
  printf '%s\n' "$fm" | grep -q '^disable-model-invocation:[[:space:]]*true$' || err "$s/SKILL.md must set disable-model-invocation: true (D04)"
  printf '%s\n' "$fm" | grep -q '^argument-hint:' || err "$s/SKILL.md has no argument-hint"
  # Task lock (SPEC 9.1): the body must open with the lock so that a weak model does not continue
  # earlier work from the context. Check the first lines of the body after the frontmatter.
  body=$(awk '/^---\r?$/ { n++; next } n >= 2 && NF { print; if (++c == 6) exit }' "$f" | tr -d '\r')
  [ "$(printf '%s\n' "$body" | sed -n 1p)" = "You were invoked with /$s." ] \
    || err "$s/SKILL.md body must start with the task lock line 'You were invoked with /$s.'"
  printf '%s\n' "$body" | grep -qx 'Your first action is Step 0 item 1\.' \
    || err "$s/SKILL.md task lock must include the line 'Your first action is Step 0 item 1.' in the first lines"
  grep -q '^## Step 0 ' "$f" || err "$s/SKILL.md has no '## Step 0' heading"
  nlines=$(lines_in "$f")
  [ "$nlines" -le 250 ] || err "$s/SKILL.md has $nlines lines (limit 250)"
  info "  $s/SKILL.md: name ok, description ${#desc} chars, $nlines lines"
}

# ---- file hygiene ----------------------------------------------------------

check_files() {
  local f rel n c bom nonascii
  while IFS= read -r f; do
    rel=${f#"$ROOT"/}
    bom=$(head -c3 "$f" | od -An -tx1 | tr -d ' \n')
    [ "$bom" != 'efbbbf' ] || err "$rel has a BOM"
    if command -v iconv > /dev/null 2>&1; then
      iconv -f UTF-8 -t UTF-8 "$f" > /dev/null 2>&1 || err "$rel is not valid UTF-8"
    fi
    case $f in
      *.ps1)
        nonascii=$(LC_ALL=C tr -d '\000-\177' < "$f" | wc -c | tr -d ' ')
        [ "$nonascii" = 0 ] || err "$rel contains non-ASCII bytes ($nonascii)"
        n=$(lines_in "$f")
        c=$(crs_in "$f")
        [ "$n" = "$c" ] || err "$rel must use CRLF line endings on every line (lines: $n, CRs: $c)"
        ;;
      *.sh | *.md | *.json | */VERSION)
        c=$(crs_in "$f")
        [ "$c" = 0 ] || err "$rel must use LF line endings (found $c CR)"
        ;;
    esac
  done < <(find "$SRC/skills" "$SRC/package" -type f 2> /dev/null | LC_ALL=C sort)
}

json_ok() { # file -> 0 when it parses; 2 when no parser is available
  local f=$1 w
  if command -v jq > /dev/null 2>&1; then jq -e . "$f" > /dev/null 2>&1; return; fi
  if python3 -c 'import json' > /dev/null 2>&1; then python3 -c 'import json,sys; json.load(open(sys.argv[1], encoding="utf-8"))' "$f" > /dev/null 2>&1; return; fi
  if command -v node > /dev/null 2>&1; then node -e 'JSON.parse(require("fs").readFileSync(process.argv[1],"utf8"))' "$f" > /dev/null 2>&1; return; fi
  for w in pwsh powershell.exe powershell; do
    if command -v "$w" > /dev/null 2>&1; then
      PD_JSON=$(winpath "$f") "$w" -NoProfile -Command 'try { Get-Content -LiteralPath $env:PD_JSON -Raw | ConvertFrom-Json | Out-Null; exit 0 } catch { exit 1 }' > /dev/null 2>&1
      return
    fi
  done
  return 2
}

winpath() {
  if command -v cygpath > /dev/null 2>&1; then cygpath -w "$1"
  elif command -v wslpath > /dev/null 2>&1; then wslpath -w "$1"
  else printf "%s" "$1"; fi
}

check_json() {
  local f rc
  while IFS= read -r f; do
    json_ok "$f"
    rc=$?
    if [ "$rc" = 2 ]; then
      echo "WARNING: no JSON parser found (jq, python3, node, PowerShell); not validated: ${f#"$ROOT"/}" >&2
    elif [ "$rc" != 0 ]; then
      err "${f#"$ROOT"/} is not valid JSON"
    fi
  done < <(find "$SRC" -type f -name '*.json' | LC_ALL=C sort)
}

# A frontmatter value must be valid YAML: a double-quoted string without an unescaped ", or a
# plain scalar that is not empty, does not start with a YAML indicator (* & ! | > % @ ` [ ] { } , # ? : '),
# and contains neither ": " nor " #". An invalid value makes Copilot drop the file silently.
yaml_value_ok() {
  local v=$1
  [ -n "$v" ] || return 1
  if [[ $v == \"* ]]; then
    [[ $v =~ ^\"([^\"\\]|\\.)*\"$ ]]
    return
  fi
  case ${v:0:1} in
    '*' | '&' | '!' | '|' | '>' | '%' | '@' | '`' | '[' | ']' | '{' | '}' | ',' | '#' | '?' | ':' | "'") return 1 ;;
  esac
  [[ $v == *': '* || $v == *' #'* || $v == *: ]] && return 1
  return 0
}

validate_rules_frontmatter() {
  local f=$SRC/skills/project-docs/assets/rules/project-docs.instructions.md rel fm line key val k
  rel=${f#"$ROOT"/}
  [ -f "$f" ] || return
  [ "$(sed -n 1p "$f" | tr -d '\r')" = '---' ] || { err "$rel must start with a --- frontmatter line"; return; }
  fm=$(set -o pipefail; awk 'NR == 1 { next } /^---\r?$/ { found = 1; exit } { print } END { if (!found) exit 1 }' "$f" | tr -d '\r') \
    || { err "$rel frontmatter is not closed by ---"; return; }
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    key=${line%%:*}
    val=${line#*:}
    val=${val#"${val%%[![:space:]]*}"}
    [[ $line == *:* ]] || { err "$rel frontmatter line is not 'key: value': '${line:0:40}'"; continue; }
    yaml_value_ok "$val" || err "$rel frontmatter '$key' is not valid YAML (quote it with double quotes): '${val:0:50}'"
  done <<< "$fm"
  for k in name description applyTo; do
    printf '%s\n' "$fm" | grep -q "^$k:" || err "$rel frontmatter has no '$k'"
  done
  info "  rules file frontmatter: valid"
}

check_required() {
  local f
  for f in \
    skills/project-docs/SKILL.md skills/project-docs/VERSION skills/project-docs/references/formats.md \
    skills/project-docs/references/migration.md skills/project-docs/references/status.md \
    skills/project-docs/references/damaged-marker.md skills/project-docs/assets/docs/README.md \
    skills/project-docs/assets/docs/log.md skills/project-docs/assets/docs/decisions.md \
    skills/project-docs/assets/docs/knowledge.md \
    skills/project-docs/assets/rules/project-docs.instructions.md \
    skills/project-docs/assets/hooks/project-docs.json \
    skills/project-docs/assets/hooks/project-docs/hook.sh skills/project-docs/assets/hooks/project-docs/hook.ps1 \
    skills/project-docs/assets/hooks/project-docs/VERSION \
    skills/project-docs-regenerate/SKILL.md skills/project-docs-regenerate/VERSION \
    skills/project-docs-regenerate/references/formats.md skills/project-docs-regenerate/references/handout-formats.md \
    package/INSTALL.md package/install.sh package/install.ps1; do
    [ -f "$SRC/$f" ] || err "missing src/$f"
  done
}

# ---- run validation --------------------------------------------------------

info 'Copying shared formats into both skills...'
copy_formats
info 'Validating...'
check_versions
for s in "${SKILLS[@]}"; do validate_skill "$s"; done
validate_rules_frontmatter
check_required
check_files
check_json

if [ "$ERRORS" != 0 ]; then
  echo "Build failed: $ERRORS error(s)." >&2
  exit 1
fi
info 'Validation passed.'

# ---- stage -----------------------------------------------------------------

if [ -z "$STAGE" ] || [ "$STAGE" = '/' ] || [ "${STAGE%/dist/stage}" = "$STAGE" ]; then
  echo "ERROR: unexpected stage path '$STAGE'" >&2
  exit 1
fi
[ -d "$STAGE" ] && rm -rf "$STAGE"
mkdir -p "$STAGE"
for s in "${SKILLS[@]}"; do cp -R "$SRC/skills/$s" "$STAGE/$s"; done
cp "$SRC/package/INSTALL.md" "$SRC/package/install.sh" "$SRC/package/install.ps1" "$STAGE/"
printf '%s\n' "$VERSION" > "$STAGE/VERSION"
chmod +x "$STAGE/install.sh" 2> /dev/null
info "Staged in dist/stage ($(find "$STAGE" -type f | wc -l | tr -d ' ') files)."

# ---- zip -------------------------------------------------------------------

ZIP=$DIST/project-docs-skills-$VERSION.zip
[ -f "$ZIP" ] && rm -f "$ZIP"
if command -v zip > /dev/null 2>&1; then
  (cd "$STAGE" && zip -q -r -X "$ZIP" project-docs project-docs-regenerate INSTALL.md install.sh install.ps1 VERSION)
  METHOD=zip
else
  PSEXE=''
  for w in powershell.exe pwsh powershell; do command -v "$w" > /dev/null 2>&1 && { PSEXE=$w; break; }; done
  if [ -z "$PSEXE" ]; then echo 'ERROR: neither `zip` nor PowerShell is available to create the archive' >&2; exit 1; fi
  PSFILE=$DIST/zip-fallback.ps1
  cat > "$PSFILE" << 'EOF'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$stage = $env:PD_STAGE
$zipPath = $env:PD_ZIP
$fs = [System.IO.File]::Open($zipPath, [System.IO.FileMode]::Create)
$zip = New-Object System.IO.Compression.ZipArchive($fs, [System.IO.Compression.ZipArchiveMode]::Create)
$base = (Get-Item -LiteralPath $stage).FullName.TrimEnd('\') + '\'
foreach ($f in (Get-ChildItem -LiteralPath $stage -Recurse -File)) {
    $rel = $f.FullName.Substring($base.Length).Replace('\', '/')
    $entry = $zip.CreateEntry($rel, [System.IO.Compression.CompressionLevel]::Optimal)
    $out = $entry.Open()
    $in = [System.IO.File]::OpenRead($f.FullName)
    $in.CopyTo($out)
    $in.Dispose()
    $out.Dispose()
}
$zip.Dispose()
$fs.Dispose()
EOF
  PD_STAGE=$(winpath "$STAGE") PD_ZIP=$(winpath "$ZIP") "$PSEXE" -NoProfile -ExecutionPolicy Bypass -File "$(winpath "$PSFILE")" \
    || { echo 'ERROR: PowerShell zip failed' >&2; rm -f "$PSFILE"; exit 1; }
  rm -f "$PSFILE"
  METHOD=powershell
fi
[ -f "$ZIP" ] || { echo 'ERROR: the zip was not created' >&2; exit 1; }

# ---- list and confirm ------------------------------------------------------

if command -v unzip > /dev/null 2>&1; then
  ENTRIES=$(unzip -Z1 "$ZIP")
else
  PD_ZIP=$(winpath "$ZIP") ENTRIES=$(powershell.exe -NoProfile -Command 'Add-Type -AssemblyName System.IO.Compression.FileSystem; $z=[System.IO.Compression.ZipFile]::OpenRead($env:PD_ZIP); $z.Entries | ForEach-Object { $_.FullName }; $z.Dispose()' | tr -d '\r')
fi
COUNT=$(printf '%s\n' "$ENTRIES" | grep -c .)
EXPECTED=$(find "$STAGE" -type f | wc -l | tr -d ' ')
BAD=0
printf '%s\n' "$ENTRIES" | grep -q '\\' && { echo 'ERROR: backslash in zip entry names' >&2; BAD=1; }
for e in INSTALL.md install.sh install.ps1 VERSION project-docs/SKILL.md project-docs-regenerate/SKILL.md; do
  printf '%s\n' "$ENTRIES" | grep -qxF "$e" || { echo "ERROR: zip entry missing: $e" >&2; BAD=1; }
done
[ "$COUNT" = "$EXPECTED" ] || { echo "ERROR: zip has $COUNT entries, stage has $EXPECTED files" >&2; BAD=1; }
[ "$BAD" = 0 ] || exit 1

info "Created ${ZIP#"$ROOT"/} ($METHOD, $COUNT entries, $(wc -c < "$ZIP" | tr -d ' ') bytes):"
printf '%s\n' "$ENTRIES" | sed 's/^/  /'
