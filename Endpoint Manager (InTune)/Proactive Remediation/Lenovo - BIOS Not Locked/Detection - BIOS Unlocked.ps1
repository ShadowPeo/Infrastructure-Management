if ((((gwmi -Class Lenovo_BIOSPasswordSettings -Namespace root\wmi).PasswordState) -eq 0) -and (((gwmi -class Lenovo_BiosSetting -namespace root\wmi | Where-Object {$_.CurrentSetting.split(",",[StringSplitOptions]::RemoveEmptyEntries) -eq "LockBIOSSetting"}).CurrentSetting.Split(",")[1]) -eq "Disable") )
{
    exit 1
}
else
{
    exit 0
}