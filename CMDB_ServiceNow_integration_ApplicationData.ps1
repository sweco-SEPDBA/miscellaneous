
$snowacc = "api_db"
$snowpw = "tQwPP[mzN,C_S,!45}H="

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $snowacc, $snowpw)))
$headers = @{
    "Authorization" = "Basic $auth";
    "Accept"        = "application/json";
    "Content-Type"  = "application/json"
}


# Specify endpoint uri
#$uri = "https://sweco.service-now.com/api/now/table/cmdb_ci_appl?sysparm_limit=1&name=3D%20Analyst"
$uri = " https://sweco.service-now.com/api/now/table/cmdb_ci_appl?sysparm_limit=3000"
# Specify HTTP method
$method = "get"
# Send HTTP request
$response = Invoke-RestMethod -Headers $headers -Method $method -Uri $uri

$result = $response.result
$result.Count
$dbtable = $result | ForEach-Object {

    
      
    ## SML
    try
    {
      $SML=''
      $SML_Team=''
      $SML = Invoke-RestMethod -Method GET -Uri $_.u_sml.link -Headers $headers
      $SML_Team = Invoke-RestMethod -Method GET -Uri $SML.result.u_team.link -Headers $headers
    }
    catch
    {
        write-host "No SML Assigned"
    }
    
    ## manufacturer

    try
    {

        $manufacturer = ''
        $manufacturer = Invoke-RestMethod -Method GET -Uri $_.manufacturer.link -Headers $headers
    
    }
    catch 
    {
        write-host "No manufacturer"
    }


    # Finding contacts for the application
    try
    {
      $IT_Contact = ''
      $IT_Contact = Invoke-RestMethod -Method GET -Uri $_.u_it_contact.link -Headers $headers
      $ITContact_Team = Invoke-RestMethod -Method GET -Uri $IT_Contact.result.u_team.link -Headers $headers
    }
    catch
    {
        write-host "No IT contact"
    }

    # Finding Support Group
    try
    {
    $supportTeam = ''
    $supportGroup = Invoke-RestMethod -Method GET -Uri $_.support_group.link -Headers $headers
    write-host $supportGroup.result
    }
    catch 
    {
    write-host "No support Group"
    }




    # Business Service
    try
    {
        $Business_Service =''
        $Business_Service = Invoke-RestMethod -Method GET -Uri $_.u_business_service.link -Headers $headers
    }
    catch 
    {
        write-host "No Business Service"
    }
    
    # Country
    try
    {
      $Country_id = ''
      $Country_id=$_.u_used_in_the_following_countries
      
    } 
    catch 
    {

      write-host "No Countries specified"

    }

    $used_countries =$Country_id| out-string       
    
          
    $cmdbprop = [pscustomobject]@{
    Description = $_.short_description
    ApplicationName = $_.name
    Application_Sysid = $_.sys_id
    SupportGroup = $supportGroup.result.name
    Business_Service = $Business_Service.result.name
    manufacturer = $manufacturer.result.name
    Hosted = $_.u_hosted
    ITContact = $IT_Contact.result.name
    ITContact_UserID = $IT_Contact.result.user_name
    ITContact_Sysid = $IT_Contact.result.sys_id
    ITContact_Team = $ITContact_Team.result.u_name
    SML = $SML.result.name
    SML_UserID = $SML.result.user_name
    SML_Sysid = $SML.result.sys_id
    SML_Team = $SML_Team.result.u_name
    SML_Team_Sysid = $SML_Team.result.sys_id    
    used_countries=$used_countries
    Environment = $_.used_for
    }


  $cmdbprop | SELECT Application_Sysid,ApplicationName,Hosted,Description,SupportGroup,manufacturer,Business_Service,Environment,ITContact,ITContact_UserID,ITContact_Sysid,ITContact_Team,SML,SML_UserID,SML_Sysid,SML_Team,SML_Team_Sysid,used_countries
  #$cmdbobj = $cmdbprop | SELECT Application_Sysid,ApplicationName,Hosted,Description,SupportGroup,manufacturer,Business_Service,Environment,ITContact,ITContact_UserID,ITContact_Sysid,ITContact_Team,SML,SML_UserID,SML_Sysid,SML_Team,SML_Team_Sysid,used_countries
    
    #$cmdbobj = New-Object -TypeName PSObject -Property $cmdbprop

  #Write-DbaDbTableData -SqlInstance "SWSQL16P.sql.sweco.se" -Database "CMDB" -Schema "dbo" -Table "CMDB_Ci_Application_Stage" -AutoCreateTable -InputObject $cmdbobj 

}
Write-DbaDbTableData -SqlInstance "SWSQL16P.sql.sweco.se" -Database "CMDB" -Schema "dbo" -Table "CMDB_Ci_Application_Stage" -AutoCreateTable -InputObject $dbtable -Truncate

