EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'xp_cmdshell',1
GO
RECONFIGURE
GO


EXEC XP_CMDSHELL 'net use F: \\4.08.42.51\DBBackup /user:username password'
