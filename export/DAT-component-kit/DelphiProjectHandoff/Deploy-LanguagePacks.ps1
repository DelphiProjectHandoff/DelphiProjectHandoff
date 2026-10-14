param(
  [Parameter(Mandatory=$true)][string]$ApplicationDirectory,
  [string]$ProjectDirectory = '',
  [switch]$SkipConfiguredDestinations)
$ErrorActionPreference = 'Stop'
if (-not [System.IO.Path]::IsPathRooted($ApplicationDirectory)) {
  if ([string]::IsNullOrWhiteSpace($ProjectDirectory)) {
    $ProjectDirectory = (Get-Location).Path
  }
  $ApplicationDirectory = Join-Path $ProjectDirectory $ApplicationDirectory
}
$ApplicationDirectory = [System.IO.Path]::GetFullPath($ApplicationDirectory)
$source = Join-Path $PSScriptRoot 'Localization\Languages'
$manifestFile = Join-Path $PSScriptRoot 'integrity-sha256.json'
if (-not (Test-Path -LiteralPath $manifestFile -PathType Leaf)) { throw 'Integrity manifest is missing.' }
$integrity = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
if ([int]$integrity.schemaVersion -ne 1) { throw 'Unsupported integrity manifest schema.' }
function Deploy-LanguagePacks([string]$TargetDirectory) {
  $resolvedTarget = [System.IO.Path]::GetFullPath($TargetDirectory)
  $localization = Join-Path $resolvedTarget 'Localization'
  $destination = Join-Path $resolvedTarget 'Localization\Languages'
  $staging = Join-Path $localization ('Languages.staging-' + [guid]::NewGuid().ToString('N'))
  $previous = Join-Path $localization 'Languages.previous'
  New-Item -ItemType Directory -Path $localization -Force | Out-Null
  New-Item -ItemType Directory -Path $staging -Force | Out-Null
  try {
    $sourceFiles = @(Get-ChildItem -LiteralPath $source -Filter '*.json' -File)
    if ($sourceFiles.Count -eq 0) { throw 'No language packs were found.' }
    foreach ($file in $sourceFiles) {
      $relative = 'Localization/Languages/' + $file.Name
      $property = $integrity.PSObject.Properties[$relative]
      if ($null -eq $property) { throw "No integrity entry for $relative" }
      $expected = ([string]$property.Value).ToLowerInvariant()
      $actual = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
      if ($actual -ne $expected) { throw "Source hash mismatch: $relative" }
      $stagedFile = Join-Path $staging $file.Name
      Copy-Item -LiteralPath $file.FullName -Destination $stagedFile
      $copied = (Get-FileHash -LiteralPath $stagedFile -Algorithm SHA256).Hash.ToLowerInvariant()
      if ($copied -ne $expected) { throw "Staged hash mismatch: $relative" }
    }
    if (Test-Path -LiteralPath $previous) { Remove-Item -LiteralPath $previous -Recurse -Force }
    if (Test-Path -LiteralPath $destination) { Move-Item -LiteralPath $destination -Destination $previous }
    try { Move-Item -LiteralPath $staging -Destination $destination }
    catch {
      if ((-not (Test-Path -LiteralPath $destination)) -and (Test-Path -LiteralPath $previous)) { Move-Item -LiteralPath $previous -Destination $destination }
      throw
    }
    Write-Output "Language packs deployed and verified at $destination"
  } finally {
    if (Test-Path -LiteralPath $staging) { Remove-Item -LiteralPath $staging -Recurse -Force }
  }
}
Deploy-LanguagePacks $ApplicationDirectory
if (-not $SkipConfiguredDestinations) {
  $settingsFile = Join-Path $PSScriptRoot 'deployment-destinations.json'
  if (Test-Path -LiteralPath $settingsFile -PathType Leaf) {
    $settings = Get-Content -LiteralPath $settingsFile -Raw | ConvertFrom-Json
    foreach ($configuredDestination in @($settings.destinations)) {
      if ([string]::IsNullOrWhiteSpace([string]$configuredDestination)) { continue }
      if (Test-Path -LiteralPath $configuredDestination -PathType Container) {
        if ([System.IO.Path]::GetFullPath($configuredDestination) -ne $ApplicationDirectory) {
          Deploy-LanguagePacks $configuredDestination
        }
      } else {
        Write-Warning "Configured application folder is unavailable; deployment skipped: $configuredDestination"
      }
    }
  }
}
