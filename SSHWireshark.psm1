function _Quote {
    Param($Data)
    $Data = $Data -replace '"', '""'
    $Data = $Data -replace '\\', '"\\"'
    """$Data"""
}

function Get-ExePath {
    Param($ProductCode, $ExeName, $ProgramFolderName)

    $RegistryPaths = @(
        "HKLM:\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$ProductCode"
        "HKLM:\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$ProductCode"
    )

    foreach ($RegistryPath in $RegistryPaths) {
        if (Test-Path $RegistryPath) {
            $InstallLocation = Get-ItemPropertyValue -LiteralPath $RegistryPath -Name InstallLocation
            if ($InstallLocation) {
                $Path = Join-Path $InstallLocation $ExeName
                if (Test-Path $Path) {
                    return $Path
                }
            }
        }
    }

    $ProgramFolderPaths = @(
        "C:\Program Files\$ProgramFolderName"
        "C:\Program Files (x86)\$ProgramFolderName"
    )

    foreach ($ProgramFolderPath in $ProgramFolderPaths) {
        $Path = Join-Path $ProgramFolderPath $ExeName
        if (Test-Path $Path) {
            return $Path
        }
    }

    # Fall back to checking on PATH...
    try {
        $command = Get-Command $ExeName -ErrorAction Stop
        return $command.Source
    } catch {
        throw "Cannot find $ExeName!"
    }
}

function Get-PlinkExePath {
    Get-ExePath -ProductCode "{45B3032F-22CC-40CD-9E97-4DA7095FA5A2}" -ExeName "plink.exe" -ProgramFolderName "PuTTY"
}

function Get-WiresharkExePath {
    Get-ExePath -ProductCode "Wireshark" -ExeName "wireshark.exe" -ProgramFolderName "Wireshark"
}

function Invoke-SSHWireshark {
    [cmdletbinding()]
    Param(
        [parameter(Mandatory = $true)]
        [string]$ComputerName,

        [parameter(Mandatory = $false)]
        [uint16]$Port,

        [parameter(ParameterSetName='PasswordAuth', Mandatory = $true)]
        [System.Net.NetworkCredential]$Credential = $null,

        [parameter(ParameterSetName='KeyAuth', Mandatory = $true)]
        [string]$UserName,

        [parameter(Mandatory = $true)]
        [string]$Command,

        [parameter(Mandatory = $false)]
        [string]$Stdin = $null
    )

    try {
        $Activity = "Capturing packets over SSH. Press Ctrl+C to stop."

        $PlinkArguments = "-v -batch -ssh $(_Quote $ComputerName)"
        switch ($PSCmdlet.ParameterSetName) {
            'KeyAuth' {
                $PlinkArguments += " -l $(_Quote $UserName)"
            }
            'PasswordAuth' {
                $PlinkArguments += " -l $(_Quote $Credential.UserName) -pw $(_Quote $Credential.Password)"
            }
        }
        if ($PSBoundParameters.ContainsKey('Port')) {
            $PlinkArguments += " -P $Port"
        }
        $PlinkArguments += " $(_Quote $Command)"

        $Plink_Process = [System.Diagnostics.Process]@{
            StartInfo = [System.Diagnostics.ProcessStartInfo]@{
                UseShellExecute        = $false
                FileName               = Get-PlinkExePath
                RedirectStandardOutput = $true
                RedirectStandardInput  = $true
                RedirectStandardError  = $true
                Arguments              = $PlinkArguments
            }
        }

        $Wireshark_Process = [System.Diagnostics.Process]@{
            StartInfo = [System.Diagnostics.ProcessStartInfo]@{
                UseShellExecute       = $false
                FileName              = Get-WiresharkExePath
                RedirectStandardInput = $true
                Arguments             = '-k -i -'
            }
        }

        if (-not $Plink_Process.Start()) {
            throw 'Error starting plink'
        }

        if (-not $Wireshark_Process.Start()) {
            throw 'Error starting wireshark'
        }

        $PlinkIn = $Plink_Process.StandardInput
        $PlinkOutStream = $Plink_Process.StandardOutput.BaseStream
        $PlinkErrorStreamReader = $Plink_Process.StandardError
        $WiresharkInStream = $Wireshark_Process.StandardInput.BaseStream

        $PlinkOutReadBuffer = [System.Array]::CreateInstance([byte], 65536)

        $TotalBytes = 0

        $PlinkStdoutReadTask = $null
        $PlinkStdoutReading = $true

        $PlinkStderrReadTask = $null
        $PlinkStderrReading = $true

        if ($Stdin) {
            $PlinkIn.Write($Stdin)
        }

        do {
            Write-Progress -Activity $Activity -Status "Captured $TotalBytes bytes"

            $Tasks = @()

            # Dispatch tasks if neccessary

            if ($PlinkStdoutReading) {
                if ($PlinkStdoutReadTask -eq $null) {
                    $PlinkStdoutReadTask = $PlinkOutStream.ReadAsync($PlinkOutReadBuffer, 0, $PlinkOutReadBuffer.Length)
                }
                $Tasks += @($PlinkStdoutReadTask)
            }

            if ($PlinkStderrReading) {
                if ($PlinkStderrReadTask -eq $null) {
                    $PlinkStderrReadTask = $PlinkErrorStreamReader.ReadLineAsync()
                }
                $Tasks += @($PlinkStderrReadTask)
            }

            # Wait for a task to complete            
            # The 100 ms timeout here is to avoid a deadlock where Ctrl+C is never handled in case
            # plink for som reason never produces data (for example, by the user specifying a capture
            # filter that matches no packets...
            
            $CompletedTaskIndex = [System.Threading.Tasks.Task]::WaitAny($Tasks, 100)
            
            if ($CompletedTaskIndex -ge 0) {
                switch ($Tasks[$CompletedTaskIndex]) {
                    $PlinkStdoutReadTask {
                        $Bytes = $PlinkStdoutReadTask.Result
                        $PlinkStdoutReadTask = $null
                        if ($bytes -gt 0) {
                            $TotalBytes += $bytes
                            $WiresharkInStream.Write($PlinkOutReadBuffer, 0, $bytes)
                            $WiresharkInStream.Flush()
                        } else {
                            # 0 bytes read from Plink stdout... so no point reading any more...
                            #write-host "stdout eof"
                            $PlinkStdoutReading = $false
                        }
                    }

                    $PlinkStderrReadTask {
                        $Line = $PlinkStderrReadTask.Result
                        $PlinkStderrReadTask = $null
                        if ($Line -ne $null) {
                            $Line
                        } else {
                            # null read from Plink stderr... so no point reading any more...
                            #write-host "stderr eof"
                            $PlinkStderrReading = $false
                        }
                    }
                }
            }
        } while ($PlinkStdoutReading -or $PlinkStderrReading)
    } catch {
        $_
    } finally {
        #write-host "cleaning up..."
        try { $Plink_Process.Kill() } catch {}
        try { $Wireshark_Process.StandardInput.BaseStream.Close() } catch {}
        Write-Progress -Activity $Activity -Completed
    }
}