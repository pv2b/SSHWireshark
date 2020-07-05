# SSHWireshark
Packet capture on remote hosts through SSH, view packets live in wireshark!

Currently supports the following over SSH:

- tcpdump
- VMware vSphere (pktcap-uw, requires PowerCli)
- generic (create your own command line)

For specific options, read the fine source code. :-)

# Usage

See examples below:

## Generic SSH

```powershell
$c = Get-Credential
Invoke-SSHWireshark -Credential $c -ComputerName 10.0.10.1 -Command "tcpdump -Un -i em0_vlan10 -w -"
```

## tcpdump

```powershell
$c = Get-Credential
Invoke-TcpdumpSSHWireshark -ComputerName 10.0.10.1 -Credential $c -Interface em0_vlan10 -Expression "host 10.0.10.17"
```

## vSphere

```powershell
Connect-VIServer vcenter.example.com
$VMHostSSHCredential = Get-Credential
Get-VM my-virtual-machine | Get-NetworkAdapter | Invoke-VsphereSSHWireshark -Credential $VMHostSSHCredential
```

## ArubaOS-CX

For this one, you'll need to set up a mirroring session on the switch with CPU destination...

For example:

```
mirror session 1
    destination cpu
    source interface lag2 both
```Then you can do:```powershell$c = Get-Credential
Invoke-ArubaOSCXSSHWireshark -Credential $c -ComputerName 192.0.2.129 -Expression icmp
```