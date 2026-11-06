function Get-NamedTraceRows {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]$Server,
        [Parameter(Mandatory)]
        [string]$TraceName
    )

    $query = @"
SELECT id, status, path, max_size, stop_time, max_files, is_rollover,
       is_default, start_time, last_event_time
FROM sys.traces
WHERE is_default = 0
"@
    $rows = $Server.Query($query)

    foreach ($row in $rows.Rows) {
        if (-not $row.path -or $row.path -is [System.DBNull]) {
            continue
        }

        $fileName = [System.IO.Path]::GetFileNameWithoutExtension([string]$row.path)
        if ($fileName -ieq $TraceName) {
            [PSCustomObject]@{
                TraceName     = $fileName
                SqlInstance   = $Server.DomainInstanceName
                ComputerName  = $Server.ComputerName
                InstanceName  = $Server.ServiceName
                Id            = [int]$row.id
                Status        = [int]$row.status
                IsRunning     = ([int]$row.status -eq 1)
                Path          = [string]$row.path
                MaxSizeMB     = [int]$row.max_size
                MaxFiles      = [int]$row.max_files
                IsRollover    = [bool]$row.is_rollover
                IsDefault     = [bool]$row.is_default
                StartTime     = $row.start_time
                LastEventTime = $row.last_event_time
            }
        }
    }
}
