# PowerShell script to build the Japanese dictionary database
# Run from the project root: .\tools\convert.ps1

$ErrorActionPreference = "Stop"

Write-Host "Building Japanese dictionary database..." -ForegroundColor Cyan

# Ensure we're in the project root
$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

# Create output directory if needed
$outputDir = "lib/assets"
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Remove existing database if present
$dbPath = "$outputDir/jpn.db"
if (Test-Path $dbPath) {
    Remove-Item $dbPath
    Write-Host "Removed existing database" -ForegroundColor Yellow
}

# Download and extract Kanji API data
Write-Host "`nDownloading Kanji API data..." -ForegroundColor Green
Invoke-WebRequest -Uri "https://kanjiapi.dev/kanjiapi_full.zip" -OutFile "tools/kanjiapi_full.zip"
Expand-Archive -Path "tools/kanjiapi_full.zip" -DestinationPath "tools" -Force

Write-Host "Converting Kanji data to SQLite..." -ForegroundColor Green
dart --packages=".dart_tool/package_config.json" tools/json_to_sqlite.dart tools/kanjiapi_full.json $dbPath

# Clean up Kanji files
Remove-Item "tools/kanjiapi_full.zip"
Remove-Item "tools/kanjiapi_full.json"

# Download JMdict data (using curl because Invoke-WebRequest doesn't support FTP)
Write-Host "`nDownloading JMdict dictionary data..." -ForegroundColor Green
curl.exe -o "tools/JMdict_e.gz" "ftp://ftp.edrdg.org/pub/Nihongo/JMdict_e.gz"

# Decompress gzip file using .NET
Write-Host "Decompressing JMdict data..." -ForegroundColor Green
$gzipPath = "tools/JMdict_e.gz"
$outputPath = "tools/JMdict_e"

$inputStream = [System.IO.File]::OpenRead((Resolve-Path $gzipPath))
$outputStream = [System.IO.File]::Create((Join-Path $projectRoot $outputPath))
$gzipStream = New-Object System.IO.Compression.GZipStream($inputStream, [System.IO.Compression.CompressionMode]::Decompress)

$gzipStream.CopyTo($outputStream)
$gzipStream.Close()
$outputStream.Close()
$inputStream.Close()

Write-Host "Converting JMdict data to SQLite..." -ForegroundColor Green
dart --packages=".dart_tool/package_config.json" tools/jmdict_to_sqlite.dart tools/JMdict_e $dbPath

# Clean up JMdict files
Remove-Item "tools/JMdict_e.gz"
Remove-Item "tools/JMdict_e"

Write-Host "`nDatabase built successfully at $dbPath" -ForegroundColor Cyan
