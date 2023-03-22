Describe 'EventLogger' {
    BeforeAll {
        . ../../modules/stacks/vdi/500_virtual_machine/scripts/azure_vdi_provisioning.ps1
    }

    Describe '#WriteEventToLog' {
        It 'Writes the log data to the log file' {
            $eventLog = [System.IO.Path]::GetRandomFileName()

            Test-Path -Path $eventLog | Should -Be $false

            $eventLogger = [EventLogger]::new($eventLog)

            $eventLogger.WriteEventToLog(
                [LogLevel]::Warning,
                'WriteEventToLog',
                'Test Message'
            )

            Test-Path -Path $eventLog | Should -Be $true

            $logData = Get-Content $eventLog

            $logData.Length | Should -BeGreaterThan 1

            Remove-Item -Path $eventLog -Force -Confirm:$false
        }
    }

    Describe '#WriteInfo' {
        It 'Writes the log data to the log file' {
            $eventLog = [System.IO.Path]::GetRandomFileName()

            Test-Path -Path $eventLog | Should -Be $false

            $eventLogger = [EventLogger]::new($eventLog)

            $eventLogger.WriteInfo(
                'EventLogger',
                'WriteEventToLog',
                'Test Message'
            )

            Test-Path -Path $eventLog | Should -Be $true

            $logData = Get-Content $eventLog

            $logData.Length | Should -BeGreaterThan 1

            Remove-Item -Path $eventLog -Force -Confirm:$false
        }
    }
}
