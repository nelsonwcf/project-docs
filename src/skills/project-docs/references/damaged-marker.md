# Damaged marker

Used by Step 0 item 3 of SKILL.md. The marker is line 1 of `docs/project-docs/log.md`:
`<!-- project-docs: v1 -->`. A byte-order mark (BOM, bytes `EF BB BF`) in front of it, or a
carriage return (CR) at the end of the line, makes the hooks treat the repository as **not
enabled**: they do nothing, silently. The usual cause is a document written with a terminal
command on Windows PowerShell 5.1.

## Detect (run from the repository root)

bash:

```
head -c 3 docs/project-docs/log.md | od -An -tx1
head -n 1 docs/project-docs/log.md | tr -cd '\r' | wc -c
```

The first command prints `ef bb bf` when there is a BOM. The second prints `1` when line 1 ends
with a CR, `0` otherwise.

PowerShell:

```
$p = (Resolve-Path docs/project-docs/log.md).Path
$b = [System.IO.File]::ReadAllBytes($p)
$bom = ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF)
$lf = [Array]::IndexOf($b, [byte]10)
$cr = ($lf -gt 0 -and $b[$lf - 1] -eq 13)
"BOM: $bom  CR on line 1: $cr"
```

The marker is damaged only when the line equals `<!-- project-docs: v1 -->` after removing a
leading BOM and/or a trailing CR. If line 1 is anything else, it is not a project-docs log:
treat the repository as not enabled.

## Fix (only after the user said yes)

Remove only the BOM and the CR on line 1. Leave every other byte of the file as it is. This is
the one case where a terminal command may change a `docs/project-docs/` file.

bash:

```
f=docs/project-docs/log.md
{ head -n 1 "$f" | sed 's/^\xEF\xBB\xBF//; s/\r$//'; tail -n +2 "$f"; } > "$f.fixed" && mv -f "$f.fixed" "$f"
```

PowerShell:

```
$p = (Resolve-Path docs/project-docs/log.md).Path
$b = [System.IO.File]::ReadAllBytes($p)
$start = 0
if ($b.Length -ge 3 -and $b[0] -eq 0xEF -and $b[1] -eq 0xBB -and $b[2] -eq 0xBF) { $start = 3 }
$lf = [Array]::IndexOf($b, [byte]10, $start)
$out = New-Object System.Collections.Generic.List[byte]
for ($i = $start; $i -lt $b.Length; $i++) {
    if ($lf -gt 0 -and $i -eq ($lf - 1) -and $b[$i] -eq 13) { continue }
    $out.Add($b[$i])
}
[System.IO.File]::WriteAllBytes($p, $out.ToArray())
```

Then repeat the detection: it must report no BOM and no CR. If other lines of the file also end
with a CR, do not change them; tell the user. Go on with state detection (Step 0 item 3).
