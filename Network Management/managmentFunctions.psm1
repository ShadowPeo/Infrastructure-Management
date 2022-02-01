
#Confirm that the IP Address is Valid
function Confirm-IPAddress
{
    Param 
    (
    
        [Parameter(Mandatory=$true)][string]$ip

    )

    if ([ipaddress]::TryParse($ip,[ref][ipaddress]::Loopback))
    {
        return $ip
    }
    else 
    {
        throw [System.Exception] "IP Address is Invalid"
    }


}

#Get the Network address of the current IP, it can also be used for DHCP scoping
function Get-NetworkAddress
{
    Param 
    (
    
        [Parameter(Mandatory=$true)][ipaddress]$ip, 
        [Parameter(Mandatory=$true)][ipaddress]$subnet

    )
    
    $ip = Confirm-IPAddress $ip
    $subnet = Confirm-IPAddress $subnet

    return ([ipaddress]($ip.address -band $subnet.address)).IPAddressToString

}

function Convert-MACAddress
{
    Param 
    (
    
        [Parameter(Mandatory=$true)][string]$MACAddress
    
    )

    $MACAddress = $MACAddress.ToLower() # Convert whole thing to lower

    $MACAddress = $MACAddress.Trim().Replace(':','').Replace('.','').Replace('-','').Replace(' ','') #Trim any leading or trailing whitespace and replace seperators

    #Check that the MAC address is the correct length (12 Characters), if not throw error
    if ($MACAddress.Length -eq 12)
    {
        #Check that the MAC Address matches the regex validating for hexadecimals, if not throw error
        if ($MACAddress -match '((\d|([a-f]|[A-F])){2}){6}')
        {
            return $MACAddress
        }
        else 
        {

            throw [System.Exception] "Invalid Characters in MAC Address Field, There needs to be 12 Hexadecimal Characters"

        }

    }
    else 
    {

        throw [System.Exception] "Not Enough Characters in MAC Address Field, There needs to be 12 Hexadecimal Characters"

    }
    
}

function Register-DeviceRecord
{
    Param 
    (
    
        [Parameter(Mandatory=$true,HelpMessage="IP Address of the device you want to add a reservation for")][ipaddress]$deviceIP,
        [Parameter(Mandatory=$true,HelpMessage="Subnet of the device you want to add a reservation for")][ipaddress]$deviceSubnet,
        [Parameter(Mandatory=$true,HelpMessage="Name of the device you want to add a reservation for")][string]$deviceName,
        [Parameter(Mandatory=$true,HelpMessage="MAC Address of the device you want to add a reservation for")][string]$deviceMAC,
        [string]$deviceDescription,
        [string]$deviceDomain,
        [ipaddress]$deviceDHCPServer,
        [ipaddress]$deviceDNSServer,
        [switch]$leaveExistingDNS,
        [switch]$leaveExistingForwardDNS,
        [switch]$leaveExistingReverseDNS
    
    )

    #Set default device description if none was provided
    if (($deviceDescription -eq $null)-or($deviceDescription -eq ""))
    {
        $deviceDescription = "Reservation for $deviceName"
    }

    #Set Domain to local domain if none specified
    if (($deviceDomain -eq $null) -or ($deviceDomain -eq ""))
    {
        $deviceDomain = $env:USERDNSDOMAIN
    }

    #Add DHCP Reservation

    if ($deviceDHCPServer -ne "" -and $null -ne $deviceDHCPServer)
    {
        Add-DhcpServerv4Reservation -ComputerName $deviceDHCPServer -ScopeId (Get-NetworkAddress $deviceIP $deviceSubnet) -IPAddress $deviceIP -Name "$deviceName.$deviceDomain" -ClientId (Convert-MACAddress $deviceMAC) -Description "$deviceDescription"
    }
    else 
    {
        Add-DhcpServerv4Reservation -ScopeId (Get-NetworkAddress $deviceIP $deviceSubnet) -IPAddress $deviceIP -Name "$deviceName.$deviceDomain" -ClientId (Convert-MACAddress $deviceMAC) -Description "$deviceDescription"
    }


    #Removing Existing Forward DNS if required
    if (!$leaveExistingForwardDNS -and !$leaveExistingDNS)
    {
        try
        {
            $tempDNSForward = @(Get-DnsServerResourceRecord -ComputerName $deviceDNSServer -ZoneName $deviceDomain -Name $deviceName)


            if ($tempDNSForward.Count -gt 0)
            {
                foreach($forwardRecord in $tempDNSForward)
                {
                    Remove-DnsServerResourceRecord -ComputerName $deviceDNSServer -ZoneName $deviceDomain -Name $deviceName -RRType $forwardRecord.RecordType -Force
                    Write-Host "Removing Forward Record for $deviceName on $((($forwardRecord.RecordData).IPv4Address).IPAddressToString)"
                }
            }
        }
        catch
        {


        }

    }

    #Removing Existing Reverse DNS if required
    if (!$leaveExistingReverseDNS -and !$leaveExistingDNS)
    {
        try
        {
            
            $ipArray = ($deviceIP.ToString()).split(".")
            $tempDNSReverse = @(Get-DnsServerResourceRecord -ComputerName $deviceDNSServer -ZoneName ("$($ipArray[2]).$($ipArray[1]).$($ipArray[0]).in-addr.arpa") -Name $ipArray[3])

            if ($tempDNSReverse.Count -gt 0)
            {
                $removedReverseRecords = @()
                foreach($reverseRecord in $tempDNSReverse)
                {
                    if ($removedReverseRecords -notcontains $ipArray[3])
                    {
                        Remove-DnsServerResourceRecord -ComputerName $deviceDNSServer -ZoneName ("$($ipArray[2]).$($ipArray[1]).$($ipArray[0]).in-addr.arpa") -Name $ipArray[3] -RRType "Ptr" -Force
                        $removedReverseRecords += $ipArray[3]
                        Write-Host "Removing Reverse Record for $((($reverseRecord.RecordData).PtrDomainName).Substring(0,(($reverseRecord.RecordData).PtrDomainName).Length-1)) on $deviceIP"
                    }
                }
            }
        }
        catch
        {


        }

    }

    #Add DNS Address
    if ($deviceDNSServer -ne "" -and $null -ne $deviceDNSServer)
    {
        Add-DnsServerResourceRecordA -ComputerName $deviceDNSServer -Name $deviceName -ZoneName $deviceDomain -IPv4Address $deviceIP -TimeToLive 01:00:00 -CreatePtr
    }
    else 
    {
        Add-DnsServerResourceRecordA -Name $deviceName -ZoneName $deviceDomain -IPv4Address $deviceIP -TimeToLive 01:00:00 -CreatePtr
    }

}


function Register-Printer
{
    
    Param 
    (
    
        [Parameter(Mandatory=$true)][ipaddress]$deviceIP,
        [Parameter(Mandatory=$true)][string]$deviceName,
        [ipaddress]$deviceSubnet,
        [string]$deviceMAC,
        [string]$deviceDescription,
        [string]$deviceDomain,
        [ipaddress]$deviceDHCPServer,
        [ipaddress]$deviceDNSServer,
        [switch]$leaveExistingDNS,
        [switch]$leaveExistingForwardDNS,
        [switch]$leaveExistingReverseDNS,
        
        #Printer Specific Information
        [Parameter(Mandatory=$true)][ipaddress]$devicePrintServer,
        [Parameter(Mandatory=$true)][string]$printerLocation,
        [Parameter(Mandatory=$true)][string]$printerSNMPCommunity,
        [Parameter(Mandatory=$true)][string]$printerDriver,
        [string]$printerShareName,
        #[string]$driverFolder,
        [string]$printerLPRQueue,
        #[switch]$installDriver,
        [switch]$printerLPR,
        [switch]$noDNS = $false,
        [switch]$noDHCP = $false
    
    )

 
    if (($printerShareName -eq $null)-or($printerShareName -eq ""))
    {
        $printerShareName = $deviceName
    }
<#    
    if (($printerSNMPCommunity -eq $null) -or ($printerSNMPCommunity -eq ""))
    {
        $printerSNMPCommunity = "public"
    }

    
    Add-PrinterPort -ComputerName "$sitePrinterServer.$siteDomain" -PrinterHostAddress "$printerDNSAddress.$siteDomain" -SNMP 1 -SNMPCommunity $printerSNMPCommunity -Name $printerDNSName
    Add-Printer -ComputerName "$sitePrinterServer.$siteDomain" -Name $printerShareName -DriverName $printerDriver -port $printerDNSName -Shared -ShareName $printerShareName –Published  -RenderingMode SSR -Location $printerLocation#>
}