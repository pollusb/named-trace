function Get-NamedTrace {
    <#
    .SYNOPSIS
        Récupère une trace nommée sur une ou plusieurs instances SQL Server.
    #>
    [CmdletBinding(DefaultParameterSetName = 'SqlInstance')]
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
        Get-NamedTraceRows -Server $server -TraceName $TraceName
    }
}
