function Get-StringHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$InputString,

        [ValidateSet('SHA256', 'SHA1', 'MD5', 'SHA384', 'SHA512')]
        [string]$Algorithm = 'SHA256'
    )
    process {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
        $stream = [System.IO.MemoryStream]::new($bytes)
        try {
            (Get-FileHash -InputStream $stream -Algorithm $Algorithm).Hash
        }
        finally {
            $stream.Dispose()
        }
    }
}

function Get-InformacoesSistema {
    [CmdletBinding()]
    param(
        [switch]$ComoTexto,
        [System.Globalization.CultureInfo]$Culture
    )

    begin {
        if (-not $PSBoundParameters.ContainsKey('Culture')) {
            $Culture = [System.Globalization.CultureInfo]::InvariantCulture
        }
    }

    process {
        $props = @(
            'BiosManufacturer', 'BiosName',
            'OsName', 'OsVersion', 'OsInstallDate', 'OsSerialNumber',
            'OsEncryptionLevel', 'OsUptime',
            'CsUserName', 'WindowsRegisteredOwner', 'OsNumberOfUsers'
        )

        $ci = Get-ComputerInfo -Property $props

        $installDateFmt = if ($ci.OsInstallDate -is [datetime]) {
            $ci.OsInstallDate.ToString('yyyy-MM-dd HH:mm:ss', $Culture)
        }
        else { [string]$ci.OsInstallDate }

        $uptimeFmt = if ($ci.OsUptime -is [TimeSpan]) {
            '{0:%d}d {0:hh}h {0:mm}m {0:ss}s' -f $ci.OsUptime
        }
        else { [string]$ci.OsUptime }

        $obj = [pscustomobject]@{
            BiosManufacturer       = $ci.BiosManufacturer
            BiosName               = $ci.BiosName
            OsName                 = $ci.OsName
            OsVersion              = $ci.OsVersion
            OsInstallDate          = $installDateFmt
            OsSerialNumber         = $ci.OsSerialNumber
            OsEncryptionLevel      = $ci.OsEncryptionLevel
            OsUptime               = $uptimeFmt
            CsUserName             = $ci.CsUserName
            WindowsRegisteredOwner = $ci.WindowsRegisteredOwner
            OsNumberOfUsers        = $ci.OsNumberOfUsers
        }

        if ($ComoTexto) {
            $ordem = @(
                'BiosManufacturer', 'BiosName',
                'OsName', 'OsVersion', 'OsInstallDate', 'OsSerialNumber',
                'OsEncryptionLevel', 'OsUptime',
                'CsUserName', 'WindowsRegisteredOwner', 'OsNumberOfUsers'
            )
            $ordem = ($ordem | ForEach-Object { ('{0}' + "`t" + '{1}') -f $_, $obj.$_ }) -join [Environment]::NewLine
            $ordem = $ordem | Write-Output | Set-Clipboard
        }
        else {
            $obj
        }
        Write-Host "Mapeamento concluído!" -ForegroundColor Yellow -BackgroundColor Black
        Write-host "O resultado pode ser colado (ctrl+v) no local de destino." -ForegroundColor Yellow -BackgroundColor Black
    }
} Get-InformacoesSistema -ComoTexto
