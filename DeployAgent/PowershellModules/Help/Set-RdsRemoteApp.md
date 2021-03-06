---
external help file: Microsoft.RDInfra.RdPowershell.dll-Help.xml
Module Name: Microsoft.RDInfra.RdPowershell
online version:
schema: 2.0.0
---

# Set-RdsRemoteApp

## SYNOPSIS
Sets the properties for a RemoteApp.

## SYNTAX

### RA1 (Default)
```
Set-RdsRemoteApp [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String> [-Name] <String>
 [-FilePath <String>] [-CommandLineSetting <CommandLineSetting>] [-Description <String>]
 [-FileVirtualPath <String>] [-FolderName <String>] [-FriendlyName <String>] [-IconIndex <Int32>]
 [-IconPath <String>] [-RequiredCommandLine <String>] [-ShowInWebFeed] [<CommonParameters>]
```

### RA2
```
Set-RdsRemoteApp [-TenantName] <String> [-HostPoolName] <String> [-AppGroupName] <String> [-Name] <String>
 [-CommandLineSetting <CommandLineSetting>] [-Description <String>] [-FileVirtualPath <String>]
 [-FolderName <String>] [-FriendlyName <String>] [-IconIndex <Int32>] [-IconPath <String>]
 [-RequiredCommandLine <String>] [-ShowInWebFeed] [-AppAlias <String>] [<CommonParameters>]
```

## DESCRIPTION
The Set-RdsRemoteApp cmdlet sets the properties for a RemoteApp published to the specified app group. With this command, you can change the icon that appears for the RemoteApp, the friendly name of the RemoteApp that appears in the Remote Desktop clients, and the start-up execution of the RemoteApp (through command line parameters).

## EXAMPLES

### Example 1: Change the friendly name of the RemoteApp
```powershell
PS C:\> Set-RdsRemoteApp -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -AppGroupName "Web apps" -Name "Internet Explorer" -FriendlyName "Contoso Web App"

TenantGroupName     : Default Tenant Group
TenantName          : Contoso
HostPoolName        : Contoso Host Pool
AppGroupName        : Web apps
RemoteAppName       : Internet Explorer
FilePath            : C:\Program Files\internet explorer\iexplore.exe
AppAlias            :
CommandLineSetting  : DoNotAllow
Description         :
FriendlyName        : Contoso Web App
IconIndex           : 0
IconPath            : C:\Program Files\internet explorer\iexplore.exe
RequiredCommandLine :
ShowInWebFeed       : True
```
This command changes the friendly name of the RemoteApp to "Contoso Web App," which will appear to end-users in the Remote Desktop clients.

### Example 2: Change the command line properties of the RemoteApp
```powershell
PS C:\> Set-RdsRemoteApp -TenantName "Contoso" -HostPoolName "Contoso Host Pool" -AppGroupName "Web apps" -Name "Internet Explorer" -CommandLineSetting Require -RequiredCommandLine "https://webapp.contoso.com"

TenantGroupName     : Default Tenant Group
TenantName          : Contoso
HostPoolName        : Contoso Host Pool
AppGroupName        : Web apps
RemoteAppName       : Internet Explorer
FilePath            : C:\Program Files\internet explorer\iexplore.exe
AppAlias            :
CommandLineSetting  : Require
Description         :
FriendlyName        : Contoso Web App
IconIndex           : 0
IconPath            : C:\Program Files\internet explorer\iexplore.exe
RequiredCommandLine : https://webapp.contoso.com
ShowInWebFeed       : True
```
This command changes the command-line arguments of Internet Explorer to always launch "https://webapp.contoso.com".

## PARAMETERS

### -AppAlias
A unique string generated by the RD host agent for each start menu apps before it is returned by the host agent. The AppAlias is returned by the Get-RdsStartMenuApp cmdlet and can be used to identify an app for publishing.

```yaml
Type: String
Parameter Sets: RA2
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AppGroupName
The name of the app group.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -CommandLineSetting
Specifies whether the RemoteApp program accepts command-line arguments from the client at connection time. The acceptable values for this parameter are: 
- Allow: Accepts command-line arguments. 
- DoNotAllow: Does not accept command-line arguments. 
- Require: Allows only command-line arguments specified in the RequiredCommandLine parameter. 

```yaml
Type: CommandLineSetting
Parameter Sets: (All)
Aliases:
Accepted values: Allow, DoNotAllow, Require

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Description
A 512 character string that describes the Tenant to help administrators. Any character is allowed.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilePath
Specifies a path for the executable file for the application. It may include any environment variables. This path must be a valid local path on all session hosts in the host pool.

```yaml
Type: String
Parameter Sets: RA1
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FileVirtualPath
The file path to the executable file for the application. This path is must be consistent across all session hosts in the host pool and does allow environment variables.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FolderName
The name of the folder where the application will be grouped in the Remote Desktop clients.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FriendlyName
A 256 character string that is intended for display to end users. Any character is allowed.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -HostPoolName
The name of the host pool.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -IconIndex
The index of the icon from the executable file, as defined by the IconPath parameter.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IconPath
Specifies a path to an application or ico file to display for the application. It may not include any environment variables. This path must be a valid local path on all session hosts in the host pool.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Name
The name of the RemoteApp.

```yaml
Type: String
Parameter Sets: (All)
Aliases: RemoteAppName

Required: True
Position: 3
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -RequiredCommandLine
Specifies a string that contains command-line arguments that the client can use at connection time with the RemoteApp program. If you specify this parameter, the CommandLineSetting parameter must have a value of Require. 

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ShowInWebFeed
Specifies whether to show the RemoteApp program in the web feed. By default, all RemoteApps are shown.
Note: This allows the admin to turn off an application temporarily and then turn it back on without deleting and re-creating the custom app information. 

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TenantName
The name of the tenant.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### Microsoft.RDInfra.RDManagementData.RdMgmtRemoteApp

## NOTES

## RELATED LINKS
