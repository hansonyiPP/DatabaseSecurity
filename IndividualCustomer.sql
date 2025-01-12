-- Create Schema for user to edit only they  data
CREATE SCHEMA Security;
GO

ALTER FUNCTION Security.securitypredicate(
	@Username AS varchar(50))
	RETURNS TABLE
WITH SCHEMABINDING
AS
	RETURN SELECT 1 AS securitypredicate_result
WHERE @Username = USER_NAME() OR IS_MEMBER('DataAdmin') = 1 OR IS_MEMBER('ComplexManager') = 1;
GO

CREATE SECURITY POLICY userFilter
ADD FILTER PREDICATE Security.securitypredicate(Username)
ON dbo.Users
WITH (STATE = ON);

ALTER SECURITY POLICY userFilter WITH ( STATE = OFF );

SELECT * FROM userDetails
SELECT * FROM Users

-- Create VIEW for user to view their details 
CREATE VIEW userDetails AS
SELECT
	ID,
    Username,
    Name,
    Mobile,
    Email
FROM
    Users

GRANT SELECT ON dbo.userDetails TO ComplexManager;
GRANT SELECT ON dbo.userDetails TO IndividualCustomer;
GRANT SELECT ON dbo.userDetails TO TournamentOrganizer;
GRANT UNMASK TO IndividualCustomer;
GRANT UNMASK TO TournamentOrganizer;
GRANT EXEC ON dbo.createUserAccount TO DataAdmin;

-- Update user details with schema
GRANT UPDATE ON dbo.Users (Name, Mobile, Email) TO IndividualCustomer; -- I feel like this is enough. This is all about security level .
GRANT UPDATE ON dbo.Users (Name, Mobile, Email) TO TournamentOrganizer; 
-- This more toward application liao
CREATE PROCEDURE updateDetails 
	@Name char(100),
	@Mobile varchar(12),
	@Email varchar(50)
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE dbo.Users
	SET 
		Name = @Name,
		Mobile = @Mobile,
		email = @Email
	WHERE Username = USER_NAME();

	IF @@ROWCOUNT = 0
	BEGIN
		PRINT 'User does not exists or you dont have permission to update.';
	END
	ELSE
	BEGIN
		PRINT 'User details update successfully.';
	END
END;

EXEC dbo.updateDetails 'ShengKit', '0123456789', 'tsk@example.com'
GRANT EXEC ON dbo.updateDetails TO IndividualCustomer;
GRANT EXEC ON dbo.updateDetails TO TournamentOrganizer;

-- Book one facility at a time
SELECT * FROM Users;
SELECT * FROM Facility;
SELECT * FROM Booking;

CREATE PROCEDURE BookFacility
	@userID INT,
	@FacilityID INT,
	@startTime DATETIME,
	@endTime DATETIME
AS
BEGIN
	-- Check if the customer already has a booking 
	IF EXISTS(
		SELECT 1
		FROM Booking
		WHERE userID = @userID
		AND ((@startTime BETWEEN startTime AND endTime) OR (@endTime BETWEEN startTime AND endTime))
	)
	BEGIN
		PRINT 'You already have a Booking at this time.';
		RETURN;
	END
	IF EXISTS(
		SELECT 1
		FROM Booking
		WHERE facilityID = @FacilityID
		AND ((@startTime BETWEEN startTime AND endTime) OR (@endTime BETWEEN startTime AND endTime))
	)
	BEGIN
		PRINT 'The facility has been booked by others.';
		RETURN;
	END
	IF NOT EXISTS(
		SELECT 1
		FROM Facility
		WHERE facilityID = @FacilityID
		AND availability > 0
	)
	BEGIN
		PRINT 'The facility is not available.'
		RETURN;
	END
	
	INSERT INTO Booking(userID, FacilityID, startTime, endTime, isApproved)
	VALUES (@userID, @FacilityID, @startTime, @endTime, 0)

	PRINT 'Booking Successful.';
	
END;

SELECT * FROM Facility
GRANT EXEC ON BookFacility TO IndividualCustomer;
EXEC BookFacility 2, 1, '2024-12-16 14:00:00', '2024-03-21 10:00:00'

-- Participant Team
SELECT * FROM Booking
SELECT * FROM ParticipantTeam
INSERT INTO ParticipantTeam (teamName, bookingID) VALUES ('Team 3', 2)

---

-- Register participant
CREATE PROCEDURE RegisterParticipants
	@teamID INT,
	@name CHAR(100),
    @email VARCHAR(50),
	@mobile VARCHAR(12)
AS
BEGIN
	-- Check if the booking exists first
	IF NOT EXISTS(
		SELECT 1 
		FROM ParticipantTeam
		WHERE teamID = @teamID
	)
	BEGIN
		PRINT 'Team not found. Please check with the team leader.';
		RETURN;
	END

	INSERT INTO Participants (teamID, Name, Mobile, email)
	VALUES (@teamID, @name, @mobile, @email);

	PRINT 'Participant registration successful.';
END;

SELECT * FROM Participants
EXEC RegisterParticipants 5, 'MewTwo', 'mewtwo@gmail.com', '012345678'
EXEC RegisterParticipants 5, 'MewFour', 'mewthree@gmail.com', '012345678'

-- View participants details under booking
GRANT SELECT ON Participants TO IndividualCustomer
GRANT SELECT ON Booking TO IndividualCustomer
GRANT SELECT ON ParticipantTeam TO IndividualCustomer
GRANT SELECT ON Participants TO TournamentOrganizer
GRANT SELECT ON Booking TO TournamentOrganizer
GRANT SELECT ON ParticipantTeam TO TournamentOrganizer
GRANT SELECT ON ViewParticipants TO IndividualCustomer
GRANT SELECT ON ViewParticipants TO TournamentOrganizer

CREATE VIEW ViewParticipants AS
SELECT 
    B.bookingID,
    UD.Name AS bookedByName, 
    B.startTime,
    B.endTime,
    PT.teamName,
	p.participantID AS ID,
    P.name AS participantName,
    P.email AS participantEmail,
    P.mobile AS participantMobile
FROM 
    Booking B
JOIN 
    userDetails UD ON B.userID = UD.ID 
JOIN 
    ParticipantTeam PT ON B.bookingID = PT.bookingID
JOIN 
    Participants P ON PT.teamID = P.teamID
WHERE 
    B.userID = UD.ID;  

SELECT * FROM ViewParticipants
---

-- Update participants detail
GRANT UPDATE ON dbo.Participants (Name, Mobile, Email) TO IndividualCustomer; -- I feel like this is enough. This is all about security level .
GRANT UPDATE ON dbo.Participants (Name, Mobile, Email) TO TournamentOrganizer; 
-- This more toward application liao
CREATE PROCEDURE UpdateParticipantInfo
	@ParticipantID INT,
    @NewName CHAR(100),
    @NewEmail VARCHAR(50),
    @NewMobile VARCHAR(12)
AS
BEGIN
    SET NOCOUNT ON;
    IF EXISTS (
        SELECT 1
		FROM Booking B
		JOIN 
			userDetails UD ON B.userID = UD.ID 
		JOIN 
			ParticipantTeam PT ON B.bookingID = PT.bookingID
		JOIN 
			Participants P ON PT.teamID = P.teamID
		WHERE  B.BookingID = PT.bookingID
		AND B.UserID = UD.ID
    )
    BEGIN
        -- Update the participant's information
        UPDATE Participants
        SET 
            Name = @NewName,
            Email = @NewEmail,
            Mobile = @NewMobile
        WHERE 
            ParticipantID = @ParticipantID;
		PRINT('Update Successfully');
    END
    ELSE
    BEGIN
        PRINT('You are not authorized to update this participant.');
    END
END;
GRANT EXEC ON UpdateParticipantInfo TO IndividualCustomer;
GRANT EXEC ON UpdateParticipantInfo TO TournamentOrganizer;
EXEC UpdateParticipantInfo 1,'MewMew1','mew123@example.com','012312311'
----

SELECT * FROM Booking
SELECT * FROM Participants
SELECT * FROM ParticipantTeam

EXECUTE AS USER = 'TZ';
SELECT * FROM userDetails
REVERT;

CREATE TABLE UserAuditTable(
	auditID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
	UserID INT NOT NULL,
	Updated_By VARCHAR(50) NOT NULL,
	Updated_Date DATE NOT NULL,
	Original_Name CHAR(100) NOT NULL,
	New_Name CHAR(100) NULL,
    Original_Mobile VARCHAR(12) NOT NULL,
	New_Mobile VARCHAR(12) NULL,
	Original_Email VARCHAR(50) NOT NULL,
    New_Email VARCHAR(50) NOT NULL
)
SELECT * FROM UserAuditTable

CREATE TRIGGER Audit_User_Update
ON Users
FOR UPDATE
AS
BEGIN
	INSERT INTO UserAuditTable (
		AuditID,
		UserID,
		Updated_By,
		Updated_Date,
		Original_Name,
		New_Name,
		Original_Mobile,
		New_Mobile,
		Original_Email,
		New_Email
	)
	SELECT
		NEWID(),
		inserted.ID,
		SYSTEM_USER,
		GETDATE(),
		deleted.Name,
		inserted.Name,
		deleted.Mobile,
		inserted.Mobile,
		deleted.email,
		inserted.email
	FROM 
		deleted
	INNER JOIN 
		inserted ON deleted.ID = inserted.ID
END

CREATE TABLE ParticipantsAuditTable(
	auditID UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
	Updated_By VARCHAR(50) NOT NULL,
	Updated_Date DATE NOT NULL,
	ParticipantID INT NOT NULL,
	Original_Name CHAR(100) NOT NULL,
	New_Name CHAR(100) NULL,
    Original_Mobile VARCHAR(12) NOT NULL,
	New_Mobile VARCHAR(12) NULL,
	Original_Email VARCHAR(50) NOT NULL,
    New_Email VARCHAR(50) NOT NULL
)
SELECT *  FROM ParticipantsAuditTable
CREATE TRIGGER Audit_Participants_Update
ON Participants
FOR UPDATE
AS
BEGIN
	INSERT INTO ParticipantsAuditTable (
		AuditID,
		Updated_By,
		Updated_Date,
		ParticipantID,
		Original_Name,
		New_Name,
		Original_Mobile,
		New_Mobile,
		Original_Email,
		New_Email
	)
	SELECT
		NEWID(),
		SYSTEM_USER,
		GETDATE(),
		inserted.participantID,
		deleted.Name,
		inserted.Name,
		deleted.Mobile,
		inserted.Mobile,
		deleted.email,
		inserted.email
	FROM 
		deleted
	INNER JOIN 
		inserted ON deleted.participantID = inserted.participantID
END