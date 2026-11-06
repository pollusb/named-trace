function ConvertTo-NamedTraceSqlLiteral {
    param (
        [Parameter(Mandatory)]
        [string]$Value
    )

    "N'$($Value.Replace("'", "''"))'"
}
