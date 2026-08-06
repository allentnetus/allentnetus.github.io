$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$article = Join-Path $root 'content\posts\ai-agent-knowledge-base.md'
$shortcode = Join-Path $root 'layouts\shortcodes\citation.html'

if ((Get-Content -LiteralPath $article -Raw) -notmatch '\{\{< citation >\}\}') {
  throw 'The article citation is not wrapped in the citation presentation component.'
}

if (-not (Test-Path -LiteralPath $shortcode)) {
  throw 'Missing citation presentation component.'
}

$markup = Get-Content -LiteralPath $shortcode -Raw
foreach ($required in @('article-citation', 'border-top', 'font-size: .88em', 'font-style: italic', 'opacity: .78', 'citation-copy-button', 'citation-copy-toast', 'navigator.clipboard.writeText', "classList.add('is-copied')", "classList.add('is-visible')")) {
  if ($markup -notmatch [regex]::Escape($required)) {
    throw "Missing citation presentation detail: $required"
  }
}

Write-Host 'Citation presentation checks passed.'
