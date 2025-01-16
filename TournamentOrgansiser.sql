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

    IF EXISTS (SELECT 1 FROM dbo.userdetails)
    BEGIN
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

        INSERT INTO dbo.TournamentEvents (facilityID, userID, eventName, eventDate, status)
        VALUES (
            @facilityID,
            (SELECT ID FROM dbo.userdetails),  
            @eventName,
            @eventDate,
            @status
        );

        PRINT 'Tournament Event has been successfully created.';
    END
    ELSE
    BEGIN
        PRINT 'You are not authorized to perform this action.';
    END
END;


EXEC AddTournamentEvent
    @facilityID = 1,
    @eventName = 'TZParty',
    @eventDate = '2010-05-15 09:00:00',
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

    -- Check if the user exists
    IF EXISTS (SELECT 1 FROM dbo.userdetails)
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM TournamentEvents
            WHERE eventName = @eventName
            AND eventDate = @eventDate
            AND eventID != @eventID  -- Ensure it is not the event being updated
        )
        BEGIN
            PRINT 'Error: An event with this name and date already exists.';
            RETURN;
        END

        -- Check if the facility is available on the selected date
        IF NOT EXISTS (
            SELECT 1
            FROM Facility
            WHERE facilityID = @facilityID
            AND availability > 0  -- Ensure the facility has availability
        )
        BEGIN
            PRINT 'Error: The facility is not available for the selected date.';
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


CREATE TRIGGER TournamentEventUpdate
ON TournamentEvents
AFTER UPDATE
AS
BEGIN
	SET NOCOUNT ON;
   
    IF UPDATE(eventName) OR UPDATE(eventDate) OR UPDATE(status)
    BEGIN
       
        INSERT INTO TournamentEventAudit
        SELECT NEWID(),I.eventID,'UPDATE',GETDATE(),I.userID,SYSTEM_USER,I.eventName,D.eventName,I.eventDate,D.eventDate,D.status                
        FROM inserted I
        INNER JOIN deleted D ON I.eventID = D.eventID; 
    END
END;

--- Testing
EXEC UpdateTournamentEvent 
    @eventID = 5, 
    @facilityID = 2, 
    @eventName = 'NYC', 
    @eventDate = '2051-01-22 08:00:00', 
    @status = 1;

Select * FROM TournamentEvents
Select * FROM TournamentEventAudit

CREATE PROCEDURE DeleteTournamentEvent
    @eventID INT                         
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (SELECT 1 FROM dbo.userdetails)
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



CREATE TRIGGER TournamentEventDelete
ON TournamentEvents
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO TournamentEventAudit
    SELECT NEWID(),D.eventID,'DELETE',GETDATE(),D.userID,SYSTEM_USER,D.eventName,D.eventName,NULL,D.eventDate,D.status                       
    FROM deleted D;  
END;

--- Testing
EXEC DeleteTournamentEvent
@eventID=5;

Select * FROM TournamentEvents
Select * FROM TournamentEventAudit


GRANT EXEC ON AddTournamentEvent TO TournamentOrganizer;
GRANT EXEC ON UpdateTournamentEvent TO TournamentOrganizer;
GRANT EXEC ON DeleteTournamentEvent TO TournamentOrganizer;
GRANT EXEC ON RegisterParticipants TO TournamentOrganizer;
GRANT EXEC ON UpdateParticipantInfo TO TournamentOrganizer;
GRANT EXEC ON Payment TO TournamentOrganizer;
GRANT EXEC ON dbo.updateDetails TO TournamentOrganizer;
GRANT EXEC ON BookFacility TO TournamentOrganizer
GRANT SELECT ON Booking TO TournamentOrganizer;
GRANT SELECT ON viewPayment TO TournamentOrganizer
GRANT SELECT ON ViewParticipants TO TournamentOrganizer;
GRANT SELECT ON viewTransaction TO TournamentOrganizer;
GRANT SELECT ON ParticipantsAdutiTable TO TournamentOrganizer;
GRANT SELECT ON dbo.userDetails TO TournamentOrganizer;
GRANT SELECT ON dbo.TournamentEvents TO TournamentOrganizer;
GRANT SELECT ON dbo.TournamentEventAudit TO TournamentOrganizer;
DENY SELECT ON Participants TO TournamentOrganizer;
DENY SELECT ON Users TO TournamentOrganizer;
DENY SELECT ON ActivityLog TO TournamentOrganizer;
DENY SELECT ON Payment TO TournamentOrganizer;
DENY SELECT ON [Transaction] TO TournamentOrganizer;

EXECUTE AS USER = 'Hanson';
REVERT;






