param([ValidatePattern('^[0-9]+(\.[0-9]+){2,3}$')][string]$Version='0.8.0.15')

$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot=[IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$archiveName='DPH_v'+$Version.Replace('.','_')+'_Source_Distribution_'+(Get-Date -Format 'yyyy-MM-dd_HHmmss')+'.zip'
$archivePath=Join-Path $projectRoot ('source distributions\'+$archiveName)
if (Test-Path -LiteralPath $archivePath) {throw "Archive already exists: $archivePath"}
$languagePacks=Get-ChildItem -LiteralPath (Join-Path $projectRoot 'Localization\Languages') -File -Filter '*.json' |
  Where-Object {$_.Name -notlike '*.layout-proposal.json'}
if($languagePacks.Count -ne 35) {throw "Expected 35 DPH language packs; found $($languagePacks.Count)"}

$files=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
foreach($relative in @('DelphiProjectHandoff.dpr','DelphiProjectHandoff.dproj',
  'DelphiProjectHandoff.res','README.md','LICENSE','THIRD_PARTY_NOTICES.md','docs\guides\Run_And_Test.txt',
  'docs\guides\DPH_User_Guide.docx','docs\guides\DPH_Engineering_Guide.docx',
  'docs\pdf\DPH_User_Guide.pdf','docs\pdf\DPH_Engineering_Guide.pdf')) {
 [void]$files.Add($relative)
}
foreach($file in Get-ChildItem -LiteralPath $projectRoot -File) {
 if($file.Name -match '^DPH\..*\.(pas|fmx)$') {[void]$files.Add($file.Name)}
}
foreach($folder in @('dependencies\DelphiAppTranslation','Localization','migrations','help',
  'images and icons','samples\OrderPractice','docs\guides\source',
  'docs\guides\assets','tests','tools\WebView2','export\DAT-component-kit')) {
 $fullFolder=Join-Path $projectRoot $folder
 foreach($file in Get-ChildItem -LiteralPath $fullFolder -File -Recurse) {
  if($file.Attributes -band [IO.FileAttributes]::ReparsePoint) {throw "Reparse point in source package: $($file.FullName)"}
  [void]$files.Add($file.FullName.Substring($projectRoot.Length+1))
 }
}
foreach($file in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'tools') -File) {
 if($file.Extension -in @('.cmd','.ps1','.dpr','.py')) {
  [void]$files.Add('tools\'+$file.Name)
 }
}

$readme=@"
DELPHI PROJECT HANDOFF $Version - EDITABLE SOURCE DISTRIBUTION

This archive contains the Delphi application source, editable FMX forms,
project and resource files, database migrations, the local HTML help, graphics,
guide source, guide illustrations, the OrderPractice example, all 35 offline
interface language packs, the experimental bundled English-to-German project-text
model, and the bundled build dependencies. It contains no personal .dphdb databases,
Git history, or compiled DPH executable.

TO BUILD
1. Extract the entire ZIP into a writable local folder. Do not build in the ZIP.
2. Before opening the main form in RAD Studio 37, choose Component > Install
   Packages > Add and select the supplied DAT FMX design BPL under
   export\DAT-component-kit\DelphiProjectHandoff\DesignPackages\Win32\Release.
   Keep its adjacent runtime BPLs. The project already includes the DAT source
   search path; there is no separate dependency preparation command. See
   export\DAT-component-kit\DelphiProjectHandoff\README.txt for details.
3. Open DelphiProjectHandoff.dproj. Select Win64 or Win32 and Release; Build.
4. Find the executable in bin\Win64\Release or bin\Win32\Release. Keep the
   corresponding WebView2Loader.dll beside it. The project copies that loader
   automatically after a successful build.
5. Run the executable from the extracted project folder. Keep migrations,
   help, images and icons, and Localization in that folder. The German project-text
   trial reads its WebAssembly model from Localization\OfflineTranslation without Internet access.
   See docs\guides\Run_And_Test.txt
   for the application's first-use and validation steps.

The Microsoft WebView2 Runtime is required for embedded HTML learning views.
LibreOffice at its standard Windows path is needed to extract text from PDF,
legacy Word, RTF and several other older word-processing formats.
The selected Delphi application is read as input; DPH does not run or modify it.
Start with Handoff dossier. A new capture remains temporary until the user
clicks Save project, or chooses Yes at close or on a project change. The save
dialog starts in DPH's databases folder and suggests a dated name if an older
save already has the project name; a confirmation shows the full saved path.
Keep the .dphdb and adjacent .dphdb.views folder together. On failure,
DPH reports the error and retains the temporary capture. No discards the
capture and Cancel keeps it open. Rescan project checks attached source for changes.
The dossier maps captured directories and project build paths and links component
and database evidence. Generated form views are reconstructions, not runtime
screenshots.
The Read public websites checkbox is off by default and controls optional
HTTPS requests for public sites referenced in selected project documents.
The included third-party dependency folders contain their own license files.

SHA256.txt lists every packaged source file and its SHA-256 digest. The
DelphiProjectHandoff.res file is part of the source release because the
DelphiProjectHandoff.dpr file references it.
"@

$hashLines=[Collections.Generic.List[string]]::new()
$archive=[IO.Compression.ZipFile]::Open($archivePath,[IO.Compression.ZipArchiveMode]::Create)
try {
 foreach($relative in @('bin/','dcu/','docs/guides/','docs/pdf/','export/','Localization/','help/',
   'images and icons/','samples/','source distributions/','tools/','Databases/')) {
   [void]$archive.CreateEntry($relative)
 }
 foreach($relative in ($files | Sort-Object)) {
   $fullPath=[IO.Path]::GetFullPath((Join-Path $projectRoot $relative))
   if(-not $fullPath.StartsWith($projectRoot+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {throw "Unsafe source path: $relative"}
   if(-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {throw "Required source file missing: $relative"}
   $entryPath=$relative.Replace('\','/')
   [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$fullPath,$entryPath,[IO.Compression.CompressionLevel]::Optimal)
   $hash=(Get-FileHash -LiteralPath $fullPath -Algorithm SHA256).Hash.ToLowerInvariant()
   $hashLines.Add("$hash  $entryPath")
 }
 foreach($item in @(@('SOURCE_DISTRIBUTION_README.txt',$readme),@('SHA256.txt',($hashLines -join "`n")+"`n"))) {
   $entry=$archive.CreateEntry($item[0],[IO.Compression.CompressionLevel]::Optimal)
   $writer=[IO.StreamWriter]::new($entry.Open(),[Text.UTF8Encoding]::new($false))
   try {$writer.Write($item[1])} finally {$writer.Dispose()}
 }
} finally {$archive.Dispose()}

$check=[IO.Compression.ZipFile]::OpenRead($archivePath)
try {
 $names=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
 foreach($entry in $check.Entries) {[void]$names.Add($entry.FullName)}
 foreach($required in @('DelphiProjectHandoff.dpr','DelphiProjectHandoff.dproj',
   'DelphiProjectHandoff.res','DPH.UI.Main.pas','DPH.UI.Main.fmx',
   'images and icons/DPH-App.ico','Localization/Languages/en-US.json',
   'export/DAT-component-kit/DelphiProjectHandoff/README.txt',
   'SOURCE_DISTRIBUTION_README.txt','SHA256.txt')) {
   if(-not $names.Contains($required)) {throw "Source archive verification failed: $required is absent"}
 }
 foreach($line in $hashLines) {
   $expected=$line.Substring(0,64)
   $name=$line.Substring(66)
   $entry=$check.GetEntry($name)
   if($null -eq $entry) {throw "Source archive verification failed: $name is absent"}
   $stream=$entry.Open()
   try {
     $sha=[Security.Cryptography.SHA256]::Create()
     try {$actual=([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','').ToLowerInvariant()}
     finally {$sha.Dispose()}
   } finally {$stream.Dispose()}
   if($actual -ne $expected) {throw "Source archive verification failed: $name checksum differs"}
 }
} finally {$check.Dispose()}

Write-Output "SOURCE_DISTRIBUTION=$archivePath"
Write-Output "FILES=$($files.Count) SHA256=$((Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant())"
