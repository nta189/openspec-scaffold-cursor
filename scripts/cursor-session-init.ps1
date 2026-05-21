# scripts/cursor-session-init.ps1 — Cursor session startup (Windows)
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

Write-Host "── Cursor Session Init ─────────────────────────"
Write-Host "IDE: Cursor | Rules: .cursor/rules/ + .cursorrules"
Write-Host ""

$SessionInit = Join-Path $ProjectRoot "scripts\session-init.sh"
if (Test-Path $SessionInit) {
    if (Get-Command bash -ErrorAction SilentlyContinue) {
        bash $SessionInit
    } else {
        Write-Host "⚠ bash not found; run git status and review DECISIONS.md manually"
        if (Test-Path (Join-Path $ProjectRoot "DECISIONS.md")) {
            Get-Content (Join-Path $ProjectRoot "DECISIONS.md") -Tail 30
        }
    }
} else {
    Write-Host "⚠ scripts/session-init.sh not found"
}

Write-Host ""
Write-Host "Context hints: @DECISIONS.md @AGENT.md @SAFETY.md @IMPLEMENTATION.md"
Write-Host "Modes: cursor/prompts/modes/*.md"
Write-Host "──────────────────────────────────────────────"
