param (
    [switch]$AndroidDebug,
    [switch]$AndroidRelease,
    [switch]$AppBundle,
    [switch]$Windows,
    [switch]$Web,
    [switch]$All,
    [switch]$SkipTests,
    [string]$OutputDirectory = "$PSScriptRoot\..\..\dist",
    [int]$WebPort = 3000
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot\config_helpers.ps1"

Write-Host "Validating configuration..." -ForegroundColor Cyan
$config = Get-AppConfiguration
$url = $config['SUPABASE_URL']
$key = $config['SUPABASE_PUBLISHABLE_KEY']
Write-Host "Configuration OK." -ForegroundColor Green

Write-Host "Validating Flutter..." -ForegroundColor Cyan
try {
    $null = flutter --version
} catch {
    Write-Error "Flutter is not available."
    exit 1
}

# Resolve version
$flutterDir = Resolve-Path "$PSScriptRoot\..\.." | Select-Object -ExpandProperty Path
$pubspecPath = Join-Path $flutterDir "pubspec.yaml"
$pubspecContent = Get-Content $pubspecPath
$versionLine = $pubspecContent | Where-Object { $_ -match "^version:\s*(.+)$" }
if (-not $versionLine) {
    Write-Error "Could not find version in pubspec.yaml."
    exit 1
}
$versionFull = $versionLine -replace "^version:\s*", ""
$versionParts = $versionFull -split "\+"
$version = $versionParts[0]
$buildNumber = if ($versionParts.Count -gt 1) { $versionParts[1] } else { "0" }

$releaseName = "Ambarket-$version-$buildNumber"
$releaseDir = Join-Path $OutputDirectory $releaseName

if (-not (Test-Path $releaseDir)) {
    New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
} else {
    Write-Host "Warning: Output directory already exists: $releaseDir" -ForegroundColor Yellow
}
Push-Location "$flutterDir"

if (-not $SkipTests) {
    Write-Host "Running Quality Gates..." -ForegroundColor Cyan

    Write-Host "1. flutter pub get"
    flutter pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host "2. dart format"
    dart format --output=none --set-exit-if-changed .
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host "3. flutter analyze"
    flutter analyze
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

    Write-Host "4. flutter test --coverage"
    flutter test --coverage
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

$buildAndroidDebug = $AndroidDebug -or $All
$buildAndroidRelease = $AndroidRelease -or $All
$buildAppBundle = $AppBundle -or $All
$buildWindows = $Windows -or $All
$buildWeb = $Web -or $All

$manifest = @()
$manifest += "# Build Manifest for $releaseName"
$manifest += ""

function Build-WithConfig {
    param([string[]]$argsList, [string]$targetName)
    Write-Host "Building $targetName..." -ForegroundColor Cyan
    $fullArgs = $argsList + "--dart-define=SUPABASE_URL=$url" + "--dart-define=SUPABASE_PUBLISHABLE_KEY=$key"
    & flutter $fullArgs
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed for $targetName."
        exit $LASTEXITCODE
    }
}

if ($buildAndroidDebug) {
    Build-WithConfig -argsList @("build", "apk", "--debug") -targetName "Android Debug APK"
    $apkPath = "build\app\outputs\flutter-apk\app-debug.apk"
    if (Test-Path $apkPath) {
        $outPath = Join-Path $releaseDir "$releaseName-android-debug.apk"
        Copy-Item $apkPath $outPath -Force
        $manifest += "- Android Debug APK: READY"
    }
}

if ($buildAndroidRelease) {
    $manifest += "- Android Release APK: BLOCKED (No release signing configured)"
    $noticePath = Join-Path $releaseDir "ANDROID_RELEASE_SIGNING_REQUIRED.md"
    Set-Content -Path $noticePath -Value "# Android Release Signing Required`n`nA private keystore is required for public distribution. The debug APK is provided for testing."
}

if ($buildAppBundle) {
    $manifest += "- Android App Bundle: BLOCKED (No release signing configured)"
}

if ($buildWindows) {
    Build-WithConfig -argsList @("build", "windows", "--release") -targetName "Windows Package"
    $winDir = "build\windows\x64\runner\Release"
    if (Test-Path $winDir) {
        $outZip = Join-Path $releaseDir "$releaseName-windows-x64.zip"
        Compress-Archive -Path "$winDir\*" -DestinationPath $outZip -Force
        $manifest += "- Windows Package: READY"
    }
}

if ($buildWeb) {
    Build-WithConfig -argsList @("build", "web", "--release") -targetName "Web Package"
    $webDir = "build\web"
    if (Test-Path $webDir) {
        $outZip = Join-Path $releaseDir "$releaseName-web.zip"
        # We need the contents at the root of the ZIP
        Compress-Archive -Path "$webDir\*" -DestinationPath $outZip -Force
        $manifest += "- Web Package: READY"
    }
}

Set-Content -Path (Join-Path $releaseDir "BUILD_MANIFEST.md") -Value ($manifest -join "`n")

Write-Host "Generating Checksums..." -ForegroundColor Cyan
Push-Location $releaseDir
$checksums = @()
Get-ChildItem -File | Where-Object { $_.Name -ne "SHA256SUMS.txt" } | ForEach-Object {
    $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
    $checksums += "$hash  $($_.Name)"
}
Set-Content -Path "SHA256SUMS.txt" -Value ($checksums -join "`n")
Pop-Location

Pop-Location
Write-Host "Build process completed for selected targets." -ForegroundColor Green
