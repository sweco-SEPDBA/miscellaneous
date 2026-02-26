
########################################################################
# Change this vaiables
$SqlInstance = "DEFRADS013.sweco.se\DESQL16P"
$MD_Message =  @"
## HR software Sage in Germany
- New 2025
- Replaces DEFRADS003
"@

#Then run this
$Message = $MD_Message | ConvertFrom-Markdown | Select-Object -ExpandProperty Html
$query = @"
insert into dbo.Notes (Note)
				values ('$Message')
update Instance set NotesId = SCOPE_IDENTITY() where SqlInstance = '$SqlInstance'
"@
Invoke-DbaQuery -SqlInstance SESTODS039.sweco.se\SWSQL16P -Database CMDB -Query $query    
#######################################################################################

###########################################################################################################################

# Change this vaiables
$SqlInstance = "NLAMSPS014.sweco.se\SAFECOMEXPRESS"
$MD_Message =  @"
## Safecom Print server 
- New 2025
"@

#Then run this
$Message = $MD_Message | ConvertFrom-Markdown | Select-Object -ExpandProperty Html
$query = @"
UPDATE Notes 
    SET (Note = '$Message'
    FROM 
        Instance i
        INNER JOIN Notes n ON i.NotesId = n.NotesId
    WHERE i.SqlInstance = '$SqlInstance'
"@
Invoke-DbaQuery -SqlInstance SESTODS039.sweco.se\SWSQL16P -Database CMDB -Query $query    
#######################################################################################
