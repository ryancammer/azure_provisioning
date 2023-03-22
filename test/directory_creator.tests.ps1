Describe 'DirectoryCreator' {
    BeforeAll {
        . ../../modules/stacks/vdi/500_virtual_machine/scripts/azure_vdi_provisioning.ps1
    }

    Describe '#CreateDirectory' {
        Context 'When the directory does not exist' {
            It 'Creates the directory' {
                $directoryToCreate = [System.IO.Path]::GetRandomFileName()

                Test-Path -Path $directoryToCreate | Should -Be $false

                $directoryCreator = [DirectoryCreator]::new()

                $directoryCreator.CreateDirectory($directoryToCreate)

                Test-Path -Path $directoryToCreate | Should -Be $true

                Remove-Item -Path $directoryToCreate
            }
        }

        Context 'When the directory does exist' {
            It 'Leaves the directory intact' {
                $directoryToCreate = [System.IO.Path]::GetRandomFileName()

                Test-Path -Path $directoryToCreate | Should -Be $false

                New-Item -Path $directoryToCreate -ItemType directory

                $directory = [DirectoryCreator]::new()

                $directory.CreateDirectory($directoryToCreate)

                Test-Path -Path $directoryToCreate | Should -Be $true

                Remove-Item -Path $directoryToCreate
            }
        }
    }
}
