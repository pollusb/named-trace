function Start-NamedTrace {
    <#
    .SYNOPSIS
        Démarre une trace nommée arrêtée.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'SqlInstance')]
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
            if ($trace.Status -eq 1) {
                $trace
                continue
            }

            if ($PSCmdlet.ShouldProcess("$instance : $TraceName", "Démarrer la trace ID $($trace.Id)")) {
                $null = $server.Query("EXEC sp_trace_setstatus $($trace.Id), 1")
                Get-NamedTraceRows -Server $server -TraceName $TraceName
            }
        }
    }
}
