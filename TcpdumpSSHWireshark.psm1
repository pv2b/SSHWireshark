function Invoke-TcpdumpSSHWireshark {
    [cmdletbinding()]
    Param(
        [parameter(Mandatory = $true)]
        [string]$ComputerName,

        [parameter(ParameterSetName='PasswordAuth', Mandatory = $true)]
        [System.Net.NetworkCredential]$Credential = $null,

        [parameter(ParameterSetName='KeyAuth', Mandatory = $true)]
        [string]$UserName,

        [parameter(Mandatory = $true)]
        [string]$Interface,

        [parameter(Mandatory = $false)]
        [string]$Expression
    )
    
    Process {
        # TODO Add escaping...
        # -U for unbuffered output from tcpdump
        # -n to disable name resolution
        # -i to choose interface
        # -w - to write to stdout
        $Command = "tcpdump -Un -i $Interface -w - $Expression"


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
        $Command
        Invoke-SSHWireshark -ComputerName $ComputerName -Command $Command @AuthParams
    }
}
