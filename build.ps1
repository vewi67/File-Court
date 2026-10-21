#requires -Version 5.1
$ErrorActionPreference = 'Stop'

$source = Join-Path $PSScriptRoot 'File-Court.ps1'
$outputDirectory = Join-Path $PSScriptRoot 'dist'
$output = Join-Path $outputDirectory 'File-Court.exe'

if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
    throw "Source script not found: $source"
}

if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name ps2exe -Scope CurrentUser -Force
}

Import-Module ps2exe -Force
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
Invoke-PS2EXE -inputFile $source -outputFile $output -noConsole -STA -DPIAware -title 'File Court' -description 'Real files. Real facts. Questionable justice.' -company 'Ghost Series' -product 'File Court' -version '1.0.0.0'

if (-not (Test-Path -LiteralPath $output -PathType Leaf)) {
    throw 'PS2EXE completed without producing File-Court.exe.'
}
Write-Host "Build complete: $output" -ForegroundColor Green
