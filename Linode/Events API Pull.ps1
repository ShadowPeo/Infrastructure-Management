#Settings
$linodeAPIKey = "<<APIKEY>>"

##### Build Headers
$headers=@{}
$headers.Add("Accept", "application/json")
$headers.Add("Authorization", "Bearer $linodeAPIKey")

$events = (ConvertFrom-Json ((Invoke-WebRequest -Uri "https://api.linode.com/v4/account/events" -Method GET -Headers $headers).Content)).data
foreach ($event in $events)
{
    $eventDetails = $null
    $eventDetails = (ConvertFrom-Json ((Invoke-WebRequest -Uri "https://api.linode.com/v4/account/events/$($event.id)" -Method GET -Headers $headers).Content))
    

    #Extract Primary Entity details if they exist
    if ($event.entity -ne $null -and $event.entity -ne "")
    {
        $entityDetails = $event.entity
    }

    #Extract Secondary Entity details if they exist
    if ($event.secondary_entity -ne $null -and $event.secondary_entity -ne "")
    {
        $entityDetails2 = $event.secondary_entity
    }

    
    
    
    if($event.message -ne $null -and $event.message -ne "")
    {
        Write-Host "$((Get-Date $event.created -Format "yyyy-MM-dd HH:mm")) - Linode reported a $($event.message) on by user $($event.username)"
        pause
    }
    

    
}