$ErrorActionPreference = 'Stop'

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$envPath = Join-Path $projectRoot '.env'

if (-not (Test-Path -LiteralPath $envPath)) {
  Write-Error 'Local .env tidak ditemukan. Buat file .env lokal atau jalankan flutter dengan --dart-define.'
  exit 1
}

$values = @{}

Get-Content -LiteralPath $envPath | ForEach-Object {
  $line = $_.Trim()
  if ($line.Length -eq 0 -or $line.StartsWith('#')) {
    return
  }

  $separatorIndex = $line.IndexOf('=')
  if ($separatorIndex -le 0) {
    return
  }

  $key = $line.Substring(0, $separatorIndex).Trim()
  $value = $line.Substring($separatorIndex + 1).Trim()

  if (
    ($value.StartsWith('"') -and $value.EndsWith('"')) -or
    ($value.StartsWith("'") -and $value.EndsWith("'"))
  ) {
    $value = $value.Substring(1, $value.Length - 2)
  }

  if ($key.Length -gt 0) {
    $values[$key] = $value
  }
}

$supabaseUrl = $values['SUPABASE_URL']
$supabasePublishableKey = $values['SUPABASE_PUBLISHABLE_KEY']

if ([string]::IsNullOrWhiteSpace($supabaseUrl)) {
  Write-Error 'SUPABASE_URL belum tersedia di .env lokal.'
  exit 1
}

if ([string]::IsNullOrWhiteSpace($supabasePublishableKey)) {
  Write-Error 'SUPABASE_PUBLISHABLE_KEY belum tersedia di .env lokal.'
  exit 1
}

$parsedUrl = $null
if (-not [Uri]::TryCreate($supabaseUrl, [UriKind]::Absolute, [ref]$parsedUrl)) {
  Write-Error 'SUPABASE_URL di .env lokal tidak valid.'
  exit 1
}

Push-Location $projectRoot
try {
  flutter run `
    -d web-server `
    --release `
    --web-port 3000 `
    --dart-define "SUPABASE_URL=$supabaseUrl" `
    --dart-define "SUPABASE_PUBLISHABLE_KEY=$supabasePublishableKey"
} finally {
  Pop-Location
}
