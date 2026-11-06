BeforeAll {
    $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'NamedTrace.psd1'
    Import-Module $modulePath -Force
}

Describe 'NamedTrace module' {
    It 'keeps exported commands in Public and helpers in Private' {
        $root = Split-Path $PSScriptRoot -Parent
        $publicFunctions = @(Get-ChildItem (Join-Path $root 'Public') -Filter '*.ps1' -File | Select-Object -ExpandProperty BaseName | Sort-Object)
        $privateFunctions = @(Get-ChildItem (Join-Path $root 'Private') -Filter '*.ps1' -File | Select-Object -ExpandProperty BaseName)

        $publicFunctions | Should -Be @(
            'Export-NamedTraceFile',
            'Get-NamedTrace',
            'Install-NamedTrace',
            'Move-NamedTraceFile',
            'Start-NamedTrace',
            'Stop-NamedTrace',
            'Uninstall-NamedTrace'
        )
        $privateFunctions | Should -Contain 'Resolve-NamedTraceInstance'
        $privateFunctions | Should -Contain 'New-NamedTraceDefinition'
        $privateFunctions | Should -Not -Contain 'Get-NamedTrace'
    }

    It 'exports only the requested public functions' {
        $expected = @(
            'Get-NamedTrace',
            'Install-NamedTrace',
            'Start-NamedTrace',
            'Stop-NamedTrace',
            'Uninstall-NamedTrace',
            'Move-NamedTraceFile',
            'Export-NamedTraceFile'
        )

        (Get-Command -Module NamedTrace -CommandType Function).Name | Sort-Object |
            Should -Be ($expected | Sort-Object)
    }

    It 'escapes apostrophes in SQL string literals' {
        InModuleScope NamedTrace {
            ConvertTo-NamedTraceSqlLiteral -Value "D:\Trace's\Audit.trc" |
                Should -Be "N'D:\Trace''s\Audit.trc'"
        }
    }

    It 'returns matching SQL trace metadata as a named trace object' {
        $table = [System.Data.DataTable]::new()
        foreach ($column in @(
            @{ Name = 'id'; Type = [int] },
            @{ Name = 'status'; Type = [int] },
            @{ Name = 'path'; Type = [string] },
            @{ Name = 'max_size'; Type = [int] },
            @{ Name = 'max_files'; Type = [int] },
            @{ Name = 'is_rollover'; Type = [bool] },
            @{ Name = 'is_default'; Type = [bool] },
            @{ Name = 'start_time'; Type = [datetime] },
            @{ Name = 'last_event_time'; Type = [datetime] }
        )) {
            $null = $table.Columns.Add($column.Name, $column.Type)
        }

        $row = $table.NewRow()
        $row.id = 7
        $row.status = 1
        $row.path = 'D:\Traces\AuditApp.trc'
        $row.max_size = 100
        $row.max_files = 5
        $row.is_rollover = $true
        $row.is_default = $false
        $row.start_time = [datetime]'2026-01-01'
        $row.last_event_time = [datetime]'2026-01-01'
        $table.Rows.Add($row)

        $server = [PSCustomObject]@{
            DomainInstanceName = 'sql01\prod'
            ComputerName       = 'sql01'
            ServiceName        = 'MSSQL$PROD'
            TraceTable         = $table
        }
        $server | Add-Member ScriptMethod Query { param($query) return ,$this.TraceTable }

        InModuleScope NamedTrace -Parameters @{ mockServer = $server } {
            Mock Connect-DbaInstance { $mockServer }
            $trace = Get-NamedTrace -SqlInstance 'sql01\prod' -TraceName 'AuditApp'

            $trace.TraceName | Should -Be 'AuditApp'
            $trace.Id | Should -Be 7
            $trace.IsRunning | Should -BeTrue
            $trace.Path | Should -Be 'D:\Traces\AuditApp.trc'
        }
    }

    It 'rejects trace names containing path separators' {
        { Install-NamedTrace -SqlInstance 'sql01' -TraceName '..\Audit' -Path 'D:\Traces' -WhatIf } |
            Should -Throw '*TraceName doit être un nom de fichier simple*'
    }

    It 'requires exactly one target parameter set' {
        {
            Get-NamedTrace -ComputerName 'sql01' -SqlInstance 'sql01' -TraceName 'Audit'
        } | Should -Throw
    }
}

AfterAll {
    Remove-Module NamedTrace -Force -ErrorAction SilentlyContinue
}
