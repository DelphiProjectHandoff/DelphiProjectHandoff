$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
$baseline = Get-Content docs\reference-inventory.json -Raw | ConvertFrom-Json
$beforeHashes = @{}
foreach ($entry in $baseline.files) {
    $path = Join-Path $projectRoot ('samples\reference-vcl2fmx-v6.0.0\' + $entry.path)
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $entry.sha256) { throw "Pinned input changed before WP7: $($entry.path)" }
    $beforeHashes[$path] = $hash
}
foreach ($file in Get-ChildItem tests\fixtures -Recurse -File) { $beforeHashes[$file.FullName] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
$instructionHashes = @{
    'DPH_CODEX_HANDOFF.txt'='7613f963a7cc7ac10b9408058b82a1bc12624dac47119984a160f4fa8c03b8e4'
    'DPH_Master_Development_Specification_v1.md'='0e150cb409905b10512cbd72b4edd9439eb70cb1bc7fb585f1f56f92ee2f0469'
    'C:\Users\marti\.codex\agents.md'='8026000ea01d0fbd7382b6e328a54068ee5230b6fe50952ed97733a5a15b44eb'
}
foreach ($name in $instructionHashes.Keys) {
    $path = $name
    if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $projectRoot $name }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $instructionHashes[$name]) { throw "Instruction changed: $name" }
    $beforeHashes[$path] = $instructionHashes[$name]
}
& cmd /c tools\build-wp7.cmd 2>&1 | Tee-Object -FilePath docs\wp7-build.log
$testExit = $LASTEXITCODE
$changed = @()
foreach ($path in $beforeHashes.Keys) { if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $beforeHashes[$path]) { $changed += $path } }
$computer = Get-CimInstance Win32_ComputerSystem
$processor = Get-CimInstance Win32_Processor | Select-Object -First 1
[ordered]@{ validated_utc=[DateTime]::UtcNow.ToString('o'); reference_commit=$baseline.commit; checked_files=$beforeHashes.Count; changed_files=$changed; test_exit=$testExit;
    compiler='37.0.59082.6021'; target='Win32 Debug'; schema_version=2; cpu=$processor.Name; logical_processors=$computer.NumberOfLogicalProcessors; physical_memory_bytes=$computer.TotalPhysicalMemory;
    budgets='Measurements only; no owner-agreed release performance budgets were supplied'; reviewer='Codex automated tests, not independent human acceptance' } |
    ConvertTo-Json -Depth 5 | Set-Content docs\wp7-input-validation.json -Encoding UTF8
if ($changed.Count -gt 0) { throw 'Selected input or instruction changed during WP7 validation' }
if ($testExit -ne 0) { throw 'WP7 integration failed; see wp7-build.log' }
Write-Output "PASS read-only proof: $($beforeHashes.Count) unchanged files"
