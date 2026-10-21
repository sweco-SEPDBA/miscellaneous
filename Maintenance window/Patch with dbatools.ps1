#Patch with dbatools
$UserName = Get-Credential -Message "Add your _da credentials"
$PathCU = "\\sestofs311\Program\DA\APPLIK\SwecoSQLPatches\MS SQL Current version"
# $VersionCU = "2017CU31" OR NEXT ROW
$kb = 'KB5102337' #2017
$kb = 'KB5102335' #2019
#$ServerName = "SEDCXDS901.sweco.se\SWERP07PC","SEDCXDS902.sweco.se\SWERP07PC","SEDCXDS903.sweco.se\SWERP07PC" #Can be one instance or a list of servers
#$ServerName = 'SESTODS058\CMS02'
#$ServerName = 'SESTOK1DS001\SESCCM01T'

#Prepare security
Enable-WSManCredSSP -Role Client -DelegateComputer SESTODS111.sweco.se
Enable-WSManCredSSP -Role Client -DelegateComputer NOOSLDS002.sweco.se
Enable-WSManCredSSP -Role Client -DelegateComputer SESDLDS002.sweco.se
Enable-WSManCredSSP -Role Client -DelegateComputer SESTOAS568.sweco.se
Enable-WSManCredSSP -Role Client -DelegateComputer SESTODS052.sweco.se
Enable-WSManCredSSP -Role Client -DelegateComputer SESTODS111.sweco.se


#Settings
$UserName = Get-Credential -Message "Add your _da credentials"
$PathCU = "\\sestofs311\Program\DA\APPLIK\SwecoSQLPatches\MS SQL Current version"
# Patches 2017
$kb = 'KB5128496' # 2017
$ServerName = 'SESTODS040.sweco.se\SWSQL19P', 'SESTODS042.sweco.se\SWSQL22P' #'SESTODS039.sweco.se\SWSQL16P', 
# Patches 2019
$kb = 'KB5128494' # 2019
$ServerName = 'SESTODS043.sweco.se\SWSCOM02P' #Servers with 2019
# Patches 2022
$kb = 'KB5126934' # 2022
$ServerName =  #Servers with 2022
# Patches 2025
$kb = 'KB5126967' # 2025
$ServerName =  #Servers with 2025
Update-DbaInstance -ComputerName $ServerName -Restart -KB $kb -Path $PathCU -Credential $UserName -Confirm:$false



# $ServerName = 'NOOSLDS002.sweco.se\NOSQL21P', 'SESTOAS568.sweco.se\SQLEXPRESS', 'SESTODS052.sweco.se\AUTODESKVAULT'
# $ServerName = 'NOOSLDS002.sweco.se\NOSQL22P', 'SESDLDS002.sweco.se\SESQL41P', 'SESTOAS568.sweco.se\SWSQL32P', 'SESTODS052.sweco.se\SWSQL28P', 'SESTODS052.sweco.se\SWSQL29P'

#Update-DbaInstance -ComputerName $ServerName -Restart -Version $VersionCU -Path $PathCU -Credential $UserName -Confirm:$false
Update-DbaInstance -ComputerName $ServerName -Restart -KB $kb -Path $PathCU -Credential $UserName -Confirm:$false

Update-DbaBuildReference 


# $UserName = Get-Credential -Message "Add your _da credentials"
# $PathCU = "\\sestofs311\Program\DA\APPLIK\SwecoSQLPatches\MS SQL Current version"
# $VersionCU = "2017CU31" #OR $kb = KBXXXXXXXX
# $ServerName = "MyServer1.sweco.se\MyInstance1", "MyServer2.sweco.se\MyInstance2"

# Update-DbaInstance -ComputerName $ServerName -Restart -Version $VersionCU -Path $PathCU -Credential $UserName -Confirm:$false
# # or Update-DbaInstance -ComputerName $ServerName -Restart -KB $kb -Path $PathCU -Credential $UserName -Confirm:$false

# Enable-WSManCredSSP -Role Client -DelegateComputer SESTOK1DS001.sweco.se