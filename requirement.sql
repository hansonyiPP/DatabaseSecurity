CREATE DATABASE testDB;

USE master;
CREATE LOGIN DataAdmin1 WITH PASSWORD = 'Password1';
CREATE LOGIN DataAdmin2 WITH PASSWORD = 'Password2';

USE testDB;
CREATE USER DataAdmin1 FOR LOGIN DataAdmin1;
CREATE USER DataAdmin2 FOR LOGIN DataAdmin2;

-- USE testDB;
-- GRANT EXECUTE TO DataAdmin1;
-- GRANT EXECUTE TO DataAdmin2;

-- Grant permission to create users
-- USE master;
-- GRANT ALTER ANY LOGIN TO DataAdmin1;
-- GRANT ALTER ANY LOGIN TO DataAdmin2;

-- Grant permission to assign roles (Complex Manager, Tournament Organizer, etc.)
-- USE testDB;
-- GRANT ALTER ANY USER TO DataAdmin1;
-- GRANT ALTER ANY USER TO DataAdmin2;

-- Grant permission management capability
-- GRANT ALTER ANY ROLE TO DataAdmin1;
-- GRANT ALTER ANY ROLE TO DataAdmin2;

CREATE TABLE Activity_Log (
LogID int IDENTITY(1,1) NOT NULL,
type text NOT NULL,
description nvarchar(256) NOT NULL,
Date datetime NULL,
UserID int NULL
) 

CREATE TABLE Users(
ID int IDENTITY(1,1) NOT NULL,
Username nvarchar(50) NOT NULL,
Password varbinary(256) NOT NULL,
Role nvarchar(50) NOT NULL,
Name char(100) NOT NULL,
Mobile varchar(12) NOT NULL,
email varchar(50) NOT NULL,
Last_login datetime NULL,
IsDeleted bit NOT NULL
)

-- Grant update/delete permission for Complex Manager table
-- GRANT UPDATE, DELETE ON Users TO DataAdmin1;
-- GRANT UPDATE, DELETE ON Users TO DataAdmin2;

CREATE VIEW ComplexManagerUsers
AS
SELECT *
FROM dbo.Users
WHERE Role = 'Complex Manager' AND IsDeleted = 0;

-- GRANT UPDATE, DELETE ON ComplexManagerUsers TO DataAdmin1;
-- GRANT UPDATE, DELETE ON ComplexManagerUsers TO DataAdmin2;

CREATE PROCEDURE CreateUserAccount
     @Role NVARCHAR(50),
     @Username NVARCHAR(50),
     @Password NVARCHAR(50),
     @Name CHAR(100),
     @Mobile VARCHAR(12),
     @Email VARCHAR(50)
 AS
 BEGIN
     -- Check if login exists
     IF EXISTS (SELECT * FROM sys.server_principals WHERE name = @Username)
     BEGIN
         PRINT 'Login already exists. No action taken.';
         RETURN;
     END

     -- Check if user exists in the database
     IF EXISTS (SELECT * FROM sys.database_principals WHERE name = @Username)
     BEGIN
         PRINT 'User already exists in the database. No action taken.';
         RETURN;
     END

     -- Create login
     DECLARE @LoginSQL NVARCHAR(MAX) = 'CREATE LOGIN ' + QUOTENAME(@Username) + ' WITH PASSWORD = ''' + @Password + ''';';
     EXEC sp_executesql @LoginSQL;

     -- Create user in the database
     DECLARE @UserSQL NVARCHAR(MAX) = 'USE testDB; CREATE USER ' + QUOTENAME(@Username) + ' FOR LOGIN ' + QUOTENAME(@Username) + ';';
     EXEC sp_executesql @UserSQL;

     -- Grant necessary permissions
     DECLARE @GrantSQL NVARCHAR(MAX) = 'GRANT SELECT ON SCHEMA::dbo TO ' + QUOTENAME(@Username) + ';';
     EXEC sp_executesql @GrantSQL;

     -- Insert user details into Users table
     INSERT INTO [dbo].[Users] (Username, Password, Role, Name, Mobile, Email, Last_login, IsDeleted)
     VALUES (@Username, HASHBYTES('SHA2_256', @Password), @Role, @Name, @Mobile, @Email, NULL, 0);

     -- Log the activity
     INSERT INTO Activity_Log (type, description, Date)
     VALUES ('User Account Creation', 'Created user account for ' + @Username, DATEADD(HOUR, 8, GETDATE()));
 END;

 EXEC CreateUserAccount 'Complex manager', 'TEST', 'Password1', 'Testing', '023948234', 'test@gmail.com';
  EXEC CreateUserAccount 'Tournament Organiser', 'YIP', 'Password1', 'Hanson', '023948234', 'yip@gmail.com';
  EXEC CreateUserAccount 'Individual Customer', 'SK', 'Password1', 'ShengKit', '023948234', 'sk@gmail.com';
  EXEC CreateUserAccount 'Data Admin', 'KS', 'Password1', 'KahShen', '023948234', 'ks@gmail.com';

 CREATE TRIGGER trg_InsteadOfUpdate_ComplexManagerUsers
 ON ComplexManagerUsers
 INSTEAD OF UPDATE
 AS
 BEGIN
     UPDATE Users
     SET Username = inserted.Username,
         Password = inserted.Password,
         Role = inserted.Role,
         Name = inserted.Name,
         Mobile = inserted.Mobile,
         email = inserted.email,
         Last_login = inserted.Last_login
     FROM inserted
     WHERE Users.ID = inserted.ID;
 END;

 CREATE PROCEDURE UpdateComplexManagerUser
     @UserID INT,
     @Username NVARCHAR(256) = NULL,
     @Password NVARCHAR(256) = NULL,
     @Role NVARCHAR(50) = NULL,
     @Name NVARCHAR(256) = NULL,
     @Mobile NVARCHAR(50) = NULL,
     @Email NVARCHAR(256) = NULL,
     @LastLogin DATETIME = NULL
 AS
 BEGIN
     SET NOCOUNT ON;

     DECLARE @OldUsername NVARCHAR(256),
             @OldPassword VARBINARY(MAX),
             @OldRole NVARCHAR(50),
             @OldName NVARCHAR(256),
             @OldMobile NVARCHAR(50),
             @OldEmail NVARCHAR(256),
             @OldLastLogin DATETIME,
             @Changes NVARCHAR(MAX) = '',
             @sql NVARCHAR(MAX); -- Declare @sql variable

     -- Ensure the user has the role "Complex Manager"
     IF EXISTS (SELECT 1 FROM dbo.Users WHERE ID = @UserID AND Role = 'Complex Manager')
     BEGIN
         -- Get the current values
         SELECT @OldUsername = Username,
                @OldPassword = Password,
                @OldRole = Role,
                @OldName = Name,
                @OldMobile = Mobile,
                @OldEmail = Email,
                @OldLastLogin = Last_login
         FROM dbo.Users
         WHERE ID = @UserID;

         -- Update the user information
         UPDATE dbo.Users
         SET 
             Username = COALESCE(@Username, Username),
             Password = COALESCE(CONVERT(varbinary, @Password), Password),
             Role = COALESCE(@Role, Role),
             Name = COALESCE(@Name, Name),
             Mobile = COALESCE(@Mobile, Mobile),
             Email = COALESCE(@Email, Email),
             Last_login = COALESCE(@LastLogin, Last_login)
         WHERE ID = @UserID;

         -- Check which fields were updated and log the changes
         IF @Username IS NOT NULL AND @Username <> @OldUsername
             SET @Changes = @Changes + 'Username, ';
         IF @Password IS NOT NULL AND CONVERT(varbinary, @Password) <> @OldPassword
             SET @Changes = @Changes + 'Password, ';
         IF @Role IS NOT NULL AND @Role <> @OldRole
             SET @Changes = @Changes + 'Role, ';
         IF @Name IS NOT NULL AND @Name <> @OldName
             SET @Changes = @Changes + 'Name, ';
         IF @Mobile IS NOT NULL AND @Mobile <> @OldMobile
             SET @Changes = @Changes + 'Mobile, ';
         IF @Email IS NOT NULL AND @Email <> @OldEmail
             SET @Changes = @Changes + 'Email, ';
         IF @LastLogin IS NOT NULL AND @LastLogin <> @OldLastLogin
             SET @Changes = @Changes + 'Last_login, ';

         -- Remove the last comma and space
         IF LEN(@Changes) > 0
             SET @Changes = LEFT(@Changes, LEN(@Changes) - 1);

         -- Log the update activity
         INSERT INTO dbo.Activity_Log (type, description, Date, UserID)
         VALUES ('Complex Manager Details Update', 'Updated fields: ' + @Changes, DATEADD(HOUR, 8, GETDATE()), @UserID);

         -- Update SQL login if username or password is changed
         IF @Username IS NOT NULL AND @Username <> @OldUsername
         BEGIN
             SET @sql = N'ALTER LOGIN [' + @OldUsername + N'] WITH NAME = [' + @Username + N']';
             EXEC sp_executesql @sql;

             -- Update the SQL user name
             SET @sql = N'ALTER USER [' + @OldUsername + N'] WITH NAME = [' + @Username + N']';
             EXEC sp_executesql @sql;
         END

         IF @Password IS NOT NULL AND CONVERT(varbinary, @Password) <> @OldPassword
         BEGIN
             SET @sql = N'ALTER LOGIN [' + COALESCE(@Username, @OldUsername) + N'] WITH PASSWORD = ''' + @Password + N'''';
             EXEC sp_executesql @sql;
         END
     END
     ELSE
     BEGIN
         RAISERROR('User does not have the role "Complex Manager" or does not exist.', 16, 1);
     END
 END;

 EXEC UpdateComplexManagerUser
     @UserID = 4,
     @Username = 'LOLTEST',
     @Email = 'testlol@example.com';

 CREATE PROCEDURE SoftDeleteComplexManagerUser
     @UserID INT
 AS
 BEGIN
     SET NOCOUNT ON;

     -- Ensure the user has the role "Complex Manager"
     IF EXISTS (SELECT 1 FROM dbo.Users WHERE ID = @UserID AND Role = 'Complex Manager')
     BEGIN
         -- Mark the user as deleted
         UPDATE dbo.Users
         SET IsDeleted = 1
         WHERE ID = @UserID;

         -- Get the username for the given user ID
         DECLARE @Username NVARCHAR(50);
         SELECT @Username = Username FROM dbo.Users WHERE ID = @UserID;

         -- Disable the SQL login
         DECLARE @DisableLoginSQL NVARCHAR(MAX) = 'ALTER LOGIN ' + QUOTENAME(@Username) + ' DISABLE;';
         EXEC sp_executesql @DisableLoginSQL;

         -- Log the soft deletion
         INSERT INTO [dbo].[Activity_Log] ([type], [description], [Date], [UserID])
         VALUES ('Soft User Deletion', 'User with ID ' + CAST(@UserID AS NVARCHAR(10)) + ' has been soft deleted', DATEADD(HOUR, 8, GETDATE()), @UserID);
     END
     ELSE
     BEGIN
         RAISERROR('User does not have the role "Complex Manager" or does not exist.', 16, 1);
     END
 END;

-- EXEC SoftDeleteComplexManagerUser @UserID = 4;

 CREATE PROCEDURE HardDeleteComplexManager
     @UserID INT
 AS
 BEGIN
     SET NOCOUNT ON;
     -- Check if the user is marked as deleted
     IF EXISTS (SELECT 1 FROM dbo.Users WHERE ID = @UserID AND Role = 'Complex Manager' AND IsDeleted = 1)
     BEGIN
         -- Delete the user from the Users table
         DELETE FROM dbo.Users
         WHERE ID = @UserID AND IsDeleted = 1;

         PRINT 'User with ID ' + CAST(@UserID AS NVARCHAR(10)) + ' has been permanently deleted.';
     END
     ELSE
     BEGIN
         RAISERROR('User with ID %d does not exist or is not marked as deleted or it is not Complex Manager.', 16, 1, @UserID);
     END
 END;

-- EXEC HardDeleteComplexManager @UserID = 4;

 CREATE PROCEDURE RecoverComplexManager
     @UserID INT
 AS
 BEGIN
     SET NOCOUNT ON;
     -- Check if the user is marked as deleted
     IF EXISTS (SELECT 1 FROM dbo.Users WHERE ID = @UserID AND Role = 'Complex Manager' AND IsDeleted = 1)
     BEGIN
         -- Recover the user by setting IsDeleted to 0
         UPDATE dbo.Users
         SET IsDeleted = 0
         WHERE ID = @UserID;

         -- Get the username for the given user ID
         DECLARE @Username NVARCHAR(50);
         SELECT @Username = Username FROM dbo.Users WHERE ID = @UserID;

         -- Enable the SQL login
         DECLARE @EnableLoginSQL NVARCHAR(MAX) = 'ALTER LOGIN ' + QUOTENAME(@Username) + ' ENABLE;';
         EXEC sp_executesql @EnableLoginSQL;

         -- Log the recovery
         INSERT INTO [dbo].[Activity_Log] ([type], [description], [Date], [UserID])
         VALUES ('User Recovery', 'Recovered user account for user ID ' + CAST(@UserID AS NVARCHAR(10)), DATEADD(HOUR, 8, GETDATE()), @UserID);

         PRINT 'User with ID ' + CAST(@UserID AS NVARCHAR(10)) + ' has been recovered and login enabled.';
     END
     ELSE
     BEGIN
         RAISERROR('User with ID %d does not exist or is not marked as deleted or not a Complex Manager.', 16, 1, @UserID);
     END
 END;

-- EXEC RecoverComplexManager @UserID= 6;

 CREATE PROCEDURE sp_DataAdminManagePermissions
     @UserName NVARCHAR(128),
     @Permission NVARCHAR(128),
     @Action NVARCHAR(10) -- 'GRANT' or 'DENY'
 AS
 BEGIN
     IF @Action = 'GRANT'
     BEGIN
         EXEC('GRANT ' + @Permission + ' ON SCHEMA::dbo TO ' + @UserName);
     END
     ELSE IF @Action = 'DENY'
     BEGIN
         EXEC('DENY ' + @Permission + ' ON SCHEMA::dbo TO ' + @UserName);
     END

     -- Log the activity
     INSERT INTO Activity_Log (type, description, Date)
     VALUES ('User Permission Alteration', 'User account ' + @Username + ' '+ @Permission + ' permisson have been ' + @Action, DATEADD(HOUR, 8, GETDATE()))
 END;

 CREATE PROCEDURE sp_ViewUserPermissions
     @UserName NVARCHAR(128)
 AS
 BEGIN
     -- Database-level permissions
     PRINT 'Database-Level Permissions:';
     SELECT 
         dp.name AS UserName,
         dp.type_desc AS UserType,
         o.name AS ObjectName,
         p.permission_name AS Permission,
         p.state_desc AS PermissionState,
         'Database-Level' AS PermissionLevel
     FROM 
         sys.database_permissions p
     JOIN 
         sys.database_principals dp ON p.grantee_principal_id = dp.principal_id
     LEFT JOIN 
         sys.objects o ON p.major_id = o.object_id
     WHERE 
         dp.name = @UserName;

     -- Server-level permissions
     PRINT 'Server-Level Permissions:';
     SELECT 
         sp.name AS UserName,
         sp.type_desc AS UserType,
         spm.permission_name AS Permission,
         spm.state_desc AS PermissionState,
         'Server-Level' AS PermissionLevel
     FROM 
         sys.server_permissions spm
     JOIN 
         sys.server_principals sp ON spm.grantee_principal_id = sp.principal_id
     WHERE 
         sp.name = @UserName;
 END;
 GO

 CREATE TRIGGER trg_AfterDelete_Users
 ON [dbo].[Users]
 FOR DELETE
 AS
 BEGIN
     SET NOCOUNT ON;

     BEGIN TRY
         -- Log the deletion
         INSERT INTO [dbo].[Activity_Log] ([type], [description], [Date], [UserID])
         SELECT 
             'User Deletion', 
             'Deleted user account for ' + DELETED.Username, 
             DATEADD(HOUR, 8, GETDATE()), -- Adjust for Malaysia Time (UTC+8)
             DELETED.ID
         FROM DELETED;

         -- Delete the corresponding login and user
         DECLARE @loginName NVARCHAR(256);
         DECLARE @sql NVARCHAR(MAX);
        
         SELECT @loginName = Username FROM DELETED;
        
         -- Check if the login exists
         IF EXISTS (SELECT 1 FROM sys.server_principals WHERE name = @loginName)
         BEGIN
             -- Drop the login
             SET @sql = N'DROP LOGIN [' + @loginName + N']';
             EXEC sp_executesql @sql;
         END
         ELSE
         BEGIN
             RAISERROR('Login ''%s'' does not exist.', 16, 1, @loginName);
         END
        
         -- Check if the user exists
         IF EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @loginName)
         BEGIN
             -- Drop the user
             SET @sql = N'DROP USER [' + @loginName + N']';
             EXEC sp_executesql @sql;
         END
         ELSE
         BEGIN
             RAISERROR('User ''%s'' does not exist.', 16, 1, @loginName);
         END
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
     END CATCH
 END;

 SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.trg_AfterDelete_Users')) AS TriggerDefinition;