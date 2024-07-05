EXEC sp_get_distributor;
GO

-- Add the Publisher to the Distributor
EXEC sp_adddistpublisher 
    @publisher = 'EC2AMAZ-LJOBLN8', 
    @distribution_db = 'distribution', 
    @security_mode = 1;  -- 1 indicates Windows Authentication, use 0 for SQL Server Authentication
GO
