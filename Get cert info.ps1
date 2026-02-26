
# Get-DbaComputerCertificate -ComputerName SESTODS050.sweco.se 

# Get-DbaNetworkCertificate -SqlInstance sestods050.sweco.se\swsql02d

# get-dbainstanceproperty -SqlInstance sestods050.sweco.se\swsql02d 

$SqlInstanceCmdb = "SESTODS039.sweco.se\SWSQL16P"
$Database = "CMDB"


# $username = "SqlAdmin"
# $pwdTxt = Get-Content "C:\Scripts\CMDB\DmzPass.txt"
# $password = $pwdTxt | ConvertTo-SecureString 
# $SqlCredentials_dmz =  New-Object System.Management.Automation.PSCredential -ArgumentList ($username, $password)


#Region ActiveDbs except DMZ

$SqlInstanceCmdb = "SESTODS039.sweco.se\SWSQL16P"
$Database = "CMDB"

$Cmd = @"
SELECT
	i.SqlInstance,
	i.CmsServerName
FROM
	[Server] s 
	INNER JOIN Instance i ON s.ServerId = i.ServerId
WHERE
	s.IsServer = 1 
	AND i.IsActive = 1
    AND s.InDmz = 0
ORDER BY SqlInstance
"@
$instances = Invoke-DbaQuery -SqlInstance $SqlInstanceCmdb -Query $Cmd -Database $Database | select-object -expandproperty CmsServerName

$a = foreach ($instance in $instances) {
    write-host "Collecting data from: $instance" -ForegroundColor Cyan
    #Get-DbaInstanceProperty -SqlInstance $instance -InstanceProperty VersionMajor, VersionMinor, BuildNumber, VersionString, Edition, Collation, PhysicalMemory, Processors, OSVersion  | Select-Object @{n = 'CmsServerName'; e = { $instance}}, Name, Value
    Get-DbaNetworkCertificate -SqlInstance  $instance
}

$result = $a | ForEach-Object {
    [pscustomobject]@{
		ComputerName = $_.ComputerName
		InstanceName = $_.InstanceName
		ForceEncryption = $_.ForceEncryption
		FriendlyName = $_.FriendlyName
		DnsNameList = ($_.DnsNameList -join ', ')  # Join ArrayList to a comma-separated string
		Expires = $_.Expires
		IssuedTo = $_.IssuedTo
		IssuedBy = $_.IssuedBy
    }
}

$result | Export-Excel -Path C:\Temp\Certs_202601.xlsx
$result | Measure-Object 
# $Cmd = @"
# SELECT
# 	i.SqlInstance,
# 	i.CmsServerName
# FROM
# 	[Server] s 
# 	INNER JOIN Instance i ON s.ServerId = i.ServerId
# WHERE
# 	s.IsServer = 1 
# 	AND i.IsActive = 1
#     AND s.InDmz = 1
# ORDER BY SqlInstance
# "@
# $instances = Invoke-DbaQuery -SqlInstance $SqlInstanceCmdb -Query $Cmd -Database $Database | select-object -expandproperty CmsServerName


# $SqlCredentials_dmz = Get-Credential -UserName "SqlAdmin" -Message "Enter password for SqlAdmin"

# $a = foreach ($instance in $instances) {
#     write-host "Collecting data from: $instance" -ForegroundColor Cyan
#     #Get-DbaInstanceProperty -SqlInstance $instance -InstanceProperty VersionMajor, VersionMinor, BuildNumber, VersionString, Edition, Collation, PhysicalMemory, Processors, OSVersion  | Select-Object @{n = 'CmsServerName'; e = { $instance}}, Name, Value
#     Get-DbaNetworkCertificate -SqlInstance  $instance -Credential $SqlCredentials_dmz
# }

# $a | Out-GridView
