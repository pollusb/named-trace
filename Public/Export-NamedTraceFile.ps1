function Export-NamedTraceFile {
    <#
    .SYNOPSIS
        Lit un ou plusieurs fichiers de trace sur une instance SQL et renvoie des objets PowerShell.
    .DESCRIPTION
        Le chemin doit être accessible au compte de service de l'instance qui lit le fichier. Aucun fichier d'export n'est créé.
    #>
    [CmdletBinding(DefaultParameterSetName = 'SqlInstance')]
    param (
        [Parameter(Mandatory, ParameterSetName = 'ComputerName')]
        [string[]]$ComputerName,
        [Parameter(Mandatory, ParameterSetName = 'SqlInstance')]
        [string[]]$SqlInstance,
        [Parameter(Mandatory)]
        [Alias('TracePath')]
        [string[]]$Path,
        [string]$TraceName,
        [PSCredential]$SqlCredential
    )

    foreach ($instance in (Resolve-NamedTraceInstance -ComputerName $ComputerName -SqlInstance $SqlInstance -SqlCredential $SqlCredential)) {
        foreach ($tracePath in $Path) {
            if ($tracePath.Contains("'")) {
                throw "Le chemin '$tracePath' contient une apostrophe non prise en charge par Read-DbaTraceFile."
            }

            $readName = $TraceName
            if (-not $readName) {
                $readName = [System.IO.Path]::GetFileNameWithoutExtension($tracePath)
            }

            $events = Read-DbaTraceFile -SqlInstance $instance -SqlCredential $SqlCredential -Path $tracePath -EnableException
            foreach ($event in $events) {
                $properties = [ordered]@{
                    TraceName   = $readName
                    SourcePath  = $tracePath
                    SqlInstance = $instance
                }

                if ($event -is [System.Data.DataRow]) {
                    foreach ($column in $event.Table.Columns) {
                        $properties[$column.ColumnName] = $event[$column.ColumnName]
                    }
                }
                else {
                    foreach ($property in $event.PSObject.Properties) {
                        if ($property.MemberType -in 'NoteProperty', 'Property') {
                            $properties[$property.Name] = $property.Value
                        }
                    }
                }

                [PSCustomObject]$properties
            }
        }
    }
}
