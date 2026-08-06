$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$layout = Join-Path $root 'layouts\_default\single.html'

if (-not (Test-Path -LiteralPath $layout)) {
  throw 'Missing the standard article layout for posts.'
}

$markup = Get-Content -LiteralPath $layout -Raw
foreach ($required in @(
  'article-standard',
  'eq .Section "posts"',
  'ne .Type "page"',
  'partial "post-meta"',
  '{{- .Content }}',
  'partial "article-citation" .',
  'partial "sidebar"'
)) {
  if ($markup -notmatch [regex]::Escape($required)) {
    throw "Missing standard article layout detail: $required"
  }
}

if ($markup.IndexOf('{{- .Content }}') -ge $markup.IndexOf('partial "article-citation" .')) {
  throw 'The automatic citation must render after the article body.'
}

foreach ($page in @('welcome.md', 'projects.md', 'contact.md')) {
  $frontMatter = Get-Content -LiteralPath (Join-Path $root "content\posts\$page") -Raw
  if ($frontMatter -notmatch 'type:\s*"page"') {
    throw "$page must remain outside the standard article layout."
  }
}

Write-Host 'Standard article layout checks passed.'
