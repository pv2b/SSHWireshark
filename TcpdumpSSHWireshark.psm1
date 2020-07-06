Import-Module $PSScriptRoot\CommonSSHParameters.psm1

function Invoke-TcpdumpSSHWireshark {
    [cmdletbinding()]
    Param(
        [parameter(Mandatory = $true)]
        [string]$Interface,

        [parameter(Mandatory = $false)]
        [string]$Expression
    )

    Dynamicparam {
        _AddCommonSSHParameters
    }
    
    Process {
        # TODO Add escaping...
        # -U for unbuffered output from tcpdump
        # -n to disable name resolution
        # -i to choose interface
        # -w - to write to stdout
        $Command = "tcpdump -Un -i $Interface -w - $Expression"

        $CommonSSHParameters = _GetCommonSSHParameters -CallerPSBoundParameters $PSBoundParameters
        Invoke-SSHWireshark -Command $Command @CommonSSHParameters
    }
}
