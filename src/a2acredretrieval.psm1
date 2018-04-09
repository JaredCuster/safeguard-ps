# Helper
function Invoke-SafeguardA2aCredentialRetrieval
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Appliance,
        [Parameter(Mandatory=$false)]
        [switch]$Insecure,
        [Parameter(ParameterSetName="File",Mandatory=$true)]
        [string]$CertificateFile,
        [Parameter(ParameterSetName="File",Mandatory=$false)]
        [SecureString]$Password,
        [Parameter(ParameterSetName="CertStore",Mandatory=$true)]
        [string]$Thumbprint,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$ApiKey,
        [Parameter(Mandatory=$true,Position=2)]
        [ValidateSet("Password","Key",IgnoreCase=$true)]
        [string]$CredentialType
    )

    $ErrorActionPreference = "Stop"
    if (-not $PSBoundParameters.ContainsKey("Verbose")) { $VerbosePreference = $PSCmdlet.GetVariableValue("VerbosePreference") }

    switch ($CredentialType)
    {
        "password" { $CredentialType = "Password"; break }
        "key" { $CredentialType = "Key"; break }
    }

    Import-Module -Name "$PSScriptRoot\sslhandling.psm1" -Scope Local
    try
    {
        if ($Insecure)
        {
            Disable-SslVerification
            if ($global:PSDefaultParameterValues) { $PSDefaultParameterValues = $global:PSDefaultParameterValues.Clone() }
        }

        if ($PsCmdlet.ParameterSetName -eq "CertStore")
        {
            Invoke-RestMethod -CertificateThumbprint $Thumbprint -Method GET -Headers @{
                    "Accept" = "application/json";
                    "Content-type" = "application/json";
                    "Authorization" = "A2A $ApiKey"
                } -Uri "https://$Appliance/service/a2a/Credentials?type=$CredentialType"
        }
        else
        {
            Import-Module -Name "$PSScriptRoot\sg-utilities.psm1" -Scope Local
            $local:Cert = (Use-CertificateFile $CertificateFile $Password)
            Invoke-RestMethod -Certificate $local:Cert -Method GET -Headers @{
                    "Accept" = "application/json";
                    "Content-type" = "application/json";
                    "Authorization" = "A2A $ApiKey"
                } -Uri "https://$Appliance/service/a2a/Credentials?type=$CredentialType"
        }
    }
    finally
    {
        if ($Insecure)
        {
            Enable-SslVerification
            if ($global:PSDefaultParameterValues) { $PSDefaultParameterValues = $global:PSDefaultParameterValues.Clone() }
        }
    }
}

function Get-SafeguardA2aPassword
{
    [CmdletBinding(DefaultParameterSetName="CertStore")]
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Appliance,
        [Parameter(Mandatory=$false)]
        [switch]$Insecure,
        [Parameter(ParameterSetName="File",Mandatory=$true)]
        [string]$CertificateFile,
        [Parameter(ParameterSetName="File",Mandatory=$false)]
        [SecureString]$Password,
        [Parameter(ParameterSetName="CertStore",Mandatory=$true)]
        [string]$Thumbprint,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$ApiKey
    )

    $ErrorActionPreference = "Stop"
    if (-not $PSBoundParameters.ContainsKey("Verbose")) { $VerbosePreference = $PSCmdlet.GetVariableValue("VerbosePreference") }

    if ($PsCmdlet.ParameterSetName -eq "CertStore")
    {
        (Invoke-SafeguardA2aCredentialRetrieval -Insecure:$Insecure -Appliance $Appliance -ApiKey $ApiKey `
            -Thumbprint $Thumbprint -CredentialType Password).Password
    }
    else
    {
        (Invoke-SafeguardA2aCredentialRetrieval -Insecure:$Insecure -Appliance $Appliance -ApiKey $ApiKey `
            -CertificateFile $CertificateFile -Password $Password -CredentialType Password).Password
    }
}

function Get-SafeguardA2aPrivateKey
{
    [CmdletBinding(DefaultParameterSetName="CertStore")]
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Appliance,
        [Parameter(Mandatory=$false)]
        [switch]$Insecure,
        [Parameter(ParameterSetName="File",Mandatory=$true)]
        [string]$CertificateFile,
        [Parameter(ParameterSetName="File",Mandatory=$false)]
        [SecureString]$Password,
        [Parameter(ParameterSetName="CertStore",Mandatory=$true)]
        [string]$Thumbprint,
        [Parameter(Mandatory=$true,Position=1)]
        [string]$ApiKey
    )

    $ErrorActionPreference = "Stop"
    if (-not $PSBoundParameters.ContainsKey("Verbose")) { $VerbosePreference = $PSCmdlet.GetVariableValue("VerbosePreference") }

    if ($PsCmdlet.ParameterSetName -eq "CertStore")
    {
        (Invoke-SafeguardA2aCredentialRetrieval -Insecure:$Insecure -Appliance $Appliance -ApiKey $ApiKey `
            -Thumbprint $Thumbprint -CredentialType Key).Key
    }
    else
    {
        (Invoke-SafeguardA2aCredentialRetrieval -Insecure:$Insecure -Appliance $Appliance -ApiKey $ApiKey `
            -CertificateFile $CertificateFile -Password $Password -CredentialType Key).Key
    }
}