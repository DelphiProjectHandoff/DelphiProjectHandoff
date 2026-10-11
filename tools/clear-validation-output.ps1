$ErrorActionPreference = 'Stop'
if (Get-Process -Name 'DPH.Tests*' -ErrorAction SilentlyContinue) {
    throw 'A DPH validation process is still running; its output cannot be removed.'
}
$projectDirectory = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$outputDirectory = [IO.Path]::GetFullPath((Join-Path $projectDirectory 'bin'))
$generatedName = '^(lifecycle-validation|wp[1-7]-tests-\{[0-9A-F-]+\}(-empty\.dphdb(\.views)?)?|wp2-tests-\d{8}-\d{6}-\d{3}|selection-tests-\{[0-9A-F-]+\}|learning-tests-\{[0-9A-F-]+\})$'
$generatedItems = Get-ChildItem -LiteralPath $outputDirectory -Force | Where-Object { $_.Name -match $generatedName }
foreach ($generatedItem in $generatedItems) {
    $resolvedOutput = [IO.Path]::GetFullPath($generatedItem.FullName)
    if (-not $resolvedOutput.StartsWith($outputDirectory + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Validation cleanup escaped its output directory.'
    }
    if ($generatedItem.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Linked validation output rejected.' }
    if ($generatedItem.PSIsContainer) {
        if (Get-ChildItem -LiteralPath $resolvedOutput -Force -Recurse | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }) {
            throw 'Linked validation content rejected.'
        }
        Remove-Item -LiteralPath $resolvedOutput -Recurse -Force
    } else { Remove-Item -LiteralPath $resolvedOutput -Force }
}
Write-Output ('Removed disposable validation outputs: ' + $generatedItems.Count)
