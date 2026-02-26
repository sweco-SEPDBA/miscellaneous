Patch with dbatools
$UserName = Get-Credential -Message "Add your _da credentials"
$PathCU = "\\sestofs311\Program\DA\APPLIK\SwecoSQLPatches\MS SQL Current version"
# $VersionCU = "2017CU31" OR NEXT ROW
$kb = 'KB5065225'
$ServerName = "EETLLBS005.sweco.se\EESQL32P" #Can be one instance or a list of servers

#Update-DbaInstance -ComputerName $ServerName -Restart -Version $VersionCU -Path $PathCU -Credential $UserName -Confirm:$false
Update-DbaInstance -ComputerName $ServerName -Restart -KB $kb -Path $PathCU -Credential $UserName -Confirm:$false

Update-DbaBuildReference