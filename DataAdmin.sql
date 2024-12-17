--a. Can create accounts for Complex Manager, Tournament Organizer,Individual Customer and Participants.
USE master;
GRANT ALTER ANY LOGIN TO DataAdmin; -- Grant permission to create logins

USE ApArenaDatabaseManagementSystem;
GRANT ALTER ANY USER TO DataAdmin; -- Grant permission to create users for logins
GRANT CREATE USER TO DataAdmin; -- Grant permission to create users without logins
GRANT ALTER ANY ROLE TO DataAdmin; -- Grant permission to alter roles and add members
GRANT EXEC ON createUserAccount TO DataAdmin; --Grant permission to create user account
GRANT EXEC ON UpdateComplexManagerDetails TO DataAdmin;

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

EXEC createUserAccount 'HANSON','Hanson Yip', '0198765432', 'hanson@gmail.com';

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

--b. Can perform permission management (grant & deny) for Complex Manager, Tournament Organizer, Individual Customer and Participants.
--c. Can add and manage (update & delete) the Complex Manager.

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

-- Create the trigger for logging updates into the ActivityLog table

CREATE TRIGGER trg_LogComplexManagerUpdate
ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Check if the updated user is a Complex Manager
    IF EXISTS (
        SELECT 1
        FROM sys.database_role_members drm
        JOIN sys.database_principals dp ON drm.role_principal_id = dp.principal_id
        JOIN sys.database_principals dp2 ON drm.member_principal_id = dp2.principal_id
        WHERE dp.name = 'ComplexManager' AND dp2.name IN (SELECT Username FROM inserted)
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

--d.Must not have any access to any personal or sensitive data of Tournament Organizer, Individual Customer and any participants that registered either directly or indirectly in the system. 

--f. Can delete data but all deleted data must be tracked for auditing and must be easily recoverable

