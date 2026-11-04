# Installs the project-docs and project-docs-regenerate skills for GitHub Copilot in VS Code.
# Usage:  powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
#         powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
# Target: %USERPROFILE%\.copilot\skills (COPILOT_HOME is not used for skills; see INSTALL.md).
# Runs on Windows PowerShell 5.1 and PowerShell 7. ASCII-only source.

param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'
$Skills = @('project-docs', 'project-docs-regenerate')
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Home1 = $env:USERPROFILE
if (-not $Home1) { $Home1 = [Environment]::GetFolderPath('UserProfile') }
$Target = Join-Path $Home1 '.copilot\skills'

function Stop-Install([string]$Message) {
    [Console]::Error.WriteLine('ERROR: ' + $Message)
    exit 1
}

function Remove-Safe([string]$Path) {
    $leaf = Split-Path -Leaf $Path
    $parent = Split-Path -Parent $Path
    $ok = ($parent -eq $Target) -and (($Skills -contains $leaf) -or $leaf.StartsWith('.pd-tmp.') -or $leaf.StartsWith('.pd-old.'))
    if (-not $ok) { Stop-Install ('refusing to remove unexpected path: ' + $Path) }
    if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Recurse -Force }
}

function Write-WslNote {
    Write-Host ''
    Write-Host 'Note: VS Code sessions connected to WSL read skills from ~/.copilot/skills inside the'
    Write-Host 'distribution; run install.sh inside WSL as well if you use WSL.'
}

try {
    if ($Uninstall) {
        foreach ($s in $Skills) {
            $p = Join-Path $Target $s
            if (Test-Path -LiteralPath $p) {
                Remove-Safe $p
                Write-Host ('Removed ' + $p)
            } else {
                Write-Host ('Not installed: ' + $p)
            }
        }
        Write-WslNote
        Write-Host 'Reload every open VS Code window (Developer: Reload Window in each one).'
        exit 0
    }

    $verFile = Join-Path $Here 'VERSION'
    if (-not (Test-Path -LiteralPath $verFile)) { Stop-Install ('VERSION not found next to install.ps1 (' + $Here + '). Run the script from the unzipped package.') }
    $pkgVer = ([System.IO.File]::ReadAllText($verFile)).Trim()
    foreach ($s in $Skills) {
        if (-not (Test-Path -LiteralPath (Join-Path $Here ($s + '\SKILL.md')))) {
            Stop-Install ((Join-Path $Here ($s + '\SKILL.md')) + ' not found. Run the script from the unzipped package.')
        }
    }

    [void][System.IO.Directory]::CreateDirectory($Target)
    $stamp = [string]$PID
    $tmp = Join-Path $Target ('.pd-tmp.' + $stamp)
    Remove-Safe $tmp
    [void][System.IO.Directory]::CreateDirectory($tmp)
    foreach ($s in $Skills) {
        Copy-Item -LiteralPath (Join-Path $Here $s) -Destination (Join-Path $tmp $s) -Recurse -Force
    }

    # Swap: move the old copies aside, move the new ones in, then delete the old ones.
    foreach ($s in $Skills) {
        $dest = Join-Path $Target $s
        if (Test-Path -LiteralPath $dest) {
            Move-Item -LiteralPath $dest -Destination (Join-Path $Target ('.pd-old.' + $s + '.' + $stamp))
        }
        Move-Item -LiteralPath (Join-Path $tmp $s) -Destination $dest
    }
    Remove-Safe $tmp
    foreach ($s in $Skills) {
        $old = Join-Path $Target ('.pd-old.' + $s + '.' + $stamp)
        if (Test-Path -LiteralPath $old) { Remove-Safe $old }
    }

    # Validate.
    $bad = $false
    foreach ($s in $Skills) {
        $f = Join-Path $Target ($s + '\SKILL.md')
        if (-not (Test-Path -LiteralPath $f)) {
            [Console]::Error.WriteLine('FAIL: ' + $f + ' is missing')
            $bad = $true
            continue
        }
        $name = ''
        $lines = [System.IO.File]::ReadAllLines($f)
        for ($i = 1; $i -lt $lines.Length; $i++) {
            if ($lines[$i].TrimEnd() -eq '---') { break }
            if ($lines[$i] -match '^name:\s*(.+?)\s*$') { $name = $Matches[1].Trim('"', "'"); break }
        }
        if ($name -cne $s) {
            [Console]::Error.WriteLine('FAIL: ' + $f + " has name '" + $name + "', expected '" + $s + "'")
            $bad = $true
        }
        $v = ([System.IO.File]::ReadAllText((Join-Path $Target ($s + '\VERSION')))).Trim()
        if ($v -cne $pkgVer) {
            [Console]::Error.WriteLine('FAIL: ' + (Join-Path $Target ($s + '\VERSION')) + " is '" + $v + "', expected '" + $pkgVer + "'")
            $bad = $true
        }
    }
    if ($bad) { Stop-Install 'validation failed; see messages above' }

    Write-Host ('Installed project-docs skills ' + $pkgVer + ' into ' + $Target + ':')
    foreach ($s in $Skills) { Write-Host ('  ' + (Join-Path $Target $s)) }
    Write-WslNote
    Write-Host ''
    Write-Host 'Next: reload every open VS Code window (Developer: Reload Window in each one), then open'
    Write-Host 'Chat: Open Customizations > Skills and check that both skills are listed.'
    exit 0
}
catch {
    [Console]::Error.WriteLine('ERROR: ' + $_.Exception.Message)
    exit 1
}
