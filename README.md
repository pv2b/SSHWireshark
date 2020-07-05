# SSHWireshark
Packet capture on remote hosts through SSH, view packets live in wireshark!

Currently supports the following over SSH:

- tcpdump
- VMware vSphere (pktcap-uw, requires PowerCli)
- generic (create your own command line)

# Usage

See examples below:

```powershell
$c = Get-Credential
Invoke-SSHWireshark -Credential $c -ComputerName 10.0.10.1 -Command "tcpdump -Un -i em0_vlan10 -w -"
```

```powershell
$c = Get-Credential
Invoke-TcpdumpSSHWireshark -ComputerName 10.0.10.1 -Credential $c -Interface em0_vlan10 -Expression "host 10.0.10.17"
```

```powershell
Connect-VIServer vcenter.example.com
$VMHostSSHCredential = Get-Credential
Get-VM my-virtual-machine | Get-NetworkAdapter | Invoke-VsphereSSHWireshark -Credential $VMHostSSHCredential -Direction Both
```
