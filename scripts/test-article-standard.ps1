$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$layout = Join-Path $root 'layouts\posts\single.html'

if (-not (Test-Path -LiteralPath $layout)) {
  throw 'Missing the standard article layout for posts.'
}

$markup = Get-Content -LiteralPath $layout -Raw
foreach ($required in @(
  'post_content article-standard',
  'partial "post-meta"',
  '{{- .Content }}',
  'partial "sidebar"'
)) {
  if ($markup -notmatch [regex]::Escape($required)) {
    throw "Missing standard article layout detail: $required"
  }
}

foreach ($page in @('welcome.md', 'projects.md', 'contact.md')) {
  $frontMatter = Get-Content -LiteralPath (Join-Path $root "content\posts\$page") -Raw
  if ($frontMatter -notmatch 'type:\s*"page"') {
    throw "$page must remain outside the standard article layout."
  }
}

Write-Host 'Standard article layout checks passed.'
