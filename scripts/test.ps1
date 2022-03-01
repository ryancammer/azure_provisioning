Configuration TestConfiguration
{
    Import-DscResource -ModuleName 'PSDesiredStateConfiguration'

    Node 'localhost'
    {
        File CreateConfigDirectory
        {
            DestinationPath = "c:\vdiconfig"
            Ensure          = "Present"
            Type            = "Directory"
        }
    }
}

function Write-EventToLog
{
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

$LogFile = "c:\temp\test_log.log"

try
{
    $outputPath = $env:TEMP
    TestConfiguration -OutputPath $outputPath | Out-Null
    Start-DscConfiguration -Wait -Verbose -Path $outputPath -ErrorAction Stop

    Write-EventToLog $LogFile "Info" "TestConfiguration" "Success"
} catch {
    Write-EventToLog $LogFile "Error" "TestConfiguration" "An error occurred. Error: $_. Stack trace: $StackTrace"
}
