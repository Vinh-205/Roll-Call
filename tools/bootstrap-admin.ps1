param([Parameter(Mandatory=$true)][string]$Email)
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$config=Get-Content -LiteralPath (Join-Path $root '.private.env') | Where-Object {$_ -like 'BOOTSTRAP_SECRET=*'}
if(!$config){throw 'Missing BOOTSTRAP_SECRET in .private.env'}
$key=$config.Substring('BOOTSTRAP_SECRET='.Length).Trim()
$base='https://truong-tuan-vinh-2577-catcheck.dreamy-gem-3550.chatgpt.site/api'
$body=@{email=$Email}|ConvertTo-Json
Invoke-RestMethod "$base/setup/admin" -Method Post -ContentType 'application/json' -Headers @{'X-Bootstrap-Secret'=$key} -Body $body | Select-Object message
