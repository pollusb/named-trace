function Get-NamedTraceFilePath {
    param (
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    if ($Path.StartsWith('\\')) {
        return $Path
    }

    if ($Path -notmatch '^(?<drive>[A-Za-z]):\\(?<relative>.*)$') {
        throw "Le chemin de trace '$Path' doit être un chemin absolu de lecteur Windows ou un chemin UNC."
    }

    "\\$ComputerName\$($Matches.drive)`$\$($Matches.relative)"
}
