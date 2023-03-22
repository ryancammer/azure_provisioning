Describe 'ArchiveExpander' {
    BeforeAll {
        . ../../modules/stacks/vdi/500_virtual_machine/scripts/azure_vdi_provisioning.ps1
    }

    Describe '#ExpandArchive' {
        Context 'When the directory to expand the archive into does not exist' {
            It 'Expands the archive into a new directory' {
                $directoryToExpandArchiveInto = [System.IO.Path]::GetRandomFileName()

                Test-Path -Path $directoryToExpandArchiveInto | Should -Be $false

                $directoryToCreateArchiveFrom = [System.IO.Path]::GetRandomFileName()

                Test-Path -Path $directoryToCreateArchiveFrom | Should -Be $false

                New-Item -Path $directoryToCreateArchiveFrom -ItemType directory

                Get-Process | Out-File -FilePath $directoryToCreateArchiveFrom\Process.txt

                $pathOfArchiveToExpand = "$( $directoryToCreateArchiveFrom ).zip"

                Compress-Archive -Path $directoryToCreateArchiveFrom `
                    -DestinationPath $pathOfArchiveToExpand

                $archiveExpander = [ArchiveExpander]::new()

                $archiveExpander.ExpandArchive(
                    $true,
                    $directoryToExpandArchiveInto,
                    $pathOfArchiveToExpand
                )

                Test-Path -Path $directoryToExpandArchiveInto | Should -Be $true

                Test-Path -Path $directoryToExpandArchiveInto\$directoryToCreateArchiveFrom\Process.txt | Should -Be $true

                Remove-Item -Path $directoryToExpandArchiveInto -Force -Confirm:$false -Recurse

                Remove-Item -Path $directoryToCreateArchiveFrom -Force -Confirm:$false -Recurse

                Remove-Item -Path $pathOfArchiveToExpand -Force -Confirm:$false
            }
        }
    }
}
