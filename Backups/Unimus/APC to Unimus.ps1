$unimusURL = "<<UNIMUS_URL>>" #URL to Unimus install
$APIKey = "<<APIKEY>>" #API Key for Unimus Install
$deviceConfig = "$PSScriptRoot/scp.csv" #Path to the device config path

function Write-Log ($logMessage)
{
    Write-Host "$(Get-Date -UFormat '+%Y-%m-%d %H:%M:%S') - $logMessage"
}

$checkURL=$unimusURL.Substring((Select-String 'http[s]:\/\/' -Input $unimusURL).Matches[0].Length)

if ($checkURL.IndexOf('/') -eq -1)
{
    #Test ICMP connection
    if ((Test-Connection -TargetName $checkURL))
    {
        Write-Log "Successfully to Unimus server at address $checkURL"
    }
    else 
    {
        Write-Log "Cannot connect to Unimus server at address $checkURL exiting"
        exit
    }
}

#Check Putty SCP exists, if not attempt to download it
if (-not (Test-Path "$PSScriptRoot/pscp.exe" -PathType Leaf))
{
    Write-Log "PSCP not found, downloading"
    try
    {
        Invoke-WebRequest -Uri "https://the.earth.li/~sgtatham/putty/latest/w64/pscp.exe" -OutFile "$PSScriptRoot/pscp.exe" | Out-Null
    }
    catch
    {
        $_.Exception.Response.StatusCode.Value__
    }
}
else 
{
    Write-Log "PSCP Found, Continuing"
}

#Check if temporary folder exists, if not create it
if (-not (Test-Path "$PSScriptRoot/Temp" -PathType Container))
{
    Write-Log "Temporary Directory not found, creating"
    try
    {
        New-Item -Path "$PSScriptRoot" -Name "Temp" -ItemType Directory | Out-Null
    }
    catch
    {
        Write-Log $_.Exception.Response
    }
}
else 
{
    Write-Log "Temporary Directory Found, Continuing"
}

#Import Device CSV
$devices = Import-CSV $deviceConfig

#Iterate through each device from the CSV
foreach ($device in $devices)
{
    #Set Device Address to be the same as device name if no address is specified
    if([string]::IsNullOrWhiteSpace($device.Address))
    {
        $device.Address = $deviceName
    }

    $useNameResolution = $false
    $fileName = ([System.IO.FileInfo]$device.Path).Name

    #Check Device can be connected to before continuing
    if ((Test-Connection -TargetName $device.Address))
    {
        Write-Log "Successfully to device at address $($device.Address)"
    }
    else 
    {

        if ($device.Address -ne $device.Name)
        {
            Write-Log "Cannot connect to device at address $($device.Address), trying DNS Resolution on name ($($device.Name))"
            
            if ((Test-Connection -TargetName $device.Name))
            {
                Write-Log "Successfully to device at address $($device.Name)"
                $useNameResolution = $true
            }
            else 
            {
                Write-Log "Cannot connect to device at address $($device.Address) or $($device.Name) and the name and address match, skipping"
                continue
            }
        }
        else 
        {
            Write-Log "Cannot connect to device at address $($device.Address) and the name and address match, skipping"
            continue
        }
    }

    #Try to get the record from Unimus
    try
    {
        $unimusDeviceRecord = Invoke-WebRequest -Uri "$unimusURL/api/v2/devices/findByAddress/$($device.Address)" -Headers @{  "Authorization"="Bearer $APIKey" }
        Write-Log "Successfully found device in Unimus"
    }
    catch 
    {
        
        if ($_.Exception.Response.StatusCode.Value__ -eq "404")
        {
            Write-Log "No Device in Unimus, Attempting to create new device"
            try
            {
                $recordCreation = (Invoke-WebRequest -Uri "$unimusURL/api/v2/devices" -Headers @{  "Authorization"="Bearer $APIKey" } -Method Post -ContentType "application/json" -Body "{`"address`":`"$($device.Address)`",`"description`":`"$($device.Name)`"}").Content
                $unimusDeviceRecord = Invoke-WebRequest -Uri "$unimusURL/api/v2/devices/findByAddress/$($device.Address)" -Headers @{  "Authorization"="Bearer $APIKey" }
            }
            catch 
            {
                Write-Log $_.Exception
                continue
            }

        }
        else 
        {
            Write-Log $_.Exception.Response.StatusCode.Value__
        }
    }
    
    $unimusDeviceRecord = (ConvertFrom-Json ($unimusDeviceRecord.Content)).data

    if (-not $useNameResolution)
    {
        if ($device.Protocol -eq "SCP")
        {
            & "$PSScriptRoot\pscp.exe"  -q -batch -pw "$($device.Password)" -scp "$($device.Username)@$($device.Address):$($device.Path)" "`"$PSScriptRoot\Temp\$fileName`""
        }
        elseif  ($device.Protocol -eq "SFTP")
        {
            & "$PSScriptRoot\pscp.exe"  -q -batch -pw "$($device.Password)" -sftp "$($device.Username)@$($device.Address):$($device.Path)" "`"$PSScriptRoot\Temp\$fileName`""
        }
    }
    else 
    {
        if ($device.Protocol -eq "SCP")
        {
            & "$PSScriptRoot\pscp.exe" -q -batch -pw "$($device.Password)" -scp "$($device.Username)@$($device.Name):$($device.Path)" "`"$PSScriptRoot\Temp\$fileName`"" 
        }
        elseif  ($device.Protocol -eq "SFTP")
        {
            & "$PSScriptRoot\pscp.exe" -q -batch -pw "$($device.Password)" -sftp "$($device.Username)@$($device.Name):$($device.Path)" "`"$PSScriptRoot\Temp\$fileName`"" 
        }
    }
    
    #Process retrieved backup
    $fileTemp = $null # clear temporary file
    $fileTemp = Get-Content "$PSScriptRoot\Temp\$fileName" #Get the file contents for processing
    
    #Process File based upon the processor setting
    switch($device.Processor)
    {
        "APC"
            {
                $fileTemp[4] = $null #Blank 5th line so that it does not force the storage of backups only because of export date
            }

    }

    if ($device.Type = "Text")
    {
        @("#BEGIN") + $fileTemp + @("#END") | Set-Content "$PSScriptRoot\Temp\$fileName" #Add The begin and end codes to the data, put the data back into the file
    }

    Pause
    
    #Pull the encoded config as a bytestream, convert it to Base64
    $encodedConfig = [Convert]::ToBase64String((Get-Content -path "$PSScriptRoot\Temp\$fileName" -AsByteStream)) 

    #Submit the Backup to Unimus
    try
    {
        $tempBackup = $null
        $tempBackup = Invoke-WebRequest -Uri "$unimusURL/api/v2/devices/$($unimusDeviceRecord.id)/backups" -Headers @{  "Authorization"="Bearer $APIKey" } -Method Post -ContentType "application/json" -Body "{`"backup`":`"$encodedConfig`",`"type`":`"$($device.Type.ToUpper())`"}"
        if ($tempBackup.StatusCode -eq 200)
        {
            Write-Log "Backup of $($device.Name) at address $($device.Address) successful"
        }
        else 
        {
            Write-Log "Backup of $($device.Name) at address $($device.Address) returned unexpected result"
            Write-Log $tempBackup.Content
        }
        
    }
    catch 
    {
        Write-Log $_.Exception
        continue
    }

    #Cleanup temporary config file
    if (Test-Path "$PSScriptRoot\Temp\$fileName" -PathType Leaf)
    {
        Write-Log "Removing Temporary Config File"
        try
        {
            Remove-Item -Path "$PSScriptRoot\Temp\$fileName" | Out-Null
        }
        catch
        {
            Write-Log $_.Exception.Response
        }
    }
}