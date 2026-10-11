$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $repo
$referenceRoot = Join-Path $repo 'samples\reference-vcl2fmx-v6.0.0'
$baseline = Get-Content -LiteralPath (Join-Path $repo 'docs\reference-inventory.json') -Raw | ConvertFrom-Json
$beforeHashes = @{}
foreach ($item in $baseline.files) {
    $path = Join-Path $referenceRoot $item.path
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $item.sha256) { throw "Pinned reference differs before validation: $($item.path)" }
    $beforeHashes[$path] = $hash
}
$fixtureRoot = Join-Path $repo 'tests\fixtures'
Get-ChildItem -LiteralPath $fixtureRoot -File -Recurse | ForEach-Object {
    $beforeHashes[$_.FullName] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
}
$instructions = @{
    'DPH_CODEX_HANDOFF.txt' = '7613f963a7cc7ac10b9408058b82a1bc12624dac47119984a160f4fa8c03b8e4'
    'DPH_Master_Development_Specification_v1.md' = '0e150cb409905b10512cbd72b4edd9439eb70cb1bc7fb585f1f56f92ee2f0469'
    'C:\Users\marti\.codex\agents.md' = '8026000ea01d0fbd7382b6e328a54068ee5230b6fe50952ed97733a5a15b44eb'
}
foreach ($name in $instructions.Keys) {
    $path = $name
    if (-not [IO.Path]::IsPathRooted($path)) { $path = Join-Path $repo $path }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $instructions[$name]) { throw "Instruction input changed: $name" }
    $beforeHashes[$path] = $instructions[$name]
}
$log = Join-Path $repo 'docs\wp2-build.log'
& cmd /c tools\build-wp1.cmd 2>&1 | Tee-Object -FilePath $log
if ($LASTEXITCODE -ne 0) { throw 'WP0/WP1 regression failed' }
& cmd /c tools\build-wp2.cmd 2>&1 | Tee-Object -FilePath $log -Append
if ($LASTEXITCODE -ne 0) { throw 'WP2 validation failed' }
$changed = @()
foreach ($path in $beforeHashes.Keys) {
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $beforeHashes[$path]) { $changed += $path }
}
$compiler = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\dcc32.exe'
$record = [ordered]@{
    schema_version = 1
    validated_utc = [DateTime]::UtcNow.ToString('o')
    reference_commit = $baseline.commit
    reference_files_verified_before_and_after = $baseline.files.Count
    total_read_only_inputs_verified = $beforeHashes.Count
    changed_inputs = $changed
    compiler_version = (Get-Item -LiteralPath $compiler).VersionInfo.FileVersion
    compiler_sha256 = (Get-FileHash -LiteralPath $compiler -Algorithm SHA256).Hash.ToLowerInvariant()
    database_schema_version = 2
    ir_schema_version = 1
    instruction_hashes = $instructions
    source_hashes = @{}
}
$implementation = Get-ChildItem -LiteralPath $repo -File -Filter 'DPH.*.pas'
foreach ($file in $implementation) { $record.source_hashes[$file.Name] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
$record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $repo 'docs\wp2-input-validation.json') -Encoding UTF8
[IO.File]::WriteAllText($log, [IO.File]::ReadAllText($log), (New-Object Text.UTF8Encoding($false)))
if ($changed.Count -ne 0) { throw "Source read-only verification failed: $($changed -join ', ')" }
Write-Output "PASS source read-only verification: $($baseline.files.Count) pinned reference files, fixtures and instructions unchanged."
