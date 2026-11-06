function Move-NamedTraceFile {
    <#
    .SYNOPSIS
        Déplace les fichiers d'une trace vers un partage UNC puis recrée et redémarre la trace.
    .DESCRIPTION
        Le dossier de destination doit exister. Les chemins locaux du serveur SQL sont lus via son partage administratif.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High', DefaultParameterSetName = 'SqlInstance')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ComputerName')]
        [string[]]$ComputerName,
        [Parameter(Mandatory, ParameterSetName = 'SqlInstance')]
        [string[]]$SqlInstance,
        [Parameter(Mandatory)]
        [string]$TraceName,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Destination,
        [PSCredential]$SqlCredential
    )

    if (-not (Test-Path -LiteralPath $Destination -PathType Container)) {
        throw "Le dossier de destination '$Destination' doit exister et être accessible."
    }
    if (-not $Destination.StartsWith('\\')) {
        throw 'Destination doit être un chemin de partage UNC (par exemple \\serveur\partage\traces).'
    }

    foreach ($instance in (Resolve-NamedTraceInstance -ComputerName $ComputerName -SqlInstance $SqlInstance -SqlCredential $SqlCredential)) {
        $server = Connect-NamedTraceInstance -SqlInstance $instance -SqlCredential $SqlCredential
        $traces = @(Get-NamedTraceRows -Server $server -TraceName $TraceName)
        if ($traces.Count -ne 1) {
            throw "Une seule trace nommée '$TraceName' doit exister sur $instance (trouvées : $($traces.Count))."
        }

        $trace = $traces[0]
        if (-not $PSCmdlet.ShouldProcess("$instance : $($trace.Path)", "Déplacer les fichiers vers $Destination et redémarrer la trace")) {
            continue
        }

        $files = @(Get-NamedTraceFiles -TracePath $trace.Path -ComputerName $trace.ComputerName)
        if (-not $files) {
            throw "Aucun fichier de trace n'a été trouvé pour '$TraceName' sur $instance."
        }

        $null = $server.Query("EXEC sp_trace_setstatus $($trace.Id), 0; EXEC sp_trace_setstatus $($trace.Id), 2;")
        $moveError = $null
        try {
            foreach ($file in $files) {
                Move-Item -LiteralPath $file.FullName -Destination $Destination -ErrorAction Stop
            }
        }
        catch {
            $moveError = $_
        }

        try {
            $newTraceId = New-NamedTraceDefinition -Server $server -Path $trace.Path
            $null = $server.Query("EXEC sp_trace_setstatus $newTraceId, 1")
        }
        catch {
            if ($moveError) {
                throw "Le déplacement a échoué ($($moveError.Exception.Message)) et la trace n'a pas pu être recréée/redémarrée ($($_.Exception.Message))."
            }
            throw
        }

        if ($moveError) {
            throw $moveError
        }

        Get-NamedTraceRows -Server $server -TraceName $TraceName |
            Select-Object *, @{ Name = 'MovedFiles'; Expression = { @($files | ForEach-Object { $_.Name }) } }
    }
}
