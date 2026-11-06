function Install-NamedTrace {
    <#
    .SYNOPSIS
        Crée une trace Profiler nommée et arrêtée.
    .DESCRIPTION
        Path est un dossier local au serveur SQL. Le compte de service SQL doit pouvoir y créer des fichiers.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium', DefaultParameterSetName = 'SqlInstance')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ComputerName')]
        [string[]]$ComputerName,
        [Parameter(Mandatory, ParameterSetName = 'SqlInstance')]
        [string[]]$SqlInstance,
        [Parameter(Mandatory)]
        [ValidateScript({ -not [string]::IsNullOrWhiteSpace($_) })]
        [string]$TraceName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,
        [PSCredential]$SqlCredential
    )

    if ([System.IO.Path]::GetFileName($TraceName) -cne $TraceName -or
        $TraceName.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0) {
        throw "TraceName doit être un nom de fichier simple, sans séparateur ni caractère interdit."
    }

    foreach ($instance in (Resolve-NamedTraceInstance -ComputerName $ComputerName -SqlInstance $SqlInstance -SqlCredential $SqlCredential)) {
        $server = Connect-NamedTraceInstance -SqlInstance $instance -SqlCredential $SqlCredential
        if (@(Get-NamedTraceRows -Server $server -TraceName $TraceName).Count -gt 0) {
            throw "Une trace nommée '$TraceName' existe déjà sur $instance."
        }

        $tracePath = [System.IO.Path]::Combine($Path, "$TraceName.trc")
        if ($PSCmdlet.ShouldProcess("$instance : $tracePath", 'Installer la trace nommée')) {
            $null = New-NamedTraceDefinition -Server $server -Path $tracePath
            Get-NamedTraceRows -Server $server -TraceName $TraceName
        }
    }
}
