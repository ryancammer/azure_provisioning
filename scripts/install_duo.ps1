<#
    .SYNOPSIS
    Installs Duo MFA on Windows.

    .DESCRIPTION
    The install_duo script install Duo MFA on Windows.

    .PARAMETER APIHostNameKeyName
    This is the name of the API hostname key that the script fetches
    from Azure Key Vault that Duo uses to connect with for user
    authentication.

    .PARAMETER IntegrationKeyName
    This is the name of the key that Duo uses to identify the Duo
    customer integration.

    .PARAMETER SecretKeyName
    This is the name of the secret key that identifies the Duo customer.

    .PARAMETER DuoInstallerArchiveDownloadUrl
    This is the path to the Duo installer.

    .PARAMETER KeyVaultName
    This is the name of the key vault that the script will fetch
    secrets from.

    .INPUTS
    None. You cannot pipe objects to Add-Extension.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> \install_duo.ps1 -APIHostNameKeyName $APIHostNameKeyName `
    >> -IntegrationKeyName $IntegrationKeyName `
    >> -SecretKeyName $SecretKeyName `
    >> -DuoInstallerArchiveDownloadUrl $DuoInstallerDownloadUrl `
    >> -KeyVaultName $KeyVaultName
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$APIHostNameKeyName,

    [Parameter(Mandatory = $true)]
    [string]$IntegrationKeyName,

    [Parameter(Mandatory = $true)]
    [string]$SecretKeyName,

    [Parameter(Mandatory = $true)]
    [string]$DuoInstallerArchiveDownloadUrl,

    [Parameter(Mandatory = $true)]
    [string]$KeyVaultName
)

function Initialize-TempFolder
{
    <#
        .SYNOPSIS
        Initializes a temp folder that the host registration script uses.

        .DESCRIPTION
        This function initializes a temp folder that the host registration
        script will download and extract the deploy agent to, and write
        log files into.

        .PARAMETER TempFolder
        This function will create this folder if it does not exist.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        None.
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [string]$TempFolder
    )

    if (-Not(Test-Path -Path $TempFolder))
    {
        New-Item -Path $TempFolder -ItemType directory
    }
}

function Install-Duo
{
    <#
        .SYNOPSIS
        Installs Duo MFA on Windows.

        .DESCRIPTION
        The install_duo script install Duo MFA on Windows.

        .PARAMETER APIHostNameKeyName
        This is the name of the API hostname key that Duo connects with
        for Duo user authentication.

        .PARAMETER IntegrationKeyName
        This is the name of the key that Duo uses to identify the
        Duo customer integration.

        .PARAMETER SecretKeyName
        This is the name of the secret key that identifies the Duo customer.

        .PARAMETER DuoInstallerArchiveDownloadUrl
        This is the path to the Duo installer.

        .PARAMETER KeyVaultName
        This is the name of the key vault that the script will fetch
        secrets from.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        None.

        .EXAMPLE
        PS> \install_duo.ps1 -APIHostName $APIHostName `
        >> -IntegrationKey $IntegrationKey `
        >> -SecretKey $SecretKey `
        >> -DuoInstallerArchiveDownloadUrl $DuoInstallerArchiveDownloadUrl`
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string]$APIHostNameKeyName,

        [Parameter(Mandatory = $true)]
        [string]$IntegrationKeyName,

        [Parameter(Mandatory = $true)]
        [string]$SecretKeyName,

        [Parameter(Mandatory = $true)]
        [string]$DuoInstallerArchiveDownloadUrl,

        [Parameter(Mandatory = $true)]
        [string]$KeyVaultName
    )

    try
    {
        $StartTime = Get-Date -Format yyyyMMddTHHmmss
        $TempFolder = "C:\\temp"
        $LogFile = "$TempFolder\\install_duo-$StartTime" + ".log"

        Initialize-TempFolder $TempFolder

        Write-EventToLog $LogFile "Info" "Install-Duo" "Install-Duo initiated. Temp folder initialized."

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        Write-EventToLog $LogFile "Info" "Install-Duo" "Connecting to Az account:"

        Connect-AzAccount -Identity

        Write-EventToLog $LogFile "Info" "Install-Duo" "Account connected. Getting Duo secrets: "

        $APIHostName = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $APIHostNameKeyName -AsPlainText

        $IntegrationKey = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $IntegrationKeyName -AsPlainText

        $SecretKey = Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name $SecretKeyName -AsPlainText

        Write-EventToLog $LogFile "Info" "Install-Duo" "Duo secrets fetched. Proceeding with installation."

        $DuoFileName = ([uri]$DuoInstallerDownloadUrl).Segments[-1]
        $DuoDownloadPath = "$TempFolder\\$DuoFileName"

        Invoke-FileDownload $LogFile $DuoInstallerDownloadUrl $DuoDownloadPath

        Write-EventToLog $LogFile "Info" "Install-Duo" "Duo downloaded. Expanding archive..."

        Expand-Archive $DuoDownloadPath -DestinationPath $TempFolder

        $DuoInstallerPath = "$TempFolder\\DuoWindowsLogon64.msi"

        Write-EventToLog $LogFile "Info" "Install-Duo" "Duo archive expanded proceeding with installation of $DuoInstallerPath"

        Invoke-DuoInstaller -LogFile $LogFile `
            -APIHostName $APIHostName `
            -IntegrationKey $IntegrationKey `
            -SecretKey $SecretKey `
            -DuoInstallerPath $DuoInstallerPath

        Write-EventToLog $LogFile "Info" "Install-Duo" "Install-Duo completed."
    }
    catch
    {
        $StackTrace = $_.ScriptStackTrace
        Write-EventToLog $LogFile "Error" "Install-Duo" "An error occurred. Error: $_. Stack trace: $StackTrace"
    }
}

function Invoke-DuoExtraction
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFile,

        [Parameter(Mandatory = $true)]
        [string] $DuoArchivePath,

        [Parameter(Mandatory = $true)]
        [string]$APIHostName,

        [Parameter(Mandatory = $true)]
        [string]$IntegrationKey,

        [Parameter(Mandatory = $true)]
        [string]$SecretKey
    )
}

function Invoke-DuoInstaller
{
    <#
    .SYNOPSIS
    Invokes the Duo installer.

    .DESCRIPTION
    The Invoke-DuoInstaller cmdlet invokes the Duo installer.

    .PARAMETER LogFile
    This cmdlet logs events to this logfile.

    .PARAMETER APIHostName
    This is the API hostname that Duo connects with for user authentication.

    .PARAMETER IntegrationKey
    This is the key that Duo uses to identify the customer integration.

    .PARAMETER SecretKey
    This is the secret key that identifies the customer.

    .PARAMETER DuoInstallerDownloadUrl
    This is the path to the Duo installer.

    .INPUTS
    None. You cannot pipe objects to Add-Extension.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> \install_duo.ps1 -APIHostName $APIHostName `
    >> -IntegrationKey $IntegrationKey `
    >> -SecretKey $SecretKey `
    >> -DuoInstallerDownloadUrl $DuoInstallerDownloadUrl
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFile,

        [Parameter(Mandatory = $true)]
        [string] $DuoInstallerPath,

        [Parameter(Mandatory = $true)]
        [string]$APIHostName,

        [Parameter(Mandatory = $true)]
        [string]$IntegrationKey,

        [Parameter(Mandatory = $true)]
        [string]$SecretKey
    )
    $InstallCommand = "/i c:\\temp\\DuoWindowsLogon64.msi /qn IKEY=`"$IntegrationKey`" SKEY=`"$SecretKey`" HOST=`"$APIHostName`" AUTOPUSH=`"#1`" FAILOPEN=`"#1`" SMARTCARD=`"#0`" RDPONLY=`"#0`""

    Write-EventToLog $LogFile "Info" "Invoke-DuoInstaller" "Invoking Duo installer using msiexec."

    $MsiExecProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $MsiExecProcessInfo.FileName = "msiexec.exe"
    $MsiExecProcessInfo.RedirectStandardError = $true
    $MsiExecProcessInfo.RedirectStandardOutput = $true
    $MsiExecProcessInfo.UseShellExecute = $false

    $MsiExecProcessInfo.Arguments = $InstallCommand

    $InstallationProcess = New-Object System.Diagnostics.Process
    $InstallationProcess.StartInfo = $MsiExecProcessInfo
    $InstallationProcess.Start() | Out-Null
    $InstallationProcess.WaitForExit()

    $stdout = $InstallationProcess.StandardOutput.ReadToEnd()
    $stderr = $InstallationProcess.StandardError.ReadToEnd()

    Write-EventToLog $LogFile "Info" "Invoke-DuoInstaller" "stdout: $stdout"
    Write-EventToLog $LogFile "Error" "Invoke-DuoInstaller" "stderr: $stderr"

    Write-EventToLog $LogFile "Info" "Invoke-DuoInstaller" "Duo installation completed."
}

function Invoke-FileDownload
{
    <#
        .SYNOPSIS
        Downloads a file from a url.

        .DESCRIPTION
        This function downloads a file from a url to a destination.

        .PARAMETER LogFile
        This function will log its operations to this file.

        .PARAMETER DownloadUrl
        This function will download the file from this url.

        .PARAMETER DownloadPath
        This function will download the file to this path.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        None.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFile,

        [Parameter(Mandatory = $true)]
        [string] $DownloadUrl,

        [Parameter(Mandatory = $true)]
        [string] $DownloadPath
    )

    Write-EventToLog $LogFile "Info" "Invoke-FileDownload" "Downloading $DownloadUrl to $DownloadPath"
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($DownloadUrl, $DownloadPath)
    Write-EventToLog $LogFile "Info" "Invoke-FileDownload" "Download completed."
}

function Write-EventToLog
{
    <#
        .SYNOPSIS
        Writes an event to the specified log.

        .DESCRIPTION
        This function writes an event to a log, along with a timestamp,
        the alert level, and the name of the function where the event occured.

        .PARAMETER LogFile
        This function will log its operations to this file.

        .PARAMETER Level
        This function writes the level to the log file.

        .PARAMETER Function
        This function writes the function that created this event.

        .PARAMETER Event
        This function writes the event to the log file.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        None.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string] $LogFile,

        [Parameter(Mandatory = $true)]
        [string] $Level,

        [Parameter(mandatory = $true)]
        [string] $Function,

        [Parameter(Mandatory = $true)]
        [string] $Event
    )

    $Time = Get-Date -Format "yyyy-MM-dd-THH-mm-ss"

    $Stream = New-Object System.IO.StreamWriter($LogFile, $true)
    $Stream.WriteLine("$Time : $Level : $Function : $Event")
    $Stream.Flush()
    $Stream.Close()
}

Install-Duo -APIHostNameKeyName $APIHostNameKeyName `
            -DuoInstallerArchiveDownloadUrl $DuoInstallerArchiveDownloadUrl `
            -IntegrationKeyName $IntegrationKeyName `
            -SecretKeyName $SecretKeyName `
            -KeyVaultName $KeyVaultName
