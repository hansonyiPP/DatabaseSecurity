CREATE DATABASE ApArenaDatabaseManagementSystem;

CREATE ROLE DataAdmin;
CREATE ROLE ComplexManager;
CREATE ROLE TournamentOrganizer;
CREATE ROLE IndividualCustomer;

CREATE LOGIN DA1 With Password='123';
CREATE USER DA1 FOR LOGIN DA1;
CREATE USER DA2 WITHOUT LOGIN;
ALTER ROLE DataAdmin ADD MEMBER DA1;
ALTER ROLE DataAdmin ADD MEMBER DA2;

CREATE LOGIN TZ with Password='123';
CREATE USER TZ FOR LOGIN TZ;
CREATE USER CM2 WITHOUT LOGIN;
ALTER ROLE ComplexManager ADD MEMBER TZ;
ALTER ROLE ComplexManager ADD MEMBER CM2;

CREATE LOGIN Hanson with Password='123';
CREATE USER Hanson FOR LOGIN Hanson;
CREATE USER TO2 WITHOUT LOGIN;
ALTER ROLE TournamentOrganizer ADD MEMBER Hanson;
ALTER ROLE TournamentOrganizer ADD MEMBER TO2;

CREATE LOGIN SK with Password='123';
CREATE USER SK FOR LOGIN SK;
CREATE USER TC2 WITHOUT LOGIN;
ALTER ROLE IndividualCustomer ADD MEMBER SK;
ALTER ROLE IndividualCustomer ADD MEMBER TC2;

CREATE TABLE Users (
    ID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    Username varchar(50) NOT NULL, -- New column
    Name char(100) MASKED WITH (FUNCTION = 'partial(1,"X",1)') NOT NULL,
    Mobile varchar(12) MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-",4)') NOT NULL,
    email varchar(50) MASKED WITH (FUNCTION = 'email()') NOT NULL,
    Last_login datetime NULL,
    IsDeleted bit NOT NULL,
    ValidFrom datetime2 GENERATED ALWAYS AS ROW START NOT NULL,
    ValidTo datetime2 GENERATED ALWAYS AS ROW END NOT NULL,
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo)
) WITH (SYSTEM_VERSIONING = ON (HISTORY_TABLE = dbo.UsersHistory));

CREATE TABLE Facility(
	facilityID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	name varchar(100) NOT NULL,
	availability int NOT NULL,
	price int NOT NULL
);

INSERT INTO Facility VALUES ('Badminton Court',10,10),('Basketball Court',5,200),('Volley Court',4,150),('Squash Court',5,20),('Olympic Sized Swimming Pool',3,30);

CREATE TABLE Booking(
    bookingID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    facilityID int NOT NULL,
    userID int NOT NULL,
    startTime datetime,
    endTime datetime,
    isApproved bit,
    CONSTRAINT FK_Booking_Facility FOREIGN KEY (facilityID) REFERENCES Facility(facilityID),
    CONSTRAINT FK_Booking_User FOREIGN KEY (userID) REFERENCES Users(ID)
);

INSERT INTO Booking (facilityID, userID, startTime, endTime, isApproved) VALUES 
(1, 1, '2024-12-16 14:00:00', '2024-12-16 16:00:00', 1), -- Booking for Badminton Court by User 1
(2, 2, '2024-12-16 10:00:00', '2024-12-16 12:00:00', 1), -- Booking for Basketball Court by User 2
(3, 3, '2024-12-17 09:00:00', '2024-12-17 11:00:00', 0), -- Booking for Volley Court by User 3 (not approved)
(4, 1, '2024-12-18 15:00:00', '2024-12-18 17:00:00', 1), -- Booking for Squash Court by User 1
(5, 3, '2024-12-19 08:00:00', '2024-12-19 10:00:00', 1); -- Booking for Olympic Sized Swimming Pool by User 3

CREATE TABLE Participants(
	participantID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	teamID int,
	Name varchar(100) NOT NULL,
    Mobile varchar(12) NOT NULL,
    email varchar(50) NOT NULL,
	CONSTRAINT FK_Participants_ParticipantTeam FOREIGN KEY (teamID) REFERENCES ParticipantTeam(teamID),
);

CREATE TABLE ParticipantTeam(
    teamID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
    teamName varchar(100) NOT NULL,
    bookingID int,
	eventID int,
	CONSTRAINT FK_ParticipantTeam_Booking FOREIGN KEY (bookingID) REFERENCES Booking(bookingID),
	CONSTRAINT FK_ParticipantTeam_TournamentEvents FOREIGN KEY (eventID) REFERENCES TournamentEvents(eventID)
);


CREATE TABLE TournamentEvents(
    eventID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	facilityID int NOT NULL,
	userID int NOT NULL,
	eventName varchar(100) NOT NULL,
	eventDate datetime NOT NULL,
	status bit NOT NULL,
	CONSTRAINT FK_TournamentEvents_Facility FOREIGN KEY (facilityID) REFERENCES Facility(facilityID),
    CONSTRAINT FK_TournamentEvents_User FOREIGN KEY (userID) REFERENCES Users(ID)
);

CREATE TABLE ActivityLog(
	logID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	type text NOT NULL,
	description nvarchar(256) NOT NULL,
	Date datetime NOT NULL
);

CREATE TABLE [Transaction](
	transactionID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	bookingID int NOT NULL,
	paymentID int NOT NULL,
	price int NOT NULL,
	dateTime datetime NOT NULL,
	CONSTRAINT FK_Transaction_Booking FOREIGN KEY (bookingID) REFERENCES Booking(bookingID),
	CONSTRAINT FK_Transaction_Payment FOREIGN KEY (paymentID) REFERENCES Payment(paymentID)
);

CREATE TABLE Payment(
	paymentID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	facilityID int NOT NULL,
	userID int NOT NULL,
	type varchar(50) NOT NULL,
	amount int NOT NULL,
	cardNo varchar(16) NOT NULL,
	expiryDate date NOT NULL,
	CCV varbinary NOT NULL,
	CONSTRAINT FK_Payment_Facility FOREIGN KEY (facilityID) REFERENCES Facility(facilityID),
    CONSTRAINT FK_Payments_User FOREIGN KEY (userID) REFERENCES Users(ID)
);

CREATE TABLE businessEntity(
	businessID int IDENTITY(1,1) NOT NULL PRIMARY KEY,
	userID int NOT NULL, -- register by which userID
	Name varchar(100) NOT NULL, -- Business name
    Mobile varchar(12) NOT NULL,
    email varchar(50) NOT NULL,
	address varchar (255) NOT NULL,
	status bit NOT NULL,
    CONSTRAINT FK_businessEntity_User FOREIGN KEY (userID) REFERENCES Users(ID)
);


EXEC sp_readerrorlog 0, 1, 'Login'

