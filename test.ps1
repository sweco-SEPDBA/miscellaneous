
Get-DbaDatabase -SqlInstance CZPRGAS001.sweco.se -ExcludeSystem -ExcludeDatabase maintenance | Select-Object SqlInstance, Name, Status, SizeMB | Out-GridView 


