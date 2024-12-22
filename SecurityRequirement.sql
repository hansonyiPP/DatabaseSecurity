
--1. All database activities including data changes (insert,update,delete) and user creation & permission settings must be tracked for auditing purposes.
--2. All user login attempts (successful and unsuccessful) must be tracked for auditing purposes.
--3. Intentional or accidental deletion of data must be tracked and recovered easily if needed.
--4. Backups must be automated and the Recovery Point Objective (RPO) must be maximum 6 hours.
--Full Backup------------------------------------------------------------------------------------------------------------------------------------------------------------
BACKUP DATABASE [ApArenaDatabaseManagementSystem] 
TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER01\MSSQL\Backup\ApArenaDatabaseManagementSystem_Full.bak'
WITH FORMAT, INIT, NAME = N'Full Database Backup';
USE master;
GO

EXEC msdb.dbo.sp_add_job
    @job_name = N'Full Database Backup';

-- Add a job step for the Full Backup
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Full Database Backup',
    @step_name = N'Full Backup Step',
    @subsystem = N'TSQL',
    @command = N'BACKUP DATABASE [ApArenaDatabaseManagementSystem]
                 TO DISK = N''C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER01\MSSQL\Backup\ApArenaDatabaseManagementSystem_Full.bak'' 
                 WITH FORMAT, INIT, NAME = N''Full Database Backup'';', -- REMEBER CHANGE DIRECTORY
    @on_success_action = 1; -- Go to the next step

-- Schedule the job to run daily
EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'Full Database Backup',
    @name = N'Daily Full Backup',
    @freq_type = 4, -- Daily
    @freq_interval = 1, -- Every 1 day
    @active_start_time = 230000; -- 11:00 PM

-- Enable the job
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'Full Database Backup',
    @server_name = N'(local)';
GO

--Differential Backup------------------------------------------------------------------------------------------------------------------------------------------------------------
USE master;
GO

-- Create a SQL Agent Job for Differential Backup
EXEC msdb.dbo.sp_add_job
    @job_name = N'Differential Database Backup';

-- Add a job step for the Differential Backup
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Differential Database Backup',
    @step_name = N'Differential Backup Step',
    @subsystem = N'TSQL',
    @command = N'BACKUP DATABASE [ApArenaDatabaseManagementSystem]
                 TO DISK = N''C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER01\MSSQL\Backup\ApArenaDatabaseManagementSystem_Diff.bak''
                 WITH DIFFERENTIAL, INIT, NAME = N''Differential Database Backup'';',
    @on_success_action = 1; -- Go to the next step

-- Schedule the job to run every 6 hours
EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'Differential Database Backup',
    @name = N'6-Hour Differential Backup',
    @freq_type = 4, -- Daily
    @freq_interval = 1, -- Every day
    @freq_subday_type = 8, -- calculate by hours
    @freq_subday_interval = 6, -- Every 6 hours
    @active_start_time = 0; -- Starts at midnight

-- Enable the job
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'Differential Database Backup',
    @server_name = N'(local)';
GO

--Transaction Log Backup------------------------------------------------------------------------------------------------------------------------------------------------------------
USE master;
GO

-- Create a SQL Agent Job for Transaction Log Backup
EXEC msdb.dbo.sp_add_job
    @job_name = N'Transaction Log Backup';

-- Add a job step for the Transaction Log Backup
EXEC msdb.dbo.sp_add_jobstep
    @job_name = N'Transaction Log Backup',
    @step_name = N'Transaction Log Backup Step',
    @subsystem = N'TSQL',
    @command = N'BACKUP LOG [ApArenaDatabaseManagementSystem]
                 TO DISK = N''C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER01\MSSQL\Backup\ApArenaDatabaseManagementSystem_Log.trn''
                 WITH INIT, NAME = N''Transaction Log Backup'';',
    @on_success_action = 1; -- Go to the next step

-- Schedule the job to run every 15 minutes
EXEC msdb.dbo.sp_add_jobschedule
    @job_name = N'Transaction Log Backup',
    @name = N'15-Minute Transaction Log Backup',
    @freq_type = 4, -- Daily
    @freq_interval = 1, -- Every day
    @freq_subday_type = 4, -- calculate by minutes
    @freq_subday_interval = 15, -- Every 15 minutes
    @active_start_time = 0; -- Starts at midnight

-- Enable the job
EXEC msdb.dbo.sp_add_jobserver
    @job_name = N'Transaction Log Backup',
    @server_name = N'(local)';
GO

--check backup--------------------------------------------------------------------------------------------------------------
SELECT * 
FROM msdb.dbo.backupset
WHERE database_name = 'ApArenaDatabaseManagementSystem'
ORDER BY backup_finish_date DESC;

USE msdb;
GO

SELECT 
    j.name AS JobName,
    h.run_date AS LastRunDate,
    h.run_time AS LastRunTime,
    CASE h.run_status
        WHEN 1 THEN 'Succeeded'
        WHEN 0 THEN 'Failed'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'In Progress'
        ELSE 'Unknown'
    END AS RunStatus,
    h.message AS ErrorMessage
FROM sysjobs j
JOIN sysjobhistory h ON j.job_id = h.job_id
WHERE j.name = 'Transaction Log Backup'
ORDER BY h.run_date DESC, h.run_time DESC;

--alert system for failed backup---------------------------------------------------------------------------------------------------------
-- Step 1: Create an Operator for Job Failure and Success Notifications
USE msdb;
GO

-- Step 1: Create an Operator for Job Failure and Success Notifications
EXEC msdb.dbo.sp_add_operator 
    @name = N'BackupFailureSuccessOperator',
    @enabled = 1,
    @email_address = 'kahshentan@gmail.com'; -- Replace with your email address
GO

-- Step 2: Configure SQL Server Agent to Use Database Mail (if not already configured)
-- (Ensure that Database Mail is configured and enabled before running this)
EXEC msdb.dbo.sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC msdb.dbo.sp_configure 'Database Mail XPs', 1;
RECONFIGURE;

-- Step 3: Configure Notifications for the First Job: Full Database Backup
EXEC msdb.dbo.sp_update_job 
    @job_name = N'Full Database Backup',  -- Replace with your job name if different
    @notify_level_email = 3,  -- Notify on job completion (success or failure)
    @notify_email_operator_name = N'BackupFailureSuccessOperator';
GO

-- Step 5: Configure Notifications for the Second Job: Differential Database Backup
EXEC msdb.dbo.sp_update_job 
    @job_name = N'Differential Database Backup',  -- Replace with your job name if different
    @notify_level_email = 3,  -- Notify on job completion (success or failure)
    @notify_email_operator_name = N'BackupFailureSuccessOperator';
GO

-- Step 7: Configure Notifications for the Third Job: Transaction Log Backup
EXEC msdb.dbo.sp_update_job 
    @job_name = N'Transaction Log Backup',  -- Replace with your job name if different
    @notify_level_email = 3,  -- Notify on job completion (success or failure)
    @notify_email_operator_name = N'BackupFailureSuccessOperator';
GO

--5. Data must be classified and protected accordingly. Masked or Encryted data must be automatically unmasked or decrypted when retrieved by the rightful owner.
CREATE OR ALTER PROCEDURE sp_CheckRolePermissions
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Select permissions for roles
        SELECT 
            dp.name AS RoleName,
            dp.type_desc AS RoleType,
            dp2.state_desc AS PermissionState, -- GRANT, DENY, REVOKE
            dp2.permission_name AS PermissionType, -- EXECUTE, SELECT, INSERT, etc.
            OBJECT_NAME(dp2.major_id) AS ObjectName, -- Object name (SP, Table, etc.)
            SCHEMA_NAME(o.schema_id) AS SchemaName, -- Schema of the object
            o.type_desc AS ObjectType -- Object type (PROCEDURE, TABLE, etc.)
        FROM 
            sys.database_principals dp
        LEFT JOIN 
            sys.database_permissions dp2 ON dp.principal_id = dp2.grantee_principal_id
        LEFT JOIN 
            sys.objects o ON dp2.major_id = o.object_id
        WHERE 
            dp.type = 'R' -- Only roles
        ORDER BY 
            dp.name, dp2.permission_name, OBJECT_NAME(dp2.major_id);

    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('An error occurred: %s', 16, 1, @ErrorMessage);
    END CATCH
END;

EXEC sp_CheckRolePermissions;









