function Get-NamedTraceFiles {
    param (
        [Parameter(Mandatory)]
        [string]$TracePath,
        [Parameter(Mandatory)]
        [string]$ComputerName
    )

    $serverPath = Get-NamedTraceFilePath -Path $TracePath -ComputerName $ComputerName
    $directory = [System.IO.Path]::GetDirectoryName($serverPath)
    $baseName = [System.IO.Path]::GetFileName($serverPath)
    $stem = [System.IO.Path]::GetFileNameWithoutExtension($baseName)
    $extension = [System.IO.Path]::GetExtension($baseName)
    $rolloverPattern = '^{0}_\d+{1}$' -f [regex]::Escape($stem), [regex]::Escape($extension)
    $rolloverAfterExtensionPattern = '^{0}_\d+$' -f [regex]::Escape($baseName)

    Get-ChildItem -LiteralPath $directory -File -ErrorAction Stop |
        Where-Object {
            $_.Name -ieq $baseName -or
            $_.Name -match $rolloverPattern -or
            $_.Name -match $rolloverAfterExtensionPattern
        }
}
