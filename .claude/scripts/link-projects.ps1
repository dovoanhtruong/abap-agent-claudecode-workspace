<#
.SYNOPSIS
  One-time per-device setup: link <workspace>\projects to the projects store repo.

.DESCRIPTION
  `projects/` in this workspace is a junction to a separate git repo whose path
  may differ on every device (rule §4 "Projects store"). Skills, commands and
  hooks only ever use `projects/<p>/...`, so this junction is the single
  per-device setting. Junctions need no admin rights.

  - Store missing + -Remote given  -> git clone
  - workspace\projects already a link -> re-pointed (rmdir removes only the link)
  - workspace\projects a real folder WITH content -> refuses (move it into the store first)

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .claude\scripts\link-projects.ps1 -Store "D:\work\projects" -Remote "https://<host>/<org>/abap-projects.git"
#>
param(
  [Parameter(Mandatory = $true)][string]$Store,
  [string]$Remote
)
$ErrorActionPreference = 'Stop'

$ws   = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent   # .claude\scripts -> workspace root
$link = Join-Path $ws 'projects'

# 1. Store: clone when missing
if (-not (Test-Path $Store)) {
  if (-not $Remote) { throw "Store '$Store' does not exist. Pass -Remote <url> to clone it." }
  git clone $Remote $Store
  if ($LASTEXITCODE -ne 0) { throw "git clone failed (exit $LASTEXITCODE)." }
} elseif (-not (Test-Path (Join-Path $Store '.git'))) {
  Write-Warning "Store '$Store' is not a git repo - linking anyway; cross-device sync stays unavailable until you git init / clone it."
}
$storeFull = (Resolve-Path $Store).Path.TrimEnd('\')

# 2. Existing workspace\projects
if (Test-Path $link) {
  $item = Get-Item $link -Force
  if ($item.LinkType) {
    $current = (@($item.Target)[0]).TrimEnd('\')
    if ($current -ieq $storeFull) { Write-Output "Already linked: $link -> $current"; return }
    cmd /c rmdir "$link"   # removes the link only, never the target's content
    if ($LASTEXITCODE -ne 0) { throw "Could not remove the old link '$link'." }
  } elseif (Get-ChildItem $link -Force | Select-Object -First 1) {
    throw "'$link' is a real folder with content. Move anything not yet in the store into '$storeFull' (and commit it there), then delete or rename '$link' and re-run. Nothing was changed."
  } else {
    Remove-Item $link -Force   # empty leftover folder
  }
}

# 3. Junction
New-Item -ItemType Junction -Path $link -Target $storeFull | Out-Null
Write-Output "Linked: $link -> $storeFull"
