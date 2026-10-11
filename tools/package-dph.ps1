$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$version = 'DPH-0.2-experimental-Win32'
$packageRoot = Join-Path $projectRoot ('bin\distribution\' + $version)
if (Test-Path -LiteralPath $packageRoot) { throw 'Package staging already exists; use a new version or review existing contents' }
[IO.Directory]::CreateDirectory($packageRoot) | Out-Null
$files = @('bin\Win32\Debug\DelphiProjectHandoff.exe','bin\Win32\Debug\DPH.ValidateHandoff.exe','tools\WebView2\Win32\WebView2Loader.dll')
foreach ($path in $files) { Copy-Item -LiteralPath (Join-Path $projectRoot $path) -Destination $packageRoot }
foreach ($directory in @('migrations','help','docs\guides','docs\pdf')) {
    $destination = Join-Path $packageRoot $directory
    [IO.Directory]::CreateDirectory($destination) | Out-Null
    Get-ChildItem -LiteralPath (Join-Path $projectRoot $directory) -File | Where-Object Name -ne '.gitkeep' | Copy-Item -Destination $destination
}
foreach ($name in @('Rework_Requirements_Audit.txt','Rework_Acceptance.txt','rework-regression-validation.json','rework-learning-validation.json','rework-wp7-validation.json','WP7_Security_and_Limits.txt','WP7_Maintenance_Exercise.txt','WP6_WebView2_Provenance.txt')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot ('docs\'+$name)) -Destination (Join-Path $packageRoot 'docs')
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\WebView2\LICENSE.txt') -Destination (Join-Path $packageRoot 'WebView2-LICENSE.txt')
[IO.Directory]::CreateDirectory((Join-Path $packageRoot 'tools')) | Out-Null
foreach ($name in @('export-pdf.ps1','finalize-guide.py')) { Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination (Join-Path $packageRoot 'tools') }
@'
Delphi Project Handoff 0.2 reworked experimental Windows Win32 build

Extract this folder to a writable local location and run DelphiProjectHandoff.exe.
Keep help, migrations and WebView2Loader.dll beside the application. Read the
Getting started page at launch, then Learn the project and Explain. The executable is
the validated Win32 Debug build. Microsoft WebView2 Runtime is required only for
embedded preview; no runtime installer is run automatically. Offline exported
HTML can also be inspected independently. LibreOffice and Python 3.13 with pypdf
are optional prerequisites for tools/export-pdf.ps1, not for normal analysis.

DPH reads an explicitly selected Delphi project without compiling or executing
it. Store each knowledge database outside its selected source tree. Copy a cache
with its adjacent .dphdb.views folder. Use Relocate verified source for an exact
source move; unrelated or changed inputs cannot claim identity continuity.

Read docs/Rework_Acceptance.txt, Rework_Requirements_Audit.txt and the guides
before relying on analysis. This version adds guided lessons, source-based object
explanations, callback traces, labeled/collapsed procedure diagrams, imported PNG
screenshots and richer offline publication. Form designs remain approximate.
The prior blanket WP7 completion claim is withdrawn. The pinned
large reference remains partial. Independent first-time-programmer acceptance
and agreed release performance budgets are outstanding. This is an experimental
distribution, not a claim that every formal product acceptance gate has passed.

Validate an export with DPH.ValidateHandoff.exe <bundle> <trusted fingerprint>.
The optional --allow-stale flag permits integrity checks on historical/partial
exports while retaining their stale status. Unsigned hashes are not signatures.

Atlas, external AI/translation and runtime instrumentation remain disabled.
The converter reference corpus, knowledge databases, source snapshots and owner
AGENTS.md are not included in this binary distribution.
'@ | Set-Content -LiteralPath (Join-Path $packageRoot 'README.txt') -Encoding UTF8
$hashes = [ordered]@{}
foreach ($file in Get-ChildItem -LiteralPath $packageRoot -File -Recurse | Sort-Object FullName) {
    $relative = $file.FullName.Substring($packageRoot.Length+1).Replace('\','/')
    $hashes[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
}
$hashes | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $packageRoot 'SHA256.json') -Encoding UTF8
Add-Type -AssemblyName System.IO.Compression.FileSystem
$binaryZip = Join-Path $projectRoot ('export\' + $version + '.zip')
if (Test-Path -LiteralPath $binaryZip) { throw 'Distribution already exists; review before replacing' }
[IO.Compression.ZipFile]::CreateFromDirectory($packageRoot,$binaryZip)
$sourceZip = Join-Path $projectRoot 'source distributions\DPH-0.2-experimental-source.zip'
if (Test-Path -LiteralPath $sourceZip) { throw 'Source distribution already exists; review before replacing' }
$sourceFiles = & 'C:\Program Files\Git\cmd\git.exe' ls-files --cached --others --exclude-standard
if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate intended source files' }
$archive = [IO.Compression.ZipFile]::Open($sourceZip,[IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($relative in $sourceFiles) {
        if ($relative.StartsWith('source distributions/') -or $relative.StartsWith('export/') -or $relative.EndsWith('.gitkeep')) { continue }
        $path = Join-Path $projectRoot $relative
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        if ((Get-Item -LiteralPath $path).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse source artifact cannot be packaged' }
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$path,$relative,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $archive.Dispose() }
$verificationRoot = Join-Path $projectRoot ('bin\distribution-verify-' + [Guid]::NewGuid().ToString('N'))
[IO.Compression.ZipFile]::ExtractToDirectory($binaryZip,$verificationRoot)
$recorded = Get-Content -LiteralPath (Join-Path $verificationRoot 'SHA256.json') -Raw | ConvertFrom-Json
foreach ($property in $recorded.PSObject.Properties) {
    if ((Get-FileHash -LiteralPath (Join-Path $verificationRoot $property.Name) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $property.Value) { throw 'Relocated binary distribution checksum mismatch' }
}
[ordered]@{ version=$version; binary=$binaryZip; binary_sha256=(Get-FileHash -LiteralPath $binaryZip -Algorithm SHA256).Hash.ToLowerInvariant();
    source=$sourceZip; source_sha256=(Get-FileHash -LiteralPath $sourceZip -Algorithm SHA256).Hash.ToLowerInvariant();
    extracted_files=@($recorded.PSObject.Properties).Count; validated_utc=[DateTime]::UtcNow.ToString('o'); verification_directory=$verificationRoot;
    acceptance='experimental rework; see explicit remaining requirements and human acceptance' } | ConvertTo-Json -Depth 4 | Set-Content docs\rework-distribution-validation.json -Encoding UTF8
Write-Output "PACKAGED and verified $binaryZip and $sourceZip"
