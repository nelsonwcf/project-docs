# Automated tests for hook.ps1 (SPEC 13.2). Creates throwaway git repos in a temp directory.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File tests/hooks/run-tests.ps1 [-Shell powershell|pwsh] [-Timing]
# -Shell selects the PowerShell that runs hook.ps1 (default: Windows PowerShell 5.1).
# Cases 1-18 are the SPEC cases; 19 to 21 are additions (escaped Windows cwd, SPEC 8.4 rule, damaged marker).
# ASCII-only source.

param(
    [ValidateSet('powershell', 'pwsh')][string]$Shell = 'powershell',
    [switch]$Timing
)

$ErrorActionPreference = 'Continue'
$utf8 = New-Object System.Text.UTF8Encoding($false)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Hook = (Resolve-Path (Join-Path $here '../../src/skills/project-docs/assets/hooks/project-docs/hook.ps1')).Path
$Templates = (Resolve-Path (Join-Path $here '../../src/skills/project-docs/assets/docs')).Path
$Tmp = Join-Path ([System.IO.Path]::GetTempPath()) ('pdtests-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
[void][System.IO.Directory]::CreateDirectory($Tmp)

$script:Pass = 0
$script:Fail = 0
$script:BadJson = 0
$script:R = ''
$script:CwdJ = ''
$script:Out = ''
$script:Err = ''
$script:Bom = $false
$script:Counter = 0
$EmDash = [string][char]0x2014

# ---- helpers ---------------------------------------------------------------

function Write-Text([string]$Path, [string]$Text) {
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path -LiteralPath $dir)) { [void][System.IO.Directory]::CreateDirectory($dir) }
    [System.IO.File]::WriteAllText($Path, $Text, $utf8)
}
function Add-Text([string]$Path, [string]$Text) { [System.IO.File]::AppendAllText($Path, $Text, $utf8) }

function G { & git -C $script:R @args 2>$null | Out-Null }

function New-Dir {
    $script:Counter++
    $script:R = Join-Path $Tmp ('repo' + $script:Counter)
    [void][System.IO.Directory]::CreateDirectory($script:R)
    $script:CwdJ = $script:R.Replace('\', '\\')
}
function New-Repo {
    New-Dir
    G init -q
    G config user.email test@example.com
    G config user.name test
    G config core.autocrlf false
}
function Enable-Repo([int]$Entries = 0) {
    $d = Join-Path $script:R 'docs/project-docs'
    [void][System.IO.Directory]::CreateDirectory($d)
    foreach ($n in 'log.md', 'decisions.md', 'knowledge.md') {
        [System.IO.File]::WriteAllText((Join-Path $d $n), [System.IO.File]::ReadAllText((Join-Path $Templates $n), $utf8), $utf8)
    }
    if ($Entries -eq 2) {
        $t = "`n## L0002 $EmDash 2026-11-02 $EmDash Second step`n- Did: second`n- Next: third`n`n## L0001 $EmDash 2026-11-02 $EmDash First step`n- Did: first`n- Next: second`n"
        Add-Text (Join-Path $d 'log.md') $t
    }
}
function Save-Commit([string]$Message) { G add -A; G commit -q -m $Message }
function Add-LogEntry {
    Add-Text (Join-Path $script:R 'docs/project-docs/log.md') "`n## L0099 $EmDash 2026-11-02 $EmDash Test entry`n- Did: x`n- Next: y`n"
}
function Get-GitDir { (& git -C $script:R rev-parse --absolute-git-dir 2>$null).Trim() }
function New-StdRepo([int]$Entries = 2) {
    New-Repo
    Enable-Repo $Entries
    Write-Text (Join-Path $script:R 'a.txt') "one`n"
    Save-Commit 'init'
}

function Test-JsonObject([string]$Text) {
    if ($script:Bom) { return $false }
    if (-not ($Text.StartsWith('{') -and $Text.EndsWith('}'))) { return $false }
    try {
        $o = $Text | ConvertFrom-Json
        return ($null -ne $o)
    } catch { return $false }
}

# Hook <event> <json>: runs hook.ps1 in the chosen shell with the repository as working directory.
function Invoke-Hook([string]$EventName, [string]$Json) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Shell
    $psi.Arguments = '-NoProfile -ExecutionPolicy Bypass -File "' + $Hook + '" ' + $EventName
    $psi.WorkingDirectory = $script:R
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $p = [System.Diagnostics.Process]::Start($psi)
    $errTask = $p.StandardError.ReadToEndAsync()
    $bytes = $utf8.GetBytes($Json)
    $p.StandardInput.BaseStream.Write($bytes, 0, $bytes.Length)
    $p.StandardInput.BaseStream.Flush()
    $p.StandardInput.Close()
    $ms = New-Object System.IO.MemoryStream
    $p.StandardOutput.BaseStream.CopyTo($ms)
    $p.WaitForExit()
    $raw = $ms.ToArray()
    $script:Bom = ($raw.Length -ge 3 -and $raw[0] -eq 0xEF -and $raw[1] -eq 0xBB -and $raw[2] -eq 0xBF)
    $script:Out = $utf8.GetString($raw)
    $script:Err = $errTask.Result
    if ($p.ExitCode -ne 0 -or -not (Test-JsonObject $script:Out)) {
        $script:BadJson++
        Write-Host ("      invalid output from " + $EventName + " (exit " + $p.ExitCode + "): " + $script:Out)
    }
}

function P-Start([string]$Sid) { '{"sessionId":"' + $Sid + '","timestamp":1,"cwd":"' + $script:CwdJ + '","source":"new","initialPrompt":"hi"}' }
function P-Prompt([string]$Sid, [string]$Prompt = 'do the thing') { '{"sessionId":"' + $Sid + '","timestamp":1,"cwd":"' + $script:CwdJ + '","prompt":"' + $Prompt + '"}' }
function P-Stop([string]$Sid, [string]$Active = 'false') { '{"sessionId":"' + $Sid + '","timestamp":1,"cwd":"' + $script:CwdJ + '","transcriptPath":"t","stopReason":"end_turn","stop_hook_active":' + $Active + '}' }

function Test-EmptyObj { $script:Out -ceq '{}' }
function Test-Block { $script:Out.StartsWith('{"decision":"block","reason":"project-docs: files changed this turn (', [StringComparison]::Ordinal) }
function Test-Has([string]$Text) { $script:Out.Contains($Text) }
function Test-TodayLine {
    # SPEC 8.6: the context text starts with "Today is YYYY-MM-DD." (local date) followed by the fixed sentence.
    $d = (Get-Date).ToString("yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture)
    $script:Out.StartsWith('{"additionalContext":"Today is ' + $d + '. project-docs is enabled in this repository.', [StringComparison]::Ordinal)
}

function Check([string]$Name, [scriptblock]$Case) {
    $ok = $false
    try { $ok = [bool](& $Case) } catch { Write-Host ('      exception: ' + $_.Exception.Message) }
    if ($ok) {
        $script:Pass++
        Write-Host ('PASS  ' + $Name)
    } else {
        $script:Fail++
        Write-Host ('FAIL  ' + $Name)
        Write-Host ('      out: ' + $script:Out)
        Write-Host ('      err: ' + $script:Err)
    }
}

# ---- cases -----------------------------------------------------------------

function Case01 {
    New-Dir
    $ok = $true
    foreach ($ev in 'session-start', 'prompt-submit', 'agent-stop') {
        Invoke-Hook $ev (P-Start 's1')
        if (-not (Test-EmptyObj)) { $ok = $false }
    }
    $ok
}

function Case02 {
    New-Repo
    Write-Text (Join-Path $script:R 'a.txt') "x`n"
    Save-Commit 'init'
    $ok = $true
    foreach ($ev in 'session-start', 'prompt-submit', 'agent-stop') {
        Invoke-Hook $ev (P-Start 's1')
        if (-not (Test-EmptyObj)) { $ok = $false }
    }
    Write-Text (Join-Path $script:R 'docs/project-docs/log.md') "# Project log`n"
    foreach ($ev in 'session-start', 'prompt-submit', 'agent-stop') {
        Invoke-Hook $ev (P-Start 's1')
        if (-not (Test-EmptyObj)) { $ok = $false }
    }
    $ok
}

function Case03 {
    New-StdRepo 2
    Invoke-Hook 'session-start' (P-Start 's1')
    (Test-TodayLine) -and (Test-Has 'L0002 ') -and -not (Test-Has 'L0001 ') -and (Test-Has 'Background only, not a task:') -and (Test-Has 'Most recent log entry:') -and -not (Test-Has 'resume point')
}

function Case04 {
    New-StdRepo 0
    Invoke-Hook 'session-start' (P-Start 's1')
    (Test-TodayLine) -and -not (Test-Has 'Most recent log entry') -and -not (Test-Has 'Background only') -and -not (Test-Has '## L')
}

function Case05 {
    New-StdRepo
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    Test-EmptyObj
}

function Case06 {
    New-StdRepo
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Add-Text (Join-Path $script:R 'a.txt') "two`n"
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    (Test-Block) -and (Test-Has '(a.txt)')
}

function Case07 {
    New-StdRepo
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Add-Text (Join-Path $script:R 'a.txt') "two`n"
    Add-LogEntry
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    Test-EmptyObj
}

function Case08 {
    New-StdRepo
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Add-Text (Join-Path $script:R 'a.txt') "two`n"
    Invoke-Hook 'agent-stop' (P-Stop 's1' 'true')
    Test-EmptyObj
}

function Case09 {
    New-StdRepo
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Add-Text (Join-Path $script:R 'docs/project-docs/knowledge.md') "- a fact`n"
    Write-Text (Join-Path $script:R 'docs/project-docs/walkthrough.ai.md') "x`n"
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    Test-EmptyObj
}

function Case10 {
    New-StdRepo
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Write-Text (Join-Path $script:R 'b.txt') "new`n"
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    (Test-Block) -and (Test-Has '(b.txt)')
}

function Case11 {
    New-StdRepo
    Add-Text (Join-Path $script:R 'a.txt') "edited before the turn`n"
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    $first = $script:Out
    Add-Text (Join-Path $script:R 'a.txt') "edited during the turn`n"
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    ($first -ceq '{}') -and (Test-Block) -and (Test-Has '(a.txt)')
}

function Case12 {
    New-StdRepo
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Add-Text (Join-Path $script:R 'a.txt') "two`n"
    Save-Commit 'change a'
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    (Test-Block) -and (Test-Has '(a.txt)')
}

function Case13 {
    New-StdRepo
    Invoke-Hook 'agent-stop' (P-Stop 'never-seen')
    (Test-EmptyObj) -and $script:Err.StartsWith('project-docs:')
}

function Case14 {
    New-Repo
    Enable-Repo 0
    Invoke-Hook 'session-start' (P-Start 's1')
    $ok = Test-Has 'project-docs is enabled'
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Write-Text (Join-Path $script:R 'a.txt') "new`n"
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    $ok -and (Test-Block) -and (Test-Has '(a.txt)')
}

function Case15 {
    New-StdRepo
    $name = 'dir with space/caf' + [char]0xE9 + ' ' + [char]0x20AC + '.txt'
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Write-Text (Join-Path $script:R $name) "x`n"
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    (Test-Block) -and (Test-Has ('(' + $name + ')'))
}

function Case16 {
    New-StdRepo
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Add-Text (Join-Path $script:R 'a.txt') "two`n"
    Invoke-Hook 'prompt-submit' (P-Prompt 's2')
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    $first = $script:Out
    Invoke-Hook 'agent-stop' (P-Stop 's2')
    $first.StartsWith('{"decision":"block"') -and (Test-EmptyObj)
}

function Case17 {
    New-StdRepo
    $dir = (Get-GitDir) + '/project-docs/snapshots'
    [void][System.IO.Directory]::CreateDirectory($dir)
    Write-Text "$dir/old.txt" "HEAD x`nLOG y`n"
    Write-Text "$dir/fresh.txt" "HEAD x`nLOG y`n"
    [System.IO.File]::SetLastWriteTimeUtc("$dir/old.txt", (Get-Date).ToUniversalTime().AddDays(-10))
    Invoke-Hook 'session-start' (P-Start 's1')
    (-not (Test-Path -LiteralPath "$dir/old.txt")) -and (Test-Path -LiteralPath "$dir/fresh.txt")
}

function Case18 {
    New-StdRepo
    Invoke-Hook 'agent-stop' (P-Stop 'never-seen')
    $ok = (Test-EmptyObj) -and $script:Err.StartsWith('project-docs:') -and ($script:BadJson -eq 0)
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Add-Text (Join-Path $script:R 'a.txt') "two`n"
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    $ok -and (Test-Block) -and ($script:BadJson -eq 0)
}

function Case19 { # additional: payload cwd with JSON-escaped backslashes and a lowercase drive letter
    New-StdRepo
    $win = $script:R
    $win = $win.Substring(0, 1).ToLowerInvariant() + $win.Substring(1)
    $script:CwdJ = $win.Replace('\', '\\')
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Add-Text (Join-Path $script:R 'a.txt') "two`n"
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    (Test-Block) -and (Test-Has '(a.txt)')
}

function Case20 { # additional, SPEC 8.4: a prompt starting with "project-docs:" keeps the snapshot
    New-StdRepo
    Invoke-Hook 'prompt-submit' (P-Prompt 's1')
    Add-Text (Join-Path $script:R 'a.txt') "two`n"
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    $first = $script:Out
    Invoke-Hook 'prompt-submit' (P-Prompt 's1' 'project-docs: files changed this turn (a.txt) but nothing was logged')
    Invoke-Hook 'agent-stop' (P-Stop 's1')
    $first.StartsWith('{"decision":"block"') -and (Test-Block)
}

function Case21 { # additional, SPEC 9.2: a damaged marker (BOM or CR on line 1) means "not enabled" for the hooks
    New-StdRepo
    $log = Join-Path $script:R 'docs/project-docs/log.md'
    $ok = $true
    $bytes = [System.IO.File]::ReadAllBytes($log)
    [System.IO.File]::WriteAllBytes($log, ([byte[]](0xEF, 0xBB, 0xBF)) + $bytes)
    foreach ($ev in 'session-start', 'prompt-submit', 'agent-stop') {
        Invoke-Hook $ev (P-Start 's1')
        if (-not (Test-EmptyObj)) { $ok = $false }
    }
    $t = [System.IO.File]::ReadAllText((Join-Path $Templates 'log.md'), $utf8)
    $i = $t.IndexOf("`n")
    [System.IO.File]::WriteAllText($log, $t.Substring(0, $i) + "`r`n" + $t.Substring($i + 1), $utf8)
    foreach ($ev in 'session-start', 'prompt-submit', 'agent-stop') {
        Invoke-Hook $ev (P-Start 's1')
        if (-not (Test-EmptyObj)) { $ok = $false }
    }
    $ok
}

# ---- timing ----------------------------------------------------------------

function Get-MedianMs([string]$EventName, [string]$Json) {
    $times = @()
    for ($i = 0; $i -lt 5; $i++) {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $saveBad = $script:BadJson
        Invoke-Hook $EventName $Json
        $sw.Stop()
        $script:BadJson = $saveBad
        $times += [int]$sw.ElapsedMilliseconds
    }
    ($times | Sort-Object)[2]
}

function Invoke-Timing {
    Write-Host 'Building a repository with 10000 tracked files...'
    New-Repo
    Enable-Repo 2
    for ($d = 1; $d -le 100; $d++) {
        $dir = Join-Path $script:R ('src/d' + $d)
        [void][System.IO.Directory]::CreateDirectory($dir)
        for ($f = 1; $f -le 100; $f++) { [System.IO.File]::WriteAllText((Join-Path $dir ('f' + $f + '.txt')), "$d $f`n", $utf8) }
    }
    Save-Commit 'big'
    Write-Host ('tracked files: ' + @(& git -C $script:R ls-files).Count)
    Write-Host ('median of 5, milliseconds, process start included (' + $Shell + '):')
    Write-Host ('  session-start            ' + (Get-MedianMs 'session-start' (P-Start 't1')))
    Write-Host ('  prompt-submit (clean)    ' + (Get-MedianMs 'prompt-submit' (P-Prompt 't1')))
    for ($f = 1; $f -le 20; $f++) { Add-Text (Join-Path $script:R ('src/d1/f' + $f + '.txt')) "x`n" }
    Write-Host ('  prompt-submit (20 dirty) ' + (Get-MedianMs 'prompt-submit' (P-Prompt 't1')))
    Add-LogEntry
    Write-Host ('  agent-stop (20 dirty)    ' + (Get-MedianMs 'agent-stop' (P-Stop 't1')))
}

# ---- run -------------------------------------------------------------------

try {
    if ($Timing) {
        Invoke-Timing
    } else {
        Write-Host ('hook.ps1: ' + $Hook)
        Write-Host ('runner PowerShell ' + $PSVersionTable.PSVersion + '; hook shell: ' + $Shell + '; ' + (& git --version))
        Check '01 not a git repo -> {}' { Case01 }
        Check '02 not enabled -> {} for all events' { Case02 }
        Check '03 session-start with entries: top entry only' { Case03 }
        Check '04 session-start with no entries' { Case04 }
        Check '05 no change -> {}' { Case05 }
        Check '06 modified tracked file -> block, path listed' { Case06 }
        Check '07 modified file plus log.md changed -> {}' { Case07 }
        Check '08 stop_hook_active true -> {}' { Case08 }
        Check '09 only docs/project-docs/ changed -> {}' { Case09 }
        Check '10 untracked new file -> block' { Case10 }
        Check '11 file modified before and during the turn -> block' { Case11 }
        Check '12 commit during the turn, no log -> block' { Case12 }
        Check '13 no snapshot -> {} with stderr note' { Case13 }
        Check '14 repository with no commits' { Case14 }
        Check '15 path with spaces and non-ASCII characters' { Case15 }
        Check '16 two sessions interleaved' { Case16 }
        Check '17 snapshots older than 7 days removed at session-start' { Case17 }
        Check '18 one JSON object on stdout; stderr does not leak' { Case18 }
        Check '19 (extra) escaped Windows cwd in payload' { Case19 }
        Check '20 (extra) prompt starting with project-docs: keeps snapshot' { Case20 }
        Check '21 (extra) damaged marker (BOM or CR on line 1) -> {}' { Case21 }
        Write-Host ''
        Write-Host ('passed: ' + $script:Pass + '  failed: ' + $script:Fail + '  invalid outputs: ' + $script:BadJson)
    }
} finally {
    if ($Tmp -and (Test-Path -LiteralPath $Tmp)) { Remove-Item -LiteralPath $Tmp -Recurse -Force -ErrorAction SilentlyContinue }
}
if ($script:Fail -ne 0 -or $script:BadJson -ne 0) { exit 1 }
exit 0
