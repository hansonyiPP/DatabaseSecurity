--USE testDB;

-- Create View
--CREATE VIEW OrganizerDetails AS
--SELECT
--    ID AS OrganizerID,
--    Username,
--    Name,
--    Mobile,
--    Email,
--    Last_login
--FROM
--    Users
--WHERE
--    Role = 'Tournament Organiser';

--CREATE PROCEDURE UpdateOrganizerDetails
--    @OrganizerID INT,
--    @Username NVARCHAR(50),
--    @Name CHAR(100),
--    @Mobile VARCHAR(12),
--    @Email VARCHAR(50)
--AS
--BEGIN
--    -- Check if the user is a Tournament Organizer
--    IF EXISTS (SELECT 1 FROM Users WHERE ID = @OrganizerID AND Role = 'Tournament Organiser')
--    BEGIN
--        -- Check if there are any events scheduled less than 24 hours from now
--        IF NOT EXISTS (
--            SELECT 1 
--            FROM TournamentEvents 
--            WHERE OrganizerID = @OrganizerID 
--              AND DATEDIFF(hour, GETDATE(), EventDate) < 24
--        )
--        BEGIN
--            -- Update the organizer's details without changing Last_login
--            UPDATE Users
--            SET Username = @Username,
--                Name = @Name,
--                Mobile = @Mobile,
--                Email = @Email
--            WHERE ID = @OrganizerID;

--            -- Log the update
--            INSERT INTO Activity_Log (type, description, Date, UserID)
--            VALUES ('Update', 'Updated details for organizer ' + @Username, GETDATE(), @OrganizerID);
--        END
--        ELSE
--        BEGIN
--            RAISERROR('Updates cannot be made less than 24 hours before a scheduled event.', 16, 1);
--        END
--    END
--    ELSE
--    BEGIN
--        RAISERROR('User is not a Tournament Organizer.', 16, 1);
--    END
--END;

--EXEC UpdateOrganizerDetails
--    @OrganizerID = 2,
--    @Username = 'YIP',
--    @Name = 'hanson',
--    @Mobile = '023948234',
--    @Email = 'yip@gmail.com';

--Facility table
--CREATE TABLE Facilities (
--    FacilityID INT PRIMARY KEY IDENTITY(1,1),
--    FacilityName VARCHAR(255),
--    Location VARCHAR(255),
--    Capacity INT
--);

--CREATE PROCEDURE AddFacility
--    @FacilityName VARCHAR(255),
--    @Location VARCHAR(255),
--    @Capacity INT,
--    @OrganizerID INT
--AS
--BEGIN
--    -- Check if the user is a Tournament Organizer
--    IF EXISTS (SELECT 1 FROM Users WHERE ID = @OrganizerID AND Role = 'Tournament Organiser')
--    BEGIN
--        INSERT INTO Facilities (FacilityName, Location, Capacity)
--        VALUES (@FacilityName, @Location, @Capacity);

--        INSERT INTO Activity_Log (type, description, Date, UserID)
--        VALUES ('Create', 'Added facility ' + @FacilityName, GETDATE(), @OrganizerID);
--    END
--    ELSE
--    BEGIN
--        RAISERROR('User is not a Tournament Organizer', 16, 1);
--    END
--END;

--EXEC AddFacility
--    @FacilityName = 'New Gym',
--    @Location = 'Building C',
--    @Capacity = 100,
--    @OrganizerID = 5;


--CREATE PROCEDURE UpdateFacility
--    @FacilityID INT,
--    @FacilityName VARCHAR(255),
--    @Location VARCHAR(255),
--    @Capacity INT,
--    @OrganizerID INT
--AS
--BEGIN
--    -- Check if the user is a Tournament Organizer
--    IF EXISTS (SELECT 1 FROM Users WHERE ID = @OrganizerID AND Role = 'Tournament Organiser')
--    BEGIN
--        -- Update the facility
--        UPDATE Facilities
--        SET FacilityName = @FacilityName, Location = @Location, Capacity = @Capacity
--        WHERE FacilityID = @FacilityID;

--        -- Log the update
--        INSERT INTO Activity_Log (type, description, Date, UserID)
--        VALUES ('Update', 'Updated facility ' + @FacilityName, GETDATE(), @OrganizerID);
--    END
--    ELSE
--    BEGIN
--        RAISERROR('User is not a Tournament Organizer', 16, 1);
--    END
--END;

--EXEC UpdateFacility
--    @FacilityID = 1,
--    @FacilityName = 'Updated Gym',
--    @Location = 'Building D',
--    @Capacity = 150,
--    @OrganizerID = 2;

--CREATE PROCEDURE DeleteFacility
--    @FacilityID INT,
--    @OrganizerID INT
--AS
--BEGIN
--    -- Check if the user is a Tournament Organizer
--    IF EXISTS (SELECT 1 FROM Users WHERE ID = @OrganizerID AND Role = 'Tournament Organiser')
--    BEGIN
--        DECLARE @FacilityName VARCHAR(255);

--        -- Retrieve the facility name for logging
--        SELECT @FacilityName = FacilityName FROM Facilities WHERE FacilityID = @FacilityID;

--        -- Delete the facility
--        DELETE FROM Facilities WHERE FacilityID = @FacilityID;

--        -- Log the deletion
--        INSERT INTO Activity_Log (type, description, Date, UserID)
--        VALUES ('Delete', 'Deleted facility ' + @FacilityName, GETDATE(), @OrganizerID);
--    END
--    ELSE
--    BEGIN
--        RAISERROR('User is not a Tournament Organizer', 16, 1);
--    END
--END;

--EXEC DeleteFacility @FacilityID = 1, @OrganizerID = 2;

--CREATE VIEW ViewFacilities AS
--SELECT 
--    FacilityID,
--    FacilityName,
--    Location,
--    Capacity
--FROM 
--    Facilities;


--ALTER TABLE Users
--ADD CONSTRAINT PK_Users PRIMARY KEY (ID);

--CREATE TABLE TournamentEvents (
--    EventID INT PRIMARY KEY IDENTITY(1,1),
--    OrganizerID INT,
--    EventName VARCHAR(255),
--    EventDate DATETIME,
--    FacilityID INT,
--    CONSTRAINT FK_Organizer FOREIGN KEY (OrganizerID) REFERENCES Users(ID),
--    CONSTRAINT FK_Facility FOREIGN KEY (FacilityID) REFERENCES Facilities(FacilityID)
--);

--CREATE PROCEDURE AddTournamentEvent
--    @OrganizerID INT,
--    @EventName VARCHAR(255),
--    @EventDate DATETIME,
--    @FacilityID INT
--AS
--BEGIN
--    -- Check if user is a Tournament Organizer
--    IF EXISTS (SELECT 1 FROM Users WHERE ID = @OrganizerID AND Role = 'Tournament Organiser')
--    BEGIN
--        -- Check if the facility is available
--        IF NOT EXISTS (SELECT 1 FROM TournamentEvents WHERE FacilityID = @FacilityID AND EventDate = @EventDate)
--        BEGIN
--            INSERT INTO TournamentEvents (OrganizerID, EventName, EventDate, FacilityID)
--            VALUES (@OrganizerID, @EventName, @EventDate, @FacilityID);

--            INSERT INTO Activity_Log (type, description, Date)
--            VALUES ('Create', 'Created tournament event ' + @EventName, GETDATE());
--        END
--        ELSE
--        BEGIN
--            RAISERROR('The specified Facility is already booked for the selected date and time.', 16, 1);
--        END
--    END
--    ELSE
--    BEGIN
--        RAISERROR('User is not a Tournament Organizer', 16, 1);
--    END
--END;

--EXEC AddTournamentEvent 
--    @OrganizerID = 5, 
--    @EventName = 'Spring Championship', 
--    @EventDate = '2024-03-20 10:00:00', 
--    @FacilityID = 1;

--DROP PROCEDURE DeleteTournamentEvent;

--CREATE PROCEDURE UpdateTournamentEvent
--    @EventID INT,
--    @EventName VARCHAR(255),
--    @FacilityID INT,
--    @OrganizerID INT
--AS
--BEGIN
--    -- Check if the user is a Tournament Organizer
--    IF NOT EXISTS (SELECT 1 FROM Users WHERE ID = @OrganizerID AND Role = 'Tournament Organiser')
--    BEGIN
--        RAISERROR('User is not a Tournament Organizer', 16, 1);
--        RETURN;
--    END

--    -- Check if the event exists
--    IF NOT EXISTS (SELECT 1 FROM TournamentEvents WHERE EventID = @EventID)
--    BEGIN
--        RAISERROR('The specified EventID does not exist.', 16, 1);
--        RETURN;
--    END

--    -- Check if the new facility exists
--    IF NOT EXISTS (SELECT 1 FROM Facilities WHERE FacilityID = @FacilityID)
--    BEGIN
--        RAISERROR('The specified FacilityID does not exist.', 16, 1);
--        RETURN;
--    END

--    -- Check if the facility is already booked
--    IF EXISTS (SELECT 1 FROM TournamentEvents WHERE FacilityID = @FacilityID AND EventDate = GETDATE())
--    BEGIN
--        RAISERROR('The specified Facility is already booked.', 16, 1);
--        RETURN;
--    END

--    DECLARE @OldEventName VARCHAR(255);

--    -- Retrieve the old event name for logging
--    SELECT @OldEventName = EventName FROM TournamentEvents WHERE EventID = @EventID;

--    -- Update the event
--    UPDATE TournamentEvents
--    SET EventName = @EventName, EventDate = GETDATE(), FacilityID = @FacilityID
--    WHERE EventID = @EventID;

--    -- Log the update
--    INSERT INTO Activity_Log (type, description, Date, UserID)
--    VALUES ('Update', 'Updated event ' + @OldEventName + ' to ' + @EventName, GETDATE(), @OrganizerID);
--END;

--EXEC UpdateTournamentEvent
--    @EventID = 2,
--    @EventName = 'Summer Championship',
--    @FacilityID = 1,
--    @OrganizerID = 2;

--CREATE PROCEDURE DeleteTournamentEvent
--    @EventID INT,
--    @OrganizerID INT
--AS
--BEGIN
--    -- Check if the organizer exists
--    IF NOT EXISTS (SELECT 1 FROM Users WHERE ID = @OrganizerID AND Role = 'Tournament Organiser')
--    BEGIN
--        RAISERROR('User is not a Tournament Organizer.', 16, 1);
--        RETURN;
--    END

--    DECLARE @EventName VARCHAR(255);

--    -- Retrieve the event name for logging
--    SELECT @EventName = EventName FROM TournamentEvents WHERE EventID = @EventID;

--    -- Delete the event
--    DELETE FROM TournamentEvents WHERE EventID = @EventID;

--    -- Log the deletion
--    INSERT INTO Activity_Log (type, description, Date, UserID)
--    VALUES ('Delete', 'Deleted tournament event ' + @EventName, GETDATE(), @OrganizerID);
--END;

--EXEC DeleteTournamentEvent @EventID = 1,@organizerID = 2;

--CREATE VIEW ViewTournamentEvents AS
--SELECT 
--    te.EventID,
--    te.EventName,
--    te.EventDate,
--    te.OrganizerID,
--    u.Username AS OrganizerUsername,
--    u.Name AS OrganizerName,
--    te.FacilityID,
--    f.FacilityName,
--    f.Location
--FROM 
--    TournamentEvents te
--JOIN 
--    Users u ON te.OrganizerID = u.ID
--JOIN 
--    Facilities f ON te.FacilityID = f.FacilityID;

--CREATE TABLE Participants (
--    ParticipantID INT PRIMARY KEY IDENTITY(1,1),
--    EventID INT,
--    Name VARCHAR(255),
--    ContactInfo VARCHAR(255),
--    CONSTRAINT FK_Event FOREIGN KEY (EventID) REFERENCES TournamentEvents(EventID)
--);

--CREATE PROCEDURE AddParticipant
--    @EventID INT,
--    @Name VARCHAR(255),
--    @ContactInfo VARCHAR(255)
--AS
--BEGIN
--    -- Check if the event exists
--    IF EXISTS (SELECT 1 FROM TournamentEvents WHERE EventID = @EventID)
--    BEGIN
--        -- Insert new participant
--        INSERT INTO Participants (EventID, Name, ContactInfo)
--        VALUES (@EventID, @Name, @ContactInfo);

--        -- Log the addition
--        INSERT INTO Activity_Log (type, description, Date)
--        VALUES ('Create', 'Added participant ' + @Name + ' to event ' + CAST(@EventID AS VARCHAR), GETDATE());
--    END
--    ELSE
--    BEGIN
--        RAISERROR('The specified EventID does not exist.', 16, 1);
--    END
--END;

--EXEC AddParticipant
--    @EventID = 2,
--    @Name = 'Zhong',
--    @ContactInfo = 'zhong@hacker.com';

--CREATE PROCEDURE UpdateParticipantDetails
--    @ParticipantID INT,
--    @Name VARCHAR(255),
--    @ContactInfo VARCHAR(255)
--AS
--BEGIN
--    -- Check if the participant exists
--    IF EXISTS (SELECT 1 FROM Participants WHERE ParticipantID = @ParticipantID)
--    BEGIN
--        -- Check if the update is less than 24 hours before the event
--        IF EXISTS (
--            SELECT 1 
--            FROM Participants p
--            JOIN TournamentEvents te ON p.EventID = te.EventID
--            WHERE p.ParticipantID = @ParticipantID
--              AND DATEDIFF(hour, GETDATE(), te.EventDate) < 24
--        )
--        BEGIN
--            RAISERROR('Updates cannot be made less than 24 hours before a scheduled event.', 16, 1);
--        END
--        ELSE
--        BEGIN
--            -- Update participant details
--            UPDATE Participants
--            SET Name = @Name, ContactInfo = @ContactInfo
--            WHERE ParticipantID = @ParticipantID;

--            -- Log the update
--            INSERT INTO Activity_Log (type, description, Date, UserID)
--            VALUES ('Update', 'Updated details for participant ' + CAST(@ParticipantID AS VARCHAR), GETDATE(), @ParticipantID);
--        END
--    END
--    ELSE
--    BEGIN
--        RAISERROR('The specified ParticipantID does not exist.', 16, 1);
--    END
--END;

--EXEC UpdateParticipantDetails
--    @ParticipantID = 1,
--    @Name = 'Zhong',
--    @ContactInfo = 'zhong@hacker.com';

--CREATE TABLE IndividualCustomerRegistrations (
--    RegistrationID INT PRIMARY KEY IDENTITY(1,1),
--    EventID INT,
--    UserID INT,
--    CONSTRAINT FK_Event_Registration FOREIGN KEY (EventID) REFERENCES TournamentEvents(EventID),
--    CONSTRAINT FK_Customer_Registration FOREIGN KEY (UserID) REFERENCES Users(ID)
--);

--CREATE PROCEDURE IndividualCustomerRegisterForEvent
--    @EventID INT,
--    @UserID INT
--AS
--BEGIN
--    -- Check if the user is an Individual Customer
--    IF EXISTS (SELECT 1 FROM Users WHERE ID = @UserID AND Role = 'Individual Customer')
--    BEGIN
--        -- Check if the event exists
--        IF EXISTS (SELECT 1 FROM TournamentEvents WHERE EventID = @EventID)
--        BEGIN
--            -- Insert into IndividualCustomerRegistrations
--            INSERT INTO IndividualCustomerRegistrations (EventID, UserID)
--            VALUES (@EventID, @UserID);

--            -- Log the registration
--            INSERT INTO Activity_Log (type, description, Date, UserID)
--            VALUES ('Register', 'Registered individual customer with UserID ' + CAST(@UserID AS VARCHAR) + ' for event ' + CAST(@EventID AS VARCHAR), GETDATE(), @UserID);
--        END
--        ELSE
--        BEGIN
--            RAISERROR('The specified EventID does not exist.', 16, 1);
--        END
--    END
--    ELSE
--    BEGIN
--        RAISERROR('The specified UserID is not an Individual Customer.', 16, 1);
--    END
--END;

--EXEC IndividualCustomerRegisterForEvent
--    @EventID = 2,
--    @UserID = 3;

-- List out all partipants
--CREATE VIEW EventParticipantsSummary AS
--SELECT
--    te.EventID,
--    te.EventName,
--    te.EventDate,
--    te.OrganizerID,
--    u.Username AS OrganizerUsername,
--    u.Name AS OrganizerName,
--    p.ParticipantID,
--    p.Name AS ParticipantName,
--    'Participant' AS ParticipantType
--FROM
--    TournamentEvents te
--LEFT JOIN
--    Participants p ON te.EventID = p.EventID
--JOIN
--    Users u ON te.OrganizerID = u.ID
--UNION
--SELECT
--    te.EventID,
--    te.EventName,
--    te.EventDate,
--    te.OrganizerID,
--    u.Username AS OrganizerUsername,
--    u.Name AS OrganizerName,
--    icr.UserID AS ParticipantID,
--    iu.Name AS ParticipantName,
--    'Individual Customer' AS ParticipantType
--FROM
--    TournamentEvents te
--LEFT JOIN
--    IndividualCustomerRegistrations icr ON te.EventID = icr.EventID
--JOIN
--    Users u ON te.OrganizerID = u.ID
--JOIN
--    Users iu ON icr.UserID = iu.ID;

-- View Total Participants
--CREATE VIEW EventParticipantsSummary AS
--SELECT
--    te.EventID,
--    te.EventName,
--    te.EventDate,
--    te.OrganizerID,
--    u.Username AS OrganizerUsername,
--    u.Name AS OrganizerName,
--    (SELECT COUNT(*) FROM Participants p WHERE p.EventID = te.EventID) +
--    (SELECT COUNT(*) FROM IndividualCustomerRegistrations icr WHERE icr.EventID = te.EventID) AS TotalParticipants
--FROM
--    TournamentEvents te
--JOIN
--    Users u ON te.OrganizerID = u.ID;







