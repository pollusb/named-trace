@{
    RootModule        = 'NamedTrace.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '2a5b3ccf-5537-4e15-8ced-f5792c8a07fb'
    Author            = 'NamedTrace contributors'
    Description       = 'Gestion de traces SQL Server Profiler nommées.'
    PowerShellVersion = '5.1'
    RequiredModules   = @('dbatools')
    FunctionsToExport = @(
        'Get-NamedTrace',
        'Install-NamedTrace',
        'Start-NamedTrace',
        'Stop-NamedTrace',
        'Uninstall-NamedTrace',
        'Move-NamedTraceFile',
        'Export-NamedTraceFile'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('SQL Server', 'Trace', 'Profiler', 'dbatools')
            LicenseUri = 'https://opensource.org/licenses/MIT'
        }
    }
}
