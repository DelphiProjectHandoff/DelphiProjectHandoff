param([Parameter(Mandatory=$true)][ValidateSet('WP5','WP6','WP7')][string]$Phase)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$backupRoot = 'D:\DPH Backups'
$destination = Join-Path $backupRoot ($Phase + '_PreChange_' + (Get-Date -Format 'yyyyMMdd_HHmmss'))
$destination = [IO.Path]::GetFullPath($destination)
if (-not $destination.StartsWith($backupRoot + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid backup destination' }
if (Test-Path -LiteralPath $destination) { throw 'Backup destination already exists' }
$files = @(Get-ChildItem -LiteralPath $projectRoot -File -Recurse -Force)
$totalBytes = ($files | Measure-Object Length -Sum).Sum
$disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='D:'"
if ($disk.FreeSpace -lt ($totalBytes + 256MB)) { throw 'Insufficient free space on the approved backup drive D:' }
$rows = [Collections.Generic.List[object]]::new()
New-Item -ItemType Directory -Path $destination | Out-Null
foreach ($file in $files) {
    if ($file.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Reparse file cannot be backed up without review: $($file.FullName)" }
    $relative = $file.FullName.Substring($projectRoot.Length + 1)
    $target = Join-Path $destination $relative
    [IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $target
    $originalHash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    if ((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $originalHash) { throw "Backup verification failed: $relative" }
    $rows.Add([ordered]@{ path=$relative; bytes=$file.Length; sha256=$originalHash })
}
[ordered]@{ phase=$Phase; source=$projectRoot; pre_change=$true; verified_utc=[DateTime]::UtcNow.ToString('o'); files=$rows.Count; bytes=$totalBytes; entries=$rows } |
    ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $destination 'DPH_Backup_Verification.json') -Encoding UTF8
Write-Output "VERIFIED $Phase pre-change backup: $destination ($($rows.Count) files, $totalBytes bytes)"
