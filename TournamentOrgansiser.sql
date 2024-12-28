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
    @userID INT,
    @eventName VARCHAR(100),
    @eventDate DATETIME,
    @status BIT
AS
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
    INSERT INTO TournamentEvents (facilityID, userID, eventName, eventDate, status)
    VALUES (@facilityID, @userID, @eventName, @eventDate, @status);

    PRINT 'Tournament Event has been successfully created.';
END;

EXEC AddTournamentEvent
    @facilityID = 1,
    @userID = 1,
    @eventName = 'Annual Tennis Championship',
    @eventDate = '2024-05-15 09:00:00',
    @status = 1;  -- 1 for active, 0 for inactive


CREATE PROCEDURE UpdateTournamentEvent
    @eventID INT,                       -- The ID of the event to update
    @facilityID INT,                    -- The new facility ID
    @userID INT,                        -- The user who is updating the event
    @eventName VARCHAR(100),            -- The new event name
    @eventDate DATETIME,                -- The new event date
    @status BIT                         -- The new status
AS
BEGIN
    -- Check if an event with the same name and date already exists (excluding the current event)
    IF EXISTS (
        SELECT 1
        FROM TournamentEvents
        WHERE eventName = @eventName
        AND eventDate = @eventDate
        AND eventID != @eventID  -- Exclude the current event being updated
    )
    BEGIN
        PRINT 'Error: An event with this name and date already exists.';
        RETURN;
    END

    -- Check if the facility is available for the new event date
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

    -- Update the existing event in the TournamentEvents table
    UPDATE TournamentEvents
    SET 
        facilityID = @facilityID,
        userID = @userID,
        eventName = @eventName,
        eventDate = @eventDate,
        status = @status
    WHERE eventID = @eventID;

    PRINT 'Tournament Event has been successfully updated.';
END;


CREATE TRIGGER trgTournamentEventUpdate
ON TournamentEvents
AFTER UPDATE
AS
BEGIN
    -- Check if the event name, date, or status was updated
    IF UPDATE(eventName) OR UPDATE(eventDate) OR UPDATE(status)
    BEGIN
        -- Insert the changes into the TournamentEventAudit table
        INSERT INTO TournamentEventAudit
        SELECT NEWID(),I.eventID,'UPDATE',GETDATE(),I.userID,SUSER_SNAME(),I.eventName,D.eventName,I.eventDate,D.eventDate,D.status                
        FROM inserted I
        INNER JOIN deleted D ON I.eventID = D.eventID;  -- Join inserted and deleted to get old and new values
    END
END;


EXEC UpdateTournamentEvent 
    @eventID = 2, 
    @facilityID = 2, 
    @userID = 3, 
    @eventName = 'sad', 
    @eventDate = '2022-09-27 08:00:00', 
    @status = 1;

Select * FROM TournamentEvents
Select * FROM TournamentEventAudit

CREATE PROCEDURE DeleteTournamentEvent
    @eventID INT                         -- The ID of the event to delete
AS
BEGIN
    -- Check if the event exists
    IF NOT EXISTS (
        SELECT 1
        FROM TournamentEvents
        WHERE eventID = @eventID
    )
    BEGIN
        PRINT 'Error: Event not found.';
        RETURN;
    END

    -- Delete the event from the TournamentEvents table
    DELETE FROM TournamentEvents
    WHERE eventID = @eventID;

    PRINT 'Tournament Event has been successfully deleted.';
END;

CREATE TRIGGER trgTournamentEventDelete
ON TournamentEvents
AFTER DELETE
AS
BEGIN
    
    INSERT INTO TournamentEventAudit
    SELECT NEWID(),D.eventID,'DELETE',GETDATE(),D.userID,SUSER_SNAME(),D.eventName,D.eventName,NULL,D.eventDate,D.status                       
    FROM deleted D;  
END;



EXEC DeleteTournamentEvent
@eventID=1;

Select * FROM TournamentEvents
Select * FROM TournamentEventAudit


-- Grant EXECUTE permission on the AddTournamentEvent stored procedure
GRANT EXEC ON AddTournamentEvent TO TournamentOrganizer;
GRANT EXEC ON UpdateTournamentEvent TO TournamentOrganizer;
GRANT EXEC ON DeleteTournamentEvent TO TournamentOrganizer;
GRANT SELECT ON dbo.TournamentEvents TO TournamentOrganizer;
GRANT SELECT ON dbo.TournamentEventAudit TO TournamentOrganizer;

EXECUTE AS USER = 'SK';
REVERT;




