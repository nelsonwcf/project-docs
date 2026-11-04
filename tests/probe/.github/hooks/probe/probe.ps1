# project-docs probe v1 (PowerShell). Logs hook events to <git-dir>/probe/events.log.
# Usage: probe.ps1 <event> [label]   (label: nested | direct)
param([string]$EventName = 'unknown', [string]$Label = 'direct')
$utf8 = New-Object System.Text.UTF8Encoding($false)
try {
    [Console]::InputEncoding = $utf8
    [Console]::OutputEncoding = $utf8
    $raw = [Console]::In.ReadToEnd()
    $gd = (& git rev-parse --absolute-git-dir 2>$null)
    if (-not $gd) { $gd = [IO.Path]::GetTempPath() }
    $dir = Join-Path $gd 'probe'
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $log = Join-Path $dir 'events.log'

    $sid = 'default'
    if ($raw -match '"[sS]ession_?[iI]d"\s*:\s*"([^"]*)"') { $sid = ($Matches[1] -replace '[^A-Za-z0-9_-]', '_') }
    if ($sid.Length -gt 64) { $sid = $sid.Substring(0, 64) }

    $out = '{}'
    # Only the nested variant may block, so the block happens once per session.
    if ($EventName -eq 'agentStop' -and $Label -eq 'nested') {
        $active = ($raw -match '"stop_?[hH]ook_?[aA]ctive"\s*:\s*true')
        $marker = Join-Path $dir ('blocked-' + $sid)
        if ((-not $active) -and (-not (Test-Path $marker))) {
            New-Item -ItemType File -Path $marker | Out-Null
            $out = '{"decision":"block","reason":"probe: say PROBE-OK and stop"}'
        }
    }

    $envNames = (Get-ChildItem Env: | Where-Object { $_.Name -match 'COPILOT' } | ForEach-Object { $_.Name }) -join ' '
    $proc = Get-Process -Id $PID
    $policy = (Get-ExecutionPolicy -List | ForEach-Object { $_.Scope.ToString() + '=' + $_.ExecutionPolicy.ToString() }) -join '; '
    $top = (& git rev-parse --show-toplevel 2>$null)
    $nl = [Environment]::NewLine
    $text = '=== ' + (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ') + ' event=' + $EventName + ' label=' + $Label + $nl
    $text += 'shell: PowerShell ' + $PSVersionTable.PSVersion.ToString() + ' edition=' + $PSVersionTable.PSEdition + ' exe=' + $proc.Path + $nl
    $text += 'execution-policy: ' + $policy + $nl
    $text += 'pwd: ' + (Get-Location).Path + $nl
    $text += 'toplevel: ' + $top + $nl
    $text += 'git-dir: ' + $gd + $nl
    $text += 'env-names: ' + $envNames + $nl
    $text += 'stdin: ' + $raw + $nl
    $text += 'output: ' + $out + $nl
    [IO.File]::AppendAllText($log, $text, $utf8)

    [Console]::Out.Write($out)
    exit 0
}
catch {
    [Console]::Error.WriteLine('probe: ' + $_.Exception.Message)
    [Console]::Out.Write('{}')
    exit 0
}
