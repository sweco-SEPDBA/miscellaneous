USE SwecoAccess;
GO
EXEC sp_addpublication @publication = N'SwecoAccessPublication'--, @publisher = N'SWSQL06PL.sweco.se', @status = N'active';
GO

-- Lägg till artiklar till publikation
EXEC sp_addarticle @publication = N'SwecoAccessPublication', @article = N'addonoptions', @source_owner = N'dbo', @source_object = N'addonoptions', @type = N'logbased';
GO
EXEC sp_addarticle @publication = N'SwecoAccessPublication', @article = N'roleAssignments', @source_owner = N'dbo', @source_object = N'roleAssignments', @type = N'logbased';
GO
EXEC sp_addarticle @publication = N'SwecoAccessPublication', @article = N'roleDescriptions', @source_owner = N'dbo', @source_object = N'roleDescriptions', @type = N'logbased';
GO

USE SwecoCore;
GO
EXEC sp_addpublication @publication = N'SwecoCorePublication', @allow_pull = N'true', @independent_agent = N'true'--, @publisher = N'SWSQL06PL.sweco.se', @publication_type = N'transactional', @status = N'active';
GO


EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'Employee', @source_owner = N'CoreData', @source_object = N'Employee', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmpManagerCategory', @source_owner = N'CoreData', @source_object = N'EmpManagerCategory', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'Employee_UserAccountType', @source_owner = N'CoreData', @source_object = N'Employee_UserAccountType', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmployeeAccess', @source_owner = N'CoreData', @source_object = N'EmployeeAccess', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmployeeDeviatingManager', @source_owner = N'CoreData', @source_object = N'EmployeeDeviatingManager', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmployeeEmailAddress', @source_owner = N'CoreData', @source_object = N'EmployeeEmailAddress', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmployeeLegalTeam', @source_owner = N'CoreData', @source_object = N'EmployeeLegalTeam', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmployeeLegalTeamFutureChanges', @source_owner = N'CoreData', @source_object = N'EmployeeLegalTeamFutureChanges', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmployeeManager', @source_owner = N'CoreData', @source_object = N'EmployeeManager', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmployeeOperatingTeam', @source_owner = N'CoreData', @source_object = N'EmployeeOperatingTeam', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmployeePersonal', @source_owner = N'CoreData', @source_object = N'EmployeePersonal', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmployeePhoneNumber', @source_owner = N'CoreData', @source_object = N'EmployeePhoneNumber', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmployeeVendor', @source_owner = N'CoreData', @source_object = N'EmployeeVendor', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmployeeWorkRatio', @source_owner = N'CoreData', @source_object = N'EmployeeWorkRatio', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'Employment', @source_owner = N'CoreData', @source_object = N'Employment', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmploymentFutureChanges', @source_owner = N'CoreData', @source_object = N'EmploymentFutureChanges', @type = N'logbased';

EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmpStatus', @source_owner = N'CoreData', @source_object = N'EmpStatus', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'LangLanguage', @source_owner = N'CoreData', @source_object = N'LangLanguage', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'LocCountry', @source_owner = N'CoreData', @source_object = N'LocCountry', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'LocOfficeAddress', @source_owner = N'CoreData', @source_object = N'LocOfficeAddress', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'OrgBusinessArea', @source_owner = N'CoreData', @source_object = N'OrgBusinessArea', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'OrgBusinessUnit', @source_owner = N'CoreData', @source_object = N'OrgBusinessUnit', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'OrgCompany', @source_owner = N'CoreData', @source_object = N'OrgCompany', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'OrgDepartment', @source_owner = N'CoreData', @source_object = N'OrgDepartment', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'OrgDivision', @source_owner = N'CoreData', @source_object = N'OrgDivision', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'OrgTeam', @source_owner = N'CoreData', @source_object = N'OrgTeam', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'OrgTeamManager', @source_owner = N'CoreData', @source_object = N'OrgTeamManager', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'OrgUnitLevel', @source_owner = N'CoreData', @source_object = N'OrgUnitLevel', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'subcategory', @source_owner = N'CoreData', @source_object = N'subcategory', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmployeeFunction', @source_owner = N'dbo', @source_object = N'EmployeeFunction', @type = N'logbased';

EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'CategoryType', @source_owner = N'CoreData', @source_object = N'CategoryType', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'Category', @source_owner = N'CoreData', @source_object = N'Category', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'OrgTeamBudgetType', @source_owner = N'CoreData', @source_object = N'OrgTeamBudgetType', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'OrgCompanyImport', @source_owner = N'CoreData', @source_object = N'OrgCompanyImport', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmpUserAccountType', @source_owner = N'CoreData', @source_object = N'EmpUserAccountType', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmpJobClassification', @source_owner = N'CoreData', @source_object = N'EmpJobClassification', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmpJobFunction', @source_owner = N'CoreData', @source_object = N'EmpJobFunction', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmploymentContractSubType', @source_owner = N'CoreData', @source_object = N'EmploymentContractSubType', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmpPricingCategory', @source_owner = N'CoreData', @source_object = N'EmpPricingCategory', @type = N'logbased';
EXEC sp_addarticle @publication = N'SwecoCorePublication', @article = N'EmpEducationLevel', @source_owner = N'CoreData', @source_object = N'EmpEducationLevel', @type = N'logbased';
