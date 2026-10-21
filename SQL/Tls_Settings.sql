DECLARE @value int
DECLARE @key VARCHAR(100)
DECLARE @Protocol_status varchar(20)

DECLARE @RegistryKey varchar(70)
--PCT Protocols
DECLARE @RegistryKeyPCT10 varchar(10)
--SSL Protocols
DECLARE @RegistryKeySSL20 varchar(10)
DECLARE @RegistryKeySSL30 varchar(10)
-- TLS protocols
DECLARE @RegistryKeyTLS10 varchar(10)
DECLARE @RegistryKeyTLS11 varchar(10)
DECLARE @RegistryKeyTLS12 varchar(10)
DECLARE @RegistryKeyTLS13 varchar(50)


DECLARE @RegistryKeyServer varchar(10)
DECLARE @RegistryKeyClient varchar(10)

SET @RegistryKey = 'SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols'

SET @RegistryKeyPCT10 = 'PCT 1.0'

SET @RegistryKeySSL20 = 'SSL 2.0'
SET @RegistryKeySSL30 = 'SSL 3.0'

SET @RegistryKeyTLS10 = 'TLS 1.0'
SET @RegistryKeyTLS11 = 'TLS 1.1'
SET @RegistryKeyTLS12 = 'TLS 1.2'
SET @RegistryKeyTLS13 = 'SYSTEM\CurrentControlSet\Services\HTTP\Parameters'



SET @RegistryKeyServer = 'Server'
SET @RegistryKeyClient = 'Client'

CREATE TABLE #result
(
	Protocol_version varchar(10),
	Protocol_function varchar(10),
	Enabled_Disabled varchar(20),
	Protocol_value varbinary(max),
	Protocol_status varchar (20)

)

-- Search for PCT 1.0
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyPCT10+'\'+@RegistryKeyServer
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'Enabled', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyPCT10,@RegistryKeyServer,'Enabled',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyPCT10+'\'+@RegistryKeyServer
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'DisabledByDefault', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyPCT10,@RegistryKeyServer,'DisabledByDefault',@value,@Protocol_status)

SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyPCT10+'\'+@RegistryKeyClient
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'Enabled', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyPCT10,@RegistryKeyClient,'Enabled',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyPCT10+'\'+@RegistryKeyClient
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'DisabledByDefault', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyPCT10,@RegistryKeyClient,'DisabledByDefault',@value,@Protocol_status)





-- Search for SSL 2.0
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeySSL20+'\'+@RegistryKeyServer
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'Enabled', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeySSL20,@RegistryKeyServer,'Enabled',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeySSL20+'\'+@RegistryKeyServer
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'DisabledByDefault', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeySSL20,@RegistryKeyServer,'DisabledByDefault',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeySSL20+'\'+@RegistryKeyClient
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'Enabled', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeySSL20,@RegistryKeyClient,'Enabled',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeySSL20+'\'+@RegistryKeyClient
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'DisabledByDefault', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeySSL20,@RegistryKeyClient,'DisabledByDefault',@value,@Protocol_status)
-- Search for SSL 3.0 
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeySSL30+'\'+@RegistryKeyServer
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'Enabled', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeySSL30,@RegistryKeyServer,'Enabled',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeySSL30+'\'+@RegistryKeyServer
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'DisabledByDefault', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeySSL30,@RegistryKeyServer,'DisabledByDefault',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeySSL30+'\'+@RegistryKeyClient
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'Enabled', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeySSL30,@RegistryKeyClient,'Enabled',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeySSL30+'\'+@RegistryKeyClient
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'DisabledByDefault', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeySSL30,@RegistryKeyClient,'DisabledByDefault',@value,@Protocol_status)









-- Search for TLS 1.0
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyTLS10+'\'+@RegistryKeyServer
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'Enabled', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyTLS10,@RegistryKeyServer,'Enabled',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyTLS10+'\'+@RegistryKeyServer
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'DisabledByDefault', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyTLS10,@RegistryKeyServer,'DisabledByDefault',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyTLS10+'\'+@RegistryKeyClient
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'Enabled', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyTLS10,@RegistryKeyClient,'Enabled',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyTLS10+'\'+@RegistryKeyClient
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'DisabledByDefault', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyTLS10,@RegistryKeyClient,'DisabledByDefault',@value,@Protocol_status)
-- Search for TLS 1.1
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyTLS11+'\'+@RegistryKeyServer
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'Enabled', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyTLS11,@RegistryKeyServer,'Enabled',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyTLS11+'\'+@RegistryKeyServer
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'DisabledByDefault', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyTLS11,@RegistryKeyServer,'DisabledByDefault',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyTLS11+'\'+@RegistryKeyClient
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'Enabled', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyTLS11,@RegistryKeyClient,'Enabled',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyTLS11+'\'+@RegistryKeyClient
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'DisabledByDefault', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyTLS11,@RegistryKeyClient,'DisabledByDefault',@value,@Protocol_status)
-- Search for TLS 1.2
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyTLS12+'\'+@RegistryKeyServer
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'Enabled', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyTLS12,@RegistryKeyServer,'Enabled',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyTLS12+'\'+@RegistryKeyServer
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'DisabledByDefault', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyTLS12,@RegistryKeyServer,'DisabledByDefault',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyTLS12+'\'+@RegistryKeyClient
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'Enabled', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyTLS12,@RegistryKeyClient,'Enabled',@value,@Protocol_status)
SET @value = 0
SET @key = @RegistryKey+'\'+@RegistryKeyTLS12+'\'+@RegistryKeyClient
EXEC xp_regread @rootkey = 'HKEY_LOCAL_MACHINE',@key = @key,@value_name = 'DisabledByDefault', @value = @value OUTPUT
IF (@value = 1) SET @Protocol_status = 'Yes' ELSE SET @Protocol_status = 'No'
INSERT INTO  #result VALUES (@RegistryKeyTLS12,@RegistryKeyClient,'DisabledByDefault',@value,@Protocol_status)


SELECT 
	se.Protocol_version,
	CASE WHEN se.Protocol_version <> 'TLS 1.2' and ((se.Protocol_status = 'Yes' OR sd.Protocol_status =  'No' ) 
			OR (ce.Protocol_status = 'Yes' OR cd.Protocol_status = 'No' )) THEN 'False'
		WHEN se.Protocol_version = 'TLS 1.2' and ((se.Protocol_status = 'No' OR sd.Protocol_status =  'Yes' ) 
			OR (ce.Protocol_status = 'No' OR cd.Protocol_status = 'Yes' )) THEN 'False'
		ELSE 'True' END AS [Is Protocol Ok]

FROM 
	#result se
	left join #result sd on se.Protocol_version = sd.Protocol_version
	left join #result ce on se.Protocol_version = ce.Protocol_version
	left join #result cd on se.Protocol_version = cd.Protocol_version
WHERE
	se.Protocol_function = 'Server'
	and se.Enabled_Disabled = 'Enabled'
	and sd.Protocol_function = 'Server'
	and sd.Enabled_Disabled = 'DisabledByDefault'
	and ce.Protocol_function = 'Client'
	and ce.Enabled_Disabled = 'Enabled'
	and cd.Protocol_function = 'Client'
	and cd.Enabled_Disabled ='DisabledByDefault'


DROP table #result