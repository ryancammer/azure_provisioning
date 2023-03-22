class ArchiveExpander
{
    [EventLogger] $Logger

    ArchiveExpander()
    {
        $this.Logger = $null
    }

    ArchiveExpander([EventLogger] $logger)
    {
        $this.Logger = $logger
    }

    [void]
    CreateArchiveDirectory(
        [string] $directoryToExpandArchiveInto,
        [bool] $deleteExistingDirectory
    )
    {
        if (Test-Path $directoryToExpandArchiveInto)
        {
            if ($deleteExistingDirectory)
            {
                Remove-Item -Path $directoryToExpandArchiveInto -Force -Confirm:$false -Recurse
                New-Item -Path $directoryToExpandArchiveInto -ItemType directory -Force

                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.CreateArchiveDirectory.Name,
                        "DeleteExistingDirectory was selected. Directory at $( $directoryToExpandArchiveInto ) was deleted and created again."
                    )
                }
            }
            else
            {
                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.CreateArchiveDirectory.Name,
                        "The directory $( $directoryToExpandArchiveInto ) exists, but deletion was not selected."
                    )
                }
            }
        }
        else
        {
            New-Item -Path $directoryToExpandArchiveInto -ItemType directory -Force

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.CreateArchiveDirectory.Name,
                    "The directory $( $directoryToExpandArchiveInto ) did not exist and was created."
                )
            }
        }
    }

    [void]
    ExpandArchive(
        [bool] $deleteExistingDirectory,
        [string] $directoryToExpandArchiveInto,
        [string] $pathOfArchiveToExpand
    )
    {
        $this.CreateArchiveDirectory(
            $directoryToExpandArchiveInto,
            $deleteExistingDirectory
        )

        Expand-Archive $pathOfArchiveToExpand -DestinationPath $directoryToExpandArchiveInto

        if ($null -ne $this.Logger)
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.ExpandArchive.Name,
                "$( $pathOfArchiveToExpand ) expanded into $( $directoryToExpandArchiveInto )."
            )
        }
    }
}

class ArgumentParser
{
    [Object[]] $Arguments

    [Hashtable] $ParsedArguments

    [EventLogger] $Logger

    ArgumentParser([Object[]] $arguments)
    {
        $this.Arguments = $arguments
        $this.parsedArguments = $this.Parse($arguments)
        $this.Logger = $null
    }

    ArgumentParser([Object[]] $arguments, [EventLogger] $logger)
    {
        $this.Arguments = $arguments
        $this.parsedArguments = $this.Parse($arguments)
        $this.Logger = $logger
    }

    [Hashtable]
    Parse([Object[]] $arguments)
    {
        $processedArgs = @{ }

        $currentKey = ''

        foreach ($arg in $arguments)
        {
            if ($arg.GetType().Name -eq 'String' -and $arg.StartsWith('-'))
            {
                $currentKey = $arg.Substring(1, $arg.Length - 1)
                $processedArgs[$currentKey] = @()
            }
            else
            {
                $processedArgs[$currentKey] += $arg

                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.Parse.Name,
                        "Adding $($arg) to $($currentKey)"
                    )
                }
            }

        }

        return $processedArgs
    }

    [String]
    ToString()
    {
        return "$( $this.Arguments )"
    }
}

class AzureStorageBlobDownloader
{
    [EventLogger] $Logger

    AzureStorageBlobDownloader(
        [EventLogger] $logger
    )
    {
        $this.Logger = $logger
    }

    [void]
    DownloadBlob(
        [string] $blobUri,
        [string] $pathToWhereToStoreDownload
    )
    {
        if ($null -ne $this.Logger)
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.DownloadBlob.Name,
                "Downloading $( $blobUri ) to $( $pathToWhereToStoreDownload )..."
            )
        }

        $result = Get-AzStorageBlobContent -Uri $blobUri -Destination $pathToWhereToStoreDownload  -Force

        if ($null -ne $this.Logger)
        {
            $uri = [uri]($blobUri)
            $fileName = $uri.Segments[-1]

            $downloaded = Get-ChildItem "$($pathToWhereToStoreDownload)\$fileName"

            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.DownloadBlob.Name,
                "Downloaded $( $blobUri ) to $( $pathToWhereToStoreDownload ). Success? $($downloaded). Result: $($result)."
            )
        }
    }
}

class AzureVdiProvisioning
{
    static [string] $DscConfigurationOptionsKey = 'DscConfigurations'

    static [string] $DefaultDeployAgentDirectoryName = 'DeployAgent'

    static [string] $DefaultPowershellVersion = '7.2.2'

    [string] $DeployAgentDirectory

    [string] $FslogixProfilePath

    [EventLogger] $Logger

    [ArgumentParser] $ArgumentParser

    [Hashtable] Options()
    {
        return $this.ArgumentParser.ParsedArguments
    }

    AzureVdiProvisioning(
        [Object[]] $arguments
    )
    {
        $this.FslogixProfilePath = ''

        $this.Logger = [EventLogger]::new(
            "$($this.TempDirectory() )\\azure-vdi-provisioning-$( Get-Date -Format yyyyMMddTHHmmss ).log"
        )

        $this.ArgumentParser = [ArgumentParser]::new($arguments, $this.Logger)

        $this.Logger.WriteInfo(
            $this.GetType().Name,
            "Initializer",
            "AzureVdiProvisioning initialized with options: $( $this.ArgumentParser.ToString() )..."
        )

        $this.DeployAgentDirectory = "$($this.TempDirectory() )\$( [AzureVdiProvisioning]::DefaultDeployAgentDirectoryName )"
    }

    AzureVdiProvisioning(
        [EventLogger] $logger,
        [Object[]] $arguments
    )
    {
        $this.FslogixProfilePath = ''

        $this.Logger = $logger

        $this.ArgumentParser = [ArgumentParser]::new($arguments, $this.Logger)

        $this.Logger.WriteInfo(
            $this.GetType().Name,
            "Initializer",
            "AzureVdiProvisioning initialied with options: $( $this.ArgumentParser.ToString() )..."
        )

        $this.LogKeysAndValues()

        $this.DeployAgentDirectory = "$($this.TempDirectory() )\$( [AzureVdiProvisioning]::DefaultDeployAgentDirectoryName )"
    }

    [void]
    LogKeysAndValues()
    {
        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.LogKeysAndValues.Name,
            "KEYS"
        )

        foreach ($key in $this.Options().Keys)
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.LogKeysAndValues.Name,
                "The key $($key) has the following value: $($this.Options()[$key])"
            )
        }
    }

    [void]
    CopyEverythingIntoTempDirectory()
    {
        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.CopyEverythingIntoTempDirectory.Name,
            "Copying everything into the temp directory..."
        )

        Copy-Item "*.*" -Destination $this.TempDirectory()

        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.CopyEverythingIntoTempDirectory.Name,
            "Temp directory copy done..."
        )
    }

    [void]
    DownloadStorageItems()
    {
        Connect-AzAccount -Identity

        $downloader = [AzureStorageBlobDownloader]::new($this.Logger)

        $urlsToDownload = $this.Options()['AzureStorageDownloadUrls']

        if ($null -eq $urlsToDownload -or $urlsToDownload.ToString() -eq '$null')
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.DownloadStorageItems.Name,
                "urlsToDownload is null. Returning."
            )

            return
        }

        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.DownloadStorageItems.Name,
            "urlsToDownload. Type: $($urlsToDownload.GetType().Name), Items to download: $( $urlsToDownload ). "
        )

        foreach ($dirtyAzureStorageDownloadUrl in $urlsToDownload)
        {
            $azureStorageDownloadUrl = [UrlCleaner]::new($dirtyAzureStorageDownloadUrl).Clean()

            if ($azureStorageDownloadUrl -eq '$null')
            {
                continue
            }

            $azureStorageDownloadUrlAsUri = [uri]($azureStorageDownloadUrl)

            if ($null -eq $azureStorageDownloadUrlAsUri.Authority)
            {
                continue
            }

            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.DownloadStorageItems.Name,
                "Downloading $( $azureStorageDownloadUrl )..."
            )

            $downloader.DownloadBlob(
                $azureStorageDownloadUrl,
                $this.TempDirectory()
            )

            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.DownloadStorageItems.Name,
                "$( $azureStorageDownloadUrl ) downloaded."
            )
        }

        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.DownloadStorageItems.Name,
            "Downloading completed."
        )
    }

    [void]
    InstallDuo()
    {
        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.InstallDuo.Name,
            "Commencing $($this.InstallDuo.Name)..."
        )

        $keyVaultName = $this.Options()['KeyVaultName']

        $duoIntegrationKey = Get-AzKeyVaultSecret -VaultName "$($keyVaultName)" -Name "$($this.Options()['DuoIntegrationKeyName'])" -AsPlainText
        $duoSecretKey = Get-AzKeyVaultSecret -VaultName "$($keyVaultName)" -Name "$($this.Options()['DuoSecretKeyName'])" -AsPlainText
        $duoApiHostname = Get-AzKeyVaultSecret -VaultName "$($keyVaultName)" -Name "$($this.Options()['DuoApiHostnameKey'])" -AsPlainText


        $startTime = Get-Date -Format yyyyMMddTHHmmss

        $poundOne = "#1"

        $deploy_status = Start-Process -FilePath "msiexec.exe" `
            -ArgumentList "/i $($this.TempDirectory())\DuoWindowsLogon64.msi", "/qn", "IKEY=$($duoIntegrationKey)", "SKEY=$($duoSecretKey)", "HOST=$($duoApiHostname)", "AUTOPUSH=$($poundOne)", "FAILOPEN=$($poundOne)", "RDPONLY=$($poundOne)", "/l* $($this.TempDirectory())\\$($this.InstallDuo.Name)-$($startTime).txt" `
            -Wait `
            -Passthru

        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.InstallDuo.Name,
            "$($this.InstallDuo.Name) installation complete. The exit code is $($deploy_status.ExitCode)."
        )
    }

    [void]
    InstallRequiredModules()
    {
        $moduleInstaller = [ModuleInstaller]::new($this.Logger)

        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.InstallRequiredModules.Name,
            "Installing required modules..."
        )

        $moduleInstaller.InstallModules()

        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.InstallRequiredModules.Name,
            "Required modules installed."
        )
    }

    [string]
    MinimumPowershellVersion()
    {
        if ( $this.Options().ContainsKey('MinimumPowershellVersion'))
        {
            $minimumPowershellVersion = $this.Options()['MinimumPowershellVersion']

            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.MinimumPowershellVersion.Name,
                "Minimum version of Powershell passed in: $minimumPowershellVersion"
            )

            return $minimumPowershellVersion
        }
        else
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.MinimumPowershellVersion.Name,
                "No minimum Powershell version required. Using default of $( [AzureVdiProvisioning]::DefaultPowershellVersion )"
            )

            return [AzureVdiProvisioning]::DefaultPowershellVersion
        }
    }

    [void]
    Provision()
    {
        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.Provision.Name,
            "Powershell Version: $($( Get-Host ).Version.ToString() ). Provisioning initiated..."
        )

        $this.CopyEverythingIntoTempDirectory()

        if ( $this.UpdatePowershell())
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.Provision.Name,
                "Powershell updated. Calling RestartProvisioning..."
            )

            $this.RestartProvisioning()
        }

        $this.InstallRequiredModules()

        $this.DownloadStorageItems()

        $this.UnzipDeployAgent()

        $this.RegisterHost()

        Connect-AzAccount -Identity

        $this.InstallDuo()
    }

    [void]
    RegisterHost()
    {
        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.RegisterHost.Name,
            "Initiating host registration..."
        )

        $hostRegistration = [HostRegistration]::new(
            $this.DeployAgentDirectory,
            $this.FslogixProfilePath,
            $this.Options()['hostPoolName'],
            $this.TempDirectory(),
            $this.Logger,
            $this.Options()['resourceGroupName'],
            $this.Options()['subscriptionId'],
            $this.Options()['tenantId']
        )

        $hostRegistration.RegisterHost()

        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.RegisterHost.Name,
            "Host registered."
        )
    }

    [void]
    RestartProvisioning()
    {
        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.RestartProvisioning.Name,
            "Restarting the script..."
        )

        [ScriptLauncher]::new($this.Logger).LaunchScript(
            "$($this.TempDirectory())\azure_vdi_provisioning.ps1",
            $this.ArgumentParser.ToString()
        )

        exit
    }

    [string]
    TempDirectory()
    {
        return [Constants]::TempDirectory()
    }

    [bool]
    UpdatePowershell()
    {
        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.UpdatePowershell.Name,
            "UpdatePowershell initiated..."
        )

        $updated = [PowershellUpdater]::new(
            $this.MinimumPowershellVersion(),
            $( Get-Host ).Version.ToString(),
            $this.TempDirectory(),
            $this.Logger
        ).Update()

        $this.Logger.WriteInfo(
            $this.GetType().Name,
            $this.UpdatePowershell.Name,
            "PowershellUpdater indicated that Powershell was updated: $( $updated )."
        )

        return $updated
    }

    [void]
    UnzipDeployAgent()
    {
        $archiveExpander = [ArchiveExpander]::new($this.Logger)

        $archiveExpander.ExpandArchive(
            $true,
            $this.DeployAgentDirectory,
            "$($this.DeployAgentDirectory).zip"
        )
    }
}

class Constants
{
    static [string] $CTemp = "c:\temp"

    static [string] $CWindowsTemp = "c:\windows\temp"

    static
    [string]
    TempDirectory()
    {
        if ($null -ne (Get-ChildItem [Constants]::CTemp))
        {
            return [Constants]::CTemp
        }

        if ($null -ne (Get-ChildItem [Constants]::CWindowsTemp))
        {
            return [Constants]::CWindowsTemp
        }

        if ($null -ne $env:TEMP)
        {
            return $env:TEMP
        }

        if ($null -ne $env:TMPDIR)
        {
            return $env:TMPDIR
        }

        return '/tmp'
    }
}

class DirectoryCreator
{
    [EventLogger] $Logger

    DirectoryCreator()
    {
        $this.Logger = $null
    }

    DirectoryCreator([EventLogger] $logger)
    {
        $this.Logger = $logger
    }

    [void]
    CreateDirectory([string] $path)
    {
        if (-Not(Test-Path -Path $path))
        {
            New-Item -Path $path -ItemType directory

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.Initialize.Name,
                    "Directory $( $path ) created."
                )
            }
        }
        else
        {
            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.Initialize.Name,
                    "Directory $( $path ) already exists."
                )
            }
        }
    }
}

class DscConfigurationInstaller
{
    [string] $ConfigurationName

    [EventLogger] $Logger

    [string] $PathToDscConfigurationToInstall

    DscConfigurationInstaller(
        [string] $pathToDscConfigurationToInstall
    )
    {
        $this.Logger = $null
        $this.PathToDscConfigurationToInstall = $pathToDscConfigurationToInstall

        $this.ConfigurationName = Select-String -Path $this.PathToDscConfigurationToInstall "(Configuration) (.*)" `
                -AllMatches | Foreach-Object { $_.Matches } | Foreach-Object { $_.Groups[2].Value }
    }

    DscConfigurationInstaller(
        [string] $pathToDscConfigurationToInstall,
        [EventLogger] $logger
    )
    {
        $this.Logger = $logger
        $this.PathToDscConfigurationToInstall = $pathToDscConfigurationToInstall

        $this.Logger.WriteInfo(
            $this.GetType().Name,
            'new',
            "DscConfigurationInstaller initialized with pathToDscConfigurationToInstall $($pathToDscConfigurationToInstall)."
        )

        $this.ConfigurationName = Select-String -Path $this.PathToDscConfigurationToInstall "(Configuration) (.*)" `
                -AllMatches | Foreach-Object { $_.Matches } | Foreach-Object { $_.Groups[2].Value }
    }

    [void]
    InstallDscConfiguration($arguments)
    {
        try
        {
            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.InstallDscConfiguration.Name,
                    "Dot sourcing $( $this.PathToDscConfigurationToInstall )..."
                )
            }

            . $this.PathToDscConfigurationToInstall

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.InstallDscConfiguration.Name,
                    "$( $this.PathToDscConfigurationToInstall ) dot sourced. Creating the DSC configuration $( $this.ConfigurationName )..."
                )
            }

            $expressionCommand = "$( $this.ConfigurationName ) $( $arguments ) -OutputPath ."

            try
            {
                Invoke-Expression $expressionCommand
            }
            catch
            {
                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteError(
                        $this.GetType().Name,
                        $this.InstallDscConfiguration.Name,
                        "Invoke-Expression didn't work. expressionCommand: $( $expressionCommand )",
                        $_
                    )
                }
            }

            try
            {
                Invoke-Command -ScriptBlock { $expressionCommand } -ComputerName localhost
            }
            catch
            {
                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteError(
                        $this.GetType().Name,
                        $this.InstallDscConfiguration.Name,
                        "Invoke-Command didn't work. expressionCommand: $( $expressionCommand )",
                        $_
                    )
                }
            }

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.InstallDscConfiguration.Name,
                    "DSC configuration $( $this.ConfigurationName ) invoked using Invoke-Command. Starting configuration..."
                )
            }

            Start-DscConfiguration -Wait -Verbose -Path "$( $this.ConfigurationName )" -ErrorAction Stop

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.InstallDscConfiguration.Name,
                    "$( $this.PathToDscConfigurationToInstall ) installed $( $this.ConfigurationName )."
                )
            }
        }
        catch
        {
            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteError(
                    $this.GetType().Name,
                    $this.InstallDscConfiguration.Name,
                    "$( $this.PathToDscConfigurationToInstall ) failed.",
                    $_
                )
            }
        }
    }
}

class EventLogger
{
    [string] $LogFile

    EventLogger([string] $logFile)
    {
        $this.LogFile = $logFile
    }

    [void]
    WriteEventToLog(
        [LogLevel] $level,
        [string] $function,
        [string] $event
    )
    {
        $time = Get-Date -Format "yyyy-MM-dd-THH-mm-ss"

        $Stream = New-Object System.IO.StreamWriter($this.LogFile, $true)
        $Stream.WriteLine("$time : $level : $function : $event")
        $Stream.Flush()
        $Stream.Close()
    }

    [void]
    WriteInfo(
        [string] $class,
        [string] $method,
        [string] $event
    )
    {
        $this.WriteEventToLog([LogLevel]::Info, "$( $class )#$( $method )", $event)
    }

    [void]
    WriteError(
        [string] $class,
        [string] $method,
        [string] $event,
        $error
    )
    {
        $StackTrace = $error.ScriptStackTrace

        $this.WriteEventToLog(
            [LogLevel]::Error,
            "$( $class )#$( $method )",
            "$( $event ) $( $error ) $( $stackTrace )"
        )
    }
}

class FileDownloader
{
    [EventLogger] $Logger
    FileDownloader()
    {
        $this.Logger = $null
    }

    FileDownloader([EventLogger] $logger)
    {
        $this.Logger = $logger
    }

    [void]
    DownloadFile([string] $PathToWhereToStoreDownload, [string] $urlToDownloadFrom)
    {
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($urlToDownloadFrom, $pathToWhereToStoreDownload)

        if ($null -ne $this.Logger)
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.Download.Name,
                "Downloaded $( $urlToDownloadFrom ) to $( $pathToWhereToStoreDownload )."
            )
        }
    }
}

class HostRegistration
{
    static [int] $ExpirationInMinutes = 120

    [string] $DeployAgentDirectory
    [string] $FslogixProfilePath
    [string] $HostPoolName
    [string] $LogDirectory
    [EventLogger] $Logger
    [string] $ResourceGroupName
    [string] $SubscriptionId
    [string] $TenantId

    HostRegistration(
        [string] $deployAgentDirectory,
        [string] $fslogixProfilePath,
        [string] $hostPoolName,
        [string] $logDirectory,
        [EventLogger] $logger,
        [string] $resourceGroupName,
        [string] $subscriptionId,
        [string] $tenantId
    )
    {

        $this.DeployAgentDirectory = $deployAgentDirectory
        $this.FslogixProfilePath = $fslogixProfilePath
        $this.HostPoolName = $hostPoolName
        $this.LogDirectory = $logDirectory
        $this.Logger = $logger
        $this.ResourceGroupName = $resourceGroupName
        $this.SubscriptionId = $subscriptionId
        $this.TenantId = $tenantId
    }

    [string]
    GetRegistrationToken()
    {
        if ($null -ne $this.Logger)
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.GetRegistrationToken.Name,
                "Creating new registration info. SubscriptionId $($this.SubscriptionId) ResourceGroupName $($this.ResourceGroupName) HostPoolName $($this.HostPoolName)"
            )
        }

        Connect-AzAccount -Identity

        $registrationInfo = New-AzWvdRegistrationInfo -SubscriptionId $this.SubscriptionId `
            -ResourceGroupName $this.ResourceGroupName `
            -HostPoolName $this.HostPoolName `
            -ExpirationTime $((get-date).ToUniversalTime().AddMinutes([HostRegistration]::ExpirationInMinutes).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ') )

        if ($null -ne $this.Logger)
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.GetRegistrationToken.Name,
                "Registration Token created. Token type: $($registrationInfo.Token.GetType().Name), Token value: $( $registrationInfo.Token )"
            )
        }

        return $registrationInfo.Token
    }

    [void]
    ProvisionRegistry(
        [bool] $reRegisterHost
    )
    {
        if ($null -ne $this.Logger)
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.InvokeRegistryProvisioning.Name,
                "Provisioning registry. Re-registerHost: $reRegisterHost"
            )
        }

        $RDInfraAgentRegistryFullPath = 'HKLM:\SOFTWARE\Microsoft\RDInfraAgent'

        $RDInfraAgentRegistryValue = Get-ItemProperty -Path $RDInfraAgentRegistryFullPath -ErrorAction SilentlyContinue

        if ($RDInfraAgentRegistryValue)
        {
            if ($ReRegisterHost -eq $true)
            {
                $preDeleteLogMessage = "RDInfraAgent Registry value $RDInfraAgentRegistryFullPath was found. " +
                    "Deleting registry value so that agent can re-register:"

                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.InvokeRegistryProvisioning.Name,
                        $preDeleteLogMessage
                    )
                }

                Remove-ItemProperty -Path $RDInfraAgentRegistryFullPath -Name "*"

                $postDeleteLogMessage = "RDInfraAgent Registry value $RDInfraAgentRegistryFullPath was deleted."

                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.InvokeRegistryProvisioning.Name,
                        $postDeleteLogMessage
                    )
                }
            }
            else
            {
                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.InvokeRegistryProvisioning.Name,
                        "RDInfraAgent Registry value was found."
                    )
                }
            }
        }
        else
        {
            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.InvokeRegistryProvisioning.Name,
                    "RDInfraAgent Registry value $RDInfraAgentRegistryFullPath was not found."
                )
            }
        }
    }

    [void]
    DeployAgent(
        [string] $agentInstallerFolder,
        [string] $agentBootServiceInstallerFolder,
        [string] $sxSStackInstallerFolder,
        [string] $enableSxSStackScriptFolder,
        [string] $registrationToken,
        [bool] $startAgent,
        [bool] $rdshIs1809OrLater
    )
    {
        try
        {
            $startTime = Get-Date -Format yyyyMMddTHHmmss

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "The boot loader folder is $($agentBootServiceInstallerFolder)."
                )
            }

            $agentBootServiceInstaller = (Get-ChildItem $agentBootServiceInstallerFolder\ -Filter *.msi | Select-Object).FullName

            if ((-not $agentBootServiceInstaller) -or (-not(Test-Path $agentBootServiceInstaller)))
            {
                throw "The RD Infra Agent Installer package '$agentBootServiceInstaller' was not found."
            }

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "The agent folder is $($agentInstallerFolder)."
                )
            }

            $agentInstaller = (Get-ChildItem $agentInstallerFolder\ -Filter *.msi | Select-Object).FullName

            if ((-not $agentInstaller) -or (-not(Test-Path $agentInstaller)))
            {
                throw "The RD Infra Agent Installer package '$agentInstaller' was not found."
            }

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "The SxS Stack Installer folder is $($sxSStackInstallerFolder)."
                )
            }

            $sxSStackInstaller = (Get-ChildItem $sxSStackInstallerFolder\ -Filter *.msi | Select-Object).FullName

            if ((-not $sxSStackInstaller) -or (-not(Test-Path $sxSStackInstaller)))
            {
                throw "The SxS Stack Installer package '$sxSStackInstaller' was not found."
            }

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "The enableSxSStackScript folder is $($enableSxSStackScriptFolder)."
                )
            }

            $enableSxSStackScript = (Get-ChildItem $enableSxSStackScriptFolder\ -Filter *.ps1 | Select-Object).FullName

            if ((-not $enableSxSStackScript) -or (-not(Test-Path $enableSxSStackScript)))
            {
                throw "The EnableSxSStack script '$enableSxSStackScript' was not found."
            }

            if (!$registrationToken)
            {
                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.DeployAgent.Name,
                        "The registration token is missing."
                    )
                }

                throw "The registration token is missing."
            }

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "Uninstalling any previous versions of RDAgentBootLoader..."
                )
            }

            $bootloader_uninstall_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x {A38EE409-424D-4A0D-B5B6-5D66F20F62A5}", "/quiet", "/qn", "/norestart", "/passive", "/l* $( $this.LogDirectory )\\AgentBootLoaderInstall-$($startTime).txt" -Wait -Passthru

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "Uninstalled RD Infra Agent. The exit code is $($bootloader_uninstall_status.ExitCode)."
                )
            }

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "Uninstalling any previous versions of RD Infra Agent..."
                )
            }

            $legacy_agent_uninstall_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x {5389488F-551D-4965-9383-E91F27A9F217}", "/quiet", "/qn", "/norestart", "/passive", "/l* $( $this.LogDirectory )\\AgentUninstall-$($startTime).txt" -Wait -Passthru

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "Uninstalled RD Infra Agent. The exit code is $($legacy_agent_uninstall_status.ExitCode)."
                )
            }

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "Uninstalling any previous versions of the RD Infra Agent DLL..."
                )
            }

            $agent_uninstall_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/x {CB1B8450-4A67-4628-93D3-907DE29BF78C}", "/quiet", "/qn", "/norestart", "/passive", "/l* $( $this.LogDirectory )\\AgentUninstall-$($startTime).txt" -Wait -Passthru

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "Uninstalled RD Infra Agent. The exit code is $($agent_uninstall_status.ExitCode)."
                )
            }

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "Installing RDAgent BootLoader $($AgentBootServiceInstaller)..."
                )
            }

            $bootloader_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentBootServiceInstaller", "/quiet", "/qn", "/norestart", "/passive", "/l* $( $this.LogDirectory )\\AgentBootLoaderInstall-$($startTime).txt" -Wait -Passthru

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "Installed RDAgentBootLoader. The exit code is $($bootloader_deploy_status.ExitCode)."
                )
            }

            $agent_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $AgentInstaller", "/quiet", "/qn", "/norestart", "/passive", "REGISTRATIONTOKEN=$($registrationToken)", "/l* $( $this.LogDirectory )\\AgentInstall-$($startTime).txt" -Wait -Passthru

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "Installed RD Infra Agent. The exit code is $($agent_deploy_status.ExitCode)."
                )
            }

            Set-ItemProperty -Name RegistrationToken -Path HKLM:\SOFTWARE\Microsoft\RDInfraAgent\ -Value $registrationToken -Force

            if ([System.Convert]::ToBoolean($startAgent))
            {
                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.DeployAgent.Name,
                        "Starting the RDInfraAgent service..."
                    )
                }

                Start-Service RDAgentBootLoader
            }

            if ($rdshIs1809OrLater)
            {
                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.DeployAgent.Name,
                        "Enabling Built-in RD SxS Stack $($enableSxSStackScript)..."
                    )
                }

                $enablesxs_deploy_status = PowerShell.exe -ExecutionPolicy Unrestricted -File $enableSxSStackScript

                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.DeployAgent.Name,
                        "Enabled Built-in RD SxS Stack. The exit code is $($enablesxs_deploy_status.ExitCode)."
                    )
                }
            }
            else
            {
                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.DeployAgent.Name,
                        "Installing SxS Stack using $($sxSStackInstaller)..."
                    )
                }

                $sxsstack_deploy_status = Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $SxSStackInstaller", "/quiet", "/qn", "/norestart", "/passive", "/l* $( $this.LogDirectory )\\SxSInstall-$StartTime-.txt" -Wait -Passthru

                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.DeployAgent.Name,
                        "RD SxS Stack installation is complete. The exit code is $($sxsstack_deploy_status.ExitCode)."
                    )
                }
            }
        }
        catch
        {
            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteError(
                    $this.GetType().Name,
                    $this.DeployAgent.Name,
                    "$( $this.PathToDscConfigurationToInstall ) failed.",
                    $_
                )
            }
        }
    }

    [void]
    SetFsLogixRegistryValues()
    {
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
                    -Value "type=smb,connectionString=$( $this.FslogixProfilePath )" `
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

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteError(
                    $this.GetType().Name,
                    $this.SetFsLogixRegistryValues.Name,
                    "Failed writing registry values.",
                    $_
                )
            }
        }
    }

    [void]
    RegisterHost()
    {
        try
        {
            $this.ProvisionRegistry($true)

            $this.DeployAgent(
                "$( $this.DeployAgentDirectory )/RDAgentBootLoaderInstall",
                "$( $this.DeployAgentDirectory )/RDInfraAgentInstall",
                "$( $this.DeployAgentDirectory )/RDInfraSxSStackInstall",
                "$( $this.DeployAgentDirectory )/EnableSxSStackScript",
                $this.GetRegistrationToken(),
                $true,
                $false
            )

            $this.SetFsLogixRegistryValues()
        }
        catch
        {
            $StackTrace = $_.ScriptStackTrace

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.InvokeDeployAgent.Name,
                    "An error occurred. Error: $_. Stack trace: $StackTrace"
                )
            }
        }
    }
}

enum LogLevel
{
    Debug = 1

    Info = 2

    Warning = 3

    Error = 4
}

class ModuleInstaller
{
    [EventLogger] $Logger

    [string[]] $ModulesToInstall

    [bool] $InstallNuget

    static [bool] $DefaultInstallNuget = $true

    static [string[]] $DefaultModulesToInstall = (
        'Az.Accounts',
        'Az.KeyVault',
        'Az.Storage',
        'Az.DesktopVirtualization',
        'PSDesiredStateConfiguration'
    )

    ModuleInstaller()
    {
        $this.InstallNuget = [ModuleInstaller]::DefaultInstallNuget
        $this.Logger = $null
        $this.ModulesToInstall = [ModuleInstaller]::DefaultModulesToInstall
    }

    ModuleInstaller([bool] $installNuget)
    {
        $this.InstallNuget = $installNuget
        $this.Logger = $null
        $this.ModulesToInstall = [ModuleInstaller]::DefaultModulesToInstall
    }

    ModuleInstaller([EventLogger] $logger)
    {
        $this.Logger = $logger
        $this.ModulesToInstall = [ModuleInstaller]::DefaultModulesToInstall
        $this.InstallNuget = [ModuleInstaller]::DefaultInstallNuget
    }

    ModuleInstaller([string[]] $modulesToInstall)
    {
        $this.Logger = $null
        $this.InstallNuget = [ModuleInstaller]::DefaultInstallNuget
        $this.ModulesToInstall = $modulesToInstall
    }

    ModuleInstaller([EventLogger] $logger, [bool] $installNuget)
    {
        $this.Logger = $logger
        $this.ModulesToInstall = [ModuleInstaller]::DefaultModulesToInstall
        $this.InstallNuget = $installNuget
    }

    ModuleInstaller([EventLogger] $logger, [string[]] $modulesToInstall)
    {
        $this.Logger = $logger
        $this.ModulesToInstall = $modulesToInstall
        $this.InstallNuget = [ModuleInstaller]::DefaultInstallNuget
    }

    ModuleInstaller([bool] $installNuget, [string[]] $modulesToInstall)
    {
        $this.InstallNuget = $installNuget
        $this.Logger = $null
        $this.ModulesToInstall = $modulesToInstall
    }

    ModuleInstaller([EventLogger] $logger, [string[]] $modulesToInstall, [EventLogger] $installNuget)
    {
        $this.Logger = $logger
        $this.ModulesToInstall = $modulesToInstall
        $this.InstallNuget = $installNuget
    }

    [void]
    PerformNugetInstallation()
    {
        if (Get-PackageProvider -Name NuGet)
        {
            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.Initialize.Name,
                    "NuGet already installed."
                )
            }
        }
        else
        {
            Install-PackageProvider -Name NuGet -Force -ForceBootstrap

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.Initialize.Name,
                    "NuGet installed."
                )
            }
        }
    }

    [void]
    InstallModule($moduleName)
    {
        if (Get-InstalledModule $moduleName -ErrorAction silentlycontinue)
        {
            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.Initialize.Name,
                    "Module $( $moduleName ) already installed."
                )
            }
        }
        else
        {
            Install-Module -Name $moduleName -Scope AllUsers -Force

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.Initialize.Name,
                    "Module $( $moduleName ) installed."
                )
            }
        }
    }

    [void]
    InstallModules()
    {
        if ($this.InstallNuget)
        {
            $this.PerformNugetInstallation()
        }

        foreach ($moduleName in $this.ModulesToInstall)
        {
            $this.InstallModule($moduleName)
        }
    }
}

class PowershellUpdater
{
    [string] $MinimumVersion
    [string] $SystemVersion
    [string] $TempDirectory
    [EventLogger] $Logger

    PowershellUpdater(
        [string] $minimumVersion,
        [string] $systemVersion,
        [string] $tempDirectory,
        [EventLogger] $logger
    )
    {
        $this.Logger = $logger
        $this.MinimumVersion = $minimumVersion
        $this.SystemVersion = $systemVersion
        $this.TempDirectory = $tempDirectory
    }

    [bool]
    PowershellRequiresUpdate()
    {
        return [System.Version]$this.SystemVersion -lt [System.Version]$this.MinimumVersion
    }

    [bool]
    InstallPowershell()
    {
        try
        {
            $PowershellInstallExecutable = "PowerShell-$( $this.MinimumVersion )-win-x64.msi"
            $PowershellExecutablePath = "$( $this.TempDirectory )\\$PowershellInstallExecutable"

            if (-Not(Test-Path -Path $PowershellExecutablePath -PathType Leaf))
            {
                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.InstallPowershell.Name,
                        "Powershell $( $this.MinimumVersion ) installer not present. Downloading..."
                    )
                }

                $PowershellDownloadUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$( $this.MinimumVersion )/$PowershellInstallExecutable"
                $PowershellDownloadPath = "$( $this.TempDirectory )/$PowershellInstallExecutable"

                [FileDownloader]::new().DownloadFile($PowershellDownloadPath, $PowershellDownloadUrl)

                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.InstallPowershell.Name,
                        "Powershell $( $this.MinimumVersion ) downloaded."
                    )
                }
            }
            else
            {
                if ($null -ne $this.Logger)
                {
                    $this.Logger.WriteInfo(
                        $this.GetType().Name,
                        $this.InstallPowershell.Name,
                        "Powershell $( $this.MinimumVersion ) already downloaded."
                    )
                }
            }

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.InstallPowershell.Name,
                    "Installing Powershell..."
                )
            }

            $this.InvokePowershellInstallProcess($PowershellExecutablePath)

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.InstallPowershell.Name,
                    "Powershell installed."
                )
            }

            return $true;
        }
        catch
        {
            $StackTrace = $_.ScriptStackTrace

            if ($null -ne $this.Logger)
            {
                $this.Logger.WriteInfo(
                    $this.GetType().Name,
                    $this.InstallPowershell.Name,
                    "An error occurred. Error: $_. Stack trace: $StackTrace"
                )
            }

            return $false;
        }
    }

    [void]
    InvokePowershellInstallProcess(
        [string]$powershellExecutablePath
    )
    {
        $powershellCommand = "Start-Process msiexec.exe -Wait -ArgumentList '/I $powershellExecutablePath /quiet ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1'"

        if ($null -ne $this.Logger)
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.InvokePowershellInstallProcess.Name,
                "The equivalent powershell command is $powershellCommand"
            )
        }

        $msiExecProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $msiExecProcessInfo.FileName = "msiexec.exe"
        $msiExecProcessInfo.RedirectStandardError = $true
        $msiExecProcessInfo.RedirectStandardOutput = $true
        $msiExecProcessInfo.UseShellExecute = $false

        $msiExecProcessInfo.Arguments = "/I $powershellExecutablePath /quiet /log ps_install.log ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1"

        $InstallationProcess = New-Object System.Diagnostics.Process
        $InstallationProcess.StartInfo = $msiExecProcessInfo
        $InstallationProcess.Start() | Out-Null
        $InstallationProcess.WaitForExit()

        $stdout = $InstallationProcess.StandardOutput.ReadToEnd()
        $stderr = $InstallationProcess.StandardError.ReadToEnd()

        if ($null -ne $this.Logger)
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.InvokePowershellInstallProcess.Name,
                "stdout: $stdout"
            )

            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.InvokePowershellInstallProcess.Name,
                "stderr: $stderr"
            )
        }
    }

    [bool]
    Update()
    {
        if ( $this.PowershellRequiresUpdate())
        {
            return $this.InstallPowershell()
        }

        return $false;
    }
}

class ScriptLauncher
{
    [EventLogger] $Logger

    ScriptLauncher()
    {
        $this.Logger = $null
    }

    ScriptLauncher([EventLogger] $logger)
    {
        $this.Logger = $logger
    }

    [void]
    LaunchScript(
        [string] $pathToScript,
        [string] $scriptArguments
    )
    {
        $PwshProcessInfo = New-Object System.Diagnostics.ProcessStartInfo
        $PwshProcessInfo.FileName = "C:\\Program Files\\PowerShell\\7\\pwsh.exe"
        $PwshProcessInfo.RedirectStandardError = $true
        $PwshProcessInfo.RedirectStandardOutput = $true
        $PwshProcessInfo.UseShellExecute = $false

        if ($null -ne $this.Logger)
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.LaunchScript.Name,
                "Powershell command: Start-Process C:\\Program Files\\PowerShell\\7\\pwsh.exe -ExecutionPolicy Unrestricted -exec bypass -File $pathToScript $scriptArguments"
            )
        }

        $PwshProcessInfo.Arguments = "-ExecutionPolicy Unrestricted -exec bypass -File $pathToScript $scriptArguments"

        $InstallationProcess = New-Object System.Diagnostics.Process
        $InstallationProcess.StartInfo = $PwshProcessInfo

        if ($null -ne $this.Logger)
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.LaunchScript.Name,
                "Starting the pwsh process now on script $pathToScript with arguments $scriptArguments."
            )
        }

        $InstallationProcess.Start() | Out-Null
        $InstallationProcess.WaitForExit()

        $stdout = $InstallationProcess.StandardOutput.ReadToEnd()
        $stderr = $InstallationProcess.StandardError.ReadToEnd()

        if ($null -ne $this.Logger)
        {
            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.LaunchScript.Name,
                "stdout: $stdout"
            )

            $this.Logger.WriteInfo(
                $this.GetType().Name,
                $this.LaunchScript.Name,
                "stderr: $stderr"
            )
        }
    }
}

class UrlCleaner
{
    [string] $DirtyUrl

    UrlCleaner([Object] $dirtyUrl)
    {
        $this.DirtyUrl = $dirtyUrl.ToString()
    }

    [string]
    Clean()
    {
        return $this.DirtyUrl.Replace(
            '(', ''
        ).Replace(
            ')', ''
        ).Replace(
            "'", ''
        ).Replace(
            ',', ''
        )
    }
}

if([ArgumentParser]::new($args).ParsedArguments.ContainsKey('Execute'))
{
    $logger = [EventLogger]::new(
        "$([Constants]::TempDirectory())\azure-vdi-provisioning-global-$( Get-Date -Format yyyyMMddTHHmmss ).log"
    )

    try
    {
        $logger.WriteInfo(
            "azure_vdi_provisioning.ps1",
            "global",
            "The following args were provided to azure_vdi_provisioning.ps1: $($args)"
        )

        $logger.WriteInfo(
            "azure_vdi_provisioning.ps1",
            "global",
            "Initializing provisioner..."
        )

        $provisioner = [AzureVdiProvisioning]::new($logger, $args)

        $logger.WriteInfo(
            "azure_vdi_provisioning.ps1",
            "global",
            "Provisioner initialized. Temp directory: $($provisioner.TempDirectory()). Provisioning..."
        )

        $provisioner.Provision()

        $logger.WriteInfo(
            "azure_vdi_provisioning.ps1",
            "global",
            "Virtual Machine provisioned."
        )
    }
    catch
    {
        $logger.WriteError(
            "azure_vdi_provisioning.ps1",
            "global",
            "Error with script.",
            $_
        )
    }
}


