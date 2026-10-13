param([ValidatePattern('^[0-9]+\.[0-9]+\.[0-9]+$')][string]$Version='0.5.0')
$ErrorActionPreference='Stop'
$projectRoot=[IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$packageName='DPH-'+$Version+'-experimental-Win32'
$packageRoot=Join-Path $projectRoot ('bin\distribution\'+$packageName)
if (Test-Path -LiteralPath $packageRoot) {throw 'Package staging already exists; choose a fresh version'}
[IO.Directory]::CreateDirectory($packageRoot) | Out-Null
foreach ($name in @('DelphiProjectHandoff.exe','DPH.ValidateHandoff.exe','WebView2Loader.dll')) {
 Copy-Item -LiteralPath (Join-Path $projectRoot ('bin\Win32\Debug\'+$name)) -Destination $packageRoot
}
foreach ($directory in @('migrations','help')) {
 Copy-Item -LiteralPath (Join-Path $projectRoot $directory) -Destination (Join-Path $packageRoot $directory) -Recurse
}
$practiceDestination=Join-Path $packageRoot 'samples\OrderPractice'
[IO.Directory]::CreateDirectory($practiceDestination) | Out-Null
foreach ($name in @('OrderPractice.dpr','OrderPractice.dproj','OrderForm.pas','OrderForm.fmx','lessons.json','practice-screen.png','practice-result.png','README.txt')) {
 Copy-Item -LiteralPath (Join-Path $projectRoot ('samples\OrderPractice\'+$name)) -Destination $practiceDestination
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
2. Double-click DelphiProjectHandoff.exe.
3. Click Try practice example for prepared lessons and a worked learning path.
4. Use Learn the project, Learn a task and Learning library in the selector.
5. Open docs\guides\Run_And_Test.txt for a repeatable first-session check.

The User Guide is in docs\pdf\DPH_User_Guide.pdf and docs\guides as an
editable document. The Engineering Guide covers building and maintaining DPH.
Keep all supplied files together. Microsoft WebView2 Runtime is needed for
embedded pages; its supplied loader is a separate file.

DPH reads source without changing or running the selected application.
Supplied tasks and answers remain attributed and may require review.
Form designs are reconstructions; Screenshots contains supplied images.
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
$sourceZip=Join-Path $projectRoot ('source distributions\DPH-'+$Version+'-experimental-source.zip')
if (Test-Path -LiteralPath $sourceZip) {throw 'Source ZIP already exists'}
$archive=[IO.Compression.ZipFile]::Open($sourceZip,[IO.Compression.ZipArchiveMode]::Create)
try {
 foreach ($directory in @('bin/','dcu/','docs/guides/','docs/pdf/','export/','help/','images and icons/','samples/','source distributions/','tools/','Databases/')) {$archive.CreateEntry($directory) | Out-Null}
 $paths=& 'C:\Program Files\Git\cmd\git.exe' -C $projectRoot ls-files
 if ($LASTEXITCODE -ne 0) {throw 'Cannot enumerate source files'}
 foreach ($relative in $paths) {
  $include=($relative -match '^DPH\..*\.(pas|fmx)$') -or ($relative -match '^DelphiProjectHandoff\.(dpr|dproj|res)$') -or
   ($relative -match '^(migrations|dependencies|tests|tools)/') -or ($relative -match '^(help|samples/(translation|OrderPractice))/') -or
   ($relative -in @('README.md','.gitattributes','.gitignore','docs/Learning_Requirements_Reconciliation.txt','docs/Learning_Requirements_Reconciliation.csv','docs/Learning_Requirements_Reconciliation.json','docs/guides/DPH_User_Guide.docx','docs/guides/DPH_Engineering_Guide.docx','docs/guides/Run_And_Test.txt','docs/guides/Developer_Test_Directions.txt','docs/guides/Workspace_Operations.txt','docs/pdf/DPH_User_Guide.pdf','docs/pdf/DPH_Engineering_Guide.pdf','docs/learning-completion-practice-task-compact.png','docs/learning-completion-practice-library-compact.png','Databases/README.txt'))
  $source=Join-Path $projectRoot $relative
  if ($include -and (Test-Path -LiteralPath $source -PathType Leaf)) {
   [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,$source,$relative,[IO.Compression.CompressionLevel]::Optimal) | Out-Null
  }
 }
} finally {$archive.Dispose()}
$verificationRoot=Join-Path $projectRoot ('bin\distribution-verify-'+[Guid]::NewGuid().ToString('N'))
[IO.Compression.ZipFile]::ExtractToDirectory($binaryZip,$verificationRoot)
foreach ($property in $hashes.GetEnumerator()) {
 if ((Get-FileHash -LiteralPath (Join-Path $verificationRoot $property.Key) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $property.Value) {throw 'Extracted package checksum mismatch'}
}
[ordered]@{version=$Version;binary=$binaryZip;source=$sourceZip;binary_sha256=(Get-FileHash -LiteralPath $binaryZip -Algorithm SHA256).Hash.ToLowerInvariant();source_sha256=(Get-FileHash -LiteralPath $sourceZip -Algorithm SHA256).Hash.ToLowerInvariant();files=$hashes.Count;verification_directory=$verificationRoot;result='PASS package integrity; independent beginner acceptance not performed'} |
 ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $projectRoot 'docs\learning-distribution-validation.json') -Encoding UTF8
Write-Output "PACKAGED AND VERIFIED $binaryZip"
