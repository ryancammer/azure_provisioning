
# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.0.1] - 2021-10-14

### Changed
- The azure_provisioning.ps1 and host_registration.ps1 scripts now use
a key vault, a cert name, and a service principal id in order for the
host_registration.ps1 script to connect to Azure via the `Connect-AzAccount`
cmdlet.

## [0.0.2] - 2021-10-19

### Changed
- The host_registration.ps1 script now downloads an archive of the Az cmdlet, 
  `Az-Cmdlets-6.5.0.34802.zip`, which reduces the installation of the Az module
  from an hour or so down to less than a minute.
  

## [1.0.0] - 2021-10-21

### Changed

The azure_provisioning.ps1 and host_registration.ps1 scripts no longer require
a cert, key vault, or service principal, as the Terraform provisioning code
assigns the necessary roles to the Virtual Machine's identity, allowing it to
get a registration token from an Azure Virtual Desktop Session Host.

## [1.1.0] - 2021-11-03

### Added

The host_registration.ps1 script now enables 
[FsLogix](https://docs.microsoft.com/en-us/fslogix/overview) roaming profiles.

## [1.2.0] - 2022-01-31

### Added

The `azure_provisioning.ps1` script now contains a switch, `-InstallDuo`, that
will attempt to install [Duo](https://duo.com/). It requires that all subsequent
parameters be assigned.
