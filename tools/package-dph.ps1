param(
 [ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')][string]$Version='0.6.1',
 [string]$Win32BuildDirectory='bin\Win32\Release'
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot=[IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$packageName='DPH-'+$Version+'-experimental-Windows'
$packageRoot=Join-Path $projectRoot ('bin\distribution\'+$packageName)
if (Test-Path -LiteralPath $packageRoot) {throw 'Package staging already exists; choose a fresh version'}
[IO.Directory]::CreateDirectory($packageRoot) | Out-Null
foreach ($arch in @('Win32','Win64')) {
 $archRoot=Join-Path $packageRoot $arch
 [IO.Directory]::CreateDirectory($archRoot) | Out-Null
 foreach ($name in @('DelphiProjectHandoff.exe','WebView2Loader.dll')) {
  $buildDirectory='bin\'+$arch+'\Release'
  if ($arch -eq 'Win32') {$buildDirectory=$Win32BuildDirectory}
  $source=[IO.Path]::GetFullPath((Join-Path $projectRoot (Join-Path $buildDirectory $name)))
  if (-not $source.StartsWith($projectRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {throw "Unsafe build path: $source"}
  Copy-Item -LiteralPath $source -Destination $archRoot
 }
 $languageDestination=Join-Path $archRoot 'Localization\Languages'
 [IO.Directory]::CreateDirectory($languageDestination) | Out-Null
 $packDirectory=Join-Path $projectRoot ('bin\'+$arch+'\Release\Localization\Languages')
 $packs=Get-ChildItem -LiteralPath $packDirectory -File -Filter '*.json' |
   Where-Object {$_.Name -notlike '*.layout-proposal.json'}
 if($packs.Count -ne 35) {throw "Expected 35 $arch language packs; found $($packs.Count)"}
 foreach($pack in $packs) {Copy-Item -LiteralPath $pack.FullName -Destination $languageDestination}
}
foreach ($directory in @('migrations','help','images and icons')) {
 Copy-Item -LiteralPath (Join-Path $projectRoot $directory) -Destination (Join-Path $packageRoot $directory) -Recurse
}
foreach ($relative in @('docs\guides\DPH_User_Guide.docx','docs\guides\DPH_Engineering_Guide.docx','docs\guides\Run_And_Test.txt','docs\guides\Developer_Test_Directions.txt','docs\guides\Workspace_Operations.txt','docs\pdf\DPH_User_Guide.pdf','docs\pdf\DPH_Engineering_Guide.pdf','Databases\README.txt','tools\export-pdf.ps1','tools\finalize-guide.py')) {
 $destination=Join-Path $packageRoot $relative
 [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
 Copy-Item -LiteralPath (Join-Path $projectRoot $relative) -Destination $destination
}
Copy-Item -LiteralPath (Join-Path $projectRoot 'tools\WebView2\LICENSE.txt') -Destination (Join-Path $packageRoot 'WebView2-LICENSE.txt')
foreach ($name in @('LICENSE','SNAPSHOT.json')) {
 $destination=Join-Path $packageRoot ('licenses\DelphiAppTranslation\'+$name)
 [IO.Directory]::CreateDirectory((Split-Path -Parent $destination)) | Out-Null
 Copy-Item -LiteralPath (Join-Path $projectRoot ('dependencies\DelphiAppTranslation\'+$name)) -Destination $destination
}
@'
Delphi Project Handoff
Experimental Windows desktop learning application

1. Extract this whole folder to a writable local location.
2. On 64-bit Windows, open Win64 and double-click DelphiProjectHandoff.exe.
   Use the Win32 copy only when you need the 32-bit edition.
3. Click Open application and select the Delphi project you want to learn.
4. Use Learn the project, Learning library, Project map, Screenshots and
   Application diagrams.
5. Screenshots contains blank screen images generated inside DPH from that
   project's .fmx and .dfm form files. Runtime appearance can differ.
6. Choose your language from the selector in the main header. All 35 language
   packs work offline and remain beside each Windows edition.

The included guides and HTML help describe the app-specific learning route.
Keep all supplied files together. Microsoft WebView2 Runtime is needed for
embedded pages; its supplied loader is a separate file.

DPH reads source and project-local documents without changing or running the
selected application. It generates empty design views from form definitions.
This package contains no owner lesson databases or private documents.
'@ | Set-Content -LiteralPath (Join-Path $packageRoot 'README.txt') -Encoding UTF8
$hashes=[ordered]@{}
foreach ($file in Get-ChildItem -LiteralPath $packageRoot -File -Recurse | Sort-Object FullName) {
 if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) {throw 'Reparse package content is not permitted'}
 $relative=$file.FullName.Substring($packageRoot.Length+1).Replace('\','/')
 $hashes[$relative]=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
}
$hashes | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $packageRoot 'SHA256.json') -Encoding UTF8
$binaryZip=Join-Path $projectRoot ('export\'+$packageName+'.zip')
if (Test-Path -LiteralPath $binaryZip) {throw 'Binary ZIP already exists'}
[IO.Compression.ZipFile]::CreateFromDirectory($packageRoot,$binaryZip)
$verificationRoot=Join-Path $projectRoot ('bin\distribution-verify-'+[Guid]::NewGuid().ToString('N'))
[IO.Compression.ZipFile]::ExtractToDirectory($binaryZip,$verificationRoot)
foreach ($property in $hashes.GetEnumerator()) {
 if ((Get-FileHash -LiteralPath (Join-Path $verificationRoot $property.Key) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $property.Value) {throw 'Extracted package checksum mismatch'}
}
$verificationParent=[IO.Path]::GetFullPath((Join-Path $projectRoot 'bin'))+[IO.Path]::DirectorySeparatorChar
if (-not ([IO.Path]::GetFullPath($verificationRoot)).StartsWith($verificationParent,[StringComparison]::OrdinalIgnoreCase)) {throw 'Unsafe temporary verification path'}
[IO.Directory]::Delete($verificationRoot,$true)
[ordered]@{version=$Version;binary=$binaryZip;binary_sha256=(Get-FileHash -LiteralPath $binaryZip -Algorithm SHA256).Hash.ToLowerInvariant();files=$hashes.Count;extracted_file_check='PASS; temporary extraction removed';result='PASS package integrity; independent beginner acceptance not performed'} |
 ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $projectRoot 'docs\validation\reports\learning-distribution-validation.json') -Encoding UTF8
Write-Output "PACKAGED AND VERIFIED $binaryZip"
