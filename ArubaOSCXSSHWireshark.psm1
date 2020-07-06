function Invoke-ArubaOSCXSSHWireshark {
    [cmdletbinding()]
    Param(
        [parameter(Mandatory = $true)]
        [string]$ComputerName,

        [parameter(ParameterSetName='PasswordAuth', Mandatory = $true)]
        [System.Net.NetworkCredential]$Credential = $null,

        [parameter(ParameterSetName='KeyAuth', Mandatory = $true)]
        [string]$UserName,

        [parameter(Mandatory = $false)]
        [string]$Expression
    )
    
    Process {
        $Command = "start-shell"
        $Stdin = "sudo ip netns exec mirror_ns tcpdump -Un -i MirrorRxNet -w - $Expression`r`n"

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
        Invoke-SSHWireshark -ComputerName $ComputerName -Command $Command -Stdin $Stdin @AuthParams
    }
}
