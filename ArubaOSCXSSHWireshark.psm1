Import-Module $PSScriptRoot\CommonSSHParameters.psm1

function Invoke-ArubaOSCXSSHWireshark {
    [cmdletbinding()]
    Param(
        [parameter(Mandatory = $false)]
        [string]$Expression
    )

    Dynamicparam {
        _AddCommonSSHParameters
    }
    
    Process {
        $Command = "start-shell"
        $Stdin = "sudo ip netns exec mirror_ns tcpdump --immediate-mode -Un -i MirrorRxNet -w - $Expression`r`n"

        $CommonSSHParameters = _GetCommonSSHParameters -CallerPSBoundParameters $PSBoundParameters
        Invoke-SSHWireshark -Command $Command -Stdin $Stdin @CommonSSHParameters
    }
}
