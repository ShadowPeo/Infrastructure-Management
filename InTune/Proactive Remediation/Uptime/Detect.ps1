# Detection
try {

    $uptime = ((get-date) - (gcim Win32_OperatingSystem).LastBootUpTime).Days
    
    # evaluate the compliance
    if ($uptime -le 7) {

        Write-Host "Uptime is acceptable"
        exit 0
    }
    else {
        Write-Host "Uptime is greater than a week"
        exit 1
    }
   
    
}
catch {
    $errMsg = _.Exception.Message
    Write-Host $errMsg
    exit 1
}