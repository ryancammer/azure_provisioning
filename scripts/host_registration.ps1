<#
    .SYNOPSIS
    Registers a Virtual Machine with a host session pool.

    .DESCRIPTION
    The host_registration script enables a Virtual Machine to serve as a
    session host. It does this by generating a session host registration
    token from a host pool, and then using that token to join the host pool.

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
    This script will download the DeployAgent archive from this url.

    .PARAMETER ReRegisterHost
    This switch will cause the VM to be re-registered, even if it has been
    previously registered. If the switch is present, the Registry key
    HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent will be deleted.
    Otherwise, registration will fail to register with the session host if
    it has already been registered. __NOTE__: If the VM was previously
    registered, the old registration will be deleted.

    .INPUTS
    None. You cannot pipe objects to Add-Extension.

    .OUTPUTS
    None.

    .EXAMPLE
    PS> \host_registration.ps1 -TenantId $TenantId `
    >> -SubscriptionId $SubscriptionId `
    >> -ResourceGroupName $ResourceGroupName `
    >> -HostPoolName $HostPoolName `
    >> -DeployAgentDownloadUrl $DeployAgentDownloadUrl `
    >> -ReRegisterHost
#>

param(
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

    [Parameter(Mandatory = $false)]
    [switch] $ReRegisterHost
)

function Get-RegistrationToken
{
    <#
        .SYNOPSIS
        Gets a registration token so that a Virtual Machine may join a session host pool.

        .DESCRIPTION
        The Get-RegistrationToken function uses the local VM's service principal in order
        to fetch a host pool session registration token from a host pool, which
        a virtual machine can then use to join the host pool.

        .PARAMETER LogFile
        This function will log its operations to this file.

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

        .PARAMETER ReRegisterHost
        This switch will cause the VM to be re-registered, even if it has been
        previously registered. If the switch is present, the Registry key
        HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent will be deleted.
        Otherwise, registration will fail to register with the session host if
        it has already been registered. __NOTE__: If the VM was previously
        registered, the old registration will be deleted.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        None.

        .EXAMPLE
        PS> \host_registration.ps1 -TenantId $TenantId `
        >> -SubscriptionId $SubscriptionId `
        >> -ResourceGroupName $ResourceGroupName `
        >> -HostPoolName $HostPoolName `
        >> -ReRegisterHost
    #>

    param(
        [Parameter(Mandatory = $true)]
        [string] $LogFile,

        [Parameter(mandatory = $true)]
        [string] $TenantId,

        [Parameter(mandatory = $true)]
        [string] $SubscriptionId,

        [Parameter(Mandatory = $true)]
        [string]$ResourceGroupName,

        [Parameter(Mandatory = $true)]
        [string] $HostPoolName
    )

    Write-EventToLog $LogFile "Info" "Get-SessionHostToken" "Connecting to Az account:"

    Connect-AzAccount -Identity

    Write-EventToLog $LogFile "Info" "Get-SessionHostToken" "Account connected. Creating new registration info: "

    $ExpirationInMinutes = 61

    $RegistrationInfo = New-AzWvdRegistrationInfo -SubscriptionId $SubscriptionId -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -ExpirationTime $((get-date).ToUniversalTime().AddMinutes($ExpirationInMinutes).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ') )

    $RegistrationToken = $RegistrationInfo.Token

    Write-EventToLog $LogFile "Info" "Get-SessionHostToken" "Registration Token created."

    $RegistrationToken
}

function Invoke-RegistryProvisioning
{
    <#
        .SYNOPSIS
        Handles registry provisioning for the RDInfraAgent registry values.

        .DESCRIPTION
        If the RDInfraAgent value is set at HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RDInfraAgent,
        a host will not join a host session pool. The caller may not want a
        Virtual Machine to join another session pool, in which case, if the
        switch ReRegisterHost is not set, the script will exit. If the switch
        is set, then the registry value will be deleted so that the Virtual
        Machine can then join the host pool.

        .PARAMETER LogFile
        This function will log its operations to this file.

        .PARAMETER ReRegisterHost
        This indicates whether the caller wishes to re-register the VM as a
        session host with the new session host pool. The script will use this
        switch to either delete the RDInfraAgent registry key, or exit if
        the switch is not set.

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
        [bool] $ReRegisterHost
    )

    $InitializationMessage = "Handle-RegistryProvisioning called with the following arguments: " +
            "LogFile: $LogFile, ReRegisterHost: $ReRegisterHost"

    Write-EventToLog $LogFile "Info" "Handle-RegistryProvisioning" $InitializationMessage

    $RDInfraAgentRegistryFullPath = 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent'

    $RDInfraAgentRegistryValue = Get-ItemProperty -Path $RDInfraAgentRegistryFullPath -ErrorAction SilentlyContinue

    if ($RDInfraAgentRegistryValue)
    {
        if ($ReRegisterHost -eq $true)
        {
            $PreDeleteLogMessage = "RDInfraAgent Registry value $RDInfraAgentRegistryFullPath was found. " +
                    "Deleting registry value so that agent can re-register:"
            Write-EventToLog $LogFile "Info" "Handle-RegistryProvisioning" $PreDeleteLogMessage

            Remove-ItemProperty -Path $RDInfraAgentRegistryFullPath -Name "*"

            $PostDeleteLogMessage = "RDInfraAgent Registry value $RDInfraAgentRegistryFullPath was deleted."
            Write-EventToLog $LogFile "Info" "Handle-RegistryProvisioning" $PostDeleteLogMessage
        }
        else
        {
            $LogMessage = "RDInfraAgent Registry value was found. Exiting."
            Write-EventToLog $LogFile "Error" "Handle-RegistryProvisioning" $LogMessage
            exit 1
        }
    }
    else
    {
        $PostDeleteLogMessage = "RDInfraAgent Registry value $RDInfraAgentRegistryFullPath was not found."
        Write-EventToLog $LogFile "Info" "Handle-Registry" $PostDeleteLogMessage
    }
}

function Get-ArchiveAndUnzip
{
    <#
        .SYNOPSIS
        Gets an archive and unzips it into a directory.

        .DESCRIPTION
        This function downloads and archive from a url and then unzips it.

        .PARAMETER LogFile
        This function will log its operations to this file.

        .PARAMETER DownloadUrl
        This function will download the zipped deploy agent from this url.

        .PARAMETER DownloadPath
        This function will download the archive to this path.

        .PARAMETER ExpandedArchiveDirectory
        This function will expand the archive to this directory.

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
        [string] $DownloadUrl,

        [Parameter(Mandatory = $true)]
        [string] $DownloadPath,

        [Parameter(Mandatory = $true)]
        [string] $ExpandedArchiveDirectory
    )

    if (Test-Path $DownloadPath)
    {
        Write-EventToLog $LogFile "Info" "Get-ArchiveAndUnzip" "Archive at $DownloadPath being deleted:"
        Remove-Item -Path $DownloadPath -Force -Confirm:$false
        Write-EventToLog $LogFile "Info" "Get-ArchiveAndUnzip" "Archive at $DownloadPath deleted."
    }

    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($DownloadUrl, $DownloadPath)

    if (Test-Path $ExpandedArchiveDirectory)
    {
        Write-EventToLog $LogFile "Info" "Get-ArchiveAndUnzip" "Directory at $ExpandedArchiveDirectory being deleted:"
        Remove-Item -Path $ExpandedArchiveDirectory -Force -Confirm:$false -Recurse
        Write-EventToLog $LogFile "Info" "Get-ArchiveAndUnzip" "Directory at $ExpandedArchiveDirectory deleted."
    }

    Write-EventToLog $LogFile "Info" "Get-ArchiveAndUnzip" "Directory at $ExpandedArchiveDirectory being created:"
    New-Item -Path $ExpandedArchiveDirectory -ItemType directory -Force
    Write-EventToLog $LogFile "Info" "Get-ArchiveAndUnzip" "Directory at $ExpandedArchiveDirectory created."

    Write-EventToLog $LogFile "Info" "Get-ArchiveAndUnzip" "$DownloadPath being expanded into $ExpandedArchiveDirectory now:"
    Expand-Archive $DownloadPath -DestinationPath $ExpandedArchiveDirectory
    Write-EventToLog $LogFile "Info" "Get-ArchiveAndUnzip" "$DownloadPath was expanded into $ExpandedArchiveDirectory ."
}

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

function Invoke-DeployAgent
{
    <#
        .SYNOPSIS
        Registers a Virtual Machine with a host session pool.

        .DESCRIPTION
        The host_registration script enables a Virtual Machine to serve as a
        session host. It does this by generating a session host registration
        token from a host pool, and then using that token to join the host pool.

        .PARAMETER LogFile
        This function logs its operations to this file.

        .PARAMETER LogDirectory
        This function logs its installation operations to this directory.

        .PARAMETER AgentInstallerFolder
        This function uses executables in this folder for installing the
        RD Infra Agent.

        .PARAMETER AgentBootServiceInstallerFolder
        This function uses executables in this folder to instal the
        RD Agent Boot Loader.

        .PARAMETER SxSStackInstallerFolder
        This function uses executables in this folder to install the
        RD Infra SxS Stack.

        .PARAMETER EnableSxSStackScriptFolder
        This function uses executables in this folder to install the
        Enable SxS Stack Script.

        .PARAMETER RegistrationToken
        This script uses this session host registration token to register
        the Virtual Machine with the session host pool.

        .PARAMETER StartAgent
        This script starts the agent service (RdInfraAgent) immediately if
        this is set to true.


        .PARAMETER rdshIs1809OrLater
        This script passes this value to DeployAgent so that it will
        run the enablesxsstack script.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        None.
    #>

    Param(
        [Parameter(Mandatory = $true)]
        [string] $LogFile,

        [Parameter(Mandatory = $true)]
        [string] $LogDirectory,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AgentInstallerFolder,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AgentBootServiceInstallerFolder,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$SxSStackInstallerFolder,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EnableSxSStackScriptFolder,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$RegistrationToken,

        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [bool]$StartAgent,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [bool]$rdshIs1809OrLater

    )

    try
    {
        $StartTime = Get-Date -Format yyyyMMddTHHmmss

        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Boot loader folder is $AgentBootServiceInstallerFolder"
        $AgentBootServiceInstaller = (Get-ChildItem $AgentBootServiceInstallerFolder\ -Filter *.msi | Select-Object).FullName
        if ((-not$AgentBootServiceInstaller) -or (-not(Test-Path $AgentBootServiceInstaller)))
        {
            throw "RD Infra Agent Installer package is not found '$AgentBootServiceInstaller'"
        }

        # Convert relative paths to absolute paths if needed
        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Agent folder is $AgentInstallerFolder"
        $AgentInstaller = (Get-ChildItem $AgentInstallerFolder\ -Filter *.msi | Select-Object).FullName
        if ((-not$AgentInstaller) -or (-not(Test-Path $AgentInstaller)))
        {
            throw "RD Infra Agent Installer package is not found '$AgentInstaller'"
        }

        # Convert relative paths to absolute paths if needed
        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "SxS folder is $SxSStackInstallerFolder"
        $SxSStackInstaller = (Get-ChildItem $SxSStackInstallerFolder\ -Filter *.msi | Select-Object).FullName
        if ((-not$SxSStackInstaller) -or (-not(Test-Path $SxSStackInstaller)))
        {
            throw "SxS Stack Installer package is not found '$SxSStackInstaller'"
        }

        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "EnableSxSStackScript is $EnableSxSStackScriptFolder"
        $EnableSxSStackScript = (Get-ChildItem $EnableSxSStackScriptFolder\ -Filter *.ps1 | Select-Object).FullName
        if ((-not$EnableSxSStackScript) -or (-not(Test-Path $EnableSxSStackScript)))
        {
            throw "EnableSxSStack script is not found '$EnableSxSStackScript'"
        }

        if (!$RegistrationToken)
        {
            Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "The registration token is missing."
            throw "The registration token is missing."
        }

        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Uninstalling any previous versions of RDAgentBootLoader on VM`n"
        $bootloader_uninstall_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x {A38EE409-424D-4A0D-B5B6-5D66F20F62A5}", "/quiet", "/qn", "/norestart", "/passive", "/l* $LogDirectory\\AgentBootLoaderInstall-$StartTime-.txt" -Wait -Passthru
        $sts = $bootloader_uninstall_status.ExitCode
        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Uninstalling RD Infra Agent on VM Complete. Exit code=$sts`n"

        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Uninstalling any previous versions of RD Infra Agent on VM"
        $legacy_agent_uninstall_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x {5389488F-551D-4965-9383-E91F27A9F217}", "/quiet", "/qn", "/norestart", "/passive", "/l* $LogDirectory\\AgentUninstall-$StartTime-.txt" -Wait -Passthru
        $sts = $legacy_agent_uninstall_status.ExitCode
        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Uninstalling RD Infra Agent on VM Complete. Exit code=$sts`n"

        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Uninstalling any previous versions of RD Infra Agent DLL on VM"
        $agent_uninstall_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x {CB1B8450-4A67-4628-93D3-907DE29BF78C}", "/quiet", "/qn", "/norestart", "/passive", "/l* $LogDirectory\\AgentUninstall-$StartTime-.txt" -Wait -Passthru
        $sts = $agent_uninstall_status.ExitCode
        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Uninstalling RD Infra Agent on VM Complete. Exit code=$sts`n"

        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Installing RDAgent BootLoader on VM $AgentBootServiceInstaller"
        $bootloader_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentBootServiceInstaller", "/quiet", "/qn", "/norestart", "/passive", "/l* $LogDirectory\\AgentBootLoaderInstall-$StartTime-.txt" -Wait -Passthru
        $sts = $bootloader_deploy_status.ExitCode
        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Installing RDAgentBootLoader on VM Complete. Exit code=$sts`n"
        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Installing RD Infra Agent on VM $AgentInstaller`n"
        $agent_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentInstaller", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$RegistrationToken", "/l* $LogDirectory\\AgentInstall-$StartTime-.txt" -Wait -Passthru
        $sts = $agent_deploy_status.ExitCode
        Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Installing RD Infra Agent on VM Complete. Exit code=$sts`n"

        $StartAgentBoolean = [System.Convert]::ToBoolean($StartAgent)

        if ($StartAgentBoolean)
        {
            Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Starting the RDInfraAgent service."
            Start-Service RDAgentBootLoader
        }

        $agent_deploy_status = $agent_deploy_status.ExitCode

        $rdshIs1809OrLaterBoolean = [System.Convert]::ToBoolean($rdshIs1809OrLaterBoolean)

        # If the session host is Windows 1809 or later, run the enablesxsstack script
        if ($rdshIs1809OrLaterBoolean)
        {
            Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Enabling Built-in RD SxS Stack on VM $EnableSxSStackScript`n"

            $enablesxs_deploy_status = PowerShell.exe -ExecutionPolicy Unrestricted -File $EnableSxSStackScript
            $sts = $enablesxs_deploy_status.ExitCode
            Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Enabling Built-in RD SxS Stack on VM Complete. Exit code=$sts`n"
        }
        else
        {
            Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Installing SxS Stack on VM $SxSStackInstaller`n"

            $sxsstack_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $SxSStackInstaller", "/quiet", "/qn", "/norestart", "/passive", "/l* $LogDirectory\\SxSInstall-$StartTime-.txt" -Wait -Passthru
            $sts = $sxsstack_deploy_status.ExitCode
            Write-EventToLog $LogFile "Info" "Invoke-DeployAgent" "Installing RD SxS Stack on VM Complete. Exit code=$sts`n"
        }

        $sxsstack_deploy_status = $sxsstack_deploy_status.ExitCode
    }
    catch
    {
        $StackTrace = $_.ScriptStackTrace
        Write-EventToLog $LogFile "Error" "Invoke-DeployAgent" "An error occurred. Error: $_. Stack trace: $StackTrace"
    }
}

function Set-FsLogixRegistryValues
{
    <#
        .SYNOPSIS
        Sets FsLogix registry settings, which enables roaming profiles.

        .DESCRIPTION
        FsLogix comes installed on the Windows VMs; however, the registry
        values to enable roaming profiles are not set. This cmdlet sets them.

        .PARAMETER LogFile
        This function logs its operations to this file.

        .INPUTS
        None. You cannot pipe objects to Add-Extension.

        .OUTPUTS
        None.
    #>

    Param(
        [Parameter(Mandatory = $true)]
        [string] $LogFile
    )

    try
    {
        Set-Location HKLM:\SOFTWARE\

        New-Item `
            -Path HKLM:\SOFTWARE\FSLogix `
            -Name Profiles `
            -Value "" `
            -Force

        New-Item `
            -Path HKLM:\Software\FSLogix\Profiles\ `
            -Name Apps `
            -Force

        Set-ItemProperty `
            -Path HKLM:\Software\FSLogix\Profiles `
            -Name "Enabled" `
            -Type "Dword" `
            -Value "1"

        New-ItemProperty `
            -Path HKLM:\Software\FSLogix\Profiles `
            -Name "CCDLocations" `
            -Value "type=smb,connectionString=$ProfilePath" `
            -PropertyType MultiString `
            -Force

        Set-ItemProperty `
            -Path HKLM:\Software\FSLogix\Profiles `
            -Name "SizeInMBs" `
            -Type "Dword" `
            -Value "30000"

        Set-ItemProperty `
            -Path HKLM:\Software\FSLogix\Profiles `
            -Name "IsDynamic" `
            -Type "Dword" `
            -Value "1"

        Set-ItemProperty `
            -Path HKLM:\Software\FSLogix\Profiles `
            -Name "VolumeType" `
            -Type String `
            -Value "vhdx"

        Set-ItemProperty `
            -Path HKLM:\Software\FSLogix\Profiles `
            -Name "FlipFlopProfileDirectoryName" `
            -Type "Dword" `
            -Value "1"

        Set-ItemProperty `
            -Path HKLM:\Software\FSLogix\Profiles `
            -Name "SIDDirNamePattern" `
            -Type String `
            -Value "%username%%sid%"

        Set-ItemProperty `
            -Path HKLM:\Software\FSLogix\Profiles `
            -Name "SIDDirNameMatch" `
            -Type String `
            -Value "%username%%sid%"

        Set-ItemProperty `
            -Path HKLM:\Software\FSLogix\Profiles `
            -Name DeleteLocalProfileWhenVHDShouldApply `
            -Type DWord `
            -Value 1

        Pop-Location
    }
    catch
    {
        $StackTrace = $_.ScriptStackTrace
        Write-EventToLog $LogFile "Error" "Set-FsLogixRegistryValues" "An error occurred. Error: $_. Stack trace: $StackTrace"
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

###############################################################################
# Perform Registration
###############################################################################

try
{
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $StartTime = Get-Date -Format yyyyMMddTHHmmss
    $TempFolder = "C:\\temp"
    $LogFile = "$TempFolder\\host_registration-external-$StartTime" + ".log"
    $DeployAgentDownloadPath = "$TempFolder\\DeployAgent.zip"
    $DeployAgentDirectory = "$TempFolder\\DeployAgent"

    Initialize-TempFolder $TempFolder

    Invoke-RegistryProvisioning -LogFile $LogFile -ReRegisterHost $ReRegisterHost.ToBool()

    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ForceBootstrap
    Install-Module -Name Az.Accounts -Scope AllUsers -Force
    Install-Module -Name Az.KeyVault -Scope AllUsers -Force
    Install-Module -Name Az.Storage -Scope AllUsers -Force
    Install-Module -Name PSDesiredStateConfiguration -AllowPrerelease -Scope AllUsers -Force

    Get-ArchiveAndUnzip -LogFile $LogFile `
        -DownloadUrl $DeployAgentDownloadUrl `
        -DownloadPath $DeployAgentDownloadPath `
        -ExpandedArchiveDirectory $DeployAgentDirectory

    $GetRegistrationTokenReturn = Get-RegistrationToken -LogFile $LogFile `
        -TenantId $TenantId `
        -SubscriptionId $SubscriptionId `
        -ResourceGroupName $ResourceGroupName `
        -HostPoolName $HostPoolName

    $RegistrationToken = $GetRegistrationTokenReturn[$GetRegistrationTokenReturn.Length - 1]

    Invoke-DeployAgent -LogFile $LogFile `
        -LogDirectory $TempFolder `
        -AgentBootServiceInstallerFolder "$DeployAgentDirectory\\RDAgentBootLoaderInstall" `
        -AgentInstallerFolder "$DeployAgentDirectory\\RDInfraAgentInstall" `
        -SxSStackInstallerFolder "$DeployAgentDirectory\\RDInfraSxSStackInstall" `
        -EnableSxSStackScriptFolder "$DeployAgentDirectory\\EnableSxSStackScript" `
        -RegistrationToken $RegistrationToken `
        -StartAgent $true `
        -rdshIs1809OrLater $true

    Set-FsLogixRegistryValues -LogFile $LogFile
}
catch
{
    $StackTrace = $_.ScriptStackTrace
    Write-EventToLog $LogFile "Error" "Main" "An error occurred. Error: $_. Stack trace: $StackTrace"
}
