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

        # --immediate-mode
        #      Capture  in  "immediate mode".  In this mode, packets are deliv-
        #      ered to tcpdump as  soon  as  they  arrive,  rather  than  being
        #      buffered  for  efficiency.   This  is  the default when printing
        #      packets rather than saving packets  to  a  ``savefile''  if  the
        #      packets are being printed to a terminal rather than to a file or
        #      pipe.
        # -U for unbuffered output from tcpdump
        # -n to disable name resolution
        # -i to choose interface
        # -w - to write to stdout
        $Command = "tcpdump --immediate-mode -Un -i $Interface -w - $Expression"

        $CommonSSHParameters = _GetCommonSSHParameters -CallerPSBoundParameters $PSBoundParameters
        Invoke-SSHWireshark -Command $Command @CommonSSHParameters
    }
}
