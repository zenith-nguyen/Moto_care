param(
  [string]$ContainerName = 'motocare-postgres',
  [string]$DatabaseName = '',
  [string]$DatabaseUser = '',
  [string]$ChatUploadDirectory = '',
  [string]$OutputRoot = ''
)

. (Join-Path $PSScriptRoot 'demo-backup.common.ps1')

$backendRoot = Get-MotoCareBackendRoot
if ([string]::IsNullOrWhiteSpace($DatabaseName)) { $DatabaseName = Get-MotoCareSetting 'DATABASE_NAME' 'motocare' }
if ([string]::IsNullOrWhiteSpace($DatabaseUser)) { $DatabaseUser = Get-MotoCareSetting 'DATABASE_USER' 'motocare' }
if ([string]::IsNullOrWhiteSpace($ChatUploadDirectory)) { $ChatUploadDirectory = Get-MotoCareSetting 'CHAT_UPLOAD_DIR' 'storage/chat' }
if (-not [System.IO.Path]::IsPathRooted($ChatUploadDirectory)) { $ChatUploadDirectory = Join-Path $backendRoot $ChatUploadDirectory }
if ([string]::IsNullOrWhiteSpace($OutputRoot)) { $OutputRoot = Join-Path $backendRoot 'backups' }

Assert-PostgresIdentifier $DatabaseName
Assert-PostgresIdentifier $DatabaseUser
Assert-DockerContainerRunning $ContainerName
New-Item -ItemType Directory -Path $OutputRoot -Force | Out-Null

$databaseBytes = Get-DatabaseSizeBytes $ContainerName $DatabaseUser $DatabaseName
$chat = Get-DirectoryMetrics $ChatUploadDirectory
$freeBytes = Get-FreeBytes $OutputRoot
$requiredBytes = [Math]::Max(100MB, 2 * ($databaseBytes + $chat.SizeBytes))
if ($freeBytes -lt $requiredBytes) {
  throw 'Not enough free disk space to create a safe backup.'
}

$timestamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssZ')
$snapshotDirectory = Join-Path $OutputRoot "motocare-$DatabaseName-$timestamp"
if (Test-Path -LiteralPath $snapshotDirectory) { throw 'Backup snapshot directory already exists.' }
New-Item -ItemType Directory -Path $snapshotDirectory | Out-Null

$dumpFileName = 'database.dump'
$chatFileName = 'chat-images.zip'
$dumpPath = Join-Path $snapshotDirectory $dumpFileName
$chatArchivePath = Join-Path $snapshotDirectory $chatFileName
$containerDump = "/tmp/motocare-$([guid]::NewGuid().ToString('N')).dump"

try {
  Invoke-DockerChecked @('exec', $ContainerName, 'pg_dump', '--format=custom', '--compress=9', '--no-owner', '--no-acl', "--username=$DatabaseUser", "--dbname=$DatabaseName", "--file=$containerDump")
  Invoke-DockerChecked @('cp', "${ContainerName}:$containerDump", $dumpPath)
} finally {
  & docker exec $ContainerName rm -f $containerDump 2>$null | Out-Null
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$chatSource = $ChatUploadDirectory
$temporaryEmptyChat = $null
if (-not (Test-Path -LiteralPath $chatSource -PathType Container)) {
  $temporaryEmptyChat = Join-Path $snapshotDirectory '.empty-chat'
  New-Item -ItemType Directory -Path $temporaryEmptyChat | Out-Null
  $chatSource = $temporaryEmptyChat
}
try {
  [System.IO.Compression.ZipFile]::CreateFromDirectory(
    $chatSource,
    $chatArchivePath,
    [System.IO.Compression.CompressionLevel]::Optimal,
    $false
  )
} finally {
  if ($null -ne $temporaryEmptyChat) { Remove-Item -LiteralPath $temporaryEmptyChat -Force }
}

$image = & docker inspect --format '{{.Config.Image}}' $ContainerName
$migrationCount = & docker exec $ContainerName psql --username=$DatabaseUser --dbname=$DatabaseName --tuples-only --no-align --command='SELECT count(*) FROM migrations'
if ($LASTEXITCODE -ne 0 -or $migrationCount -notmatch '^\d+$') { throw 'Unable to read migration count.' }

$manifest = [ordered]@{
  formatVersion = 1
  createdAtUtc = [DateTime]::UtcNow.ToString('o')
  databaseName = $DatabaseName
  containerImage = [string]$image
  migrationCount = [int]$migrationCount
  database = [ordered]@{
    file = $dumpFileName
    sizeBytes = (Get-Item -LiteralPath $dumpPath).Length
    sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $dumpPath).Hash.ToLowerInvariant()
  }
  chatImages = [ordered]@{
    file = $chatFileName
    sourcePresent = Test-Path -LiteralPath $ChatUploadDirectory -PathType Container
    fileCount = $chat.FileCount
    originalSizeBytes = $chat.SizeBytes
    archiveSizeBytes = (Get-Item -LiteralPath $chatArchivePath).Length
    sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $chatArchivePath).Hash.ToLowerInvariant()
  }
}
$manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $snapshotDirectory 'manifest.json') -Encoding UTF8

Write-Output "Backup completed: $snapshotDirectory"
Write-Output "Database and chat archive checksums recorded in manifest.json. No secret was written."
