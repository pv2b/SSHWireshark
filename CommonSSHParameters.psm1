function _AddCommonSSHParameters {
    Param($ParamDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new())

    $parameter = [System.Management.Automation.RuntimeDefinedParameter]::new(
        'ComputerName',
        [String],
        [Attribute[]]@(
            [Parameter]@{
                Mandatory = $true
            }
        )
    )
    $paramDictionary.Add($parameter.Name, $parameter)

    $parameter = [System.Management.Automation.RuntimeDefinedParameter]::new(
        'Credential',
        [System.Net.NetworkCredential],
        [Attribute[]]@(
            [Parameter]@{
                Mandatory = $true
                ParameterSetName = 'PasswordAuth'
            }
        )
    )
    $paramDictionary.Add($parameter.Name, $parameter)

    $parameter = [System.Management.Automation.RuntimeDefinedParameter]::new(
        'UserName',
        [String],
        [Attribute[]]@(
            [Parameter]@{
                Mandatory = $true
                ParameterSetName = 'KeyAuth'
            }
        )
    )
    $paramDictionary.Add($parameter.Name, $parameter)

    $parameter = [System.Management.Automation.RuntimeDefinedParameter]::new(
        'Port',
        [uint16],
        [Attribute[]]@(
            [Parameter]@{
                Mandatory = $false
            }
        )
    )
    $paramDictionary.Add($parameter.Name, $parameter)

    return $paramDictionary
}

$CommonSSHParameterNames = (_AddCommonSSHParameters).Keys

function _GetCommonSSHParameters {
    Param($CallerPSBoundParameters)
    
    $CommonSSHParameters = @{}
    foreach ($Key in $CommonSSHParameterNames) {
        if ($CallerPSBoundParameters.ContainsKey($Key)) {
            $CommonSSHParameters[$Key] = $CallerPSBoundParameters[$Key]
        }
    }

    return $CommonSSHParameters
}
