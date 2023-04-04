#Enable ICMP Echo
Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In
Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-Out
Enable-NetFirewallRule -Name FPS-ICMP6-ERQ-In
Enable-NetFirewallRule -Name FPS-ICMP6-ERQ-Out

#Enable SMB
Set-NetFirewallRule FPS-SMB-In-TCP -Enabled True

#Disable IE Enchanced Security Mode for Administrators
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0

#Enable Remote Management Functions
Enable-NetFirewallRule -Name ComPlusNetworkAccess-DCOM-In  
Enable-NetFirewallRule -Name ComPlusRemoteAdministration-DCOM-In
Enable-NetFirewallRule -DisplayGroup "Remote Event Log Management"
Enable-NetFirewallRule -DisplayGroup "Windows Management Instrumentation (WMI)"

#Enable RDP
Set-ItemProperty ‘HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\‘ -Name “DenyTSConnections” -Value 0
Set-ItemProperty ‘HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp\‘ -Name “UserAuthentication” -Value 1
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

#Set Correct Timezone
Set-TimeZone -Name "AUS Eastern Standard Time"

#Set NTP Peers
net stop w32time
w32tm /config /syncfromflags:manual /manualpeerlist:"10.124.224.137 10.124.224.138 time.education.vic.gov.au"
net start w32time
w32tm /config /update
w32tm /resync /rediscover

#Set NTP Firewall Rules if Server
New-NetFirewallRule -DisplayName "NTP Server - Inbound" -Direction Inbound -LocalPort 123 -Protocol UDP -Action Allow -Profile Any
New-NetFirewallRule -DisplayName "NTP Server - Outbound" -Direction Outbound -LocalPort 123 -Protocol UDP -Action Allow -Profile Any

#Remote IIS Management Enablement
    ##Install on Local Machine
    https://www.microsoft.com/en-us/download/details.aspx?id=41177

    ##On Remote Machine
        Install-WindowsFeature Web-Mgmt-Service
        netsh advfirewall firewall add rule name="IIS Remote Management" dir=in action=allow service=WMSVC
        reg add HKLM\SOFTWARE\Microsoft\WebManagement\Server /t REG_DWORD /v EnableRemoteManagement /d 1 /f
        Set-Service WMSVC -StartupType Automatic
        Start-Service WMSVC




#Enable PS Remoting
Enable-PSRemoting
#Set-Item WSMan:\localhost\Client\TrustedHosts -Value "SVR-HV01"
#Enable-WSManCredSSP -Role client -DelegateComputer "SVR-HV01"

#Enable SNMP with WMI
Install-WindowsFeature "SNMP-Service","RSAT-SNMP" -IncludeAllSubFeature
    #Set SNMP Hosts
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities" /v "7893Read" /t REG_DWORD /d 4 /f | Out-Null #Read Only
    #reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\SNMP\Parameters\ValidCommunities" /v "7893Read" /t REG_DWORD /d 8 /f | Out-Null #Read/Write

#NIC SET Teaming for Hyper-V
New-VMSwitch -Name "External" -NetAdapterName "Card - Left","Card - Right" -AllowManagementOS $false

## WSUS Update IIS site RAM/Connections


## Get UUID
wmic csproduct get "UUID"

##Change UUID on VM - Run from host

[CmdletBinding()]
param
(
    [String]$VMName = "3432SDC02"
)
if((Get-VM $VMName).State -eq 'Running')
{
    Stop-VM -Name $VMName
}
$VMMS = gwmi -Namespace root\virtualization\v2 -Class msvm_virtualsystemmanagementservice
$ModifySystemSettingsParams = $VMMS.GetMethodParameters('ModifySystemSettings')
$VMObject = gwmi -Namespace root\virtualization\v2 -Class msvm_computersystem -Filter "ElementName = '$VMName'"
$CurrentSettingsDataCollection = $VMObject.GetRelated('msvm_virtualsystemsettingdata')
$GUID = [System.Guid]::NewGuid()

$CurrentSettingsData = $null
foreach($SettingsObject in $CurrentSettingsDataCollection)
{
    $CurrentSettingsData = [System.Management.ManagementObject]$SettingsObject
}
Write-Host ('Old GUID: {0}' -f $CurrentSettingsData.BIOSGUID)
$CurrentSettingsData['BIOSGUID'] = "{$($GUID.Guid.ToUpper())}"
Write-Host ('New GUID: {0}' -f $CurrentSettingsData.BIOSGUID)
$ModifySystemSettingsParams['SystemSettings'] = $CurrentSettingsData.GetText([System.Management.TextFormat]::CimDtd20)
$VMMS.InvokeMethod('ModifySystemSettings', $ModifySystemSettingsParams, $null)