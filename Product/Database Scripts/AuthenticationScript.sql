/****** Object:  Table [dbo].[AccountStatusValues] ******/
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AccountStatusValues](
	[AccountStatusValue] [nvarchar](50) NOT NULL,
	CONSTRAINT [PK_AccountStatusValues] PRIMARY KEY CLUSTERED 
	(
		[AccountStatusValue] ASC
	)
	WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

INSERT [dbo].[AccountStatusValues] ([AccountStatusValue]) VALUES (N'Active')
INSERT [dbo].[AccountStatusValues] ([AccountStatusValue]) VALUES (N'Disabled')
INSERT [dbo].[AccountStatusValues] ([AccountStatusValue]) VALUES (N'Inactive')
INSERT [dbo].[AccountStatusValues] ([AccountStatusValue]) VALUES (N'Locked')

/****** Object:  Table [dbo].[Users] ******/
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[UserId] [uniqueidentifier] NOT NULL,
	[FirstName] [nvarchar](100) NOT NULL,
	[MiddleName] [nvarchar](100) NULL,
	[LastName] [nvarchar](100) NULL,
	[Email] [nvarchar](250) NOT NULL,
	[City] [nvarchar](100) NULL,
	[State] [nvarchar](100) NULL,
	[Country] [nvarchar](100) NULL,
	[LogOnName] [nvarchar](100) NOT NULL,
	[Password] [nvarchar](1024) NOT NULL,
	[AccountStatus] [nvarchar](50) NOT NULL,
	[DateCreated] [datetime] NULL,
	[DateModified] [datetime] NULL,
	[PasswordCreationDate] [date] NULL,
	[SecurityQuestion] [nvarchar](500) NOT NULL,
	[Answer] [nvarchar](1024) NOT NULL,
	[IsAdmin] [bit] NULL,
	CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED 
	(
		[UserId] ASC
	)
	WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY],
	CONSTRAINT [UQ_Users] UNIQUE NONCLUSTERED 
	(
		[LogOnName] ASC
	)
	WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Unique id for the user' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'UserId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'User first name' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'FirstName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'User middle name' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'MiddleName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'User last name' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'LastName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'User email' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'Email'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Demographic information of the user' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'City'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Demographic information of the user' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'State'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Demographic information of the user' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'Country'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Login id of the user' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'LogOnName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Hashed password' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'Password'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Enabled/Disabled' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'AccountStatus'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date of user account creation' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'DateCreated'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date of user account modification' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'DateModified'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Date of password creation / modification' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Users', @level2type=N'COLUMN',@level2name=N'PasswordCreationDate'
GO
INSERT [dbo].[Users] ([UserId], [FirstName], [MiddleName], [LastName], [Email], [City], [State], [Country], [LogOnName], [Password], [AccountStatus], [DateCreated], [DateModified], [PasswordCreationDate], [SecurityQuestion], [Answer], [IsAdmin]) VALUES (N'b8132ca7-45d4-495b-8e3b-b78f72586b1b', N'Built in Administrator Account', NULL, NULL, N'admin@zentityinstallation.com', NULL, NULL, NULL, N'Administrator', N'7w1uHnIXsiTN50l2updXJPK7WwiZU+ag8yl3sNydZNA=', N'Active', GETDATE(), NULL, NULL, N'WHAT IS ZENTITY?', N'ﳭც捪烔弌ᑈ�ꢣ', 1)
INSERT [dbo].[Users] ([UserId], [FirstName], [MiddleName], [LastName], [Email], [City], [State], [Country], [LogOnName], [Password], [AccountStatus], [DateCreated], [DateModified], [PasswordCreationDate], [SecurityQuestion], [Answer], [IsAdmin]) VALUES (N'40f0d988-de61-46a9-b9cc-b65e8c89aef6', N'guest', NULL, NULL, N'guest@abc.com', NULL, NULL, NULL, N'Guest', N'dG1nVE+aJKgXeDEP8PuFWDaMvaHr5U5nmaFgpnKwxMM=', N'Active', GETDATE(), NULL, NULL, N'??', N'㨭䃗抄︘≙昷鵽', NULL)
/****** Object:  UserDefinedFunction [dbo].[GetAccountStatusValues]    Script Date: 04/20/2009 16:13:12 ******/
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetAccountStatusValues]() 
RETURNS 
@statusValues TABLE 
(
 StatusValue NVARCHAR(100)
)
AS
BEGIN
	INSERT INTO @statusValues SELECT AccountStatusValue FROM dbo.AccountStatusValues;
	RETURN 
END
GO

/****** Object:  UserDefinedFunction [dbo].[GetAccountStatus] ******/
SET QUOTED_IDENTIFIER ON
GO
--Query account status
CREATE FUNCTION [dbo].[GetAccountStatus](
@LogOnName NVARCHAR(100))
RETURNS NVARCHAR(50) 
AS
BEGIN
	DECLARE @AccountStatus NVARCHAR(50);
	SELECT @AccountStatus = AccountStatus FROM [dbo].[Users]
	WHERE LogOnName = @LogOnName;
	RETURN @AccountStatus;
END
GO
/****** Object:  StoredProcedure [dbo].[ForgotPassword] ******/
CREATE PROCEDURE [dbo].[ForgotPassword](@LogOnName NVARCHAR(100),
@SecurityQuestion NVARCHAR(500), 
@Answer NVARCHAR(1024),
@NewPassword NVARCHAR(1024))
AS
BEGIN 
	UPDATE dbo.[Users]
	SET Password = @NewPassword
	WHERE LogOnName = @LogOnName
	AND SecurityQuestion = @SecurityQuestion
	AND Answer = @Answer
END
GO
/****** Object:  StoredProcedure [dbo].[DeleteUser] ******/
CREATE PROCEDURE [dbo].[DeleteUser](
@LogOnName NVARCHAR(100))
AS
BEGIN
	DELETE FROM dbo.[Users] WHERE LogOnName = @LogOnName;
END
GO
/****** Object:  StoredProcedure [dbo].[DeactivateUser] ******/
--Deactivates a user account. This stored procedure expects either user credentials, (so that a user 
--can deactivate his own account), or admin credentials (so that an admin can deactivate a user account)
CREATE PROCEDURE [dbo].[DeactivateUser](
@LogonName NVARCHAR(100))
AS
BEGIN
	UPDATE [dbo].[Users] 
	SET AccountStatus = 'Disabled', 
	DateModified = GETDATE()
	WHERE LogOnName = @LogonName;
END
GO
/****** Object:  StoredProcedure [dbo].[ChangePassword] ******/
--Updates password for a user
CREATE PROCEDURE [dbo].[ChangePassword](
@LogOnName NVARCHAR(100),
@CurrentPassword NVARCHAR(1024),
@NewPassword NVARCHAR(1024))
AS
BEGIN
	UPDATE [dbo].[Users] 
	SET Password = @NewPassword,
	PasswordCreationDate = GETDATE()
	WHERE LogOnName = @LogOnName
	AND Password = @CurrentPassword
END
GO
/****** Object:  UserDefinedFunction [dbo].[AuthenticateUser] ******/
--Verifies whether user logon name and password are correct as stored in the database
--and that the user status is active
CREATE FUNCTION [dbo].[AuthenticateUser](
@LogOnName NVARCHAR(100), 
@Password NVARCHAR(1024), 
@PasswordExpiresInDays INT)
RETURNS BIT
AS
BEGIN
	DECLARE @PasswordExpiryDate DATETIME;
	DECLARE @PasswordCreationDate DATETIME;
	DECLARE @Success BIT;

	--Check if password matches.
	IF EXISTS(SELECT * FROM dbo.[Users]
	WHERE LogOnName = @LogOnName AND AccountStatus = 'Active'
	AND Password = @Password)
	BEGIN
		--Decide whether password expiry is to be checked
		IF @PasswordExpiresInDays = -1
		BEGIN
		-- Password expiry is not to be checked.
			SELECT @Success = 1; --TRUE
		END
		ELSE
		BEGIN
			--Check if password has expired.
			SELECT @PasswordCreationDate = PasswordCreationDate
			FROM dbo.[Users]
			WHERE LogOnName = @LogOnName;
			--If password expiry date is null it means no policy regarding password expiry is in place.
			--The password is already verified. So return true.
			IF @PasswordCreationDate IS NULL
			BEGIN
				SELECT @Success = 1; --TRUE
			END
			ELSE
			BEGIN
				-- Find out whether password has expired
				SELECT @PasswordExpiryDate = DATEADD(DAY, @PasswordExpiresInDays, @PasswordCreationDate);
				IF @PasswordExpiryDate >= GETDATE()
				BEGIN 
					SELECT @Success = 1; --TRUE
				END
				ELSE
				BEGIN
					SELECT @Success = 0; -- FALSE
				END
			END
		END
	END
	ELSE -- user name and password do not match.
	BEGIN
	SELECT @Success = 0; --FALSE
	END
	RETURN @Success;
	END
GO

/****** Object:  StoredProcedure [dbo].[UpdateProfile] ******/
--Updates user profile
CREATE PROCEDURE [dbo].[UpdateProfile](
@LogOnName NVARCHAR(100),
@FirstName NVARCHAR(100) = NULL,
@MiddleName NVARCHAR(100) = NULL,
@LastName NVARCHAR(100) = NULL,
@Email NVARCHAR(250) = NULL,
@City NVARCHAR(100) = NULL,
@State NVARCHAR(100) = NULL,
@Country NVARCHAR(100) = NULL, 
@SecurityQuestion NVARCHAR(500) = NULL, 
@Answer NVARCHAR(1024) = NULL)
AS
BEGIN 
	UPDATE [dbo].[Users] SET 
	FirstName = @FirstName,
	MiddleName = @MiddleName,
	LastName = @LastName,
	Email = @Email,
	City = @City,
	[State] = @State,
	Country = @Country,
	SecurityQuestion = @SecurityQuestion,
	Answer = @Answer,
	DateModified = GETDATE()
	WHERE LogOnName = @LogOnName; 
END
GO
/****** Object:  StoredProcedure [dbo].[UpdateLogOnName]  ******/
--Update logon name
CREATE PROCEDURE [dbo].[UpdateLogOnName](
@CurrentLogOnName NVARCHAR(100),
@NewLogOnName NVARCHAR(100))
AS
BEGIN
	UPDATE [dbo].[Users] 
	SET LogOnName = @NewLogOnName, 
	DateModified = GETDATE()
	WHERE LogOnName = @CurrentLogOnName;
END
GO
/****** Object:  StoredProcedure [dbo].[UpdateAccountStatus] ******/
--Updates account status
CREATE PROCEDURE [dbo].[UpdateAccountStatus](
@LogOnName NVARCHAR(100),
@AccountStatus NVARCHAR(50))
AS
BEGIN
	UPDATE [dbo].[Users] 
	SET AccountStatus = @AccountStatus, 
	DateModified = GETDATE()
	WHERE LogOnName = @LogOnName;
END
GO
/****** Object:  StoredProcedure [dbo].[SetAdminUser] ******/
--This procedure sets a user to be an administrator
CREATE PROCEDURE [dbo].[SetAdminUser](
@LogOnName NVARCHAR(100), 
@IsAdmin Bit)
AS
BEGIN
	UPDATE dbo.[Users] SET IsAdmin = @IsAdmin
	WHERE LogOnName = @LogOnName;
END
GO
/****** Object:  StoredProcedure [dbo].[RegisterUser] ******/
--Creates a new user account
CREATE PROCEDURE [dbo].[RegisterUser](
@FirstName NVARCHAR(100),
@MiddleName NVARCHAR(100) = NULL,
@LastName NVARCHAR(100) = NULL,
@Email NVARCHAR(250),
@City NVARCHAR(100) = NULL,
@State NVARCHAR(100) = NULL,
@Country NVARCHAR(100) = NULL,
@LogOnName NVARCHAR(100),
@Password NVARCHAR(1024),
@AccountStatus NVARCHAR(50),
@SecurityQuestion NVARCHAR(500),
@Answer NVARCHAR(1024))
AS
BEGIN
	DECLARE @CurrentDateTime DATETIME;
	IF NOT EXISTS(SELECT * FROM dbo.[Users]
	WHERE LogOnName = @LogOnName)
	BEGIN
		SELECT @CurrentDateTime = GETDATE();
		INSERT INTO [dbo].[Users](
		UserId, 
		FirstName,
		MiddleName, 
		LastName,
		Email,
		City,
		State,
		Country,
		LogOnName,
		Password,
		AccountStatus,
		DateCreated,
		PasswordCreationDate,
		SecurityQuestion,
		Answer
		)
		VALUES(
		NEWID(),
		@FirstName,
		@MiddleName,
		@LastName,
		@Email,
		@City,
		@State,
		@Country,
		@LogOnName,
		@Password,
		@AccountStatus,
		@CurrentDateTime, 
		@CurrentDateTime,
		@SecurityQuestion,
		@Answer
		);
	END
END
GO
/****** Object:  UserDefinedFunction [dbo].[IsLogOnNameAvailable] ******/
CREATE FUNCTION [dbo].[IsLogOnNameAvailable](@name nvarchar(100))
RETURNS BIT AS
BEGIN
	DECLARE @isAvailable BIT;
	IF EXISTS(SELECT * FROM dbo.Users WHERE LogOnName = @name)
		SET @isAvailable = 0;--FALSE
	ELSE
		SET @isAvailable = 1;--TRUE
	RETURN @isAvailable;
END
GO
/****** Object:  UserDefinedFunction [dbo].[IsAdmin]  ******/
CREATE FUNCTION [dbo].[IsAdmin](@LogOnName NVARCHAR(100))
RETURNS BIT AS
BEGIN
	DECLARE @IsAdmin BIT;
	SELECT @IsAdmin = 0;
	SELECT @IsAdmin = IsAdmin FROM dbo.[Users]
	WHERE LogOnName = @LogOnName;
	RETURN @IsAdmin;
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetUserInfo] ******/
-- This function can be called with a user credentials who gets his own profile
-- or by an admin user who can get any user's profile
CREATE FUNCTION [dbo].[GetUserInfo](
	@LogOnName NVARCHAR(100))
	RETURNS @UserInfo TABLE (UserId UNIQUEIDENTIFIER PRIMARY KEY NOT NULL,
	FirstName NVARCHAR(100) NOT NULL,
	MiddleName NVARCHAR(100) NULL,
	LastName NVARCHAR(100) NULL,
	Email NVARCHAR(100) NOT NULL,
	City NVARCHAR(100) NULL,
	State NVARCHAR(100) NULL,
	Country NVARCHAR(100) NULL,
	AccountStatus NVARCHAR(50) NULL,
	DateCreated DATETIME NULL,
	DateModified DATETIME NULL,
	PasswordCreationDate DATETIME NULL,
	SecurityQuestion NVARCHAR(500),
	Answer NVARCHAR(1024))
AS
BEGIN
	INSERT INTO @UserInfo(UserId, 
		FirstName, 
		MiddleName, 
		LastName, 
		Email, 
		City, 
		State, 
		Country, 
		AccountStatus, 
		DateCreated, 
		DateModified, 
		PasswordCreationDate,
		SecurityQuestion,
		Answer)
	SELECT UserId, 
		FirstName, 
		MiddleName, 
		LastName, 
		Email, 
		City, 
		State, 
		Country, 
		AccountStatus, 
		DateCreated, 
		DateModified, 
		PasswordCreationDate,
		SecurityQuestion,
		Answer
		FROM dbo.[Users]
	WHERE LogOnName = @LogOnName;
	RETURN;
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetUserId] ******/
--Returns UserId for a user with given logon name
CREATE FUNCTION [dbo].[GetUserId](
	@LogOnName NVARCHAR(100))
RETURNS UNIQUEIDENTIFIER
AS
BEGIN
	DECLARE @Id UNIQUEIDENTIFIER;
	SELECT @Id = UserId FROM [dbo].[Users] 
	WHERE LogOnName = @LogOnName;
	RETURN @Id;
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetPasswordCreationDate] ******/
CREATE FUNCTION [dbo].[GetPasswordCreationDate](
	@LogOnName NVARCHAR(100))
RETURNS DATETIME AS
BEGIN
	DECLARE @passwordDate DATETIME;
	SELECT @passwordDate = PasswordCreationDate
	FROM dbo.[Users]
	WHERE LogOnName = @LogOnName;
	RETURN @passwordDate;
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetPassword]  ******/
CREATE FUNCTION [dbo].[GetPassword](@logOnName NVARCHAR(100))
RETURNS NVARCHAR(100)
AS
BEGIN
	DECLARE @password NVARCHAR(100);
	SELECT @password = Password FROM dbo.Users 
	WHERE LogOnName = @LogOnName;
	RETURN @password;
END
GO
/****** Object:  UserDefinedFunction [dbo].[GetPagedUserRecords] ******/
CREATE FUNCTION [dbo].[GetPagedUserRecords](
	@StartIndex INTEGER, 
	@EndIndex INTEGER)
RETURNS @UserInfo TABLE (UserId UNIQUEIDENTIFIER PRIMARY KEY NOT NULL,
	FirstName NVARCHAR(100) NOT NULL,
	MiddleName NVARCHAR(100) NULL,
	LastName NVARCHAR(100) NULL,
	Email NVARCHAR(100) NOT NULL,
	City NVARCHAR(100) NULL,
	State NVARCHAR(100) NULL,
	Country NVARCHAR(100) NULL,
	LogOnName NVARCHAR(100) NOT NULL,
	AccountStatus NVARCHAR(50) NULL,
	DateCreated DATETIME NULL,
	DateModified DATETIME NULL,
	PasswordCreationDate DATETIME NULL,
	SecurityQuestion NVARCHAR(500),
	Answer NVARCHAR(1024), 
	RowIndex INTEGER)
AS
BEGIN
	IF @EndIndex <> -1
	BEGIN
	WITH AllUsers AS
	(
		SELECT UserId, 
		FirstName, 
		MiddleName, 
		LastName, 
		Email, 
		City, 
		State, 
		Country, 
		LogOnName, 
		AccountStatus, 
		DateCreated, 
		DateModified, 
		PasswordCreationDate,
		SecurityQuestion,
		Answer,
		ROW_NUMBER() OVER (ORDER BY LogOnName) AS RowIndex
		FROM dbo.[Users]
	)
	INSERT INTO @UserInfo(UserId, 
		FirstName, 
		MiddleName, 
		LastName, 
		Email, 
		City, 
		State, 
		Country, 
		LogOnName,
		AccountStatus, 
		DateCreated, 
		DateModified, 
		PasswordCreationDate,
		SecurityQuestion,
		Answer,
		RowIndex)
	SELECT UserId, 
		FirstName, 
		MiddleName, 
		LastName, 
		Email, 
		City, 
		State, 
		Country, 
		LogOnName, 
		AccountStatus, 
		DateCreated, 
		DateModified,    
		PasswordCreationDate,
		SecurityQuestion,
		Answer,
		RowIndex
	FROM AllUsers 
	WHERE RowIndex BETWEEN @StartIndex AND @EndIndex;
	END
	ELSE
	BEGIN
		WITH AllUsers AS
		(
			SELECT UserId, 
			FirstName, 
			MiddleName, 
			LastName, 
			Email, 
			City, 
			State, 
			Country, 
			LogOnName, 
			AccountStatus, 
			DateCreated, 
			DateModified, 
			PasswordCreationDate,
			SecurityQuestion,
			Answer,
			ROW_NUMBER() OVER (ORDER BY LogOnName) AS RowIndex
			FROM dbo.[Users]
		)
		INSERT INTO @UserInfo(UserId, 
			FirstName, 
			MiddleName, 
			LastName, 
			Email, 
			City, 
			State, 
			Country, 
			LogOnName,
			AccountStatus, 
			DateCreated, 
			DateModified, 
			PasswordCreationDate,
			SecurityQuestion,
			Answer,
			RowIndex)
		SELECT UserId, 
			FirstName, 
			MiddleName, 
			LastName, 
			Email, 
			City, 
			State, 
			Country, 
			LogOnName, 
			AccountStatus, 
			DateCreated, 
			DateModified,    
			PasswordCreationDate,
			SecurityQuestion,
			Answer,
			RowIndex
		FROM AllUsers 
		WHERE RowIndex >= @StartIndex;
	END
	RETURN;
END
GO
/****** Object:  ForeignKey [FK_Users_AccountStatusValues] ******/
ALTER TABLE [dbo].[Users]  WITH CHECK ADD  CONSTRAINT [FK_Users_AccountStatusValues] FOREIGN KEY([AccountStatus])
REFERENCES [dbo].[AccountStatusValues] ([AccountStatusValue])
GO
ALTER TABLE [dbo].[Users] CHECK CONSTRAINT [FK_Users_AccountStatusValues]
GO
