<#
    .SYNOPSIS
    Downloads Powershell 7, and kicks off VM host registration with a host session pool.

    .DESCRIPTION
    The azure_provisioning script downloads Powershell 7, which is the version
    of powershell recommended for installing and running the Az module. Az is used
    by the host_registration script for registering a Virtual Machine with an
    Azure Virtual Desktop host session pool, which enables the host to be used for
    Virtual Desktop users.

    .PARAMETER TenantId
    This is the Tenant id for the Azure Active Directory that the resources
    such as the Virtual Machine, and Session Host Pool
    belong to.

    .PARAMETER SubscriptionId
    This is the Azure Subscription Id for all of the resources used in this
    script.

    .PARAMETER ResourceGroupName
    This script modifies resources in the resource group with this name.

    .PARAMETER HostPoolName
    This script joins the VM to a host pool with this name.

    .PARAMETER RegistrationScriptName
    This script executes a registration script with this name.

    .PARAMETER RegistrationScriptDownloadUrl
    This script downloads the registration script from this url.

    .PARAMETER DeployAgentDownloadUrl
    This script downloads the deployment agent that installs the executables
    that join the host to the session host pool.

    .PARAMETER $AzArchiveDownloadUrl
    This function downloads the Az cmdlets archive file from this url.

    .INPUTS
    None. You cannot pipe objects to Add-Extension.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> \azure_provisioning.ps1 -TenantId $TenantId `
    >> -SubscriptionId $SubscriptionId `
    >> -ResourceGroupName $ResourceGroupName `
    >> -HostPoolName $HostPoolName `
    >> -RegistrationScriptName $RegistrationScriptName `
    >> -RegistrationScriptDownloadUrl $RegistrationScriptDownloadUrl `
    >> -DeployAgentDownloadUrl $DeployAgentDownloadUrl `
    >> -AzArchiveDownloadUrl $AzArchiveDownloadUrl
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$TenantId,

    [Parameter(Mandatory = $true)]
    [string]$SubscriptionId,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory = $true)]
    [string]$HostPoolName,

    [Parameter(Mandatory = $true)]
    [string]$RegistrationScriptName,

    [Parameter(Mandatory = $true)]
    [string]$RegistrationScriptDownloadUrl,

    [Parameter(Mandatory = $true)]
    [string]$DeployAgentDownloadUrl,

    [Parameter(Mandatory = $true)]
    [string] $AzArchiveDownloadUrl
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

function Invoke-HostRegistration
{
    <#
        .SYNOPSIS
        Execute the host registration script.

        .DESCRIPTION
        This function executes the host registration script using Powershell 7.

        .PARAMETER LogFile
        This function will log its operations to this file.

        .PARAMETER RegistrationScript
        This function executes this registration script with Powershell 7.

        .PARAMETER TenantId
        This is the Tenant id for the Azure Active Directory that the resources
        such as the Virtual Machine, and Session Host Pool
        belong to.

        .PARAMETER SubscriptionId
        This is the Azure Subscription Id for all of the resources used in this
        script.

        .PARAMETER ResourceGroupName
        This is the name of the Resource Group that the resources used in this
        script.

        .PARAMETER HostPoolName
        This is the name of the session host pool that the VM will join.

        .PARAMETER DeployAgentDownloadUrl
        This is the url the script will download the deploy agent from.

        .PARAMETER $AzArchiveDownloadUrl
        This function downloads the Az cmdlets archive file from this url.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        None.
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $LogFile,

        [Parameter(Mandatory = $true)]
        [string] $RegistrationScript,

        [Parameter(Mandatory = $true)]
        [string] $TenantId,

        [Parameter(Mandatory = $true)]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string] $HostPoolName,

        [Parameter(Mandatory = $true)]
        [string] $DeployAgentDownloadUrl,

        [Parameter(Mandatory = $true)]
        [string] $AzArchiveDownloadUrl
    )

    $PwshProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $PwshProcessInfo.FileName = "C:\\Program Files\\PowerShell\\7\\pwsh.exe"
    $PwshProcessInfo.RedirectStandardError = $true
    $PwshProcessInfo.RedirectStandardOutput = $true
    $PwshProcessInfo.UseShellExecute = $false

    Write-EventToLog $LogFile "Info" "Invoke-HostRegistration" "Powershell 7 command: Start-Process C:\\Program Files\\PowerShell\\7\\pwsh.exe -ExecutionPolicy Unrestricted -exec bypass -File $RegistrationScript -AzArchiveDownloadUrl $AzArchiveDownloadUrl -DeployAgentDownloadUrl $DeployAgentDownloadUrl -TenantId $TenantId -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName"

    $PwshProcessInfo.Arguments = "-ExecutionPolicy Unrestricted -exec bypass -File $RegistrationScript -AzArchiveDownloadUrl $AzArchiveDownloadUrl -DeployAgentDownloadUrl $DeployAgentDownloadUrl -TenantId $TenantId -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName"

    $InstallationProcess = New-Object System.Diagnostics.Process
    $InstallationProcess.StartInfo = $PwshProcessInfo
    Write-EventToLog $LogFile "Info" "Invoke-HostRegistration" "Starting the pwsh process now on script $RegistrationScript"
    $InstallationProcess.Start() | Out-Null
    $InstallationProcess.WaitForExit()

    $stdout = $InstallationProcess.StandardOutput.ReadToEnd()
    $stderr = $InstallationProcess.StandardError.ReadToEnd()

    Write-EventToLog $LogFile "Info" "Invoke-HostRegistration" "stdout: $stdout"
    Write-EventToLog $LogFile "Error" "Invoke-HostRegistration" "stderr: $stderr"
}

function Invoke-PowershellInstallProcess
{
    <#
        .SYNOPSIS
        Installs Powershell 7.

        .DESCRIPTION
        This function executes the host registration script using Powershell 7.

        .PARAMETER LogFile
        This function logs its operations to this file.

        .PARAMETER PowershellExecutablePath
        This function installs Powershell from this path.

        .PARAMETER MsiExecLogPath
        This function writes MSI events to this log.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        None.
    #>

    [CmdletBinding()]
    param (
        [string]$LogFile,
        [string]$PowershellExecutablePath,
        [string]$MsiExecLogPath
    )

    $PowershellCommand = "Start-Process msiexec.exe -Wait -ArgumentList '/I $PowershellExecutablePath /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1'"

    Write-EventToLog $LogFile "Info" "Invoke-PowershellInstallProcess" "The equivalent powershell command is $PowershellCommand"

    $MsiExecProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $MsiExecProcessInfo.FileName = "msiexec.exe"
    $MsiExecProcessInfo.RedirectStandardError = $true
    $MsiExecProcessInfo.RedirectStandardOutput = $true
    $MsiExecProcessInfo.UseShellExecute = $false

    $MsiExecProcessInfo.Arguments = "/I $PowershellExecutablePath /quiet /log $MsiExecLogPath ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1"

    $InstallationProcess = New-Object System.Diagnostics.Process
    $InstallationProcess.StartInfo = $MsiExecProcessInfo
    $InstallationProcess.Start() | Out-Null
    $InstallationProcess.WaitForExit()

    $stdout = $InstallationProcess.StandardOutput.ReadToEnd()
    $stderr = $InstallationProcess.StandardError.ReadToEnd()

    Write-EventToLog $LogFile "Info" "Invoke-PowershellInstallProcess" "stdout: $stdout"
    Write-EventToLog $LogFile "Error" "Invoke-PowershellInstallProcess" "stderr: $stderr"
}

function Register-Host
{
    <#
        .SYNOPSIS
        This function downloads Powershell 7, and kicks off VM host registration with a host session pool.

        .DESCRIPTION
        This function downloads Powershell 7, which is the version
        of powershell recommended for installing and running the Az module. Az is used
        by the host_registration script for registering a Virtual Machine with an
        Azure Virtual Desktop host session pool, which enables the host to be used for
        Virtual Desktop users.

        .PARAMETER TenantId
        This is the Tenant id for the Azure Active Directory that the resources
        such as the Virtual Machine, and Session Host Pool belong to.

        .PARAMETER SubscriptionId
        This is the Azure Subscription Id for all of the resources used in this
        script.

        .PARAMETER RegistrationScriptDownloadUrl
        This script downloads the registration script from this url.

        .PARAMETER ResourceGroupName
        This is the name of the Resource Group that the resources used in this
        script.

        .PARAMETER HostPoolName
        This is the name of the session host pool that the VM will join.

         .PARAMETER RegistrationScriptName
        This is the name of the registration script that this script calls.

        .PARAMETER DeployAgentDownloadUrl
        This script downloads the deployment agent that installs the executables
        that join the host to the session host pool.

        .PARAMETER $AzArchiveDownloadUrl
        This function downloads the Az cmdlets archive file from this url.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        None.
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string] $TenantId,

        [Parameter(Mandatory = $true)]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string] $HostPoolName,

        [Parameter(Mandatory = $true)]
        [string] $RegistrationScriptName,

        [Parameter(Mandatory = $true)]
        [string] $RegistrationScriptDownloadUrl,

        [Parameter(Mandatory = $true)]
        [string] $DeployAgentDownloadUrl,

        [Parameter(Mandatory = $true)]
        [string] $AzArchiveDownloadUrl
    )

    $StartTime = Get-Date -Format yyyyMMddTHHmmss

    $PowershellVersion = "7.1.5"
    $PowershellInstallExecutable = "PowerShell-$PowershellVersion-win-x64.msi"
    $TempFolder = "C:\\temp"
    $PowershellExecutablePath = "$TempFolder\\$PowershellInstallExecutable"
    $RegistrationScriptName = "host_registration.ps1"

    Initialize-TempFolder $TempFolder

    $LogFile = "$TempFolder\\azure_provisioning-$StartTime" + ".log"

    Write-EventToLog $LogFile "Info" "Register-Host" "Temp folder initialized."

    try
    {
        if (-Not(Test-Path -Path $PowershellExecutablePath -PathType Leaf))
        {
            Write-EventToLog $LogFile "Info" "Register-Host" "Powershell $PowershellVersion installer not present. Downloading..."

            $PowershellDownloadUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$PowershellVersion/$PowershellInstallExecutable"
            $PowershellDownloadPath = "$TempFolder\\$PowershellInstallExecutable"

            Invoke-FileDownload $LogFile $PowershellDownloadUrl $PowershellDownloadPath
            Write-EventToLog $LogFile "Info" "Register-Host" "Powershell $PowershellVersion downloaded."
        }
        else
        {
            Write-EventToLog $LogFile "Info" "Register-Host" "Powershell $PowershellVersion already downloaded."
        }

        $MsiLogPath = "$TempFolder\\msi_install-$StartTime.log"

        Write-EventToLog $LogFile "Info" "Register-Host" "Installing Powershell..."

        Invoke-PowershellInstallProcess $LogFile $PowershellExecutablePath $MsiLogPath

        Write-EventToLog $LogFile "Info" "Register-Host" "Powershell installed. Downloading registration script..."

        $RegistrationScriptPath = "$TempFolder\\$RegistrationScriptName"

        Invoke-FileDownload $LogFile $RegistrationScriptDownloadUrl $RegistrationScriptPath

        Write-EventToLog $LogFile "Info" "Register-Host" "Executing registration script..."

        Invoke-HostRegistration -LogFile $LogFile `
            -RegistrationScript $RegistrationScriptPath `
            -TenantId $TenantId `
            -SubscriptionId $SubscriptionId `
            -ResourceGroupName $ResourceGroupName `
            -HostPoolName $HostPoolName `
            -DeployAgentDownloadUrl $DeployAgentDownloadUrl `
            -AzArchiveDownloadUrl $AzArchiveDownloadUrl

        Write-EventToLog $LogFile "Info" "Register-Host" "Registration script execution complete."
    }
    catch
    {
        $StackTrace = $_.ScriptStackTrace
        Write-EventToLog $LogFile "Error" "Register-Host" "An error occurred. Error: $_. Stack trace: $StackTrace"
    }
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

Register-Host -TenantId $TenantId `
    -SubscriptionId $SubscriptionId `
    -ResourceGroupName $ResourceGroupName `
    -HostPoolName $HostPoolName `
    -RegistrationScriptName $RegistrationScriptName `
    -RegistrationScriptDownloadUrl $RegistrationScriptDownloadUrl `
    -DeployAgentDownloadUrl $DeployAgentDownloadUrl `
    -AzArchiveDownloadUrl $AzArchiveDownloadUrl
