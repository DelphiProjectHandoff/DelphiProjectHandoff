param(
 [ValidatePattern('^[0-9]+(\.[0-9]+){2,3}$')][string]$Version='0.8.0.21',
 [string]$Win32BuildDirectory='bin\Win32\Release'
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot=[IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$packages=@()
foreach ($arch in @('Win64','Win32')) {
 $packageName='DPH-'+$Version+'-experimental-'+$arch
 $packageRoot=Join-Path $projectRoot ('bin\distribution\'+$packageName)
 if (Test-Path -LiteralPath $packageRoot) {throw "Package staging already exists: $packageRoot"}
 [IO.Directory]::CreateDirectory($packageRoot) | Out-Null
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
foreach ($directory in @('migrations','help','images and icons')) {
 Copy-Item -LiteralPath (Join-Path $projectRoot $directory) -Destination (Join-Path $packageRoot $directory) -Recurse
}
$offlineTranslation=Join-Path $projectRoot 'Localization\OfflineTranslation'
if (-not (Test-Path -LiteralPath (Join-Path $offlineTranslation 'package\worker\bergamot-translator-worker.wasm') -PathType Leaf)) {
 throw 'Offline German translation engine is missing'
}
Copy-Item -LiteralPath $offlineTranslation -Destination (Join-Path $packageRoot 'Localization\OfflineTranslation') -Recurse
foreach ($relative in @('LICENSE','THIRD_PARTY_NOTICES.md','docs\guides\DPH_User_Guide.docx','docs\guides\DPH_Engineering_Guide.docx','docs\guides\Change_Guide.txt','docs\guides\Run_And_Test.txt','docs\guides\Workspace_Operations.txt','docs\pdf\DPH_User_Guide.pdf','docs\pdf\DPH_Engineering_Guide.pdf','Databases\README.txt',("docs\guides\Release_Notes_$Version.txt"))) {
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
@"
Delphi Project Handoff
Experimental Windows desktop handoff application - version $Version

1. Extract this whole folder to a writable local location. This is the
   ready-to-run edition; no RAD Studio or DAT language-component installation
   is needed. Do not open a .dproj to run this edition.
2. Open the $arch folder and double-click DelphiProjectHandoff.exe.
   This ZIP contains only the $arch edition. To use the other architecture,
   download its separately labeled ZIP from the same release page.
3. Click Open application and select a Delphi .dproj, .dpr, or .groupproj.
   DPH reads the project; it does not compile or run the selected application.
4. Start with Handoff dossier for the captured purpose evidence, startup
   forms, commands, data candidates, and questions. Use Learning library,
   Project map, Screenshots, and Application diagrams for deeper inspection.
   Use Rescan project after attached source files change. The dossier also
   lists captured build paths, component leads, and database templates.
   In Project map, select a control or routine and choose Change Guide to
   review incoming uses, nearby dependencies, files, checks, and cited
   evidence before editing. The guide narrative is English-language beta
   content; its native navigation buttons use your selected language pack.
5. Screenshots reconstruct saved controls from .fmx and .dfm form files on
   demand and open at 90 percent zoom. They are not captures of the running
   application; custom painting and runtime data may differ.
6. Choose your language from the selector in the main header. All 35 language
   packs work offline and remain beside this edition's executable.
   The experimental English-to-German project-text model is also bundled in
   Localization\OfflineTranslation and runs without Internet access.
7. A new capture stays temporary. Click Save project at any time to keep it.
   When closing DPH or opening another project, choose Yes to save it as a
   .dphdb, No to discard it, or Cancel
   to continue. Keep a saved .dphdb and its adjacent .dphdb.views folder
   together. Use Open saved project to restore them later.

A centered progress window shows the current step and percentage during a new
capture. The Learning library reads guides from the selected project's docs folder and
the project's README. The Read public websites checkbox is off by default.
Leave it off for fully offline use. When enabled, eligible public HTTPS pages
from that project's sitemap or documents may appear in the Learning library.

The included guides and HTML help describe the app-specific learning route.
Keep all supplied files together. Microsoft WebView2 Runtime is needed for
embedded pages; its supplied loader is a separate file.

DPH reads source and project-local documents without changing or running the
selected application. It generates empty design views from form definitions.
This package contains no owner lesson databases or private documents.
"@ | Set-Content -LiteralPath (Join-Path $packageRoot 'README.txt') -Encoding UTF8
$hashes=[ordered]@{}
foreach ($file in Get-ChildItem -LiteralPath $packageRoot -File -Recurse | Sort-Object FullName) {
 if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) {throw 'Reparse package content is not permitted'}
  $relative=$file.FullName.Substring($packageRoot.Length+1).Replace('\','/')
  if ($relative -match '(?i)(^|/)(tests|samples|tools)/|\.(dproj|dpr|dpk|pas|fmx|dphdb)$') {
   throw "Development or owner file in Windows package: $relative"
  }
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
 $packages+=([ordered]@{architecture=$arch;binary=$binaryZip;binary_sha256=(Get-FileHash -LiteralPath $binaryZip -Algorithm SHA256).Hash.ToLowerInvariant();files=$hashes.Count;extracted_file_check='PASS; temporary extraction removed'})
 Write-Output "PACKAGED AND VERIFIED $binaryZip"
}
[ordered]@{version=$Version;packages=$packages;result='PASS package integrity for both architectures; independent beginner acceptance not performed'} |
 ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $projectRoot 'docs\validation\reports\learning-distribution-validation.json') -Encoding UTF8
