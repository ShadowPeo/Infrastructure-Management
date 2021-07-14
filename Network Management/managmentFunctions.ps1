$siteDomain = $env:USERDNSDOMAIN







<#Param
{
    
}#>

function addDeviceRecord ($dchpScope, $dhcpAddress, $dnsName, $deviceMAC, $dhcpDescription)
{
    if (($dhcpDescription -eq $null)-or($dhcpDescription -eq ""))
    {
        $dhcpDescription = "Reservation for $dnsName"
    }

    $tempDNS = Get-DnsServerResourceRecord -ComputerName "$siteDNSServer.$siteDomain" -ZoneName $siteDomain -Name $dnsName | Out-Null

    if ($tempDNS -ne $null)
    {
        Remove-DnsServerResourceRecord -ComputerName "$siteDNSServer.$siteDomain" -Name $dnsName -ZoneName $siteDomain -RRType "A" -Force
        
    }
    Add-DhcpServerv4Reservation -ComputerName "$siteDHCPServer.$siteDomain" -ScopeId $dchpScope -IPAddress $dhcpAddress -Name "$dnsName.$siteDomain" -ClientId $deviceMAC -Description $dhcpDescription
    Add-DnsServerResourceRecordA -ComputerName "$siteDNSServer.$siteDomain" -Name $dnsName -ZoneName $siteDomain -IPv4Address $dhcpAddress -TimeToLive 01:00:00 -CreatePtr
    

}


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
}