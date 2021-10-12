
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

function addDeviceRecord
{
    Param 
    (
    
        [Parameter(Mandatory=$true)][ipaddress]$deviceIP,
        [Parameter(Mandatory=$true)][ipaddress]$deviceSubnet,
        [Parameter(Mandatory=$true)][string]$deviceName,
        [Parameter(Mandatory=$true)][string]$deviceMAC,
        [string]$deviceDescription,
        [string]$deviceDomain,
        [ipaddress]$deviceDHCPServer,
        [ipaddress]$deviceDNSServer,
        [switch]$LeaveExistingDNS
    
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
        #Add-DhcpServerv4Reservation -ComputerName $deviceDHCPServer -ScopeId (Get-NetworkAddress $deviceIP $deviceSubnet) -IPAddress $deviceIP -Name "$deviceName.$deviceDomain" -ClientId (Convert-MACAddress $deviceMAC) -Description "`"$deviceDescription`""
    }
    else 
    {
        #Add-DhcpServerv4Reservation -ScopeId (Get-NetworkAddress $deviceIP $deviceSubnet) -IPAddress $deviceIP -Name "$deviceName.$deviceDomain" -ClientId (Convert-MACAddress $deviceMAC) -Description $deviceDescription
    }

    #Removing Existing DNS if required
    if (!$LeaveExistingDNS)
    {
        try
        {
            $tempDNS = @(Get-DnsServerResourceRecord -ComputerName $deviceDNSServer -ZoneName $deviceDomain -Name $deviceName)
            Write-Host $tempDNS

            if ($null -ne $tempDNS)
            {
                Remove-DnsServerResourceRecord -ComputerName $deviceDNSServer -ZoneName $deviceDomain -Name $deviceName -RRType "A" -Force
                Write-Host "Removing Existing DNS"
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

<#
function addPrinter ($printerDNSAddress, $printerDNSName, $printerShareName, $printerLocation, $printerSNMPCommunity, $printerDriver)
{
    if (($printerShareName -eq $null)-or($printerShareName -eq ""))
    {
        $printerShareName = $printerDNSName
    }

    if (($printerSNMPCommunity -eq $null)-or($printerSNMPCommunity -eq ""))
    {
        $printerSNMPCommunity = "public"
    }

    
    Add-PrinterPort -ComputerName "$sitePrinterServer.$siteDomain" -PrinterHostAddress "$printerDNSAddress.$siteDomain" -SNMP 1 -SNMPCommunity $printerSNMPCommunity -Name $printerDNSName
    Add-Printer -ComputerName "$sitePrinterServer.$siteDomain" -Name $printerShareName -DriverName $printerDriver -port $printerDNSName -Shared -ShareName $printerShareName –Published  -RenderingMode SSR -Location $printerLocation
}#>