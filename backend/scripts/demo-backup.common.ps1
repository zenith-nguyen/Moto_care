Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-MotoCareBackendRoot {
  return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
}

function Get-MotoCareSetting {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$DefaultValue
  )

  $environmentValue = [Environment]::GetEnvironmentVariable($Name)
  if (-not [string]::IsNullOrWhiteSpace($environmentValue)) {
    return $environmentValue
  }

  $backendRoot = Get-MotoCareBackendRoot
  $configuredPath = [Environment]::GetEnvironmentVariable('DOTENV_CONFIG_PATH')
  $envPath = if ([string]::IsNullOrWhiteSpace($configuredPath)) {
    Join-Path $backendRoot '.env'
  } elseif ([System.IO.Path]::IsPathRooted($configuredPath)) {
    $configuredPath
  } else {
    Join-Path $backendRoot $configuredPath
  }

  if (Test-Path -LiteralPath $envPath -PathType Leaf) {
    $prefix = "$Name="
    $line = Get-Content -LiteralPath $envPath | Where-Object { $_.StartsWith($prefix) } | Select-Object -Last 1
    if ($null -ne $line) {
      $value = $line.Substring($prefix.Length).Trim()
      if (-not [string]::IsNullOrWhiteSpace($value)) {
        return $value
      }
    }
  }

  return $DefaultValue
}

function Assert-PostgresIdentifier {
  param([Parameter(Mandatory = $true)][string]$Value)
  if ($Value -notmatch '^[a-z][a-z0-9_]{0,62}$') {
    throw "Unsafe PostgreSQL identifier. Use lowercase letters, numbers and underscores only."
  }
}

function Assert-DockerContainerRunning {
  param([Parameter(Mandatory = $true)][string]$ContainerName)
  $running = & docker inspect --format '{{.State.Running}}' $ContainerName 2>$null
  if ($LASTEXITCODE -ne 0 -or $running -ne 'true') {
    throw "Docker container '$ContainerName' is not running. Run docker compose up -d first."
  }
}

function Invoke-DockerChecked {
  param([Parameter(Mandatory = $true)][string[]]$Arguments)
  & docker @Arguments
  if ($LASTEXITCODE -ne 0) {
    throw "Docker command failed with exit code $LASTEXITCODE."
  }
}

function Get-DirectoryMetrics {
  param([Parameter(Mandatory = $true)][string]$Path)
  if (-not (Test-Path -LiteralPath $Path -PathType Container)) {
    return [pscustomobject]@{ FileCount = 0; SizeBytes = [int64]0 }
  }
  $files = @(Get-ChildItem -LiteralPath $Path -File -Recurse -Force)
  $size = [int64]0
  if ($files.Count -gt 0) {
    $size = [int64](($files | Measure-Object -Property Length -Sum).Sum)
  }
  return [pscustomobject]@{ FileCount = $files.Count; SizeBytes = $size }
}

function Get-FreeBytes {
  param([Parameter(Mandatory = $true)][string]$Path)
  $root = [System.IO.Path]::GetPathRoot([System.IO.Path]::GetFullPath($Path))
  $driveName = $root.TrimEnd('\').TrimEnd(':')
  return [int64](Get-PSDrive -Name $driveName).Free
}

function Get-DatabaseSizeBytes {
  param(
    [Parameter(Mandatory = $true)][string]$ContainerName,
    [Parameter(Mandatory = $true)][string]$DatabaseUser,
    [Parameter(Mandatory = $true)][string]$DatabaseName
  )
  $result = & docker exec $ContainerName psql --username=$DatabaseUser --dbname=$DatabaseName --tuples-only --no-align --command='SELECT pg_database_size(current_database())'
  if ($LASTEXITCODE -ne 0 -or $result -notmatch '^\d+$') {
    throw "Unable to read PostgreSQL database size."
  }
  return [int64]$result
}

function Assert-SafeManifestFileName {
  param([Parameter(Mandatory = $true)][string]$FileName)
  if ([System.IO.Path]::GetFileName($FileName) -ne $FileName) {
    throw 'Backup manifest contains an unsafe file path.'
  }
}
