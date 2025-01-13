EXECUTE AS USER = 'SK';
REVERT;
SELECT * FROM Payment

INSERT INTO Payment VALUES (1, 2, 'Card', 60, '0000000000000001', '2025-05-31', '133')

-- Create Master Key
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'QwErTy12345!@#$%'
GO
SELECT * FROM sys.symmetric_keys
GO

-- Create Certificate
CREATE CERTIFICATE Cert_Payment
WITH Subject = 'Cert_For_Payment'
GO
SELECT * FROM sys.certificates

CREATE TRIGGER trg_EncryptCards
ON Payment
AFTER INSERT
AS
BEGIN
	UPDATE Payment
	SET
		cardNo =  ENCRYPTBYCERT(CERT_ID('Cert_Payment'), CAST(i.cardNo AS NVARCHAR(MAX))),
        CCV = HASHBYTES('sha2_256', CAST(i.CCV AS NVARCHAR(MAX)))
	FROM Payment p
	INNER JOIN inserted i
		ON p.facilityID = i.facilityID
		AND p.userID = i.userID
		AND p.type = i.type
		AND p.amount = i.amount
		AND p.expiryDate = i.expiryDate;
END

INSERT INTO Payment VALUES (1, 3, 'Card', 150, '2024-07-31', CONVERT(VARBINARY(MAX), '1234567812345678'), CONVERT(VARBINARY(MAX), '123'))


SELECT * FROM Payment
