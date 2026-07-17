$ErrorActionPreference = "Stop"

. "$PSScriptRoot\config_helpers.ps1"

Write-Host "Validating local configuration..." -ForegroundColor Cyan
$config = Get-AppConfiguration
Write-Host "Configuration validation successful." -ForegroundColor Green

Write-Host "Verifying Flutter..." -ForegroundColor Cyan
try {
    $null = flutter --version
} catch {
    Write-Error "Flutter is not available in PATH."
    exit 1
}

$port = 3000
Write-Host "Checking port $port..." -ForegroundColor Cyan
$portCheck = netstat -ano | findstr ":$port "
if ($portCheck) {
    Write-Error "Port $port is already in use. Please free the port before running local web."
    exit 1
}

Write-Host "Platform: web-server"
Write-Host "Port: $port"
Write-Host "Starting Flutter Web Server..." -ForegroundColor Yellow

$url = $config['SUPABASE_URL']
$key = $config['SUPABASE_PUBLISHABLE_KEY']

$flutterProcess = Start-Process -NoNewWindow -Wait -PassThru -FilePath "flutter" -ArgumentList "run", "-d", "web-server", "--web-port", "$port", "--dart-define=SUPABASE_URL=$url", "--dart-define=SUPABASE_PUBLISHABLE_KEY=$key"

if ($flutterProcess.ExitCode -ne 0) {
    Write-Error "Flutter run failed with exit code $($flutterProcess.ExitCode)."
    exit $flutterProcess.ExitCode
}

Write-Host "Flutter run completed successfully." -ForegroundColor Green
