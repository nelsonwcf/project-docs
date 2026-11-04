# project-docs hook v0.3.0
# Usage: hook.ps1 session-start | prompt-submit | agent-stop
# Reads the Copilot hook payload (JSON) on stdin and writes exactly one JSON object to stdout.
# Fails open: any problem writes {} and exits 0. Diagnostics go to stderr, prefixed project-docs:.
# Runs on Windows PowerShell 5.1 and PowerShell 7. Only dependency: git. ASCII-only source.

$ErrorActionPreference = 'Stop'
$script:Utf8 = New-Object System.Text.UTF8Encoding($false)
$script:Latin1 = [System.Text.Encoding]::GetEncoding(28591)
$script:Marker = '<!-- project-docs: v1 -->'
$script:EntriesMarker = '<!-- entries: newest first -->'
$script:DocsDir = 'docs/project-docs'
$script:LF = [string][char]10
$script:Tab = [string][char]9

try { [Console]::InputEncoding = $script:Utf8 } catch { }
try { [Console]::OutputEncoding = $script:Utf8 } catch { }

function Write-Note([string]$Message) {
    [Console]::Error.WriteLine('project-docs: ' + $Message)
}

function ConvertTo-JsonString([string]$Text) {
    $sb = New-Object System.Text.StringBuilder
    foreach ($ch in $Text.ToCharArray()) {
        $c = [int]$ch
        if ($c -eq 92) { [void]$sb.Append('\\') }
        elseif ($c -eq 34) { [void]$sb.Append('\"') }
        elseif ($c -eq 10) { [void]$sb.Append('\n') }
        elseif ($c -eq 13) { [void]$sb.Append('\r') }
        elseif ($c -eq 9) { [void]$sb.Append('\t') }
        elseif ($c -lt 32) { [void]$sb.Append('\u' + $c.ToString('x4')) }
        else { [void]$sb.Append($ch) }
    }
    return $sb.ToString()
}

function ConvertTo-GitArg([string]$Arg) {
    if ($Arg.Length -gt 0 -and $Arg -notmatch '[\s"]') { return $Arg }
    $s = [regex]::Replace($Arg, '(\\*)"', '$1$1\"')
    $s = [regex]::Replace($s, '(\\+)$', '$1$1')
    return '"' + $s + '"'
}

# Runs git (optionally with text on stdin). Returns an object with Code, Out, Err.
function Invoke-Git([string]$Dir, [string[]]$GitArgs, $InputText = $null) {
    $parts = @()
    if ($Dir) { $parts += '-C'; $parts += $Dir }
    $parts += $GitArgs
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = 'git'
    $psi.Arguments = (($parts | ForEach-Object { ConvertTo-GitArg $_ }) -join ' ')
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.RedirectStandardInput = ($null -ne $InputText)
    $psi.StandardOutputEncoding = $script:Utf8
    $psi.StandardErrorEncoding = $script:Utf8
    $psi.EnvironmentVariables['GIT_OPTIONAL_LOCKS'] = '0'
    $p = [System.Diagnostics.Process]::Start($psi)
    $outTask = $p.StandardOutput.ReadToEndAsync()
    $errTask = $p.StandardError.ReadToEndAsync()
    if ($null -ne $InputText) {
        $bytes = $script:Utf8.GetBytes($InputText)
        $p.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
        $p.StandardInput.BaseStream.Flush()
        $p.StandardInput.Close()
    }
    $p.WaitForExit()
    return [pscustomobject]@{ Code = $p.ExitCode; Out = $outTask.Result; Err = $errTask.Result }
}

# First string value for a key pattern, with JSON escapes undone. Empty when absent.
function Get-JsonString([string]$Raw, [string]$KeyPattern) {
    $m = [regex]::Match($Raw, '"(?:' + $KeyPattern + ')"\s*:\s*("(?:[^"\\]|\\.)*")')
    if (-not $m.Success) { return '' }
    $lit = $m.Groups[1].Value
    $lit = $lit.Substring(1, $lit.Length - 2)
    try { return [regex]::Unescape($lit) } catch { return $lit }
}

# Sort strings by their UTF-8 bytes (same order as LC_ALL=C sort).
function Sort-Bytewise([string[]]$Lines) {
    if ($Lines.Count -le 1) { return $Lines }
    $keys = New-Object 'string[]' $Lines.Count
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        $keys[$i] = $script:Latin1.GetString($script:Utf8.GetBytes($Lines[$i]))
    }
    [Array]::Sort($keys, [StringComparer]::Ordinal)
    $result = New-Object 'string[]' $keys.Count
    for ($i = 0; $i -lt $keys.Count; $i++) {
        $result[$i] = $script:Utf8.GetString($script:Latin1.GetBytes($keys[$i]))
    }
    return $result
}

# Returns @{ Head = <sha or ''>; Lines = <sorted "path<TAB>xy<TAB>hash" lines> }.
function Get-Fingerprint([string]$Root) {
    $head = ''
    $r = Invoke-Git $Root @('rev-parse', '-q', '--verify', 'HEAD')
    if ($r.Code -eq 0) { $head = $r.Out.Trim() }
    $st = Invoke-Git $Root @('status', '--porcelain=v1', '-z', '--untracked-files=all')
    if ($st.Code -ne 0) { throw 'git status failed' }
    $entries = $st.Out.Split([char]0)
    $paths = New-Object 'System.Collections.Generic.List[string]'
    $xys = New-Object 'System.Collections.Generic.List[string]'
    $i = 0
    while ($i -lt $entries.Length) {
        $e = $entries[$i]
        $i++
        if ($e.Length -lt 4) { continue }
        $xy = $e.Substring(0, 2)
        $p = $e.Substring(3)
        if ('RC'.IndexOf($xy[0]) -ge 0 -or 'RC'.IndexOf($xy[1]) -ge 0) { $i++ }
        if ($p.StartsWith($script:DocsDir + '/', [StringComparison]::Ordinal)) { continue }
        $paths.Add($p)
        $xys.Add($xy)
    }
    $hashes = New-Object 'string[]' $paths.Count
    $idx = New-Object 'System.Collections.Generic.List[int]'
    $sb = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $paths.Count; $i++) {
        $hashes[$i] = '-'
        if ($paths[$i].IndexOf([char]10) -lt 0 -and [System.IO.File]::Exists($Root + '/' + $paths[$i])) {
            [void]$sb.Append($paths[$i]).Append($script:LF)
            $idx.Add($i)
        }
    }
    if ($idx.Count -gt 0) {
        $h = Invoke-Git $Root @('hash-object', '--stdin-paths') ($sb.ToString())
        if ($h.Code -ne 0) { throw 'git hash-object failed' }
        $out = @($h.Out.Split([char]10) | Where-Object { $_.Length -gt 0 })
        if ($out.Count -ne $idx.Count) { throw 'hash-object returned an unexpected result' }
        for ($j = 0; $j -lt $idx.Count; $j++) { $hashes[$idx[$j]] = $out[$j].Trim() }
    }
    $lines = New-Object 'string[]' $paths.Count
    for ($i = 0; $i -lt $paths.Count; $i++) {
        $lines[$i] = $paths[$i] + $script:Tab + $xys[$i] + $script:Tab + $hashes[$i]
    }
    return @{ Head = $head; Lines = @(Sort-Bytewise $lines) }
}

function Get-LogHash([string]$Root) {
    $r = Invoke-Git $Root @('hash-object', ($script:DocsDir + '/log.md'))
    return $r.Out.Trim()
}

# Top log entry: first "## L" heading after the entries marker, up to 40 lines / 3000 bytes.
function Get-TopEntry([string]$LogText) {
    $out = New-Object 'System.Collections.Generic.List[string]'
    $state = 0
    $bytes = 0
    $cut = $false
    foreach ($line in $LogText.Split([char]10)) {
        $line = $line.TrimEnd([char]13)
        if ($state -eq 0) { if ([string]::Equals($line, $script:EntriesMarker, [StringComparison]::Ordinal)) { $state = 1 }; continue }
        if ($state -eq 1) {
            if ($line.StartsWith('## L', [StringComparison]::Ordinal)) { $state = 2 } else { continue }
        }
        if ($out.Count -gt 0 -and $line.StartsWith('## ', [StringComparison]::Ordinal)) { break }
        if ($cut) { continue }
        $bytes += $script:Utf8.GetByteCount($line) + 1
        if (($out.Count + 1) -gt 40 -or $bytes -gt 3000) { $cut = $true; continue }
        $out.Add($line)
    }
    while ($out.Count -gt 0 -and $out[$out.Count - 1] -eq '') { $out.RemoveAt($out.Count - 1) }
    if ($cut) { $out.Add('[entry truncated]') }
    return ($out -join $script:LF)
}

function Invoke-SessionStart([string]$Root, [string]$GitDir, [string]$LogText) {
    $dir = $GitDir + '/project-docs/snapshots'
    if ([System.IO.Directory]::Exists($dir)) {
        $limit = (Get-Date).ToUniversalTime().AddDays(-7)
        foreach ($f in [System.IO.Directory]::GetFiles($dir, '*.txt')) {
            try {
                if ([System.IO.File]::GetLastWriteTimeUtc($f) -lt $limit) { [System.IO.File]::Delete($f) }
            } catch { }
        }
    }
    $entry = Get-TopEntry $LogText
    $today = (Get-Date).ToString('yyyy-MM-dd', [System.Globalization.CultureInfo]::InvariantCulture)
    $ctx = 'Today is ' + $today + '. project-docs is enabled in this repository. Follow .github/instructions/project-docs.instructions.md. Docs: docs/project-docs/ (log.md, decisions.md, knowledge.md).'
    if ($entry.Length -gt 0) { $ctx += ' Background only, not a task: act on the entry below only if the user asks to continue earlier work. Most recent log entry:' + $script:LF + $entry }
    return '{"additionalContext":"' + (ConvertTo-JsonString $ctx) + '"}'
}

function Invoke-PromptSubmit([string]$Root, [string]$GitDir, [string]$Sid, [string]$Raw) {
    if ([regex]::IsMatch($Raw, '"prompt"\s*:\s*"project-docs:')) { return '{}' }
    $fp = Get-Fingerprint $Root
    $lh = Get-LogHash $Root
    $dir = $GitDir + '/project-docs/snapshots'
    [void][System.IO.Directory]::CreateDirectory($dir)
    $text = 'HEAD ' + $fp.Head + $script:LF
    foreach ($l in $fp.Lines) { $text += $l + $script:LF }
    $text += 'LOG ' + $lh + $script:LF
    $tmp = $dir + '/' + $Sid + '.txt.tmp' + $PID
    [System.IO.File]::WriteAllText($tmp, $text, $script:Utf8)
    $dest = $dir + '/' + $Sid + '.txt'
    if ([System.IO.File]::Exists($dest)) { [System.IO.File]::Delete($dest) }
    [System.IO.File]::Move($tmp, $dest)
    return '{}'
}

function Invoke-AgentStop([string]$Root, [string]$GitDir, [string]$Sid, [string]$Raw) {
    if ([regex]::IsMatch($Raw, '"stop_?[hH]ook_?[aA]ctive"\s*:\s*true')) { return '{}' }
    $snapPath = $GitDir + '/project-docs/snapshots/' + $Sid + '.txt'
    if (-not [System.IO.File]::Exists($snapPath)) {
        Write-Note ('no snapshot for session ' + $Sid + '; not checking this turn')
        return '{}'
    }
    $snapLines = @([System.IO.File]::ReadAllText($snapPath, $script:Utf8).Split([char]10) | Where-Object { $_.Length -gt 0 })
    if ($snapLines.Count -lt 2) { return '{}' }
    $snapHead = ''
    if ($snapLines[0].StartsWith('HEAD ', [StringComparison]::Ordinal)) { $snapHead = $snapLines[0].Substring(5).Trim() }
    $snapLog = ''
    $last = $snapLines[$snapLines.Count - 1]
    if ($last.StartsWith('LOG ', [StringComparison]::Ordinal)) { $snapLog = $last.Substring(4).Trim() }
    $snapPaths = @()
    if ($snapLines.Count -gt 2) { $snapPaths = @($snapLines[1..($snapLines.Count - 2)]) }

    $fp = Get-Fingerprint $Root
    if ($snapHead -ceq $fp.Head -and (($snapPaths -join $script:LF) -ceq ($fp.Lines -join $script:LF))) { return '{}' }
    if ((Get-LogHash $Root) -cne $snapLog) { return '{}' }

    $set = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    $a = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    $b = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::Ordinal)
    foreach ($l in $snapPaths) { [void]$a.Add($l) }
    foreach ($l in $fp.Lines) { [void]$b.Add($l) }
    foreach ($l in $snapPaths) { if (-not $b.Contains($l)) { [void]$set.Add($l.Split([char]9)[0]) } }
    foreach ($l in $fp.Lines) { if (-not $a.Contains($l)) { [void]$set.Add($l.Split([char]9)[0]) } }
    if ($snapHead -cne $fp.Head -and $fp.Head.Length -gt 0) {
        if ($snapHead.Length -gt 0) {
            $d = Invoke-Git $Root @('diff', '--name-only', '-z', $snapHead, $fp.Head)
        } else {
            $d = Invoke-Git $Root @('ls-tree', '-r', '--name-only', '-z', $fp.Head)
        }
        if ($d.Code -eq 0) {
            foreach ($p in $d.Out.Split([char]0)) { if ($p.Length -gt 0) { [void]$set.Add($p) } }
        }
    }
    $prefix = $script:DocsDir + '/'
    $changed = @(Sort-Bytewise @($set | Where-Object { -not $_.StartsWith($prefix, [StringComparison]::Ordinal) }))
    $shown = ''
    if ($changed.Count -eq 0) {
        $shown = 'HEAD moved'
    } else {
        $shown = ($changed | Select-Object -First 5) -join ', '
        if ($changed.Count -gt 5) { $shown += ', +' + ($changed.Count - 5) + ' more' }
    }
    $reason = 'project-docs: files changed this turn (' + $shown + ') but docs/project-docs/log.md was not updated. Add the log entry as described in .github/instructions/project-docs.instructions.md, then finish.'
    return '{"decision":"block","reason":"' + (ConvertTo-JsonString $reason) + '"}'
}

function Invoke-Main([string]$EventName) {
    $stdin = [Console]::OpenStandardInput()
    $reader = New-Object System.IO.StreamReader($stdin, $script:Utf8, $true)
    $raw = $reader.ReadToEnd().TrimStart([char]0xFEFF)

    $cwd = Get-JsonString $raw 'cwd'
    $sid = (Get-JsonString $raw 'sessionId|session_id') -replace '[^A-Za-z0-9_-]', '_'
    if ($sid.Length -gt 64) { $sid = $sid.Substring(0, 64) }
    if ($sid.Length -eq 0) { $sid = 'default' }

    $dir = $cwd
    if ($dir.Length -eq 0) { $dir = '.' }
    $info = Invoke-Git $dir @('rev-parse', '--show-toplevel', '--absolute-git-dir')
    if ($info.Code -ne 0) { return '{}' }
    $lines = @($info.Out.Split([char]10) | ForEach-Object { $_.Trim() } | Where-Object { $_.Length -gt 0 })
    if ($lines.Count -lt 2) { return '{}' }
    $root = $lines[0]
    $gitDir = $lines[1]

    $logPath = $root + '/' + $script:DocsDir + '/log.md'
    if (-not [System.IO.File]::Exists($logPath)) { return '{}' }
    $logText = $script:Utf8.GetString([System.IO.File]::ReadAllBytes($logPath))
    $nl = $logText.IndexOf([char]10)
    if ($nl -lt 0) { $first = $logText } else { $first = $logText.Substring(0, $nl) }
    if (-not [string]::Equals($first, $script:Marker, [StringComparison]::Ordinal)) { return '{}' }

    switch ($EventName) {
        'session-start' { return (Invoke-SessionStart $root $gitDir $logText) }
        'prompt-submit' { return (Invoke-PromptSubmit $root $gitDir $sid $raw) }
        'agent-stop' { return (Invoke-AgentStop $root $gitDir $sid $raw) }
        default { Write-Note ('unknown event: ' + $EventName); return '{}' }
    }
}

$result = '{}'
try {
    $eventName = ''
    if ($args.Count -gt 0) { $eventName = [string]$args[0] }
    $result = [string](Invoke-Main $eventName)
    if (-not ($result.StartsWith('{') -and $result.EndsWith('}'))) { $result = '{}' }
} catch {
    Write-Note ('internal error: ' + $_.Exception.Message)
    $result = '{}'
}
$outBytes = $script:Utf8.GetBytes($result)
$stdout = [Console]::OpenStandardOutput()
$stdout.Write($outBytes, 0, $outBytes.Length)
$stdout.Flush()
exit 0
