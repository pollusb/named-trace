function Resolve-NamedTraceInstance {
    [CmdletBinding()]
    param (
        [string[]]$ComputerName,
        [string[]]$SqlInstance,
        [PSCredential]$SqlCredential
    )

    if ($SqlInstance) {
        return @($SqlInstance | Select-Object -Unique)
    }

    $instances = @(
        Find-DbaInstance -ComputerName $ComputerName -SqlCredential $SqlCredential -EnableException |
            ForEach-Object { $_.SqlInstance } |
            Where-Object { $_ } |
            Select-Object -Unique
    )

    if (-not $instances) {
        throw "Aucune instance SQL active n'a été détectée sur $($ComputerName -join ', ')."
    }

    return $instances
}
