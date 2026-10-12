param([string]$GuideDirectory, [string]$PDFDirectory)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $GuideDirectory) { $GuideDirectory = Join-Path $projectRoot 'docs\guides' }
if (-not $PDFDirectory) { $PDFDirectory = Join-Path $projectRoot 'docs\pdf' }
$guideRoot = [IO.Path]::GetFullPath($GuideDirectory)
$pdfRoot = [IO.Path]::GetFullPath($PDFDirectory)
$pythonPath = 'C:\Users\marti\AppData\Local\Microsoft\WindowsApps\python.exe'
$renderer = 'C:\Users\marti\.codex\plugins\cache\openai-primary-runtime\documents\26.1011.11113\skills\documents\render_docx.py'
$env:PATH = 'C:\Program Files\LibreOffice\program;C:\Users\marti\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\poppler\Library\bin;' + $env:PATH
[IO.Directory]::CreateDirectory($pdfRoot) | Out-Null
foreach ($guide in Get-ChildItem -LiteralPath $guideRoot -File -Filter '*.docx') {
    $qaRoot = Join-Path $projectRoot ('bin\guide-qa\' + $guide.BaseName)
    & $pythonPath $renderer $guide.FullName --output_dir $qaRoot --emit_pdf
    if ($LASTEXITCODE -ne 0) { throw "Guide rendering failed: $($guide.Name)" }
    $pdfPath = Join-Path $qaRoot ($guide.BaseName + '.pdf')
    & $pythonPath (Join-Path $PSScriptRoot 'finalize-guide.py') $guide.FullName $pdfPath
    if ($LASTEXITCODE -ne 0) { throw "Guide TOC validation failed: $($guide.Name)" }
    & $pythonPath $renderer $guide.FullName --output_dir $qaRoot --emit_pdf
    if ($LASTEXITCODE -ne 0) { throw "Final guide rendering failed: $($guide.Name)" }
    Copy-Item -LiteralPath $pdfPath -Destination (Join-Path $pdfRoot ($guide.BaseName + '.pdf'))
    Write-Output "RENDERED $($guide.Name) and companion PDF; inspect every page in $qaRoot"
}
