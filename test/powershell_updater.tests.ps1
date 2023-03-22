Describe 'PowershellUpdater' {
    BeforeAll {
        . ../../modules/stacks/vdi/500_virtual_machine/scripts/azure_vdi_provisioning.ps1
    }

    Describe '#PowershellRequiresUpdate' {
        Context 'When the system version is less than the required version' {
            It 'returns true' {
                $powershellUpdater = [PowershellUpdater]::new(
                    '7.2',
                    '5.1.2',
                    $null,
                    $null
                )

                $powershellUpdater.PowershellRequiresUpdate() | Should -Be $true

                $powershellUpdater = [PowershellUpdater]::new(
                    '7.2.6',
                    '7.2.1',
                    $null,
                    $null
                )

                $powershellUpdater.PowershellRequiresUpdate() | Should -Be $true

                $powershellUpdater = [PowershellUpdater]::new(
                    '7.2.6',
                    '7.2.0',
                    $null,
                    $null
                )

                $powershellUpdater.PowershellRequiresUpdate() | Should -Be $true
            }
        }

        Context 'When the system version is greater than or equal to the required version' {
            It 'returns false' {
                $powershellUpdater = [PowershellUpdater]::new(
                    '7.2.0',
                    '7.2.0',
                    $null,
                    $null
                )

                $powershellUpdater.PowershellRequiresUpdate() | Should -Be $false

                $powershellUpdater = [PowershellUpdater]::new(
                    '7.2',
                    '7.2',
                    $null,
                    $null
                )

                $powershellUpdater.PowershellRequiresUpdate() | Should -Be $false

                $powershellUpdater = [PowershellUpdater]::new(
                    '7.2.0',
                    '7.2.4',
                    $null,
                    $null
                )

                $powershellUpdater.PowershellRequiresUpdate() | Should -Be $false

                $powershellUpdater = [PowershellUpdater]::new(
                    '7.2',
                    '9.2.1',
                    $null,
                    $null
                )

                $powershellUpdater.PowershellRequiresUpdate() | Should -Be $false
            }
        }
    }
}
