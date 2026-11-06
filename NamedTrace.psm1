Set-StrictMode -Version Latest

foreach ($functionFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'Private') -Filter '*.ps1' -File | Sort-Object Name) {
    . $functionFile.FullName
}

foreach ($functionFile in Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File | Sort-Object Name) {
    . $functionFile.FullName
}

Export-ModuleMember -Function @(
    'Get-NamedTrace',
    'Install-NamedTrace',
    'Start-NamedTrace',
    'Stop-NamedTrace',
    'Uninstall-NamedTrace',
    'Move-NamedTraceFile',
    'Export-NamedTraceFile'
)