function Uninstall-NamedTrace {
    <#
    .SYNOPSIS
        Ferme et supprime la définition d'une trace nommée, sans effacer ses fichiers.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'SqlInstance')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ComputerName')]
        [string[]]$ComputerName,
        [Parameter(Mandatory, ParameterSetName = 'SqlInstance')]
        [string[]]$SqlInstance,
        [Parameter(Mandatory)]
        [string]$TraceName,
        [PSCredential]$SqlCredential
    )

    foreach ($instance in (Resolve-NamedTraceInstance -ComputerName $ComputerName -SqlInstance $SqlInstance -SqlCredential $SqlCredential)) {
        $server = Connect-NamedTraceInstance -SqlInstance $instance -SqlCredential $SqlCredential
        $traces = @(Get-NamedTraceRows -Server $server -TraceName $TraceName)
        if (-not $traces) {
            throw "La trace nommée '$TraceName' est introuvable sur $instance."
        }

        foreach ($trace in $traces) {
            if ($PSCmdlet.ShouldProcess("$instance : $TraceName", "Désinstaller la trace ID $($trace.Id)")) {
                $query = @"
IF EXISTS (SELECT 1 FROM sys.traces WHERE id = $($trace.Id) AND status = 1)
    EXEC sp_trace_setstatus $($trace.Id), 0;
EXEC sp_trace_setstatus $($trace.Id), 2;
"@
                $null = $server.Query($query)
                [PSCustomObject]@{
                    TraceName   = $TraceName
                    SqlInstance = $instance
                    Id          = $trace.Id
                    Path        = $trace.Path
                    Removed     = $true
                }
            }
        }
    }
}
