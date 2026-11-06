function New-NamedTraceDefinition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]$Server,
        [Parameter(Mandatory)]
        [string]$Path
    )

    $tracePath = ConvertTo-NamedTraceSqlLiteral -Value $Path
    $eventConfigurations = @{
        10 = @(1, 3, 6, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 26, 27, 34, 35)
        12 = @(1, 3, 6, 8, 10, 11, 12, 13, 14, 15, 16, 17, 18, 26, 27, 34, 35)
        33 = @(1, 3, 6, 7, 8, 9, 10, 11, 12, 14, 20, 26, 27, 30, 31, 35)
    }
    $eventStatements = foreach ($eventConfiguration in $eventConfigurations.GetEnumerator()) {
        foreach ($columnId in $eventConfiguration.Value) {
            $eventId = $eventConfiguration.Key
            "IF EXISTS (SELECT 1 FROM sys.trace_event_bindings WHERE trace_event_id = $eventId AND trace_column_id = $columnId) BEGIN EXEC @ReturnCode = sp_trace_setevent @TraceId, $eventId, $columnId, 1; IF @ReturnCode <> 0 RAISERROR('sp_trace_setevent failed with error %d.', 16, 1, @ReturnCode); END"
        }
    }

    $query = @"
DECLARE @TraceId int;
DECLARE @ReturnCode int;
BEGIN TRY
    EXEC @ReturnCode = sp_trace_create @TraceId OUTPUT, 2, $tracePath, 100, NULL, 5;
    IF @ReturnCode <> 0 RAISERROR('sp_trace_create failed with error %d.', 16, 1, @ReturnCode);
    $($eventStatements -join [Environment]::NewLine)
    SELECT @TraceId AS TraceId;
END TRY
BEGIN CATCH
    IF @TraceId IS NOT NULL
    BEGIN
        EXEC sp_trace_setstatus @TraceId, 0;
        EXEC sp_trace_setstatus @TraceId, 2;
    END
    DECLARE @ErrorMessage nvarchar(4000) = ERROR_MESSAGE();
    RAISERROR(N'%s', 16, 1, @ErrorMessage);
END CATCH
"@

    $result = $Server.Query($query)
    if ($result.Rows.Count -ne 1) {
        throw "La création de la trace sur $($Server.DomainInstanceName) n'a retourné aucun identifiant."
    }

    [int]$result.Rows[0].TraceId
}
