
Get-ADGroupMember -identity "SW-SSO-Azure-RedgateMonitor_Users" | 
select-object name, samaccountname | 
format-table

Get-ADGroup -Identity "SW-SSO-Azure-RedgateMonitor_Users" 

Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'SW-ROLE-SQLAdmin'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'SEPDBA'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'SENEKU'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'DKIVER'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'DKSTET'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'SE1B3Y'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'DKIAIM'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'SEOETT'
Add-ADGroupMember -Identity 'SW-SSO-Azure-RedgateMonitor_Users' -Members 'BEVERB'