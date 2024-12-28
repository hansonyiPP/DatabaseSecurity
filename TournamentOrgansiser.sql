CREATE TABLE TournamentEventAudit (
    auditID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,      
    eventID INT,                                 
    actionType VARCHAR(10),                     
    actionDate DATETIME,                         
    userID INT,                                 
    userName VARCHAR(100),                       
    eventName VARCHAR(100),                     
    oldEventName VARCHAR(100),  
	newEventDate DATETIME ,
    oldEventDate DATETIME,                      
    oldStatus BIT                                                
);


CREATE PROCEDURE AddTournamentEvent
    @facilityID INT,
    @eventName VARCHAR(100),
    @eventDate DATETIME,
    @status BIT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @userID INT;

    -- Retrieve the userID based on the current session or user context
    SELECT @userID = ID FROM dbo.userdetails WHERE username = SYSTEM_USER;

    -- Check if the userID exists and is authorized
    IF EXISTS (SELECT 1 FROM dbo.userdetails WHERE ID = @userID)
    BEGIN
        -- Check if an event with the same name and date already exists
        IF EXISTS (
            SELECT 1
            FROM TournamentEvents
            WHERE eventName = @eventName
            AND eventDate = @eventDate
        )
        BEGIN
            PRINT 'Error: An event with this name and date already exists.';
            RETURN;
        END

        -- Check if the facility is available for the event date
        IF NOT EXISTS (
            SELECT 1
            FROM Facility
            WHERE facilityID = @facilityID
            AND availability > 0
        )
        BEGIN
            PRINT 'The facility is not available for the selected date.';
            RETURN;
        END

        -- Insert the new event into the TournamentEvents table
        INSERT INTO dbo.TournamentEvents (facilityID, userID, eventName, eventDate, status)
        VALUES (@facilityID, @userID, @eventName, @eventDate, @status);

        PRINT 'Tournament Event has been successfully created.';
    END
    ELSE
    BEGIN
        PRINT 'You are not authorized to perform this action.';
    END
END;


EXEC AddTournamentEvent
    @facilityID = 1,
    @eventName = 'GayParty',
    @eventDate = '2029-05-15 09:00:00',
    @status = 1;  -- 1 for active, 0 for inactive


CREATE PROCEDURE UpdateTournamentEvent
    @eventID INT,                       
    @facilityID INT,                    
    @eventName VARCHAR(100),            
    @eventDate DATETIME,                
    @status BIT                         
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @userID INT;
    SELECT @userID = ID FROM dbo.userdetails WHERE username = SYSTEM_USER;

    IF EXISTS (SELECT 1 FROM dbo.userdetails WHERE ID = @userID)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM TournamentEvents
            WHERE eventName = @eventName
            AND eventDate = @eventDate
            AND eventID != @eventID  
        )
        BEGIN
            PRINT 'An event with this name and date already exists.';
            RETURN;
        END

        
        IF NOT EXISTS (
            SELECT 1
            FROM Facility
            WHERE facilityID = @facilityID
            AND availability > 0
        )
        BEGIN
            PRINT 'The facility is not available for the selected date.';
            RETURN;
        END

        UPDATE TournamentEvents
        SET 
            facilityID = @facilityID,
            eventName = @eventName,
            eventDate = @eventDate,
            status = @status
        WHERE eventID = @eventID;

        PRINT 'Tournament Event has been successfully updated.';
    END
    ELSE
    BEGIN
        PRINT 'You are not authorized to perform this action.';
    END
END;



CREATE TRIGGER trgTournamentEventUpdate
ON TournamentEvents
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
    -- Check if the event name, date, or status was updated
    IF UPDATE(eventName) OR UPDATE(eventDate) OR UPDATE(status)
    BEGIN
        -- Insert the changes into the TournamentEventAudit table
        INSERT INTO TournamentEventAudit
        SELECT NEWID(),I.eventID,'UPDATE',GETDATE(),I.userID,SYSTEM_USER,I.eventName,D.eventName,I.eventDate,D.eventDate,D.status                
        FROM inserted I
        INNER JOIN deleted D ON I.eventID = D.eventID;  -- Join inserted and deleted to get old and new values
    END
END;


EXEC UpdateTournamentEvent 
    @eventID = 16, 
    @facilityID = 2, 
    @eventName = 'PIKACHU', 
    @eventDate = '2022-09-27 08:00:00', 
    @status = 1;

Select * FROM TournamentEvents
Select * FROM TournamentEventAudit

CREATE PROCEDURE DeleteTournamentEvent
    @eventID INT                         -- The ID of the event to delete
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @userID INT;
    SELECT @userID = ID FROM dbo.userdetails WHERE username = SYSTEM_USER;

    IF EXISTS (SELECT 1 FROM dbo.userdetails WHERE ID = @userID)
    BEGIN
        
        IF NOT EXISTS (
            SELECT 1
            FROM TournamentEvents
            WHERE eventID = @eventID
        )
        BEGIN
            PRINT 'Event not found.';
            RETURN;
        END

        DELETE FROM TournamentEvents
        WHERE eventID = @eventID;

        PRINT 'Tournament Event has been successfully deleted.';
    END
    ELSE
    BEGIN
        PRINT 'You are not authorized to perform this action.';
    END
END;


CREATE TRIGGER trgTournamentEventDelete
ON TournamentEvents
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO TournamentEventAudit
    SELECT NEWID(),D.eventID,'DELETE',GETDATE(),D.userID,SYSTEM_USER,D.eventName,D.eventName,NULL,D.eventDate,D.status                       
    FROM deleted D;  
END;



EXEC DeleteTournamentEvent
@eventID=2;

Select * FROM TournamentEvents
Select * FROM TournamentEventAudit


GRANT EXEC ON AddTournamentEvent TO TournamentOrganizer;
GRANT EXEC ON UpdateTournamentEvent TO TournamentOrganizer;
GRANT EXEC ON DeleteTournamentEvent TO TournamentOrganizer;
GRANT SELECT ON dbo.TournamentEvents TO TournamentOrganizer;
GRANT SELECT ON dbo.TournamentEventAudit TO TournamentOrganizer;

EXECUTE AS USER = 'Hanson';
REVERT;






