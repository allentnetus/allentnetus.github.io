$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$partial = Join-Path $root 'layouts\partials\share.html'
$config = Join-Path $root 'hugo.toml'

if (-not (Test-Path -LiteralPath $partial)) {
  throw 'Missing share partial.'
}

$markup = Get-Content -LiteralPath $partial -Raw
foreach ($required in @('navigator.share', 'navigator.clipboard.writeText', 'api.qrserver.com', 'x.com/intent/tweet', 'share-native', 'share-wechat', 'share-leading-icon', 'share-button', 'share-platform-icon', 'simpleicons.org/wechat/07C160', 'simpleicons.org/x/000000')) {
  if ($markup -notmatch [regex]::Escape($required)) {
    throw "Missing share behavior: $required"
  }
}

if ($markup -match 'share-label') {
  throw 'The visible 分享 text label has not been removed.'
}

if ($markup -notmatch '(?s)share-wechat.*?share-x.*?share-copy') {
  throw 'Copy link is not the final desktop sharing action.'
}

if ($markup -notmatch 'share-button \{[^}]*border-radius: 999px') {
  throw 'Desktop sharing actions are not circular icon buttons.'
}

if ($markup -notmatch 'share-platform-icon \{[^}]*display: block;[^}]*width: 1.45rem;[^}]*height: 1.45rem;[^}]*object-fit: contain;[^}]*justify-self: center;[^}]*align-self: center') {
  throw 'Platform icons are not enlarged proportionally and centered within their buttons.'
}

if ($markup -notmatch 'share-copy \.icon \{[^}]*display: block;[^}]*width: 1.2rem;[^}]*height: 1.2rem') {
  throw 'The copy icon is not enlarged proportionally and centered within its button.'
}

if ($markup -notmatch 'post_meta \.page_only \{[^}]*margin-left: auto') {
  throw 'The sharing group is not right-aligned independently from the tags.'
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
