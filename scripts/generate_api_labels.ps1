# Regenere lib/constants/api_label_dictionary.g.dart depuis le dictionnaire de
# l'app web Next.js (lib/constants/label-object.ts), partage par les deux apps.
#
# Usage : pwsh -File scripts/generate_api_labels.ps1
#
# A relancer des que label-object.ts change, pour que le mobile et le web
# affichent les memes libelles.

$ErrorActionPreference = 'Stop'

$root = Split-Path $PSScriptRoot -Parent
$source = Join-Path $root 'lib\constants\label-object.ts'
$target = Join-Path $root 'lib\constants\api_label_dictionary.g.dart'

if (-not (Test-Path $source)) { throw "Source introuvable : $source" }

$txt = [IO.File]::ReadAllText($source, [Text.Encoding]::UTF8)

# Delimite l'objet `const labelObject = { ... }` par equilibrage des accolades.
$marker = $txt.IndexOf('const labelObject = {')
if ($marker -lt 0) { throw "Declaration 'const labelObject' introuvable dans $source" }
$open = $txt.IndexOf('{', $marker)
$depth = 0
$close = -1
for ($k = $open; $k -lt $txt.Length; $k++) {
    if ($txt[$k] -eq '{') { $depth++ }
    elseif ($txt[$k] -eq '}') { $depth--; if ($depth -eq 0) { $close = $k; break } }
}
if ($close -lt 0) { throw "Accolade fermante de labelObject introuvable" }
$body = $txt.Substring($open + 1, $close - $open - 1)

# Cle nue ou entre guillemets (les identifiants peuvent etre accentues),
# valeur entre guillemets, eventuellement sur la ligne suivante.
$rx = [regex]'(?:"([^"\r\n]+)"|([\p{L}_][\p{L}\p{N}_]*))\s*:\s*"((?:[^"\\]|\\.)*)"'

$map = [ordered]@{}
foreach ($match in $rx.Matches($body)) {
    $key = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
    $value = $match.Groups[3].Value -replace '\\"', '"'
    # Derniere occurrence gagne, comme un litteral objet JavaScript.
    $map[$key] = $value
}

if ($map.Count -eq 0) { throw "Aucune paire extraite : le format de $source a change" }

function ConvertTo-DartLiteral([string]$s) {
    ($s -replace '\\', '\\') -replace "'", "\'" -replace '\$', '\$'
}

$sb = [Text.StringBuilder]::new()
[void]$sb.AppendLine('// GENERATED - ne pas modifier a la main.')
[void]$sb.AppendLine("// Source : lib/constants/label-object.ts (dictionnaire de l'app web Next.js).")
[void]$sb.AppendLine('// Regenerer avec scripts/generate_api_labels.ps1 apres toute modification du .ts.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('/// Libelles francais partages avec l app web, indexes par code API.')
[void]$sb.AppendLine('///')
[void]$sb.AppendLine('/// Sert de repli commun aux tables curatees de `lib/constants/` : secteurs et')
[void]$sb.AppendLine('/// domaines de formation, metiers, fonctions... Consulte apres la table')
[void]$sb.AppendLine('/// specifique et avant l humanisation du code brut.')
[void]$sb.AppendLine('const Map<String, String> kApiLabelDictionary = {')
foreach ($key in $map.Keys) {
    [void]$sb.AppendLine("  '$(ConvertTo-DartLiteral $key)': '$(ConvertTo-DartLiteral $map[$key])',")
}
[void]$sb.AppendLine('};')

[IO.File]::WriteAllText($target, $sb.ToString(), (New-Object Text.UTF8Encoding $false))
Write-Host "$($map.Count) libelles ecrits dans $target"
