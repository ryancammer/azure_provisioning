Describe 'ModuleInstaller' {
    BeforeAll {
        . ../../modules/stacks/vdi/500_virtual_machine/scripts/azure_vdi_provisioning.ps1
    }

    Describe '#Install' {
        It 'Installs the specified modules' {
            $modulesToInstall = (
            'Module1'
            )

            $moduleInstaller = [ModuleInstaller]::new(
                $false,
                $modulesToInstall
            )

            $moduleInstaller.ModulesToInstall | Should -Be $modulesToInstall

            Mock Get-InstalledModule { return $false }

            Mock Install-Module { return $true }

            $moduleInstaller.InstallModules()

            Should -Invoke -CommandName Get-InstalledModule -Times 1

            Should -Invoke -CommandName Install-Module -Times 1

        }
    }
}
