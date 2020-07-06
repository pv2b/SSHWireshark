enum PktcapUWCaptureDirection {
    In = 0
    Out = 1
    Both = 2
}

function _NormalizeUUID {
    Param($UUID)
    $NormalizedUUID = $UUID.ToLower() -replace '[^0-9a-f]'
    if ($NormalizedUUID.Length -ne 32) {
        throw '$UUID is not a valid UUID!'
    } else {
        $NormalizedUUID
    }
}

function Invoke-VsphereSSHWireshark {
    [cmdletbinding()]
    Param(
        [parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [VMware.VimAutomation.Types.NetworkAdapter]$VMNetworkAdapter,

        [parameter(ParameterSetName='PasswordAuth', Mandatory = $true)]
        [System.Net.NetworkCredential]$Credential,

        [parameter(ParameterSetName='KeyAuth', Mandatory = $false)]
        [string]$UserName = 'root',

        [parameter(Mandatory = $false)]
        [switch]$Uplink = $false,

        [parameter(Mandatory = $false)]
        [PktcapUWCaptureDirection]$Direction = 'Both',

        [parameter(Mandatory = $false)]
        [System.Net.Sockets.ProtocolType]$Protocol,

        [parameter(Mandatory = $false)]
        [uint16]$SourcePort,

        [parameter(Mandatory = $false)]
        [uint16]$DestinationPort,

        [parameter(Mandatory = $false)]
        [uint16]$TCPPort,

        [parameter(Mandatory = $false)]

        [ValidatePattern('^([0-9a-f]{2}:){5}[0-9a-f]{2}$')]
        [string]$SourceMac,

        [parameter(Mandatory = $false)]
        [ValidatePattern('^([0-9a-f]{2}:){5}[0-9a-f]{2}$')]
        [string]$DestinationMac,

        [parameter(Mandatory = $false)]
        [ValidatePattern('^([0-9a-f]{2}:){5}[0-9a-f]{2}$')]
        [string]$Mac,

        [parameter(Mandatory = $false)]
        [system.net.ipaddress]$SourceIP,

        [parameter(Mandatory = $false)]
        [system.net.ipaddress]$DestinationIP,

        [parameter(Mandatory = $false)]
        [system.net.ipaddress]$IP


    )
    
    Process {
        $VM = $VMNetworkAdapter.Parent
        $VMHost = $VM.VMhost
        $VMView = Get-View $VM
        $VMUUID = _NormalizeUUID $VMView.Config.UUID

        $MacAddress = $VMNetworkAdapter.MacAddress

        $EsxCli = Get-EsxCli -V2 -VMHost $VMHost
        $VMProcess = $EsxCli.vm.process.list.invoke() | Where { (_NormalizeUUID $_.UUID) -eq $VMUUID }
        $VMPort = $esxcli.network.vm.port.list.invoke(@{worldid=($VMProcess.WorldID)}) | Where MACAddress -eq "$MacAddress"

        $PktcapUWCommand = "pktcap-uw"
        if ($Uplink) {
            $PktcapUWCommand += " --uplink $($VMPort.TeamUplink)"
        } else {
            $PktcapUWCommand += " --switchport $($VMPort.PortID)"
        }

        $PktcapUWCommand += " --dir $([int]$Direction)"

        if ($PSBoundParameters.ContainsKey('Protocol')) {
            $PktcapUWCommand += ' --proto 0x{0:x2}' -f [int]$Protocol
        }

        if ($PSBoundParameters.ContainsKey('SourcePort')) {
            $PktcapUWCommand += " --srcport $SourcePort"
        }

        if ($PSBoundParameters.ContainsKey('DestinationPort')) {
            $PktcapUWCommand += " --dstport $DestinationPort"
        }

        if ($PSBoundParameters.ContainsKey('TCPPort')) {
            $PktcapUWCommand += " --tcpport $TCPPort"
        }


        if ($PSBoundParameters.ContainsKey('SourceMac')) {
            $PktcapUWCommand += " --srcmac $SourceMac"
        }
        if ($PSBoundParameters.ContainsKey('DestinationMac')) {
            $PktcapUWCommand += " --dstmac $DestinationMac"
        }
        if ($PSBoundParameters.ContainsKey('Mac')) {
            $PktcapUWCommand += " --mac $Mac"
        }

        if ($PSBoundParameters.ContainsKey('SourceIP')) {
            $PktcapUWCommand += " --srcip $SourceIP"
        }
        if ($PSBoundParameters.ContainsKey('DestinationIP')) {
            $PktcapUWCommand += " --dstip $DestinationIP"
        }
        if ($PSBoundParameters.ContainsKey('IP')) {
            $PktcapUWCommand += " --ip $IP"
        }

        $PktcapUWCommand += " -o -"

        # Do not refactor this to use _GetCommonSSHParameters, since this cmdlet determines
        # ComputerName etc from the vCenter server. (Ideally we'd like to somehow authenticate
        # without requiring host creds...)
        $AuthParams = @{}
        switch ($PSCmdlet.ParameterSetName) {
            'KeyAuth' {
                if ($PSBoundParameters.ContainsKey('UserName')) {
                    $AuthParams['UserName'] = $UserName
                }
            }
            'PasswordAuth' {
                if ($PSBoundParameters.ContainsKey('Credential')) {
                    $AuthParams['Credential'] = $Credential
                }
            }
        }
        Invoke-SSHWireshark -ComputerName $VMHost.Name -Command $PktcapUWCommand @AuthParams
    }
}
