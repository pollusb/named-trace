function Connect-NamedTraceInstance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$SqlInstance,
        [PSCredential]$SqlCredential
    )

    Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential -MinimumVersion 9
}
