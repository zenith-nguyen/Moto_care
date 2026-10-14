param(
  [string]$ContainerName = 'motocare-postgres',
  [string]$DatabaseName = '',
  [string]$DatabaseUser = '',
  [string]$ChatUploadDirectory = '',
  [string]$BackupRoot = ''
)

. (Join-Path $PSScriptRoot 'demo-backup.common.ps1')

$backendRoot = Get-MotoCareBackendRoot
if ([string]::IsNullOrWhiteSpace($DatabaseName)) { $DatabaseName = Get-MotoCareSetting 'DATABASE_NAME' 'motocare' }
if ([string]::IsNullOrWhiteSpace($DatabaseUser)) { $DatabaseUser = Get-MotoCareSetting 'DATABASE_USER' 'motocare' }
if ([string]::IsNullOrWhiteSpace($ChatUploadDirectory)) { $ChatUploadDirectory = Get-MotoCareSetting 'CHAT_UPLOAD_DIR' 'storage/chat' }
if (-not [System.IO.Path]::IsPathRooted($ChatUploadDirectory)) { $ChatUploadDirectory = Join-Path $backendRoot $ChatUploadDirectory }
if ([string]::IsNullOrWhiteSpace($BackupRoot)) { $BackupRoot = Join-Path $backendRoot 'backups' }

Assert-PostgresIdentifier $DatabaseName
Assert-PostgresIdentifier $DatabaseUser
Assert-DockerContainerRunning $ContainerName
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null

$databaseBytes = Get-DatabaseSizeBytes $ContainerName $DatabaseUser $DatabaseName
$chat = Get-DirectoryMetrics $ChatUploadDirectory
$backups = Get-DirectoryMetrics $BackupRoot
$freeBytes = Get-FreeBytes $BackupRoot
$recommendedFreeBytes = [Math]::Max(1GB, 2 * ($databaseBytes + $chat.SizeBytes))

[pscustomobject]@{
  DatabaseName = $DatabaseName
  DatabaseBytes = $databaseBytes
  ChatFiles = $chat.FileCount
  ChatBytes = $chat.SizeBytes
  ExistingBackupBytes = $backups.SizeBytes
  FreeBytes = $freeBytes
  RecommendedFreeBytes = $recommendedFreeBytes
  EnoughSpace = $freeBytes -ge $recommendedFreeBytes
} | Format-List

if ($freeBytes -lt $recommendedFreeBytes) {
  throw 'Free disk space is below the safe backup threshold.'
}
