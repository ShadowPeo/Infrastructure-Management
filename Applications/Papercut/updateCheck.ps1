$PaperCutServerAddress = "<<SERVER>>:<<PORT>>"
$PaperCutServerAuthKey = "<<APIKEY>>"
$PaperCutEdition = "<<EDITION>>" #NG or MF

$temp = ((ConvertFrom-JSON(Invoke-WebRequest -Uri "$PaperCutServerAddress/api/health/application-server?Authorization=$PaperCutServerAuthKey")).systemInfo.version)
$PCVersion, $PCBuild = $null
$PCVersion = $temp.SubString(0,($temp.IndexOf(" ")))
$PCBuild = $temp.SubString(($temp.LastIndexOf(" ")+1),(($temp.Length) - ($temp.LastIndexOf(" "))-2))


$releases=[System.Collections.ArrayList] (Invoke-RestMethod -Uri "http://www.papercut.com/products/$($PaperCutEdition.ToLower())/release-history.atom" | Sort-Object published -Descending)

$currentRelease = $null

for ($i=0;$i-lt $releases.count; $i++)
{
    $release = $null
    $release = $releases[$i]
    if ($currentRelease -eq $null -or ((([DateTime]$release.published).ToString('yyyy-MM-dd')) -ge ([DateTime]$currentRelease.published).ToString('yyyy-MM-dd')))
    {
        Write-Host ([DateTime]$release.published).ToString('yyyy-MM-dd')
        $currentRelease = $release
    }
    else 
    {
        $releases.Remove($release)
    }

}

