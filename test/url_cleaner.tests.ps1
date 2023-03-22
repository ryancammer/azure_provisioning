Describe 'UrlCleaner' {
    BeforeAll {
        . ../../modules/stacks/vdi/500_virtual_machine/scripts/azure_vdi_provisioning.ps1
    }

    Describe '#Clean' {
        It 'Cleans a url with all kinds of weirdness in it' {
            $cleanUrl = 'https://www.something.com/somethingelse?a=4'

            $dirtyUrl = "('$($cleanUrl),'"

            [UrlCleaner]::new($dirtyUrl).Clean() | Should -Eq $cleanUrl
        }
    }
}
