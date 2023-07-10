if (((gwmi -Class Lenovo_BIOSPasswordSettings -Namespace root\wmi).PasswordState) -eq 0)
{
    exit 1
}
else 
{
    exit 0
}