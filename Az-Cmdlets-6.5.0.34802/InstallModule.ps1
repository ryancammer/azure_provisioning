<#
.SYNOPSIS
    .
.DESCRIPTION
    .
.PARAMETER ModuleName
    Name of the module to install. By default all modules are installed.
.PARAMETER SourceLocation
    Specifies the path for discovering and installing modules from.
    Taking current folder as source location by default
.EXAMPLE
    C:\PS> ./InstallModule.ps1 -ModuleName Az.Accounts
.NOTES
    Author: Ryan Cammer
    Date:   2020/10/20
#>

    [cmdletbinding()]
param(
    [string]
    [Parameter(Mandatory = $false, Position = 0, HelpMessage = "Name of the module to install. By default all modules are installed.")]
    $ModuleName = "Az",

    [string]
    [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Specifies the path for discovering and installing modules from.")]
    $SourceLocation = $PSScriptRoot
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

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$StartTime = Get-Date -Format yyyyMMddTHHmmss
$TempFolder = "C:\\temp"
$LogFile = "$TempFolder\\InstallModule-$StartTime" + ".log"
Initialize-TempFolder $TempFolder

$gallery = [guid]::NewGuid().ToString()
Write-EventToLog $LogFile "Info" "Main" "Registering temporary repository $gallery with InstallationPolicy Trusted..."
Register-PSRepository -Name $gallery -SourceLocation $SourceLocation -PackageManagementProvider NuGet -InstallationPolicy Trusted

try
{
    Write-EventToLog $LogFile "Info" "Main"  "Installing $ModuleName..."
    Install-Module -Name $ModuleName -Repository $gallery -AllowClobber -Force -Scope AllUsers
    Write-EventToLog $LogFile "Info" "Main"  "$ModuleName installed."
}
catch
{
    $StackTrace = $_.ScriptStackTrace
    Write-EventToLog $LogFile "Error" "Main" "An error occurred. Error: $_. Stack trace: $StackTrace"
}
finally
{
    Write-EventToLog $LogFile "Info" "Main" "Unregistering gallery $gallery..."
    Unregister-PSRepository -Name $gallery
}
