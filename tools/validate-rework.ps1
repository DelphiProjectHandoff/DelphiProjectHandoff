$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $projectRoot
# Preserve historical phase reports; write this run's evidence under rework-*.
$historical = @{}
foreach ($file in Get-ChildItem docs -File | Where-Object Name -Match '^wp[0-7]-') {
    $historical[$file.FullName] = [IO.File]::ReadAllBytes($file.FullName)
}
$inputHashes = @{}
$baseline = Get-Content docs\validation\reports\reference-inventory.json -Raw | ConvertFrom-Json
foreach ($entry in $baseline.files) {
    $path = Join-Path $projectRoot ('samples\reference-vcl2fmx-v6.0.0\' + $entry.path)
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne $entry.sha256) { throw "Pinned input differs before validation: $($entry.path)" }
    $inputHashes[$path] = $hash
}
foreach ($file in Get-ChildItem tests\fixtures -Recurse -File) { $inputHashes[$file.FullName] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
foreach ($name in @('docs\planning\DPH_CODEX_HANDOFF.txt','docs\planning\DPH_Master_Development_Specification_v1.md','C:\Users\marti\.codex\agents.md')) {
    $path = if ([IO.Path]::IsPathRooted($name)) { $name } else { Join-Path $projectRoot $name }
    $inputHashes[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}
$results = @()
$commands = [ordered]@{
    storage='tools\build-wp1.cmd'
    discovery='tools\build-wp2.cmd'
    semantics_build='tools\build-wp3.cmd'
    semantics='bin\Win32\Debug\DPH.Tests.Semantics.exe'
    workspace='tools\build-wp4.cmd'
    knowledge='tools\build-wp5.cmd'
    publishing='tools\build-wp6.cmd'
    hardening='tools\build-wp7.cmd'
}
try {
    foreach ($item in $commands.GetEnumerator()) {
        if ($item.Key -eq 'semantics') { & $item.Value $projectRoot 2>&1 | Tee-Object ('docs\rework-'+$item.Key+'-tests.log') }
        else { & cmd /c $item.Value 2>&1 | Tee-Object ('docs\rework-'+$item.Key+'-tests.log') }
        $testExit = $LASTEXITCODE
        $results += [ordered]@{ suite=$item.Key; exit_code=$testExit }
        if ($testExit -ne 0) { throw "Rework regression failed: $($item.Key)" }
    }
    $reference = Get-Content docs\validation\reports\wp7-validation.json -Raw | ConvertFrom-Json
    & cmd /c tools\build-learning.cmd (Join-Path $reference.work 'reference.dphdb') 2>&1 | Tee-Object logs\validation\rework-learning-tests.log
    $testExit = $LASTEXITCODE
    $results += [ordered]@{ suite='learning'; exit_code=$testExit }
    if ($testExit -ne 0) { throw 'Rework learning regression failed' }
} finally {
    foreach ($path in $historical.Keys) {
        $name = Split-Path -Leaf $path
        if ([IO.Path]::GetExtension($path) -ne '.png' -and (Test-Path -LiteralPath $path) -and
            ([Convert]::ToBase64String([IO.File]::ReadAllBytes($path)) -ne [Convert]::ToBase64String($historical[$path]))) {
            Copy-Item -LiteralPath $path -Destination (Join-Path $projectRoot ('docs\rework-'+$name))
        }
        [IO.File]::WriteAllBytes($path,$historical[$path])
    }
    $changed = @()
    foreach ($path in $inputHashes.Keys) { if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $inputHashes[$path]) { $changed += $path } }
    [ordered]@{ validated_utc=[DateTime]::UtcNow.ToString('o'); suites=$results; checked_files=$inputHashes.Count; changed_files=$changed;
        reference_commit=$baseline.commit; independent_human_acceptance='not_run'; plan_status='reworked learning product; explicit remaining requirements in Rework_Requirements_Audit.txt' } |
        ConvertTo-Json -Depth 5 | Set-Content docs\validation\reports\rework-regression-validation.json -Encoding UTF8
    if ($changed.Count -gt 0) { throw 'Selected source or instruction files changed during validation' }
}
Write-Output "PASS rework regression and read-only proof: $($inputHashes.Count) unchanged files"
