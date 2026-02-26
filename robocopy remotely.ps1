

$creds =Get-Credential -Credential "SWECO\sepdba" 
$SourceFolder = "\\sestofs311\koncern\Komm\Restore\sestods012"
$TargetFolder = "\\Sestofs010\projekt\96514\10000217_Database_Archive\000_Database_Archive\Data\DSSTH003"

#Mount drive. Persist makes it a windows drive. So only one letter name.
New-PSDrive -Name R -PSProvider FileSystem -Root $SourceFolder -Credential $creds -Persist
New-PSDrive -Name u -PSProvider FileSystem -Root $TargetFolder -Persist

#robocopy <source> <destination> <filename>
robocopy Q: U: /s *.bak





#Some usefull commands
##################################################


#Test the mounted drive
Get-ChildItem Z:

#List mounted drives
Get-PSDrive

#Remove the share again
Remove-PSDrive R
