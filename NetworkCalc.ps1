
function Test-IPv4inCidr {
    [cmdletBinding(DefaultParameterSetName = 'fromCidr')]
    Param(
        [Parameter(Mandatory = $true)]
        [System.Net.IPAddress]
        $ip,
        [parameter(ParameterSetName = 'fromCidrInfo', Mandatory = $true)]
        [PSTypeName('IPv4CidrInfo')]
        $IPv4CidrInfo,
        [parameter(ParameterSetName = 'fromCidr', Mandatory = $true)]
        [ValidatePattern("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$")]
        $cidr
    )
    begin {
        if ($PSCmdlet.ParameterSetName -eq 'fromCidr') {
            $IPv4CidrInfo = Get-IPv4CidrInfo -cidr $cidr
        }
    }
    process {
        if (($ip.Address -band $IPv4CidrInfo.NetworkMask.Address) -eq ($IPv4CidrInfo.NetworkIP.Address -band $IPv4CidrInfo.NetworkMask.Address)) {
            return $true
        }
        else {
            return $false
        }
    }
    
}

function Get-IPv4CidrInfo {
    [cmdletBinding()]
    Param(
        [ValidatePattern("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$")]
        $cidr
    )

    "Working on $ip and $cidr" | Write-Debug
    #separate Ip from cidr notation
    $NetWorkAddress = [ipaddress]($cidr -split '\/')[0] 
    "$NetWorkAddress is the given Network address" | Write-Debug

    #separate network bit length from cidr notation
    $NetbitLength = [int]($cidr -split '\/')[1]
    "$NetbitLength is the given NetbitLength" | Write-Debug

    #creating binary representation of the network mask
    $binMask = '1'.PadLeft($NetbitLength,'1').PadRight(32,'0')
    "$binMask is the binary representation of the subnet mask" | Write-Debug
    
    #creating decimal representatin of the network mask: i.e. 255.255.255.128
    $subnetMask  = [ipaddress]([System.Net.IPAddress]"$([System.Convert]::ToInt64($binMask,2))").IPAddressToString
    "$($subnetMask.IPAddressToString) is the Subnet Mask for bitlenghth of $NetbitLength" | Write-Debug
    
    #calculating Wildcard mask: 255.255.255.255 - subnet mask
    $wildcardmask = [ipaddress]((([ipaddress]'255.255.255.255').Address) - ($subnetMask.Address))
    "$wildcardmask is the wildcard mask" | Write-Debug

    #calculating expected network address from given network address {binary and operator} calculated subnet mask
    $expectedNetAddr = [ipaddress]($NetWorkAddress.Address -band $subnetMask.Address)
    "$expectedNetAddr is the expected Network Address" | Write-Debug
    
    #calculating Broadcast address
    $broadcastAddr = [ipaddress]($NetWorkAddress.Address -bor $wildcardmask.Address)
    "$broadcastAddr is the broadcast Address" | Write-Debug

    #calculating last adress by substracting 1 to the last octet
    $broadcastBytes = $broadcastAddr.GetAddressBytes()
    $broadcastBytes[3] -= 1
    $lastAddress = [ipaddress]$broadcastBytes
    "$lastAddress is the last Address of the range" | Write-Debug

    #calculating first adress by adding 1 to the last octet
    $NetworkBytes = $NetWorkAddress.GetAddressBytes()
    $NetworkBytes[3] += 1
    $firstAddress = [ipaddress]$NetworkBytes
    "$firstAddress is the first Address of the range" | Write-Debug

    #the expected network address should be the same as the given one. Warn if not
    if($NetWorkAddress -ne $expectedNetAddr) {
        "The network $networkAddress is incorrect, should be $($expectedNetAddr)" | Write-Warning
    }

    #Returning the given cidr but the expected (true) Network mask
    Write-Output ([PSCustomObject]@{
                PSTypeName = 'IPv4CidrInfo'
                'cidr' = $cidr
                'NetBitLength' = $NetbitLength
                'NetworkMask' = $subnetMask
                'wildcardMask' = $wildcardMask
                'NetworkIP' = $expectedNetAddr
                'firstIPinRange' = $firstAddress
                'lastIPinRange' = $lastAddress
                'broadcast' = $broadcastAddr
            } | Tee-Object -Variable Output)
    
    "`r`n$(($output | Out-String).Trim())`r`n" | Write-Verbose
}

Function Get-NicIpInIPv4Network {
    Param (
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $true)]
        [ValidatePattern("^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$")]
        $cidr,
        [Parameter(ValueFromPipelineByPropertyName = $true, Mandatory = $false)]
        [System.Net.NetworkInformation.PrefixOrigin[]]
        $PrefixOrigin = @([System.Net.NetworkInformation.PrefixOrigin]::Dhcp,[System.Net.NetworkInformation.PrefixOrigin]::Manual)
    )
    Begin {
        $localIPs = Get-NetIPAddress -Type Unicast -AddressFamily IPv4 -PrefixOrigin $PrefixOrigin
    }

    process {
        foreach ($cidrItem in $cidr)
        {
          foreach ($ip in $localIPs.IPAddress) {
            "--> Testing against ip $ip for CIDR $cidrItem" | Write-Verbose
            if (Test-IPv4inCidr -ip $ip -cidr $cidrItem) {
                Write-Output ([PSCustomObject]@{
                    PSTypeName='IPinNetwork'
                    'IPAddress' = $ip
                    'Network' = $_
                })
            }
          }
        }
    }
}

