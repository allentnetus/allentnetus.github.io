$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$partial = Join-Path $root 'layouts\partials\share.html'
$config = Join-Path $root 'hugo.toml'

if (-not (Test-Path -LiteralPath $partial)) {
  throw 'Missing share partial.'
}

$markup = Get-Content -LiteralPath $partial -Raw
foreach ($required in @('navigator.share', 'navigator.clipboard.writeText', 'api.qrserver.com', 'x.com/intent/tweet', 'share-native', 'share-wechat', 'share-label', 'share-icon')) {
  if ($markup -notmatch [regex]::Escape($required)) {
    throw "Missing share behavior: $required"
  }
}

if ((Get-Content -LiteralPath $config -Raw) -notmatch 'showShare = true') {
  throw 'Global article sharing is not enabled.'
}

foreach ($page in @('welcome.md', 'contact.md', 'projects.md')) {
  $content = Get-Content -LiteralPath (Join-Path $root "content\posts\$page") -Raw
  if ($content -notmatch 'showshare: false') {
    throw "Static page still enables sharing: $page"
  }
}

Write-Host 'Share feature checks passed.'
