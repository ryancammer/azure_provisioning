Describe 'ArgumentParser' {
    BeforeAll {
        . ../../modules/stacks/vdi/500_virtual_machine/scripts/azure_vdi_provisioning.ps1
    }

    $VerbosePreference = "Continue"
    Describe '#Parse' {
        It 'Expands the archive into a new directory' {
            $arguments = ('-a', 1, 2, 3, 4, '-b', '-c', 'one')

            $argumentParser = [ArgumentParser]::new($arguments)

            $parsedArguments = $argumentParser.ParsedArguments

            $parsedArguments['a'] | Should -EQ (1, 2, 3, 4)
            $parsedArguments['b'] | Should -EQ $null
            $parsedArguments['c'] | Should -EQ 'one'

            "$($argumentParser)" | Should -Eq "-a 1 2 3 4 -b -c one"
        }
    }
}
