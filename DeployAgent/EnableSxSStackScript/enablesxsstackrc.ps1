<# 
.Synopsis
Powershell script that enables inbox SxSStack to be used for reverse connect (for versions starting from RS4)
.Description
Creates a new registry and copies the full content in registery RDP-Tcp.
On top the contents copied, two additional fields are created for the new registery.
Then create a listener for the new registry so that an Inbox SxS Stack can be used for ReverseConnect.
.Parameter SxSStackVersionName
Optional
The name of the new registery created.
If not used the scripts assigns a default value to this parameter.
.Example
User needs to run this script with admin privileges since we are editing and creating the registery values.
.\enablesxsstackrc.ps1
#>

#This parameter will be taken as commandline parameter.
Param(
    [string]$SxSStackVersionName
)

#Checking the OSVersion number extracted from version string to determine whether the current OS is before or after RS4.
$RS4Version = "10.0.17083"
if([System.Environment]::OSVersion.VersionString.Split(" ")[[System.Environment]::OSVersion.VersionString.Split(" ").Length-1] -lt $RS4Version){
    Write-Error "Please use the MSI for the current OS version."
    throw
}

#Helper function to recursively traverse and add folders existing under RDP-Tcp
function addChildFolder($children, $destination){
    foreach($child in $children){
        $names = $child.Name.Split('\')
        if(-not ($names.Count -gt 0)){
            Write-Error "Child Name format is invalid"
            throw
        }
        $newDestination = $destination+ '\' + $names[$names.Count-1] 
        
        New-Item -ItemType Directory -Force -Path $newDestination

        $message = "Created directory for "+$names[$names.Count-1]
        Write-Output $message

        $existingFolder = $child.Name -replace "HKEY_LOCAL_MACHINE", "HKLM:"

        $childRegistry = Get-ItemProperty -Path $existingFolder
        $childProperties = $childRegistry.psobject.properties
        
        foreach($property in $childProperties){
            Copy-ItemProperty -Path $existingFolder -Destination $newDestination -Name $property.Name
        }

        $message = "Copied properties from "+$names[$names.Count-1]
        Write-Output $message

        $subChildren = Get-ChildItem -Path $existingFolder
        addChildFolder ($subChildren) ($newDestination)
    }
}

if([string]::IsNullOrEmpty($SxSStackVersionName)){
    $SxSStackVersionName = "rdp-sxs"
}

#This is used for errors that should be ignored.
$ErrorActionPreference = "SilentlyContinue"

$destinationRegistry = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\"+$SxSStackVersionName

if(Test-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"){
    
    #Create the new registery if it doesn't exist
    #If it exist then we will prompt user to uninstall the existing sxsstack for the given version.
    if(!(Test-Path $destinationRegistry)){
        New-Item -ItemType Directory -Force -Path $destinationRegistry
    
        $registryKey = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
        $propertiesToBeCopied = $registryKey.psobject.properties

        #Assign all existing properties of RDP-Tcp to the new Registery except fEnableWinStation
        foreach ($property in $propertiesToBeCopied) {
            if($property.Name -ne "fEnableWinStation"){
                Copy-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Destination $destinationRegistry -Name $property.Name
            }
            else{
                New-ItemProperty -Path $destinationRegistry -Name "fEnableWinStation" -Value 0
            }
        }

        $message = "Properties of RDP-Tcp are added to registery "+ $SxSStackVersionName
        Write-Output $message

        $rdpReverseConnectListener = "RDPRECCONNamedPipeServer_" + $SxSStackVersionName
        #Setting the extra properties neeeded
        New-ItemProperty -Path $destinationRegistry -Name "SxSStackType" -Value 3
        New-ItemProperty -Path $destinationRegistry -Name "ReverseConnectionPipeName" -Value $rdpReverseConnectListener

        $message = "Additional required key value pairs are added to "+ $SxSStackVersionName
        Write-Output $message

        $childFolders = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
        addChildFolder ($childFolders) ($destinationRegistry)

        $message = "Child folders of RDP-Tcp are added to "+ $SxSStackVersionName
        Write-Output $message

        #Setting a listener on 1 level up.
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations" -Name "ReverseConnectionListener" -Value $SxSStackVersionName
        
        $message = "Reverse connect listener for "+ $SxSStackVersionName+ " is added to WinStations"
        Write-Output $message


        #Change the parameter on fEnableWinStation to 1.
        Set-ItemProperty -Path $destinationRegistry -Name "fEnableWinStation" -Value 1

        $message = "Enabled WinStation for " + $SxSStackVersionName
        Write-Output $message

        # this needs to be done after the stack is activated
        Write-Output "Setting active listener for RedirectionInfo"
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\ClusterSettings" -Name "SessionDirectoryListener" -Value $SxSStackVersionName

        $qwinstaOutput = & "qwinsta" | Out-String
        Write-Output $qwinstaOutput
    }
    else{
        $qwinstaOutput = & "qwinsta" | Out-String
        Write-Output $qwinstaOutput
        $errorMessage = "The SxSStack you wish to enable "+ $SxSStackVersionName + " already exists either specify a new name with parameter -SxSStackVersionName or disable the existing version.An example with a parameter would be: .\enablesxsstackrc -SxSStackVersionName 'sxsrcstack'"
        Write-Error $errorMessage
    }
}
else{
    $qwinstaOutput = & "qwinsta" | Out-String
    Write-Output $qwinstaOutput
    $errorMessage = "Inbox SxSStack is not installed so cannot generate new SxSStackVersion please check your settings."
    Write-Error $errorMessage
}

# SIG # Begin signature block
# MIInLAYJKoZIhvcNAQcCoIInHTCCJxkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAzLRJFViRO0Ydt
# Q8uQa/rRMgiVoDMp/mB7By9pY46jU6CCEWUwggh3MIIHX6ADAgECAhM2AAAAgrsy
# RpV6geNbAAEAAACCMA0GCSqGSIb3DQEBCwUAMEExEzARBgoJkiaJk/IsZAEZFgNH
# QkwxEzARBgoJkiaJk/IsZAEZFgNBTUUxFTATBgNVBAMTDEFNRSBDUyBDQSAwMTAe
# Fw0xODA3MTAxMzAyMzlaFw0xOTA3MTAxMzAyMzlaMCQxIjAgBgNVBAMTGU1pY3Jv
# c29mdCBBenVyZSBDb2RlIFNpZ24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQC6B/SG/b3ES+fa/jW7OzSAQxWlD1iY2W9U8MBJPBf23WR6PepYXO61z3JE
# H1MiAeAI8CA9XQCgUcrCXqQWJc6qEoSa2bScGXkApC7HukqFA+9cSdNe04QaS+S0
# RjWToYR09NjCCps6FLlmkwXZWgryrCGsAk48MggRMRNE2um1fSeEOWCLMHsFgWYN
# jwDxDsLpYhufbvvzwRBVy866Exm//HiOpR/vy1CEGZ37jT4LCklGIbvWJ7LuQ9Wj
# wZxj4JNwsx/AKwsDWweQ85Rfi+g3+FM7MCEyoJ98qEVTDApOZvUQEBxd771b97dR
# 5aKAfzc1H9oFDoh52jNmz3rDeWH/AgMBAAGjggWDMIIFfzApBgkrBgEEAYI3FQoE
# HDAaMAwGCisGAQQBgjdbAQEwCgYIKwYBBQUHAwMwPQYJKwYBBAGCNxUHBDAwLgYm
# KwYBBAGCNxUIhpDjDYTVtHiE8Ys+hZvdFs6dEoFgg93NZoaUjDICAWQCAQswggJ2
# BggrBgEFBQcBAQSCAmgwggJkMGIGCCsGAQUFBzAChlZodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpaW5mcmEvQ2VydHMvQlkyUEtJQ1NDQTAxLkFNRS5HQkxfQU1F
# JTIwQ1MlMjBDQSUyMDAxKDEpLmNydDBSBggrBgEFBQcwAoZGaHR0cDovL2NybDEu
# YW1lLmdibC9haWEvQlkyUEtJQ1NDQTAxLkFNRS5HQkxfQU1FJTIwQ1MlMjBDQSUy
# MDAxKDEpLmNydDBSBggrBgEFBQcwAoZGaHR0cDovL2NybDIuYW1lLmdibC9haWEv
# QlkyUEtJQ1NDQTAxLkFNRS5HQkxfQU1FJTIwQ1MlMjBDQSUyMDAxKDEpLmNydDBS
# BggrBgEFBQcwAoZGaHR0cDovL2NybDMuYW1lLmdibC9haWEvQlkyUEtJQ1NDQTAx
# LkFNRS5HQkxfQU1FJTIwQ1MlMjBDQSUyMDAxKDEpLmNydDBSBggrBgEFBQcwAoZG
# aHR0cDovL2NybDQuYW1lLmdibC9haWEvQlkyUEtJQ1NDQTAxLkFNRS5HQkxfQU1F
# JTIwQ1MlMjBDQSUyMDAxKDEpLmNydDCBrQYIKwYBBQUHMAKGgaBsZGFwOi8vL0NO
# PUFNRSUyMENTJTIwQ0ElMjAwMSxDTj1BSUEsQ049UHVibGljJTIwS2V5JTIwU2Vy
# dmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlvbixEQz1BTUUsREM9R0JM
# P2NBQ2VydGlmaWNhdGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0
# aG9yaXR5MB0GA1UdDgQWBBSOTzmrWuq9s4lp8xOp1ano/K6DwDAOBgNVHQ8BAf8E
# BAMCB4AwUAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRp
# b25zIFB1ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzYxNjcrNDM4MDQyMIIB1AYDVR0f
# BIIByzCCAccwggHDoIIBv6CCAbuGPGh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9w
# a2lpbmZyYS9DUkwvQU1FJTIwQ1MlMjBDQSUyMDAxLmNybIYuaHR0cDovL2NybDEu
# YW1lLmdibC9jcmwvQU1FJTIwQ1MlMjBDQSUyMDAxLmNybIYuaHR0cDovL2NybDIu
# YW1lLmdibC9jcmwvQU1FJTIwQ1MlMjBDQSUyMDAxLmNybIYuaHR0cDovL2NybDMu
# YW1lLmdibC9jcmwvQU1FJTIwQ1MlMjBDQSUyMDAxLmNybIYuaHR0cDovL2NybDQu
# YW1lLmdibC9jcmwvQU1FJTIwQ1MlMjBDQSUyMDAxLmNybIaBumxkYXA6Ly8vQ049
# QU1FJTIwQ1MlMjBDQSUyMDAxLENOPUJZMlBLSUNTQ0EwMSxDTj1DRFAsQ049UHVi
# bGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJhdGlv
# bixEQz1BTUUsREM9R0JMP2NlcnRpZmljYXRlUmV2b2NhdGlvbkxpc3Q/YmFzZT9v
# YmplY3RDbGFzcz1jUkxEaXN0cmlidXRpb25Qb2ludDAfBgNVHSMEGDAWgBQbZqIZ
# /JvrpdqEjxiY6RCkw3uSvTAfBgNVHSUEGDAWBgorBgEEAYI3WwEBBggrBgEFBQcD
# AzANBgkqhkiG9w0BAQsFAAOCAQEAkTjDgWcKF5AekFyhXDv4trHLi7qyl4UZrgpC
# mKDeftiGYPzlwtxKNBKToum6mWxLS5QvkurudtJBR26IPRXOCjwr8G4CpcC+4DOY
# cTm6xTaWUsJwINkhOFG0OozHXcfaAsdHXnm27Bi9cDcbBu+BTGQYYUfwpONZNoOt
# CZNzahokKX5DRPlevedCKMOlmcF9s28dFsD4He+4cn3fFzC9DcaNn0IwKAMOZl2B
# 5KpANKBRiAxfLOXunlBuJayl/3k5r78bxefxxrDq1rO0gGla1c8sVceaYLl5lB7N
# VgwLLWgLI1lkk2axdHo3W4D2TJBU+RG2PSmmPMzsILYs8oTcYTCCCOYwggbOoAMC
# AQICEx8AAAAUtMUfxvKAvnEAAAAAABQwDQYJKoZIhvcNAQELBQAwPDETMBEGCgmS
# JomT8ixkARkWA0dCTDETMBEGCgmSJomT8ixkARkWA0FNRTEQMA4GA1UEAxMHYW1l
# cm9vdDAeFw0xNjA5MTUyMTMzMDNaFw0yMTA5MTUyMTQzMDNaMEExEzARBgoJkiaJ
# k/IsZAEZFgNHQkwxEzARBgoJkiaJk/IsZAEZFgNBTUUxFTATBgNVBAMTDEFNRSBD
# UyBDQSAwMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANVXgQLW+frQ
# 9xuAud03zSTcZmH84YlyrSkM0hsbmr+utG00tVRHgw40pxYbJp5W+hpDwnmJgicF
# oGRrPt6FifMmnd//1aD/fW1xvGs80yZk9jxTNcisVF1CYIuyPctwuJZfwE3wcGxh
# kVw/tj3ZHZVacSls3jRD1cGwrcVo1IR6+hHMvUejtt4/tv0UmUoH82HLQ8w1oTX9
# D7xj35Zt9T0pOPqM3Gt9+/zs7tPp2gyoOYv8xR4X0iWZKuXTzxugvMA63YsB4ehu
# SBqzHdkF55rxH47aT6hPhvDHlm7M2lsZcRI0CUAujwcJ/vELeFapXNGpt2d3wcPJ
# M0bpzrPDJ/8CAwEAAaOCBNowggTWMBAGCSsGAQQBgjcVAQQDAgEBMCMGCSsGAQQB
# gjcVAgQWBBSR/DPOQp72k+bifVTXCBi7uNdxZTAdBgNVHQ4EFgQUG2aiGfyb66Xa
# hI8YmOkQpMN7kr0wggEEBgNVHSUEgfwwgfkGBysGAQUCAwUGCCsGAQUFBwMBBggr
# BgEFBQcDAgYKKwYBBAGCNxQCAQYJKwYBBAGCNxUGBgorBgEEAYI3CgMMBgkrBgEE
# AYI3FQYGCCsGAQUFBwMJBggrBgEFBQgCAgYKKwYBBAGCN0ABAQYLKwYBBAGCNwoD
# BAEGCisGAQQBgjcKAwQGCSsGAQQBgjcVBQYKKwYBBAGCNxQCAgYKKwYBBAGCNxQC
# AwYIKwYBBQUHAwMGCisGAQQBgjdbAQEGCisGAQQBgjdbAgEGCisGAQQBgjdbAwEG
# CisGAQQBgjdbBQEGCisGAQQBgjdbBAEGCisGAQQBgjdbBAIwGQYJKwYBBAGCNxQC
# BAweCgBTAHUAYgBDAEEwCwYDVR0PBAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAw
# HwYDVR0jBBgwFoAUKV5RXmSuNLnrrJwNp4x1AdEJCygwggFoBgNVHR8EggFfMIIB
# WzCCAVegggFToIIBT4YjaHR0cDovL2NybDEuYW1lLmdibC9jcmwvYW1lcm9vdC5j
# cmyGMWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2lpbmZyYS9jcmwvYW1lcm9v
# dC5jcmyGI2h0dHA6Ly9jcmwyLmFtZS5nYmwvY3JsL2FtZXJvb3QuY3JshiNodHRw
# Oi8vY3JsMy5hbWUuZ2JsL2NybC9hbWVyb290LmNybIaBqmxkYXA6Ly8vQ049YW1l
# cm9vdCxDTj1BTUVST09ULENOPUNEUCxDTj1QdWJsaWMlMjBLZXklMjBTZXJ2aWNl
# cyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPUFNRSxEQz1HQkw/Y2Vy
# dGlmaWNhdGVSZXZvY2F0aW9uTGlzdD9iYXNlP29iamVjdENsYXNzPWNSTERpc3Ry
# aWJ1dGlvblBvaW50MIIBqwYIKwYBBQUHAQEEggGdMIIBmTA3BggrBgEFBQcwAoYr
# aHR0cDovL2NybDEuYW1lLmdibC9haWEvQU1FUk9PVF9hbWVyb290LmNydDBHBggr
# BgEFBQcwAoY7aHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraWluZnJhL2NlcnRz
# L0FNRVJPT1RfYW1lcm9vdC5jcnQwNwYIKwYBBQUHMAKGK2h0dHA6Ly9jcmwyLmFt
# ZS5nYmwvYWlhL0FNRVJPT1RfYW1lcm9vdC5jcnQwNwYIKwYBBQUHMAKGK2h0dHA6
# Ly9jcmwzLmFtZS5nYmwvYWlhL0FNRVJPT1RfYW1lcm9vdC5jcnQwgaIGCCsGAQUF
# BzAChoGVbGRhcDovLy9DTj1hbWVyb290LENOPUFJQSxDTj1QdWJsaWMlMjBLZXkl
# MjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPUFNRSxE
# Qz1HQkw/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29iamVjdENsYXNzPWNlcnRpZmljYXRp
# b25BdXRob3JpdHkwDQYJKoZIhvcNAQELBQADggIBACi3Soaajx+kAWjNwgDqkIvK
# AOFkHmS1t0DlzZlpu1ANNfA0BGtck6hEG7g+TpUdVrvxdvPQ5lzU3bGTOBkyhGmX
# oSIlWjKC7xCbbuYegk8n1qj3rTcjiakdbBqqHdF8J+fxv83E2EsZ+StzfCnZXA62
# QCMn6t8mhCWBxpwPXif39Ua32yYHqP0QISAnLTjjcH6bAV3IIk7k5pQ/5NA6qIL8
# yYD6vRjpCMl/3cZOyJD81/5+POLNMx0eCClOfFNxtaD0kJmeThwL4B2hAEpHTeRN
# tB8ib+cze3bvkGNPHyPlSHIuqWoC31x2Gk192SfzFDPV1PqFOcuKjC8049SSBtC1
# X7hyvMqAe4dop8k3u25+odhvDcWdNmimdMWvp/yZ6FyjbGlTxtUqE7iLTLF1eaUL
# SEobAap16hY2N2yTJTISKHzHI4rjsEQlvqa2fj6GLxNj/jC+4LNy+uRmfQXShd30
# lt075qTroz0Nt680pXvVhsRSdNnzW2hfQu2xuOLg8zKGVOD/rr0GgeyhODjKgL2G
# Hxctbb9XaVSDf6ocdB//aDYjiabmWd/WYmy7fQ127KuasMh5nSV2orMcAed8CbIV
# I3NYu+sahT1DRm/BGUN2hSpdsPQeO73wYvp1N7DdLaZyz7XsOCx1quCwQ+bojWVQ
# TmKLGegSoUpZNfmP9MtSMYIVHTCCFRkCAQEwWDBBMRMwEQYKCZImiZPyLGQBGRYD
# R0JMMRMwEQYKCZImiZPyLGQBGRYDQU1FMRUwEwYDVQQDEwxBTUUgQ1MgQ0EgMDEC
# EzYAAACCuzJGlXqB41sAAQAAAIIwDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcN
# AQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUw
# LwYJKoZIhvcNAQkEMSIEILyl3qmjHcErwEKz4ejRE+hxukI37sDj4idJ/tMvnWsu
# MEIGCisGAQQBgjcCAQwxNDAyoBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRw
# Oi8vd3d3Lm1pY3Jvc29mdC5jb20wDQYJKoZIhvcNAQEBBQAEggEAUQOZ2GIwLCp2
# W0i7nF8OGwGBr97CSMCJYchKkh1OVsRgklh1pJNxfIAAvzcl32JTDrTv4JnJ0buS
# NYHwiQ36c/SFffFqcWJj1t0LHU4BxO0nOzS0xJG/mLEQC0gfaqXURzcXHrRSnJgf
# v8x0Mdv3tpvVB6lpqJtC9y0GJxqvUHjzoKr4sKbzMbCkjscziAVqYNwIvB4LBjWx
# rl1VO/GAPy/VHGjRGFueyGW171QRt01kVmhYOn8o9LfMH8GIDllkMZhfNkANpmoI
# 9m+DKuCVGRZzbiEU8+zLXcMJxmiHLq1WEAbOKfJYbN61RvzrUMj4tmdZ8MwJhQvl
# BAOiLljWL6GCEuUwghLhBgorBgEEAYI3AwMBMYIS0TCCEs0GCSqGSIb3DQEHAqCC
# Er4wghK6AgEDMQ8wDQYJYIZIAWUDBAIBBQAwggFRBgsqhkiG9w0BCRABBKCCAUAE
# ggE8MIIBOAIBAQYKKwYBBAGEWQoDATAxMA0GCWCGSAFlAwQCAQUABCD1QqX6knwc
# BQ5iDxaaypdqUiOH0ABaDFHJ/A7QKDy7+AIGW7Ss7nT8GBMyMDE4MTAxMTEwMjU1
# NC43NjFaMASAAgH0oIHQpIHNMIHKMQswCQYDVQQGEwJVUzELMAkGA1UECBMCV0Ex
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEtMCsGA1UECxMkTWljcm9zb2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVk
# MSYwJAYDVQQLEx1UaGFsZXMgVFNTIEVTTjoxNzlFLTRCQjAtODI0NjElMCMGA1UE
# AxMcTWljcm9zb2Z0IFRpbWUtU3RhbXAgc2VydmljZaCCDjwwggTxMIID2aADAgEC
# AhMzAAAA26pt4yJ/NAAlAAAAAADbMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYT
# AlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFBDQSAyMDEwMB4XDTE4MDgyMzIwMjY1M1oXDTE5MTEyMzIwMjY1
# M1owgcoxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJXQTEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNy
# b3NvZnQgSXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxl
# cyBUU1MgRVNOOjE3OUUtNEJCMC04MjQ2MSUwIwYDVQQDExxNaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBzZXJ2aWNlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# p6GakAyYJItLNm7N/TusT1Rc/lMKotEQMM6qIDDelrmRJgp1EDCdCa8DDiUUDZxN
# 8IuMUv3OdLf4n7wJYbaLKccQiKtWCQOvqcbXwfbyu8bt2N2hE6odY2ZjzLM/dgX6
# SIi/lGruB9dgJixv7TIbfvGBboN9IscE3ygmrQZndzvknhKIZWIgX/e2iVQ/az0j
# 5SllIaw5HaVFDLEGFNN1q++uIpRGy1HPc8D/8/+sLTyPkak1/N+31KrlOMpQ+Re9
# P65EYeit1jqx1rEKouO+gRhijY0MosJcQ8LebwsFIrtZXQJNLCPcCok0L+x6Gzb6
# LdkXb2RzMfWK07MlL6pNCwIDAQABo4IBGzCCARcwHQYDVR0OBBYEFLK63x2AXHOm
# zbbt5ByMrd4qQwNIMB8GA1UdIwQYMBaAFNVjOlyKMZDzQ3t8RhvFM2hahW1VMFYG
# A1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3Js
# L3Byb2R1Y3RzL01pY1RpbVN0YVBDQV8yMDEwLTA3LTAxLmNybDBaBggrBgEFBQcB
# AQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kv
# Y2VydHMvTWljVGltU3RhUENBXzIwMTAtMDctMDEuY3J0MAwGA1UdEwEB/wQCMAAw
# EwYDVR0lBAwwCgYIKwYBBQUHAwgwDQYJKoZIhvcNAQELBQADggEBABVCwpqdvRlg
# fiJHiSTpgZXVXm5XY1Gb+kfsl5NZMUxYaSAVAf0AmRTkT64R8uCOt1Ayr83JwThA
# irRxvQdWdg4o8aeK8UOGZp1kfVoFBZB/8OW+LIcaEgP19qqe084C2bnWMAa+ejsf
# jEbN3tLOay8D2GDD3Ot2yIK2THWzm4I9xUV0QAWL6hL00uTY0ULm608rokc40uQU
# 0OkEFiy/k93UPYPJjUk+BKGyENGv9TFXhtwz4QcYwpdGZ67AwB0RiT7dreoyikxG
# 32xkisijcfrDbdDstERmqVy4GsxfFPyk5eVSpR9YWL+Pe+vyGg/wQnMcllGuSr9w
# mTpaVGQ9IYswggZxMIIEWaADAgECAgphCYEqAAAAAAACMA0GCSqGSIb3DQEBCwUA
# MIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMH
# UmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQD
# EylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0x
# MDA3MDEyMTM2NTVaFw0yNTA3MDEyMTQ2NTVaMHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqR0NvHcR
# ijog7PwTl/X6f2mUa3RUENWlCgCChfvtfGhLLF/Fw+Vhwna3PmYrW/AVUycEMR9B
# GxqVHc4JE458YTBZsTBED/FgiIRUQwzXTbg4CLNC3ZOs1nMwVyaCo0UN0Or1R4HN
# vyRgMlhgRvJYR4YyhB50YWeRX4FUsc+TTJLBxKZd0WETbijGGvmGgLvfYfxGwScd
# JGcSchohiq9LZIlQYrFd/XcfPfBXday9ikJNQFHRD5wGPmd/9WbAA5ZEfu/QS/1u
# 5ZrKsajyeioKMfDaTgaRtogINeh4HLDpmc085y9Euqf03GS9pAHBIAmTeM38vMDJ
# RF1eFpwBBU8iTQIDAQABo4IB5jCCAeIwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0O
# BBYEFNVjOlyKMZDzQ3t8RhvFM2hahW1VMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIA
# QwBBMAsGA1UdDwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2
# VsuP6KJcYmjRPZSQW9fOmhjEMFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwu
# bWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEw
# LTA2LTIzLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYt
# MjMuY3J0MIGgBgNVHSABAf8EgZUwgZIwgY8GCSsGAQQBgjcuAzCBgTA9BggrBgEF
# BQcCARYxaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL1BLSS9kb2NzL0NQUy9kZWZh
# dWx0Lmh0bTBABggrBgEFBQcCAjA0HjIgHQBMAGUAZwBhAGwAXwBQAG8AbABpAGMA
# eQBfAFMAdABhAHQAZQBtAGUAbgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAB+aI
# UQ3ixuCYP4FxAz2do6Ehb7Prpsz1Mb7PBeKp/vpXbRkws8LFZslq3/Xn8Hi9x6ie
# JeP5vO1rVFcIK1GCRBL7uVOMzPRgEop2zEBAQZvcXBf/XPleFzWYJFZLdO9CEMiv
# v3/Gf/I3fVo/HPKZeUqRUgCvOA8X9S95gWXZqbVr5MfO9sp6AG9LMEQkIjzP7QOl
# lo9ZKby2/QThcJ8ySif9Va8v/rbljjO7Yl+a21dA6fHOmWaQjP9qYn/dxUoLkSbi
# OewZSnFjnXshbcOco6I8+n99lmqQeKZt0uGc+R38ONiU9MalCpaGpL2eGq4EQoO4
# tYCbIjggtSXlZOz39L9+Y1klD3ouOVd2onGqBooPiRa6YacRy5rYDkeagMXQzafQ
# 732D8OE7cQnfXXSYIghh2rBQHm+98eEA3+cxB6STOvdlR3jo+KhIq/fecn5ha293
# qYHLpwmsObvsxsvYgrRyzR30uIUBHoD7G4kqVDmyW9rIDVWZeodzOwjmmC3qjeAz
# LhIp9cAvVCch98isTtoouLGp25ayp0Kiyc8ZQU3ghvkqmqMRZjDTu3QyS99je/WZ
# ii8bxyGvWbWu3EQ8l1Bx16HSxVXjad5XwdHeMMD9zOZN+w2/XU/pnR4ZOC+8z1gF
# Lu8NoFA12u8JJxzVs341Hgi62jbb01+P3nSISRKhggLOMIICNwIBATCB+KGB0KSB
# zTCByjELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAldBMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jv
# c29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVz
# IFRTUyBFU046MTc5RS00QkIwLTgyNDYxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1l
# LVN0YW1wIHNlcnZpY2WiIwoBATAHBgUrDgMCGgMVAFulKU6vGKz4cDwkT2pEW61v
# x9swoIGDMIGApH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24x
# EDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlv
# bjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZI
# hvcNAQEFBQACBQDfaQ6GMCIYDzIwMTgxMDExMDc0OTI2WhgPMjAxODEwMTIwNzQ5
# MjZaMHcwPQYKKwYBBAGEWQoEATEvMC0wCgIFAN9pDoYCAQAwCgIBAAICHkMCAf8w
# BwIBAAICEbIwCgIFAN9qYAYCAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGE
# WQoDAqAKMAgCAQACAwehIKEKMAgCAQACAwGGoDANBgkqhkiG9w0BAQUFAAOBgQBQ
# CmR/iX1RmzyzNRnSnHtpA9QACLJINjSwLBuWiner682rbCtxVdp7A+zX3Umvvd9p
# TK++qGLAHwNdzGQpgnLcnisMuopLDxL6AxSTtCtb10CkA1TbNo7Mbgq0RKwyjpE0
# iYip7TCMAyZUrzq4kiI0eXHZ5qDgEFr7Wlx6hz1KizGCAw0wggMJAgEBMIGTMHwx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1p
# Y3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwAhMzAAAA26pt4yJ/NAAlAAAAAADb
# MA0GCWCGSAFlAwQCAQUAoIIBSjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQw
# LwYJKoZIhvcNAQkEMSIEIPzx4CSUz/XvLSDZHXwu5XpKEHCWmJwNn5r3VStByIub
# MIH6BgsqhkiG9w0BCRACLzGB6jCB5zCB5DCBvQQgAlMdsdOYAS0itWojJWOwi31H
# tuIgt/yw+vLrnSGM/qowgZgwgYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMAITMwAAANuqbeMifzQAJQAAAAAA2zAiBCBAmX1F8InQ4Us+4gzS6i241UV8
# G8WBp7LYEoU+KuWNFjANBgkqhkiG9w0BAQsFAASCAQB1eYXLCQQT/cUZgLWTdxw1
# JoGo8wDea852x8X3W9PQ4a1pL+232brKcc5MeKvgucn8EnOW6pZt5mYsZ/sLP2ok
# AZQDU13WjfeOQj17eTu/GJMMOjUkotmv2SKGpAoQsHDhV8H0xQ9HPoiceUT2FgCx
# c+jJEuM2XZkGfPAyeUbET7GcisjEp7n6dHjWwnT13IBXQOegzzvpNv94AtnKqaeQ
# rEJYGfffsneSKqkHCy/GK1hBrXskctt//RFz4vmD6lWZNCHAkdBbpVoIcZdA3by8
# 5aGZwiw1PJF7uH+0+YhwP+AdMwV6BUwqhUqjhH1ysRVXuYtONYYN9ccyRS0mlHhg
# SIG # End signature block
