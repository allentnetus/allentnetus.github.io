$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$partial = Join-Path $root 'layouts\partials\article-citation.html'
$layout = Join-Path $root 'layouts\_default\single.html'
$rules = Join-Path $root 'AGENTS.md'

if (-not (Test-Path -LiteralPath $partial)) {
  throw 'Missing automatic citation presentation component.'
}

$markup = Get-Content -LiteralPath $partial -Raw
foreach ($required in @('article-citation', '.Title', '.Permalink', 'article{', 'citation-copy-button', 'citation-copy-toast', 'navigator.clipboard.writeText', 'document.readyState', "classList.add('is-copied')", "classList.add('is-visible')")) {
  if ($markup -notmatch [regex]::Escape($required)) {
    throw "Missing citation presentation detail: $required"
  }
}

if ((Get-Content -LiteralPath $layout -Raw) -notmatch [regex]::Escape('partial "article-citation" .')) {
  throw 'Standard article pages do not render the automatic citation component.'
}

if (-not (Test-Path -LiteralPath $rules) -or (Get-Content -LiteralPath $rules -Raw) -notmatch 'article-citation\.html') {
  throw 'Publishing rules do not document the automatic citation requirement.'
}

Write-Host 'Citation presentation checks passed.'
