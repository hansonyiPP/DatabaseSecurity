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

CREATE PROCEDURE doPayment
	@facilityID INT,
	@userID INT,
	@type VARCHAR(50),
	@amount INT,
	@cardNo VARCHAR(16),
	@expiryDate DATE,
	@CCV VARCHAR(3)
AS
BEGIN
	DECLARE @ENC_CardNumber VARBINARY(MAX);
	DECLARE @ENC_CCV VARBINARY(MAX);
	SET @ENC_CardNumber = ENCRYPTBYCERT(CERT_ID('Cert_Payment'), @cardNo);
	SET @ENC_CCV = ENCRYPTBYCERT(CERT_ID('Cert_Payment'), @CCV); 

	INSERT INTO Payment (facilityID, userID, type, amount, cardNo, expiryDate, CCV)
	VALUES (@facilityID, @userID, @type, @amount, @ENC_CardNumber, @expiryDate, @ENC_CCV);
END

UPDATE Payment SET
cardNo = ENCRYPTBYCERT(CERT_ID('Cert_Payment'), '1234567891234567')
WHERE paymentID = 1

EXEC doPayment 1, 2, 'Card', 150, '0000000000000000', '2025-07-31', '125'