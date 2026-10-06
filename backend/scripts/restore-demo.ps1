param(
  [Parameter(Mandatory = $true)][string]$BackupDirectory,
  [Parameter(Mandatory = $true)][string]$TargetDatabase,
  [Parameter(Mandatory = $true)][string]$ConfirmTargetName,
  [string]$ContainerName = 'motocare-postgres',
  [string]$DatabaseUser = '',
  [string]$RestoreChatDirectory = ''
)

. (Join-Path $PSScriptRoot 'demo-backup.common.ps1')

$backendRoot = Get-MotoCareBackendRoot
if ([string]::IsNullOrWhiteSpace($DatabaseUser)) { $DatabaseUser = Get-MotoCareSetting 'DATABASE_USER' 'motocare' }
$configuredDatabase = Get-MotoCareSetting 'DATABASE_NAME' 'motocare'
if ([string]::IsNullOrWhiteSpace($RestoreChatDirectory)) {
  $RestoreChatDirectory = Join-Path $backendRoot "backups/restored/$TargetDatabase/chat"
}

Assert-PostgresIdentifier $TargetDatabase
Assert-PostgresIdentifier $DatabaseUser
Assert-DockerContainerRunning $ContainerName
if ($TargetDatabase -ne $ConfirmTargetName) { throw 'ConfirmTargetName must exactly match TargetDatabase.' }
if ($TargetDatabase -eq $configuredDatabase) { throw 'Refusing to restore over the configured application database.' }
if ($TargetDatabase -notmatch '^motocare_[a-z0-9_]*(restore|test)[a-z0-9_]*$') {
  throw 'Restore target must be a dedicated MotoCare test/restore database.'
}

$manifestPath = Join-Path $BackupDirectory 'manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw 'Backup manifest.json not found.' }
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ($manifest.formatVersion -ne 1) { throw 'Unsupported backup format version.' }
Assert-SafeManifestFileName $manifest.database.file
Assert-SafeManifestFileName $manifest.chatImages.file

$dumpPath = Join-Path $BackupDirectory $manifest.database.file
$chatArchivePath = Join-Path $BackupDirectory $manifest.chatImages.file
foreach ($path in @($dumpPath, $chatArchivePath)) {
  if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Backup file missing: $path" }
}
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $dumpPath).Hash.ToLowerInvariant() -ne $manifest.database.sha256) {
  throw 'Database dump checksum mismatch.'
}
if ((Get-FileHash -Algorithm SHA256 -LiteralPath $chatArchivePath).Hash.ToLowerInvariant() -ne $manifest.chatImages.sha256) {
  throw 'Chat archive checksum mismatch.'
}
if (Test-Path -LiteralPath $RestoreChatDirectory) { throw 'Restore chat directory already exists; refusing to overwrite it.' }

$databaseExists = & docker exec $ContainerName psql --username=$DatabaseUser --dbname=postgres --tuples-only --no-align --command="SELECT 1 FROM pg_database WHERE datname = '$TargetDatabase'"
if ($LASTEXITCODE -ne 0) { throw 'Unable to check restore target database.' }
if ($databaseExists -eq '1') { throw 'Restore target database already exists; refusing to overwrite it.' }

$containerDump = "/tmp/motocare-restore-$([guid]::NewGuid().ToString('N')).dump"
$databaseCreated = $false
try {
  Invoke-DockerChecked @('cp', $dumpPath, "${ContainerName}:$containerDump")
  Invoke-DockerChecked @('exec', $ContainerName, 'createdb', "--username=$DatabaseUser", $TargetDatabase)
  $databaseCreated = $true
  Invoke-DockerChecked @('exec', $ContainerName, 'pg_restore', '--exit-on-error', '--no-owner', '--no-acl', "--username=$DatabaseUser", "--dbname=$TargetDatabase", $containerDump)

  Add-Type -AssemblyName System.IO.Compression.FileSystem
  [System.IO.Compression.ZipFile]::ExtractToDirectory($chatArchivePath, $RestoreChatDirectory)
} catch {
  if ($databaseCreated) {
    & docker exec $ContainerName dropdb --if-exists --username=$DatabaseUser $TargetDatabase 2>$null | Out-Null
  }
  if (Test-Path -LiteralPath $RestoreChatDirectory) { Remove-Item -LiteralPath $RestoreChatDirectory -Recurse -Force }
  throw
} finally {
  & docker exec $ContainerName rm -f $containerDump 2>$null | Out-Null
}

$restoredMigrations = & docker exec $ContainerName psql --username=$DatabaseUser --dbname=$TargetDatabase --tuples-only --no-align --command='SELECT count(*) FROM migrations'
if ($LASTEXITCODE -ne 0 -or [int]$restoredMigrations -ne [int]$manifest.migrationCount) {
  throw 'Restore verification failed: migration count differs from the manifest.'
}

Write-Output "Restore verified in database '$TargetDatabase'."
Write-Output "Chat archive restored to: $RestoreChatDirectory"
Write-Output 'The configured application database was not modified.'
