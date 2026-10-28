[CmdletBinding()]
param(
    [ValidateSet('RunWeb', 'BuildWeb', 'Check')]
    [string]$Action = 'RunWeb',
    [string]$EnvFile = '.env',
    [string]$FlutterPath = 'flutter',
    [int]$Port = 5177
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$taskEnvPath = if ([IO.Path]::IsPathRooted($EnvFile)) { $EnvFile } else { Join-Path $repoRoot $EnvFile }
if (!(Test-Path -LiteralPath $taskEnvPath -PathType Leaf)) {
    throw 'Create .env from .env.example, then fill in your Supabase URL and public client key.'
}

# Parse assignments as data. Never dot-source, Invoke-Expression, expand
# variables or print the file: it may contain optional private CLI credentials.
$settings = @{}
$lineNumber = 0
foreach ($line in [IO.File]::ReadAllLines($taskEnvPath)) {
    $lineNumber++
    $trimmed = $line.Trim()
    if (!$trimmed -or $trimmed.StartsWith('#')) { continue }
    if ($trimmed -notmatch '^(?:export\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
        throw "Invalid environment assignment at line $lineNumber."
    }
    $settingName = $Matches[1]
    $settingValue = $Matches[2].Trim()
    if ($settings.ContainsKey($settingName)) { throw "Duplicate environment variable: $settingName" }
    if ($settingValue.StartsWith('"') -or $settingValue.StartsWith("'")) {
        $quote = $settingValue.Substring(0, 1)
        if ($settingValue.Length -lt 2 -or !$settingValue.EndsWith($quote)) {
            throw "Unclosed quoted value at line $lineNumber."
        }
        $settingValue = $settingValue.Substring(1, $settingValue.Length - 2)
    } else {
        $settingValue = ($settingValue -replace '\s+#.*$', '').Trim()
    }
    $settings[$settingName] = $settingValue
}

$clientKey = $settings['SUPABASE_PUBLISHABLE_KEY']
if (!$clientKey) { $clientKey = $settings['SUPABASE_ANON_KEY'] }
$projectUrl = $settings['SUPABASE_URL']
$uri = $null
if (!$projectUrl -or !$clientKey -or $projectUrl.Contains('YOUR_PROJECT_REF') -or
    ![Uri]::TryCreate($projectUrl, [UriKind]::Absolute, [ref]$uri) -or $uri.UserInfo -or
    ($uri.Scheme -ne 'https' -and !($uri.Scheme -eq 'http' -and $uri.Host -in @('127.0.0.1', 'localhost')))) {
    throw 'Fill in a valid SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY (or SUPABASE_ANON_KEY).'
}
if ($clientKey.StartsWith('sb_secret_')) { throw 'Use a public client key, never a secret/service-role key.' }
if (!$clientKey.StartsWith('sb_publishable_')) {
    try {
        $segment = $clientKey.Split('.')[1].Replace('-', '+').Replace('_', '/')
        $segment = $segment.PadRight($segment.Length + ((4 - $segment.Length % 4) % 4), '=')
        $claims = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($segment)) | ConvertFrom-Json
        if ($claims.role -ne 'anon') { throw 'Unexpected client role' }
    } catch { throw 'SUPABASE_ANON_KEY must be a public anon key; server credentials cannot be used in Flutter.' }
}
if ($Action -eq 'Check') {
    Write-Output 'Environment format is valid. No key values printed. Server connectivity has not been checked.'
    exit 0
}

$publicConfig = @{
    SUPABASE_URL = $projectUrl
    SUPABASE_PUBLISHABLE_KEY = $clientKey
}
$publicConfigPath = Join-Path ([IO.Path]::GetTempPath()) ('daystick-public-' + [Guid]::NewGuid().ToString('N') + '.json')
$exitCode = 1
Push-Location -LiteralPath $repoRoot
try {
    # Explicit allowlist: optional access token / DB password never enter here.
    [IO.File]::WriteAllText($publicConfigPath, ($publicConfig | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
    if ($Action -eq 'BuildWeb') {
        & $FlutterPath --no-version-check build web --release --web-renderer html "--dart-define-from-file=$publicConfigPath"
    } else {
        & $FlutterPath --no-version-check run -d web-server --web-port $Port "--dart-define-from-file=$publicConfigPath"
    }
    $exitCode = $LASTEXITCODE
} finally {
    Pop-Location
    if ([IO.File]::Exists($publicConfigPath)) { [IO.File]::Delete($publicConfigPath) }
}
exit $exitCode
