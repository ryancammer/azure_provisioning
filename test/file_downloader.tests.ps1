Describe 'FileDownloader' {
    BeforeAll {
        . ../../modules/stacks/vdi/500_virtual_machine/scripts/azure_vdi_provisioning.ps1
    }

    Describe '#DownloadFile' {
        It 'Downloads the file' {
            $fileToCreate = [System.IO.Path]::GetRandomFileName()

            Test-Path -Path $fileToCreate | Should -Be $false

            $urlToDownload = 'https://www.google.com'

            $fileDownloader = [FileDownloader]::new()

            $fileDownloader.DownloadFile($fileToCreate, $urlToDownload)

            Test-Path -Path $fileToCreate | Should -Be $true

            Remove-Item -Path $fileToCreate
        }
    }
}
