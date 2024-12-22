--a. Can create accounts for Complex Manager, Tournament Organizer,Individual Customer and Participants. -------------------------------------------------------------------------------------------------------------------------------------
USE master;
GRANT ALTER ANY LOGIN TO DataAdmin; -- Grant permission to create logins

USE ApArenaDatabaseManagementSystem;
GRANT ALTER ANY USER TO DataAdmin; -- Grant permission to create users for logins
GRANT CREATE USER TO DataAdmin; -- Grant permission to create users without logins
GRANT ALTER ANY ROLE TO DataAdmin; -- Grant permission to alter roles and add members

GRANT VIEW DEFINITION TO DataAdmin;
GRANT EXECUTE ON SCHEMA::dbo TO DataAdmin WITH GRANT OPTION;
GRANT CONTROL ON SCHEMA::dbo TO DataAdmin;

CREATE PROCEDURE createUserAccount
    @Username VARCHAR(50),
    @Name VARCHAR(100),
    @Mobile VARCHAR(12),
    @Email VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the username already exists
    IF EXISTS (SELECT 1 FROM Users WHERE Username = @Username)
    BEGIN
        PRINT 'Username already exists. No new user account created.';
        RETURN;
    END

    -- Set default values for Last_login and IsDeleted
    DECLARE @Last_login DATETIME = NULL;
    DECLARE @IsDeleted BIT = 0;

    -- Insert the new user
    INSERT INTO Users (Username, Name, Mobile, Email, Last_login, IsDeleted)
    VALUES (@Username, @Name, @Mobile, @Email, @Last_login, @IsDeleted);

    PRINT 'User account created';
END;

EXEC createUserAccount 'testdelete','TESTERRRRR', '0125165432', 'testerrrr@gmail.com';
GRANT EXEC ON createUserAccount TO DataAdmin; 

CREATE TRIGGER trg_AfterInsert_Users
ON [dbo].[Users]
FOR INSERT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Log the insertion
        INSERT INTO [dbo].[ActivityLog] (type, description, Date)
        SELECT 
            'User Insertion', 
            'A new user with ID ' + CAST(INSERTED.ID AS NVARCHAR(10)) + ' and name=' + INSERTED.Name + ' has been added into the database', GETDATE()
        FROM INSERTED;
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH;
END;

--b. Can perform permission management (grant & deny) for Complex Manager, Tournament Organizer, Individual Customer and Participants. ------------------------------------------------------------------
CREATE PROCEDURE ManagePermissionOnSP
	@Role NVARCHAR(100),
	@Action NVARCHAR(10),
	@ProcedureName NVARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	IF @Action NOT IN ('GRANT','DENY')
	BEGIN
		RAISERROR('Invalid action. Use GRANT or DENY.', 16, 1);
        RETURN;
	END;

	IF NOT EXISTS (
        SELECT 1
        FROM sys.database_principals
        WHERE name = @Role AND type IN ('R') -- Role type
    )
    BEGIN
        RAISERROR('The specified role does not exist.', 16, 1);
        RETURN;
    END

	IF NOT EXISTS(
		SELECT schema_name(o.schema_id) AS SchemaName, o.name AS ProcedureName
		FROM sys.objects o
		WHERE o.type = 'P' AND o.name = @ProcedureName
	)
    BEGIN
        RAISERROR('The inputed stored procedure does not exist.', 16, 1);
        RETURN;
    END

	IF @Action = 'GRANT'
	BEGIN
		EXEC('GRANT EXECUTE ON [dbo].['+@ProcedureName+'] TO '+@Role);
	END
    ELSE IF @Action = 'DENY'
	BEGIN
		EXEC('DENY EXECUTE ON [dbo].['+@ProcedureName+'] TO '+@Role);
	END

	INSERT INTO ActivityLog (type, description, Date)
    VALUES ('Permission Management', @Action +' Permission of the stored procedure name: '+@ProcedureName+' have been given to role: '+@Role, GETDATE());
END;

GRANT EXEC ON ManagePermissionOnSP TO DataAdmin;

CREATE OR ALTER PROCEDURE sp_ManageTablePermissions
    @RoleName NVARCHAR(128),
    @TableName NVARCHAR(128),
    @Permissions NVARCHAR(128),  -- Comma-separated list of permissions (e.g., 'SELECT, INSERT')
    @Action NVARCHAR(10)         -- 'GRANT' or 'DENY'
AS
BEGIN
    SET NOCOUNT ON;

    -- Validate inputs
    IF @RoleName IS NULL OR @RoleName = ''
    BEGIN
        RAISERROR('Role name cannot be null or empty.', 16, 1);
        RETURN;
    END

    IF @TableName IS NULL OR @TableName = ''
    BEGIN
        RAISERROR('Table name cannot be null or empty.', 16, 1);
        RETURN;
    END

    IF @Permissions IS NULL OR @Permissions = ''
    BEGIN
        RAISERROR('Permissions cannot be null or empty.', 16, 1);
        RETURN;
    END

    IF @Action NOT IN ('GRANT', 'DENY')
    BEGIN
        RAISERROR('Action must be either ''GRANT'' or ''DENY''.', 16, 1);
        RETURN;
    END

    -- Check if the role exists
    IF NOT EXISTS (
        SELECT 1
        FROM sys.database_principals
        WHERE name = @RoleName AND type = 'R' -- 'R' is for roles
    )
    BEGIN
        RAISERROR('The specified role does not exist.', 16, 1);
        RETURN;
    END

    -- Check if the table exists
    IF NOT EXISTS (
        SELECT 1
        FROM sys.tables
        WHERE name = @TableName
    )
    BEGIN
        RAISERROR('The specified table does not exist.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        -- Loop through the permissions and build the SQL command
        DECLARE @SQL NVARCHAR(MAX);
        DECLARE @Permission NVARCHAR(128);
        DECLARE @Pos INT;
        DECLARE @StartPos INT;

        SET @SQL = '';
        SET @StartPos = 1;

        -- Loop through the permissions and build the SQL command
        WHILE @StartPos > 0
        BEGIN
            SET @Pos = CHARINDEX(',', @Permissions, @StartPos);
            IF @Pos > 0
                SET @Permission = LTRIM(RTRIM(SUBSTRING(@Permissions, @StartPos, @Pos - @StartPos)));
            ELSE
                SET @Permission = LTRIM(RTRIM(SUBSTRING(@Permissions, @StartPos, LEN(@Permissions) - @StartPos + 1)));

            -- Add the GRANT or DENY statement to the SQL command
            IF @Action = 'GRANT'
                SET @SQL = @SQL + 'GRANT ' + @Permission + ' ON ' + QUOTENAME(@TableName) + ' TO ' + QUOTENAME(@RoleName) + '; ';
            ELSE IF @Action = 'DENY'
                SET @SQL = @SQL + 'DENY ' + @Permission + ' ON ' + QUOTENAME(@TableName) + ' TO ' + QUOTENAME(@RoleName) + '; ';

            -- Move to the next permission
            SET @StartPos = @Pos + 1;
            IF @Pos = 0 BREAK;
        END

        -- Execute the dynamic SQL to grant or deny the permissions
        EXEC sp_executesql @SQL;

        -- Log the action
		INSERT INTO ActivityLog (type, description, Date)
        VALUES ('Permission Management', 
                @Action + ' ' + @Permissions + ' on table ' + QUOTENAME(@TableName) + ' for role ' + QUOTENAME(@RoleName), 
                GETDATE());
        PRINT 'Permission management successful.';
    END TRY
    BEGIN CATCH
        -- Handle errors
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('An error occurred: %s', 16, 1, @ErrorMessage);
    END CATCH
END;

GRANT EXEC ON sp_ManageTablePermissions TO DataAdmin;

--c. Can add and manage (update & delete) the Complex Manager. -------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE UpdateComplexManagerDetails
    @Username VARCHAR(50),
    @Name VARCHAR(100) = NULL,
    @Mobile VARCHAR(12) = NULL,
    @Email VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM sys.database_role_members drm
        JOIN sys.database_principals dp ON drm.role_principal_id = dp.principal_id
        JOIN sys.database_principals dp2 ON drm.member_principal_id = dp2.principal_id
        WHERE dp.name = 'ComplexManager' AND dp2.name = @Username
    )
    BEGIN
        -- Update the details of the complex manager
        UPDATE Users
        SET Name = COALESCE(@Name, Name),
            Mobile = COALESCE(@Mobile, Mobile),
            Email = COALESCE(@Email, Email)
        WHERE Username = @Username;

        PRINT 'Complex manager details updated successfully.';
    END
    ELSE
    BEGIN
        PRINT 'User is not a complex manager or does not exist.';
    END
END;

EXEC UpdateComplexManagerDetails
    @Username = 'TZ',
	@Name = 'Tan Zhong',
    @Email = 'tz@gmail.com';

GRANT EXEC ON UpdateComplexManagerDetails TO DataAdmin;

-- Create the trigger for logging updates into the ActivityLog table
CREATE TRIGGER trg_LogComplexManagerUpdate
ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the updated user is a Complex Manager and if columns other than IsDeleted were updated
    IF EXISTS (
        SELECT 1
        FROM sys.database_role_members drm
        JOIN sys.database_principals dp ON drm.role_principal_id = dp.principal_id
        JOIN sys.database_principals dp2 ON drm.member_principal_id = dp2.principal_id
        WHERE dp.name = 'ComplexManager' AND dp2.name IN (SELECT Username FROM inserted)
    ) AND (
        UPDATE(Username) OR UPDATE(Name) OR UPDATE(Email) OR UPDATE(Mobile)
    )
    BEGIN
        -- Insert the log for each updated user
        INSERT INTO ActivityLog (type, description, Date)
        SELECT 
            'Complex Manager Details Update' AS type,
            'The complex manager with username=''' + inserted.Username + 
            ''' and name=''' + ISNULL(inserted.Name, 'NULL') + '''' +
            CASE 
                WHEN ISNULL(deleted.Email, '') <> ISNULL(inserted.Email, '') THEN 
                    ', updated their old email from ''' + ISNULL(deleted.Email, 'NULL') + ''' to ''' + ISNULL(inserted.Email, 'NULL') + ''''
                ELSE ''
            END +
            CASE 
                WHEN ISNULL(deleted.Mobile, '') <> ISNULL(inserted.Mobile, '') THEN 
                    ', old mobile from ''' + ISNULL(deleted.Mobile, 'NULL') + ''' to ''' + ISNULL(inserted.Mobile, 'NULL') + ''''
                ELSE ''
            END + '.' AS description,
            GETDATE() AS Date
        FROM inserted
        INNER JOIN deleted ON inserted.Username = deleted.Username;
    END
END;

--Hard and Soft Delete Complex Manager
CREATE PROCEDURE SoftDeleteComplexManager
    @Username VARCHAR(50)
AS BEGIN 
	SET NOCOUNT ON;

	IF EXISTS (
        SELECT 1
        FROM sys.database_role_members drm
        JOIN sys.database_principals dp ON drm.role_principal_id = dp.principal_id
        JOIN sys.database_principals dp2 ON drm.member_principal_id = dp2.principal_id
        WHERE dp.name = 'ComplexManager' AND dp2.name = @Username
    )
	BEGIN
	UPDATE Users SET IsDeleted = 1 WHERE Username = @Username;

	INSERT INTO ActivityLog (type,description,Date)
	VALUES('Soft User Deletion','The user ' + @Username + ' have been soft deleted', GETDATE());
	END
	ELSE
	BEGIN
         RAISERROR('User does not have the role "Complex Manager" or does not exist.', 16, 1);
     END
END;

EXEC SoftDeleteComplexManager @Username='CM2'

GRANT EXEC ON SoftDeleteComplexManager TO DataAdmin;

CREATE PROCEDURE HardDeleteComplexManager
    @Username VARCHAR(50)
AS BEGIN 
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1 FROM Users WHERE Username = @Username AND IsDeleted = 1)
	BEGIN
	DELETE FROM Users WHERE Username = @Username;

	END
	ELSE
	BEGIN
         RAISERROR('User does not exist or is not marked as deleted or it is not Complex Manager.', 16, 1);
     END
END;

EXEC HardDeleteComplexManager @Username='CM2'

GRANT EXEC ON HardDeleteComplexManager TO DataAdmin;

CREATE TRIGGER trg_AfterDelete_Users
 ON [dbo].[Users]
 FOR DELETE
 AS
 BEGIN
     SET NOCOUNT ON;
         -- Log the deletion
         INSERT INTO [dbo].[ActivityLog] ([type], [description], [Date])
         SELECT 'Hard User Deletion', 'The user ' + DELETED.Username+' have been deleted from the database',  GETDATE() FROM DELETED;
 END;

--d.Must not have any access to any personal or sensitive data of Tournament Organizer, Individual Customer and any participants that registered either directly or indirectly in the system. --------------
--Sensitive data: Users, Participants, Business Entity,
DENY SELECT ON Users TO DataAdmin;
DENY SELECT ON businessEntity TO DataAdmin;
DENY SELECT ON Participants TO DataAdmin;

CREATE VIEW PublicUsersView AS
SELECT ID, Name, Last_login, IsDeleted
FROM Users;

CREATE VIEW PublicParticipantsView AS
SELECT participantID, Name
FROM Participants;

CREATE VIEW PublicBusinessEntityView AS
SELECT businessID, Name
FROM businessEntity;

GRANT SELECT ON PublicParticipantsView TO DataAdmin;
GRANT SELECT ON PublicBusinessEntityView TO DataAdmin;
GRANT SELECT ON PublicUsersView TO DataAdmin;

--f. Can delete data but all deleted data must be tracked for auditing and must be easily recoverable -------------------------------------------------------------------------------------------------------------------------------------

CREATE PROCEDURE RecoverSoftDeletedUser
    @Username VARCHAR(50)
AS BEGIN 
	SET NOCOUNT ON;

	IF EXISTS (SELECT 1 FROM Users WHERE Username = @Username AND IsDeleted = 1)
	BEGIN
	UPDATE Users SET IsDeleted = 0 WHERE Username = @Username;

	INSERT INTO ActivityLog (type,description,Date)
	VALUES('Recover Soft Delete User','The user ' + @Username + ' have been recovered from soft delete', GETDATE());
	END
	ELSE
	BEGIN
         RAISERROR('User is not marked as soft delete or does not exist.', 16, 1);
     END
END;

GRANT EXEC ON RecoverSoftDeletedUser TO DataAdmin;

CREATE PROCEDURE RecoverHardDeletedUser
    @Username varchar(50)
AS
BEGIN
    -- Declare a variable to hold the latest ValidTo time
    DECLARE @LatestValidTo datetime2;

    -- Find the latest ValidTo time for the deleted user
    SELECT @LatestValidTo = MAX(ValidTo)
    FROM UsersHistory
    WHERE Username = @Username
    AND IsDeleted = 1;

    -- Insert the deleted user back into the Users table
    INSERT INTO Users (Username, Name, Mobile, email, Last_login, IsDeleted)
    SELECT Username, Name, Mobile, email, Last_login, 0 -- Set IsDeleted to 0 to mark as active
    FROM UsersHistory
    WHERE Username = @Username
    AND IsDeleted = 1
    AND ValidTo = @LatestValidTo;
END;

GRANT EXEC ON RecoverHardDeletedUser TO DataAdmin;

--TESTING-------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE test2
AS
SELECT * FROM TournamentEvents

SELECT * FROM sys.objects WHERE type = 'P' 






