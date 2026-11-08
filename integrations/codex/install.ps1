param([ValidateSet('Project','User')][string]$Scope = 'Project')
$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$target = if ($Scope -eq 'Project') { Join-Path (Get-Location) '.agents/skills' } else { Join-Path $HOME '.agents/skills' }
New-Item -ItemType Directory -Force -Path $target | Out-Null
Get-ChildItem -LiteralPath (Join-Path $repo 'skills') -Directory | ForEach-Object {
  $destination = Join-Path $target $_.Name
  New-Item -ItemType Directory -Force -Path $destination | Out-Null
  Copy-Item -Path (Join-Path $_.FullName '*') -Destination $destination -Recurse -Force
}
Write-Output "Installed fs-skills for Codex at $target"

