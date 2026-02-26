
#########################################################
# Add-SwInstanceChange

$SqlInstance = 'SESTOAS017.sweco.se\SESQL44P'
$Signature = "SEPDBA"
$ChangeDescription = "Low privileged user deleted"
$SNOWTicket = ""
$MD_Message =  @"
# User group deleted
BUILTIN\Users group has been deleted from the SQL Server instance.
"@
$Message = $MD_Message | ConvertFrom-Markdown | Select-Object -ExpandProperty Html
Add-SwInstanceChange -SqlInstance $SqlInstance -Signature $Signature -ChangeDescription $ChangeDescription -ChangeNote $Message -SNOWTicket $SNOWTicket

