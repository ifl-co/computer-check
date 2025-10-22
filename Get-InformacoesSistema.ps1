function Get-StringHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$InputString,

        [ValidateSet('SHA256','SHA1','MD5','SHA384','SHA512')]
        [string]$Algorithm = 'SHA256'
    )
    process {
        $bytes  = [System.Text.Encoding]::UTF8.GetBytes($InputString)
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

        [ValidateSet('SHA256','SHA1','MD5','SHA384','SHA512')]
        [string]$AlgoritmoHash = 'SHA256'
    )

    process {
        # Buscar apenas o necessário
        $props = @(
            'BiosSMBIOSBIOSVersion',  # versão de BIOS (ex.: 1.29.1)
            'OsVersion',              # versão do SO (ex.: 10.0.26100)
            'OsSerialNumber',         # serial do SO (será hasheado)
            'OsUptime'                # uptime (TimeSpan)
        )

        $ci = Get-ComputerInfo -Property $props

        $serialHash = if ($ci.OsSerialNumber) {
            Get-StringHash -InputString $ci.OsSerialNumber -Algorithm $AlgoritmoHash
        } else { $null }

        $uptimeFmt = if ($ci.OsUptime -is [TimeSpan]) {
            '{0:%d}d {0:hh}h {0:mm}m {0:ss}s' -f $ci.OsUptime
        } else { [string]$ci.OsUptime }

        $obj = [pscustomobject]@{
            BiosNome       = $ci.BiosSMBIOSBIOSVersion
            VersaoSO       = $ci.OsVersion
            SerialSO_Hash  = $serialHash
            UptimeSO       = $uptimeFmt
        }

        if ($ComoTexto) {
            $ordem = 'BiosNome','VersaoSO','SerialSO_Hash','UptimeSO'
            $ordem = ($ordem | ForEach-Object { ('{0}'+"`t"+'{1}') -f $_, $obj.$_ }) -join [Environment]::NewLine
            $ordem = $ordem | Write-Output | Set-Clipboard
        } else {
            $obj
        }
    }
}
# O resultado será incorporado no clipboard, basta dar Ctrl+V no local desejado após execução
Get-InformacoesSistema -ComoTexto;
