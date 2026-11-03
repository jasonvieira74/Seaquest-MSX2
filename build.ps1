$ErrorActionPreference = 'Stop'

$versionRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent $versionRoot)
$assembler = Join-Path $projectRoot 'tools\sjasmplus-1.23.0\sjasmplus-1.23.0.win\sjasmplus.exe'
$outputDir = Join-Path $versionRoot 'build'
$outputRom = Join-Path $outputDir 'seaquest-v40-final-msx2.rom'
$sourceFile = (Join-Path $versionRoot 'src\main.asm').Replace('\','/')

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
Push-Location $versionRoot
try {
    & $assembler "--raw=$outputRom" $sourceFile
    if ($LASTEXITCODE -ne 0) { throw "sjasmplus failed with exit code $LASTEXITCODE" }
}
finally {
    Pop-Location
}

$rom = Get-Item -LiteralPath $outputRom
if ($rom.Length -ne 32768) { throw "Unexpected ROM size: $($rom.Length) bytes" }
Write-Host "Built $($rom.FullName) ($($rom.Length) bytes)"
