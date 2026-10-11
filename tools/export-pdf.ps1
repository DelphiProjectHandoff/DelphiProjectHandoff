param([Parameter(Mandatory=$true)][string]$BundleDirectory)
$ErrorActionPreference = 'Stop'
$bundleRoot = [IO.Path]::GetFullPath($BundleDirectory)
$ancestor = $bundleRoot
while ($ancestor) {
    if ((Get-Item -LiteralPath $ancestor).Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse bundle paths are not allowed' }
    $parent = [IO.Path]::GetDirectoryName($ancestor)
    if ($parent -eq $ancestor) { break }
    $ancestor = $parent
}
$pending = [Collections.Generic.Stack[string]]::new()
$pending.Push($bundleRoot)
while ($pending.Count) {
    foreach ($item in Get-ChildItem -LiteralPath $pending.Pop() -Force) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse artifacts are not allowed' }
        if ($item.PSIsContainer) { $pending.Push($item.FullName) }
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $bundleRoot 'manifest.json'))) { throw 'Select an existing DPH export bundle' }
$pythonPath = 'C:\Users\marti\AppData\Local\Microsoft\WindowsApps\python.exe'
$officePath = 'C:\Program Files\LibreOffice\program\soffice.com'
if (-not (Test-Path -LiteralPath $officePath)) { throw 'LibreOffice is required for optional PDF conversion' }
$checksumPath = Join-Path $bundleRoot 'validation\manifest-sha256.json'
$expected = Get-Content -LiteralPath $checksumPath -Raw | ConvertFrom-Json
foreach ($property in $expected.PSObject.Properties) {
    if ($property.Name.Contains('..') -or $property.Name.Contains(':') -or [IO.Path]::IsPathRooted($property.Name)) { throw 'Invalid artifact filename' }
    $artifact = Join-Path $bundleRoot $property.Name
    if ((Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant() -ne $property.Value) { throw "Damaged artifact: $($property.Name)" }
}
$profileRoot = Join-Path ([IO.Path]::GetTempPath()) ('DPH-PDF-' + [Guid]::NewGuid().ToString('N'))
$profileURI = ([Uri]$profileRoot).AbsoluteUri
foreach ($guideName in @('Engineering_Guide','User_Guide')) {
    $guidePath = Join-Path $bundleRoot ($guideName + '.docx')
    $pdfPath = Join-Path $bundleRoot ($guideName + '.pdf')
    & $officePath "-env:UserInstallation=$profileURI" --headless --convert-to pdf --outdir $bundleRoot $guidePath
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $pdfPath)) { throw "PDF conversion failed: $guideName" }
    & $pythonPath (Join-Path $PSScriptRoot 'finalize-guide.py') $guidePath $pdfPath
    if ($LASTEXITCODE -ne 0) { throw "TOC population failed: $guideName (Python pypdf is required)" }
    & $officePath "-env:UserInstallation=$profileURI" --headless --convert-to pdf --outdir $bundleRoot $guidePath
    if ($LASTEXITCODE -ne 0) { throw "Final PDF conversion failed: $guideName" }
}
$hashes = [ordered]@{}
foreach ($artifact in Get-ChildItem -LiteralPath $bundleRoot -Recurse -File | Sort-Object FullName) {
    if ($artifact.FullName -eq $checksumPath) { continue }
    if ($artifact.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Reparse artifacts are not allowed' }
    $relative = $artifact.FullName.Substring($bundleRoot.Length + 1).Replace('\','/')
    $hashes[$relative] = (Get-FileHash -LiteralPath $artifact.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
}
$hashes | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $checksumPath -Encoding UTF8
Write-Output 'PDF companions and editable TOC caches created; bundle checksums refreshed. Canonical source facts are unchanged.'
