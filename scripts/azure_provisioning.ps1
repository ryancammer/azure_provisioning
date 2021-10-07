<#
    .SYNOPSIS
    Downloads Powershell 7, and kicks off VM host registration with a host session pool.

    .DESCRIPTION
    The azure_provisioning script downloads Powershell 7, which is the version
    of powershell recommended for installing and running the Az module. Az is used
    by the host_registration script for registering a Virtual Machine with an
    Azure Virtual Desktop host session pool, which enables the host to be used for
    Virtual Desktop users.

    .PARAMETER ServicePrincipalApplicationId
    This is the service principal id, which corresponds to an App Registration
    in Azure Active Directory. There is a 1 to 1 correlation between an App
    Registration and a Service Principal.

    .PARAMETER ServicePrincipalApplicationSecret
    This is the value of the Client Secret for the App Registration.

    .PARAMETER TenantId
    This is the Tenant id for the Azure Active Directory that the resources
    such as the Virtual Machine, Service Principal, and Session Host Pool
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

    .INPUTS
    None. You cannot pipe objects to Add-Extension.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> \azure_provisioning.ps1 -ServicePrincipalApplicationId $ServicePrincipalApplicationId `
    >> -ServicePrincipalApplicationSecret $ServicePrincipalApplicationSecret `
    >> -TenantId $TenantId `
    >> -SubscriptionId $SubscriptionId `
    >> -ResourceGroupName $ResourceGroupName `
    >> -HostPoolName $HostPoolName `
    >> -RegistrationScriptName $RegistrationScriptName
    >> -RegistrationScriptDownloadUrl $RegistrationScriptDownloadUrl
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$ServicePrincipalApplicationId,

    [Parameter(Mandatory = $true)]
    [string]$ServicePrincipalApplicationSecret,

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
    [string]$DeployAgentDownloadUrl
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

        .PARAMETER ServicePrincipalApplicationId
        This is the service principal id, which corresponds to an App Registration
        in Azure Active Directory. There is a 1 to 1 correlation between an App
        Registration and a Service Principal.

        .PARAMETER ServicePrincipalApplicationSecret
        This is the value of the Client Secret for the App Registration.

        .PARAMETER TenantId
        This is the Tenant id for the Azure Active Directory that the resources
        such as the Virtual Machine, Service Principal, and Session Host Pool
        belong to.

        .PARAMETER SubscriptionId
        This is the Azure Subscription Id for all of the resources used in this
        script.

        .PARAMETER ResourceGroupName
        This is the name of the Resource Group that the resources used in this
        script.

        .PARAMETER HostPoolName
        This is the name of the session host pool that the VM will join.

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
        [string] $ServicePrincipalApplicationId,

        [Parameter(Mandatory = $true)]
        [string] $ServicePrincipalApplicationSecret,

        [Parameter(Mandatory = $true)]
        [string] $TenantId,

        [Parameter(Mandatory = $true)]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string] $HostPoolName
    )

    $PwshProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
    $PwshProcessInfo.FileName = "C:\\Program Files\\PowerShell\\7\\pwsh.exe"
    $PwshProcessInfo.RedirectStandardError = $true
    $PwshProcessInfo.RedirectStandardOutput = $true
    $PwshProcessInfo.UseShellExecute = $false

    # TODO: strip out sensitive parameters after getting command to work
    Write-EventToLog $LogFile "Powershell 7 command: Start-Process C:\\Program Files\\PowerShell\\7\\pwsh.exe -ExecutionPolicy Unrestricted -exec bypass -File $RegistrationScript -ServicePrincipalApplicationId $ServicePrincipalApplicationId -ServicePrincipalApplicationSecret $ServicePrincipalApplicationSecret -Tenant $Tenant -Subscription $Subscription -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName'"

    $PwshProcessInfo.Arguments = "-ExecutionPolicy Unrestricted -exec bypass -File $RegistrationScript -ServicePrincipalApplicationId $ServicePrincipalApplicationId -ServicePrincipalApplicationSecret $ServicePrincipalApplicationSecret -TenantId $TenantId -Subscription $Subscription -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName'"

    $InstallationProcess = New-Object System.Diagnostics.Process
    $InstallationProcess.StartInfo = $PwshProcessInfo
    Write-EventToLog $LogFile "Starting the pwsh process now on script $RegistrationScript"
    $InstallationProcess.Start() | Out-Null
    $InstallationProcess.WaitForExit()

    $stdout = $InstallationProcess.StandardOutput.ReadToEnd()
    $stderr = $InstallationProcess.StandardError.ReadToEnd()

    Write-EventToLog $LogFile "stdout: $stdout"
    Write-EventToLog $LogFile "stderr: $stderr"
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
        [string]$PowershellExecutablePath,
        [string]$LogFile,
        [string]$MsiExecLogPath
    )

    $PowershellCommand = "Start-Process msiexec.exe -Wait -ArgumentList '/I $PowershellExecutablePath /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1'"

    Write-EventToLog $LogFile "The equivalent powershell command is $PowershellCommand"

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

    Write-EventToLog $LogFile "stdout: $stdout"
    Write-EventToLog $LogFile "stderr: $stderr"
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

        .PARAMETER ServicePrincipalApplicationId
        This is the service principal id, which corresponds to an App Registration
        in Azure Active Directory. There is a 1 to 1 correlation between an App
        Registration and a Service Principal.

        .PARAMETER ServicePrincipalApplicationSecret
        This is the value of the Client Secret for the App Registration.

        .PARAMETER TenantId
        This is the Tenant id for the Azure Active Directory that the resources
        such as the Virtual Machine, Service Principal, and Session Host Pool
        belong to.

        .PARAMETER SubscriptionId
        This is the Azure Subscription Id for all of the resources used in this
        script.

        .PARAMETER ResourceGroupName
        This is the name of the Resource Group that the resources used in this
        script.

        .PARAMETER HostPoolName
        This is the name of the session host pool that the VM will join.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        None.
    #>

    param (
        [Parameter(Mandatory = $true)]
        [string] $ServicePrincipalApplicationId,

        [Parameter(Mandatory = $true)]
        [string] $ServicePrincipalApplicationSecret,

        [Parameter(Mandatory = $true)]
        [string] $TenantId,

        [Parameter(Mandatory = $true)]
        [string] $Subscription,

        [Parameter(Mandatory = $true)]
        [string] $ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string] $HostPoolName
    )

    $StartTime = Get-Date -Format yyyyMMddTHHmmss

    $PowershellVersion = "7.1.4"
    $PowershellInstallExecutable = "PowerShell-$PowershellVersion-win-x64.msi"
    $TempFolder = "C:\\temp"
    $PowershellExecutablePath = "$TempFolder\\$PowershellInstallExecutable"
    $RegistrationScriptName = "host_registration.ps1"

    Initialize-TempFolder $TempFolder

    $LogFile = "$TempFolder\\azure_provisioning-$StartTime" + ".log"

    Write-EventToLog "Info" "Register-Host" $LogFile "Temp folder initialized."

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

        Invoke-PowershellInstallProcess $PowershellExecutablePath $LogFile $MsiLogPath

        Write-EventToLog $LogFile "Info" "Register-Host" "Powershell installed. Downloading registration script..."

        $RegistrationScriptPath = "$TempFolder\\$RegistrationScriptName"

        Invoke-FileDownload $LogFile $RegistrationScriptDownloadUrl $RegistrationScriptPath

        Write-EventToLog $LogFile "Info" "Register-Host" "Executing registration script..."

        Invoke-HostRegistration -LogFile $LogFile `
            -RegistrationScript $RegistrationScript `
            -ServicePrincipalApplicationId $ServicePrincipalApplicationId `
            -ServicePrincipalApplicationSecret $ServicePrincipalApplicationSecret `
            -TenantId $TenantId `
            -SubscriptionId $SubscriptionId `
            -ResourceGroupName $ResourceGroupName `
            -RegistrationScriptPath $RegistrationScriptPath

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

Register-Host -ServicePrincipalApplicationId $ServicePrincipalApplicationId `
    -ServicePrincipalApplicationSecret $ServicePrincipalApplicationSecret `
    -TenantId $TenantId `
    -SubscriptionId $SubscriptionId `
    -ResourceGroupName $ResourceGroupName `
    -HostPoolName $HostPoolName `
    -RegistrationScriptName $RegistrationScriptName `
    -RegistrationScriptDownloadUrl $RegistrationScriptDownloadUrl `
    -DeployAgentDownloadUrl $DeployAgentDownloadUrl
