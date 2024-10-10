CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) UNIQUE NOT NULL,
    Password NVARCHAR(255) NOT NULL, -- Store hashed passwords
    Role NVARCHAR(50) CHECK (Role IN ('DataAdmin', 'ComplexManager', 'TournamentOrganizer', 'IndividualCustomer')) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    LastLogin DATETIME NULL, 

);

CREATE TABLE TournamentOrganizers (
    OrganizerID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL,
    OrganizationName NVARCHAR(100) NOT NULL,
    ContactNumber NVARCHAR(15) NULL,
    Email NVARCHAR(100) UNIQUE NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE
);