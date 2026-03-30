function ReplaceSensitive {param([string]$Path, [switch]$help)

# Usage.
if ((-not $Path) -and (-not $help)) {Write-Host -f cyan "`nUsage: replacesensitive <inputfile> -help`n"; return}

# Modify fields sent to it with proper word wrapping.
function wordwrap ($field, $maximumlinelength) {if ($null -eq $field) {return $null}
$breakchars = ',.;?!\/ '; $wrapped = @()
if (-not $maximumlinelength) {[int]$maximumlinelength = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($maximumlinelength -lt 60) {[int]$maximumlinelength = 60}
if ($maximumlinelength -gt $Host.UI.RawUI.BufferSize.Width) {[int]$maximumlinelength = $Host.UI.RawUI.BufferSize.Width}
foreach ($line in $field -split "`n", [System.StringSplitOptions]::None) {if ($line -eq "") {$wrapped += ""; continue}
$remaining = $line
while ($remaining.Length -gt $maximumlinelength) {$segment = $remaining.Substring(0, $maximumlinelength); $breakIndex = -1
foreach ($char in $breakchars.ToCharArray()) {$index = $segment.LastIndexOf($char)
if ($index -gt $breakIndex) {$breakIndex = $index}}
if ($breakIndex -lt 0) {$breakIndex = $maximumlinelength - 1}
$chunk = $segment.Substring(0, $breakIndex + 1); $wrapped += $chunk; $remaining = $remaining.Substring($breakIndex + 1)}
if ($remaining.Length -gt 0 -or $line -eq "") {$wrapped += $remaining}}
return ($wrapped -join "`n")}

# Display a horizontal line.
function line ($colour, $length, [switch]$pre, [switch]$post, [switch]$double) {if (-not $length) {[int]$length = (100, $Host.UI.RawUI.WindowSize.Width | Measure-Object -Maximum).Maximum}
if ($length) {if ($length -lt 60) {[int]$length = 60}
if ($length -gt $Host.UI.RawUI.BufferSize.Width) {[int]$length = $Host.UI.RawUI.BufferSize.Width}}
if ($pre) {Write-Host ""}
$character = if ($double) {"="} else {"-"}
Write-Host -f $colour ($character * $length)
if ($post) {Write-Host ""}}

function help {# Inline help.
# Select content.
$scripthelp = Get-Content -Raw -Path $PSCommandPath; $sections = [regex]::Matches($scripthelp, "(?im)^## (.+?)(?=\r?\n)"); $selection = $null; $lines = @(); $wrappedLines = @(); $position = 0; $pageSize = 30; $inputBuffer = ""

function scripthelp ($section) {$pattern = "(?ims)^## ($([regex]::Escape($section)).*?)(?=^##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $lines = $match.Groups[1].Value.TrimEnd() -split "`r?`n", 2; if ($lines.Count -gt 1) {$wrappedLines = (wordwrap $lines[1] 100) -split "`n", [System.StringSplitOptions]::None}
else {$wrappedLines = @()}
$position = 0}

# Display Table of Contents.
while ($true) {cls; Write-Host -f cyan "$(Get-ChildItem (Split-Path $PSCommandPath) | Where-Object { $_.FullName -ieq $PSCommandPath } | Select-Object -ExpandProperty BaseName) Help Sections:`n"

if ($sections.Count -gt 7) {$half = [Math]::Ceiling($sections.Count / 2)
for ($i = 0; $i -lt $half; $i++) {$leftIndex = $i; $rightIndex = $i + $half; $leftNumber  = "{0,2}." -f ($leftIndex + 1); $leftLabel   = " $($sections[$leftIndex].Groups[1].Value)"; $leftOutput  = [string]::Empty

if ($rightIndex -lt $sections.Count) {$rightNumber = "{0,2}." -f ($rightIndex + 1); $rightLabel  = " $($sections[$rightIndex].Groups[1].Value)"; Write-Host -f cyan $leftNumber -n; Write-Host -f white $leftLabel -n; $pad = 40 - ($leftNumber.Length + $leftLabel.Length)
if ($pad -gt 0) {Write-Host (" " * $pad) -n}; Write-Host -f cyan $rightNumber -n; Write-Host -f white $rightLabel}
else {Write-Host -f cyan $leftNumber -n; Write-Host -f white $leftLabel}}}

else {for ($i = 0; $i -lt $sections.Count; $i++) {Write-Host -f cyan ("{0,2}. " -f ($i + 1)) -n; Write-Host -f white "$($sections[$i].Groups[1].Value)"}}

# Display Header.
line yellow 100
if ($lines.Count -gt 0) {Write-Host  -f yellow $lines[0]}
else {Write-Host "Choose a section to view." -f darkgray}
line yellow 100

# Display content.
$end = [Math]::Min($position + $pageSize, $wrappedLines.Count)
for ($i = $position; $i -lt $end; $i++) {Write-Host -f white $wrappedLines[$i]}

# Pad display section with blank lines.
for ($j = 0; $j -lt ($pageSize - ($end - $position)); $j++) {Write-Host ""}

# Display menu options.
line yellow 100; Write-Host -f white "[↑/↓]  [PgUp/PgDn]  [Home/End]  |  [#] Select section  |  [Q] Quit  " -n; if ($inputBuffer.length -gt 0) {Write-Host -f cyan "section: $inputBuffer" -n}; $key = [System.Console]::ReadKey($true)

# Define interaction.
switch ($key.Key) {'UpArrow' {if ($position -gt 0) { $position-- }; $inputBuffer = ""}
'DownArrow' {if ($position -lt ($wrappedLines.Count - $pageSize)) { $position++ }; $inputBuffer = ""}
'PageUp' {$position -= 30; if ($position -lt 0) {$position = 0}; $inputBuffer = ""}
'PageDown' {$position += 30; $maxStart = [Math]::Max(0, $wrappedLines.Count - $pageSize); if ($position -gt $maxStart) {$position = $maxStart}; $inputBuffer = ""}
'Home' {$position = 0; $inputBuffer = ""}
'End' {$maxStart = [Math]::Max(0, $wrappedLines.Count - $pageSize); $position = $maxStart; $inputBuffer = ""}

'Enter' {if ($inputBuffer -eq "") {"`n"; return}
elseif ($inputBuffer -match '^\d+$') {$index = [int]$inputBuffer
if ($index -ge 1 -and $index -le $sections.Count) {$selection = $index; $pattern = "(?ims)^## ($([regex]::Escape($sections[$selection-1].Groups[1].Value)).*?)(?=^##|\z)"; $match = [regex]::Match($scripthelp, $pattern); $block = $match.Groups[1].Value.TrimEnd(); $lines = $block -split "`r?`n", 2
if ($lines.Count -gt 1) {$wrappedLines = (wordwrap $lines[1] 100) -split "`n", [System.StringSplitOptions]::None}
else {$wrappedLines = @()}
$position = 0}}
$inputBuffer = ""}

default {$char = $key.KeyChar
if ($char -match '^[Qq]$') {"`n"; return}
elseif ($char -match '^\d$') {$inputBuffer += $char}
else {$inputBuffer = ""}}}}}

# External call to help.
if ($help) {help; return}

# ---------------- PATH RESOLUTION ----------------
try {function Try-Resolve([string]$p) {try {return (Resolve-Path -LiteralPath $p -ErrorAction Stop).Path}
catch {return $null}}

$resolved = $null
$candidates = @()

$candidates += $Path
if (-not ([System.IO.Path]::IsPathRooted($Path))) {$candidates += (Join-Path (Get-Location) $Path)}
if ($PSScriptRoot) {$candidates += (Join-Path $PSScriptRoot $Path)
$candidates += (Join-Path $PSScriptRoot (Split-Path -Leaf $Path))}

foreach ($c in $candidates | Select-Object -Unique) {$try = Try-Resolve $c
if ($try) {$resolved = $try; break}}

if (-not $resolved) {throw "Input file not found. Checked:`n - " + ($candidates -join "`n - ")}

$Path = $resolved
$OutPath = "$Path.safereplacement"

# ---------------- RNG & MAPS ----------------
$Rng = [System.Random]::new()

function Get-RandInt($min,$max){$Rng.Next($min,$max+1)}

$Ipv4Map   = @{}
$Ipv6Map   = @{}
$UserMap   = @{}
$DomainMap = @{}

# ---------------- GENERATORS ----------------
function New-RandomIPv4 {$ranges = @(@(192,0,2), @(198,51,100), @(203,0,113))
$base = $ranges[(Get-RandInt 0 ($ranges.Count-1))]
$last = Get-RandInt 1 254
return "$($base[0]).$($base[1]).$($base[2]).$last"}

function New-RandomIPv6 {$bytes = New-Object byte[] 16
$bytes[0]=0x20; $bytes[1]=0x01; $bytes[2]=0x0D; $bytes[3]=0xB8  # 2001:db8::
for ($i=4;$i -lt 16;$i++){$bytes[$i] = Get-RandInt 0 255}
return ([System.Net.IPAddress]::new($bytes)).ToString()}

function Get-RandomLetter([bool]$upper) {$letters = "abcdefghijklmnopqrstuvwxyz"
$ch = [string]$letters[(Get-RandInt 0 25)]
if ($upper) {return $ch.ToUpper()}
return $ch}

function Get-RandomDigit {return "0123456789"[(Get-RandInt 0 9)]}

function New-RandomUsernameLike($orig) {$sb = New-Object System.Text.StringBuilder
foreach ($ch in $orig.ToCharArray()) {if ($ch -match '[A-Za-z]') {$sb.Append((Get-RandomLetter ($ch -cmatch '[A-Z]'))) | Out-Null}
elseif ($ch -match '\d') {$sb.Append((Get-RandomDigit)) | Out-Null}
elseif ($ch -in @('-','_','.')) {$sb.Append($ch) | Out-Null}
else {$sb.Append((Get-RandomLetter $false)) | Out-Null}}
return $sb.ToString()}

function New-RandomDomainLabelLike($label){$sb = New-Object System.Text.StringBuilder
foreach ($ch in $label.ToCharArray()) {if ($ch -match '[A-Za-z]') {$sb.Append((Get-RandomLetter ($ch -cmatch '[A-Z]'))) | Out-Null}
elseif ($ch -match '\d') {$sb.Append((Get-RandomDigit)) | Out-Null}
elseif ($ch -eq '-') {$sb.Append('-') | Out-Null}
else {$sb.Append($ch) | Out-Null}}
return $sb.ToString()}

function New-RandomDomainLike($domain) {(($domain -split '\.') | ForEach-Object {New-RandomDomainLabelLike $_}) -join '.'}

# ---------------- RULES ----------------
function Test-UsernameRule($u){if ($u.Length -lt 3 -or $u.Length -gt 14) {return $false}
if ($u -notmatch '^[A-Za-z0-9_-]+$') {return $false}
if (([regex]::Matches($u,'[A-Za-z]')).Count -lt 3) {return $false}
if (([regex]::Matches($u,'-')).Count + ([regex]::Matches($u,'_')).Count -gt 1) {return $false}
return $true}

function Test-FirstLastRule($u){$m = [regex]::Match($u,'^(?<f>[A-Za-z0-9]{3,14})\.(?<l>[A-Za-z0-9]{3,14})$')
if (-not $m.Success) {return $false}
if (([regex]::Matches($u,'[A-Za-z]')).Count -lt 3) {return $false}
return $true}

function Map-GetOrAdd($map,$key,[scriptblock]$gen) {if ($map.ContainsKey($key)) {return $map[$key]}
$map[$key] = & $gen
return $map[$key]}

# ---------------- REGEX DEFINITIONS ----------------
$IPv4Pattern = @'
\b(?:(?:25[0-5]|2[0-4]\d|1?\d{1,2})\.){3}(?:25[0-5]|2[0-4]\d|1?\d{1,2})\b
'@

$IPv6Pattern = @'
(?<![A-Fa-f0-9:])(?:(?:[A-Fa-f0-9]{1,4}:){7}[A-Fa-f0-9]{1,4}|(?:[A-Fa-f0-9]{1,4}:){1,7}:|:(?::[A-Fa-f0-9]{1,4}){1,7}|(?:[A-Fa-f0-9]{1,4}:){1,6}:(?:[A-Fa-f0-9]{1,4})|(?:[A-Fa-f0-9]{1,4}:){1,5}(?::[A-Fa-f0-9]{1,4}){1,2}|(?:[A-Fa-f0-9]{1,4}:){1,4}(?::[A-Fa-f0-9]{1,4}){1,3}|(?:[A-Fa-f0-9]{1,4}:){1,3}(?::[A-Fa-f0-9]{1,4}){1,4}|(?:[A-Fa-f0-9]{1,4}:){1,2}(?::[A-Fa-f0-9]{1,4}){1,5}|[A-Fa-f0-9]{1,4}:(?:(?::[A-Fa-f0-9]{1,4}){1,6}))(?![A-Fa-f0-9:])
'@

$EmailFirstLast = @'
(?<u1>[A-Za-z0-9]{3,14})\.(?<u2>[A-Za-z0-9]{3,14})@(?<domain>(?:[A-Za-z0-9-]{1,63}\.)+[A-Za-z0-9-]{2,63})
'@

$EmailSimple = @'
(?<user>[A-Za-z0-9][A-Za-z0-9_-]{2,13})@(?<domain>(?:[A-Za-z0-9-]{1,63}\.)+[A-Za-z0-9-]{2,63})
'@

$DomainUser = @'
(?<domain>[A-Za-z0-9][A-Za-z0-9._-]{0,252})(?<sep>[\\/])(?<user>(?:[A-Za-z0-9]{3,14}\.[A-Za-z0-9]{3,14}|[A-Za-z0-9][A-Za-z0-9_-]{2,13}))
'@

# Context-driven usernames: CAPTURE spacing after prefix
$ContextUser = @'
(?<prefix>(?:/u:?|-u:?|--?user(?:name)?|user(?:name)?|login|acct|account|uid|u|un|usr)(?:\s*[=:])?)(?<gap>\s*)(?<user>(?:[A-Za-z0-9]{3,14}\.[A-Za-z0-9]{3,14}|[A-Za-z0-9][A-Za-z0-9_-]{2,13}))
'@

# Password redaction: Fixes ALL your cases including: -p password, "/p: secret", pwd=foo, "--password test"
$PasswordPattern = @'
(?<pre>(?:^|[\s"']))(?<key>(?:/p|-p|--?password|password|pass(?:wd)?|pwd))(?<sep>\s*[:=]?)(?<gap>\s*)(?<val>"[^"]+"|'[^']+'|\S+)
'@

$RxIC = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase

# ---------------- LOAD FILE ----------------
$text = Get-Content -Raw -LiteralPath $Path

# ---------------- IPs ----------------
$text = [regex]::Replace($text, $IPv4Pattern, {param($m) Map-GetOrAdd $Ipv4Map $m.Value {New-RandomIPv4}})

$text = [regex]::Replace($text, $IPv6Pattern, {param($m) Map-GetOrAdd $Ipv6Map $m.Value {New-RandomIPv6}})

# ---------------- EMAILS ----------------
$text = [regex]::Replace($text, $EmailFirstLast, {param($m)
$u1 = $m.Groups['u1'].Value
$u2 = $m.Groups['u2'].Value
$domain = $m.Groups['domain'].Value
$local = "$u1.$u2"
if (-not (Test-FirstLastRule $local)) {return $m.Value}

$rl = Map-GetOrAdd $UserMap $local {(New-RandomUsernameLike $u1)+'.'+(New-RandomUsernameLike $u2)}
$rd = Map-GetOrAdd $DomainMap $domain {New-RandomDomainLike $domain}
"$rl@$rd"}, $RxIC)

$text = [regex]::Replace($text, $EmailSimple, {param($m)
$user = $m.Groups['user'].Value
$domain = $m.Groups['domain'].Value
if (-not (Test-UsernameRule $user)) {return $m.Value}

$ru = Map-GetOrAdd $UserMap $user {New-RandomUsernameLike $user}
$rd = Map-GetOrAdd $DomainMap $domain {New-RandomDomainLike $domain}
"$ru@$rd"}, $RxIC)

# ---------------- DOMAIN\USER ----------------
$text = [regex]::Replace($text, $DomainUser, {param($m)
$domain = $m.Groups['domain'].Value
$sep    = $m.Groups['sep'].Value
$user   = $m.Groups['user'].Value
$isFL = Test-FirstLastRule $user
$isSimple = Test-UsernameRule $user
if (-not ($isFL -or $isSimple)) {return $m.Value}

if ($isFL) {$parts = $user.Split('.')
$ru = Map-GetOrAdd $UserMap $user {(New-RandomUsernameLike $parts[0])+'.'+(New-RandomUsernameLike $parts[1])}}
else {$ru = Map-GetOrAdd $UserMap $user {New-RandomUsernameLike $user}}
$rd = Map-GetOrAdd $DomainMap $domain {New-RandomDomainLike $domain}
"$rd$sep$ru"}, $RxIC)

# ---------------- CONTEXT-DRIVEN USERNAMES ----------------
$text = [regex]::Replace($text, $ContextUser, {param($m)
$prefix = $m.Groups['prefix'].Value
$gap    = $m.Groups['gap'].Value
$user   = $m.Groups['user'].Value
$isFL = Test-FirstLastRule $user
$isSimple = Test-UsernameRule $user
if (-not ($isFL -or $isSimple)) {return $m.Value}

if ($isFL) {$parts = $user.Split('.')
$ru = Map-GetOrAdd $UserMap $user {(New-RandomUsernameLike $parts[0])+'.'+(New-RandomUsernameLike $parts[1])}}
else {$ru = Map-GetOrAdd $UserMap $user {New-RandomUsernameLike $user}}
"$prefix$gap$ru"}, $RxIC)

# ---------------- PASSWORD REDACTION ----------------
$PasswordCount = 0
$text = [regex]::Replace($text, $PasswordPattern, {param($m)
$pre   = $m.Groups['pre'].Value
$key   = $m.Groups['key'].Value
$sep   = $m.Groups['sep'].Value
$gap   = $m.Groups['gap'].Value
$val   = $m.Groups['val'].Value

# Detect quoting
$isDQ = ($val.Length -ge 2 -and $val[0] -eq '"' -and $val[$val.Length-1] -eq '"')
$isSQ = ($val.Length -ge 2 -and $val[0] -eq "'" -and $val[$val.Length-1] -eq "'")

if ($isDQ) {$inner = $val.Substring(1, $val.Length - 2)}
elseif ($isSQ) {$inner = $val.Substring(1, $val.Length - 2)}
else {$inner = $val}

# Only redact true passwords (≥1 letter)
if ($inner -notmatch '[A-Za-z]') {return $m.Value}

$script:PasswordCount++
$red = 'XXX-PASSWORD-REDACTED-XXX'

if ($isDQ) {return "$pre$key$sep$gap`"$red`""}
if ($isSQ) {return "$pre$key$sep$gap'$red'"}

return "$pre$key$sep$gap$red"}, $RxIC)

# ---------------- WRITE OUTPUT ----------------
Set-Content -LiteralPath $OutPath -Value $text -Encoding UTF8

Write-Host -f gre "`nSafe replacement completed."
Write-Host -f c -n "Output File: "
Write-Host -f y $OutPath
Write-Host -f c -n "`nIPv4:`t`t"
Write-Host -f y -n $($Ipv4Map.Count)
Write-Host -f c -n "`tIPv6:`t`t"
Write-Host -f y $($Ipv6Map.Count)
Write-Host -f c -n "Users:`t`t"
Write-Host -f y -n $($UserMap.Count)
Write-Host -f c -n "`tPasswords:`t"
Write-Host -f y $($PasswordCount)
Write-Host -f c -n "Domains:`t"
Write-Host -f y $($DomainMap.Count)
Write-Host}

catch {Write-Error $_; exit 1}}

sal -name anonymize -value replacesensitive
sal -name anon -value replacesensitive

Export-ModuleMember -Function replacesensitive
Export-ModuleMember -Alias anon, anonymize

# Helptext.

<#
## Overview
Anonymize IPs, usernames, domains, and redact passwords.

This module replaces various strings within a user defined text file, including:

	• IPv4/IPv6 with RFC documentation ranges
	• Usernames over 3 characters in length, while preserving length and style
	• Domains when used with usernames (email or domain\user)
	• Redacts passwords with ≥1 letter, avoiding strings that represent ports like "/P: 123456"
	• Preserves whitespace and quoting exactly
	• Maintains 1:1 mappings for repeat appearances

## Sample text to test
log u:aaa.basc@somewhere.com 2:00:00UTC blarg
log domain/username.last at 1.1.1.1
2001:0db8:85a3:0000:0000:8a2e:0370:7334
::1
::7334
::0370:7334
0:0:0:0:0:0:0370:7334 
blarg /u: user
blargagain -u name -p password
"/p: secret"
"-p password"
"pwd=foo"
"/P: 123456"
"/u: user"
-u name
"--user bob"
"username=alice"
john.smith@corp.local
"user_123@domain.com"
"CORP\john.smith"
"dept/user_123"

## License
MIT License

Copyright (c) 2025 Craig Plath

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
##>