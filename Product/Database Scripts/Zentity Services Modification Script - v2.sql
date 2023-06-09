USE [master]
GO

/*************************************************/
/*  SET NOCOUNT ON added to prevent extra result */
/*  sets from interfering with SELECT statements */
/*************************************************/
SET NOCOUNT ON;

/*************************************************/
/*  Enable Service Broker for "Zentity" Database */
/*************************************************/
IF NOT EXISTS (SELECT * FROM [sys].[databases] WHERE is_broker_enabled = 1 AND name = 'Zentity')
BEGIN
    ALTER DATABASE [Zentity] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
    
    ALTER DATABASE [Zentity] SET ENABLE_BROKER

    ALTER DATABASE [Zentity] SET  MULTI_USER WITH ROLLBACK IMMEDIATE
END
GO

-- Restrict MAXSIZE of Zentity_Log file to 10GB
-- Use code in comments section below to shrink log files
/**********************************************************
USE [Zentity];
GO
-- Truncate the log by changing the database recovery model to SIMPLE.
ALTER DATABASE [Zentity]
SET RECOVERY SIMPLE;
GO
-- Shrink the truncated log file to 1 GB.
DBCC SHRINKFILE (Zentity_Log, 1024);
GO
-- Reset the database recovery model.
ALTER DATABASE [Zentity]
SET RECOVERY FULL;
GO
**********************************************************/
ALTER DATABASE [Zentity] 
MODIFY FILE
(
    NAME = Zentity_Log,
    MAXSIZE = 10240MB
);
GO

USE [Zentity]
GO

BEGIN TRANSACTION
    SET QUOTED_IDENTIFIER ON
    SET ARITHABORT ON
    SET NUMERIC_ROUNDABORT OFF
    SET CONCAT_NULL_YIELDS_NULL ON
    SET ANSI_NULLS ON
    SET ANSI_PADDING ON
    SET ANSI_WARNINGS ON
COMMIT

/**********************************************************/
/*  Allow deletion of relationships if all resources of   */
/*  a resource type are deleted by sync scripts           */
/**********************************************************/
BEGIN TRANSACTION
GO
ALTER TABLE Core.Relationship DROP CONSTRAINT ResourceHasRelationship
GO
ALTER TABLE Core.Resource SET (LOCK_ESCALATION = TABLE)
GO
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE Core.Relationship ADD CONSTRAINT
    ResourceHasRelationship FOREIGN KEY
    (
    SubjectResourceId
    ) REFERENCES Core.Resource
    (
    Id
    ) ON UPDATE NO ACTION 
      ON DELETE CASCADE 
GO
ALTER TABLE Core.Relationship SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

/**********************************************************/
/*  Add the ConfigurationXml column to ResourceType table */
/**********************************************************/
IF NOT EXISTS (SELECT * FROM [INFORMATION_SCHEMA].[COLUMNS]
               WHERE TABLE_SCHEMA = 'Core' AND 
                     TABLE_NAME = 'ResourceType' AND 
                     COLUMN_NAME = 'ConfigurationXml')
BEGIN
    BEGIN TRANSACTION
    ALTER TABLE [Core].[ResourceType] ADD ConfigurationXml xml NULL
    ALTER TABLE [Core].[ResourceType] SET (LOCK_ESCALATION = TABLE)
    COMMIT
END
GO
UPDATE Core.ResourceType SET ConfigurationXml = 
        '<ResourceTypeSetting xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
                              xmlns:xsd="http://www.w3.org/2001/XMLSchema" 
                              xmlns="http://schemas.microsoft.com/zentity/pivot/configuration" 
                              name="Resource" disableCollectionCreation="true">
          <Visual type="Default" propertyName="" />
          <Link propertyName="" />
        </ResourceTypeSetting>'
WHERE Discriminator = 1
GO

/*****************************************************************/
/*  Alter the GetDataModelModules stored procedure to allow the  */
/*  inclusion of ConfigurationXml into the Zentity Core entities */
/*****************************************************************/
ALTER PROCEDURE [Core].[GetDataModelModules]
    @DataModelModules NVARCHAR (MAX) OUTPUT
AS
BEGIN
 DECLARE @IsFullTextEnable [bit];
 DECLARE @MaxDiscriminator [int];
 DECLARE @ConfigMaxDiscriminator [int];
 DECLARE @ResourceTypeMaxDiscriminator [int];
 DECLARE @ZentityVersion [nvarchar](256);

 SET @MaxDiscriminator = 0;
 SELECT @ConfigMaxDiscriminator = CAST([ConfigValue] AS [int])
 FROM [Core].[Configuration]
 WHERE [ConfigName] = 'MaxDiscriminator';

 IF (@ConfigMaxDiscriminator IS NOT NULL) 
  AND (@ConfigMaxDiscriminator > @MaxDiscriminator)
 SELECT @MaxDiscriminator = @ConfigMaxDiscriminator;

 SELECT @ResourceTypeMaxDiscriminator = MAX([Discriminator])
 FROM [Core].[ResourceType];

 IF(@ResourceTypeMaxDiscriminator IS NOT NULL) 
  AND (@ResourceTypeMaxDiscriminator > @MaxDiscriminator)
 SELECT @MaxDiscriminator = @ResourceTypeMaxDiscriminator;

 SELECT @ZentityVersion = [ConfigValue]
 FROM [Core].[Configuration]
 WHERE [ConfigName] = 'ZentityVersion';

 SELECT TOP(1) @IsFullTextEnable = CASE WHEN [ConfigValue] = 'True' THEN 1 ELSE 0 END
 FROM [Core].[Configuration]
 WHERE [ConfigName] ='IsFullTextSearchEnabled';

 DECLARE @Temp TABLE
 (
  [Tag] [int],
  [Parent] [int],

  [DataModel!1!!element] [nvarchar](256),
  [DataModel!1!ZentityVersion] [nvarchar](256),
  [DataModel!1!MaxDiscriminator] [int],

  [DataModelModule!2!Id] [uniqueidentifier],
  [DataModelModule!2!Namespace] [nvarchar](150),
  [DataModelModule!2!Uri] [nvarchar](1024),
  [DataModelModule!2!Description] [nvarchar](max),
  [DataModelModule!2!IsMsShipped] [bit],

  [ResourceType!3!Id] [uniqueidentifier],
  [ResourceType!3!BaseTypeId] [uniqueidentifier],
  [ResourceType!3!Name] [nvarchar](100),
  [ResourceType!3!Uri] [nvarchar](1024),
  [ResourceType!3!Description] [nvarchar](4000),
  [ResourceType!3!Discriminator] [int],
  [ResourceType!3!ConfigurationXml] [xml],

  [ScalarProperty!4!Id] [uniqueidentifier],
  [ScalarProperty!4!Name] [nvarchar](100),
  [ScalarProperty!4!Uri] [nvarchar](1024),
  [ScalarProperty!4!Description] [nvarchar](max),
  [ScalarProperty!4!DataType] [nvarchar](100),
  [ScalarProperty!4!Nullable] [bit],
  [ScalarProperty!4!MaxLength] [int],
  [ScalarProperty!4!Scale] [int],
  [ScalarProperty!4!Precision] [int],
  [ScalarProperty!4!TableName] [nvarchar](128),
  [ScalarProperty!4!ColumnName] [nvarchar](100),
  [ScalarProperty!4!IsFullTextIndexed] [bit],

  [NavigationProperty!5!Id] [uniqueidentifier],
  [NavigationProperty!5!Name] [nvarchar](100),
  [NavigationProperty!5!Uri] [nvarchar](1024),
  [NavigationProperty!5!Description] [nvarchar](max),
  [NavigationProperty!5!TableName] [nvarchar](128),
  [NavigationProperty!5!ColumnName] [nvarchar](100),

  [Association!6!Id] [uniqueidentifier],
  [Association!6!Name] [nvarchar](100),
  [Association!6!Uri] [nvarchar](1024),
  [Association!6!SubjectNavigationPropertyId] [uniqueidentifier],
  [Association!6!ObjectNavigationPropertyId] [uniqueidentifier],
  [Association!6!PredicateId] [uniqueidentifier],
  [Association!6!SubjectMultiplicity] [nvarchar](32),
  [Association!6!ObjectMultiplicity] [nvarchar](32),
  [Association!6!ViewName] [nvarchar](150)
 )
 
 INSERT INTO @Temp VALUES
 (
  1,
  NULL,
  
  NULL,
  @ZentityVersion,
  @MaxDiscriminator,
  
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL
 )
 
 DECLARE @DataModelModuleId [uniqueidentifier],
  @DataModelModuleNamespace [nvarchar](150),
  @DataModelModuleUri [nvarchar](1024),
  @DataModelModuleDescription [nvarchar](max),
  @DataModelModuleIsMsShipped [bit];

 DECLARE DataModelModuleCursor CURSOR
 FOR SELECT [Id], [Namespace], [Uri], [Description], [IsMsShipped]
  FROM [Core].[DataModelModule]
 
 OPEN DataModelModuleCursor;
 FETCH NEXT FROM DataModelModuleCursor INTO 
 @DataModelModuleId, @DataModelModuleNamespace, @DataModelModuleUri,
 @DataModelModuleDescription, @DataModelModuleIsMsShipped;
 WHILE @@FETCH_STATUS = 0
 BEGIN
  INSERT INTO @Temp VALUES
  (
   2,
   1,
  
   NULL,
   NULL,
   NULL,
  
   @DataModelModuleId,
   @DataModelModuleNamespace,
   @DataModelModuleUri,
   @DataModelModuleDescription,
   @DataModelModuleIsMsShipped,
  
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
    
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
  
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
  
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL
  );

  INSERT INTO @Temp
  SELECT 3,
   2,
  
   NULL,
   NULL,
   NULL,
  
   @DataModelModuleId,
   NULL,
   NULL,
   NULL,
   NULL,
  
   [R].[Id],
   [R].[BaseTypeId],
   [R].[Name],
   [R].[Uri],
   [R].[Description],
   [R].[Discriminator],
   [R].ConfigurationXml,
   
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
  
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL,
   NULL  
  FROM [Core].[ResourceType] [R]
  WHERE [R].[DataModelModuleId] = @DataModelModuleId;
  
  DECLARE @ResourceTypeId [uniqueidentifier]
  
  DECLARE ResourceTypeCursor CURSOR
  FOR SELECT [Id]
   FROM [Core].[ResourceType] [R]
   WHERE [R].[DataModelModuleId] = @DataModelModuleId;
 
  OPEN ResourceTypeCursor;
  
  FETCH NEXT FROM ResourceTypeCursor INTO 
   @ResourceTypeId;
  WHILE @@FETCH_STATUS = 0
  BEGIN
   
   INSERT INTO @Temp
   SELECT 4,
    3,
    
    NULL,
    NULL,
    NULL,
    
    @DataModelModuleId,
    NULL,
    NULL,
    NULL,
    NULL,
    
    @ResourceTypeId,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
     
    [S].[Id],
    [S].[Name],
    [S].[Uri],
    [S].[Description],
    [S].[DataType],
    [S].[Nullable],
    [S].[MaxLength],
    [S].[Scale],
    [S].[Precision],
    [S].[TableName],
    [S].[ColumnName],
    CASE WHEN @IsFullTextEnable = 1 AND [FTSDetails].[IsFullTextIndexed] = 1 THEN 1 
    ELSE 0 END [IsFullTextIndexed],
    
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
   
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL    
   FROM [Core].[ScalarProperty] [S]
   LEFT OUTER JOIN
   (
    SELECT [T].[name] [TableName], [C].[name] [ColumnName], 1 [IsFullTextIndexed]
    FROM [sys].[fulltext_index_columns] [FTS]
    INNER JOIN [sys].[columns] [C]
    ON [FTS].[object_id] = [C].[object_id]
    AND [FTS].[column_id] = [C].[column_id]
    INNER JOIN [sys].[tables] [T]
    ON [C].[object_id] = [T].[object_id]
    INNER JOIN [sys].[schemas] [S]
    ON [T].[schema_id] = [S].[schema_id]
    AND [S].[name] = 'Core'
   ) [FTSDetails]
   ON [S].[TableName] = [FTSDetails].[TableName]
   AND [S].[ColumnName] = [FTSDetails].[ColumnName]
   WHERE [S].ResourceTypeId = @ResourceTypeId
   
   
   INSERT INTO @Temp
   SELECT 5,
    3,
    
    NULL,
    NULL,
    NULL,
    
    @DataModelModuleId,
    NULL,
    NULL,
    NULL,
    NULL,
    
    @ResourceTypeId,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
   
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    
    [N].[Id],
    [N].[Name],
    [N].[Uri],
    [N].[Description],
    [N].[TableName],
    [N].[ColumnName],
   
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL    
   FROM [Core].[NavigationProperty] [N]
   WHERE @ResourceTypeId = [N].[ResourceTypeId]
   
   FETCH NEXT FROM ResourceTypeCursor INTO 
   @ResourceTypeId;
  END
  CLOSE ResourceTypeCursor;
  DEALLOCATE ResourceTypeCursor;
 
  FETCH NEXT FROM DataModelModuleCursor INTO 
  @DataModelModuleId, @DataModelModuleNamespace, @DataModelModuleUri,
  @DataModelModuleDescription, @DataModelModuleIsMsShipped;
 END
 CLOSE DataModelModuleCursor;
 DEALLOCATE DataModelModuleCursor;

 INSERT INTO @Temp
 SELECT 6,
  1,

  NULL,
  NULL,
  NULL,

  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,

  [A].[Id],
  [A].[Name],
  [A].[Uri],
  [A].[SubjectNavigationPropertyId],
  [A].[ObjectNavigationPropertyId],
  [A].[PredicateId],
  [A].[SubjectMultiplicity],
  [A].[ObjectMultiplicity],
  [A].[ViewName]
 FROM [Core].[Association] [A]

 SET @DataModelModules = (SELECT * FROM @Temp 
 ORDER BY [DataModelModule!2!Id],[ResourceType!3!Id],[ScalarProperty!4!Id],
 [NavigationProperty!5!Id],[Association!6!Id]
 FOR XML EXPLICIT);
END
GO

/************************************************************************/
/*  Alter the CreateOrUpdateResourceType stored procedure to allow the  */
/*  inclusion of ConfigurationXml into the Zentity Core entities        */
/************************************************************************/
ALTER PROCEDURE [Core].[CreateOrUpdateResourceType]
    @Id UNIQUEIDENTIFIER, 
    @DataModelModuleId UNIQUEIDENTIFIER, 
    @BaseTypeId UNIQUEIDENTIFIER, 
    @Name NVARCHAR (100), 
    @Uri NVARCHAR (1024), 
    @Description NVARCHAR (4000), 
    @Discriminator INT,
    @ConfigurationXml XML
AS
BEGIN
 IF (SELECT COUNT(1) FROM [Core].[ResourceType] WHERE Id = @Id) = 0
 BEGIN

  INSERT INTO [Core].[ResourceType]
           ([Id]
           ,[DataModelModuleId]
           ,[BaseTypeId]
           ,[Name]
           ,[Uri]
           ,[Description]
           ,[Discriminator])
  VALUES
           (@Id
           ,@DataModelModuleId
           ,@BaseTypeId
           ,@Name
           ,@Uri
           ,@Description
           ,@Discriminator);
 END
 ELSE
 BEGIN
  UPDATE [Core].[ResourceType]
     SET [DataModelModuleId] = @DataModelModuleId
     ,[BaseTypeId] = @BaseTypeId
     ,[Name] = @Name 
     ,[Uri] = @Uri
     ,[Description] = @Description
     ,[Discriminator] = @Discriminator
     ,[ConfigurationXml] = @ConfigurationXml
   WHERE [Id] = @Id
 END
 
 -- Update the max discriminator value.
 DECLARE @MaxDiscriminator [int];
 DECLARE @ConfigurationExists [bit];
 SELECT @ConfigurationExists = 1, @MaxDiscriminator = [ConfigValue]
 FROM [Core].[Configuration]
 WHERE [ConfigName] = 'MaxDiscriminator';

 IF @ConfigurationExists IS NULL
 BEGIN
  INSERT INTO [Core].[Configuration]
  SELECT 'MaxDiscriminator', 
  CASE WHEN MAX([Discriminator]) > @Discriminator THEN MAX([Discriminator])
  ELSE @Discriminator END
  FROM [Core].[ResourceType];
 END
 ELSE
 BEGIN
  UPDATE [Core].[Configuration]
  SET [ConfigValue] = 
  CASE WHEN CAST([ConfigValue] AS [int]) > @Discriminator THEN [ConfigValue]
  ELSE @Discriminator END
  WHERE [ConfigName] = 'MaxDiscriminator';
 END
END
GO

/*******************************************************/
/*  Drop and Create the [Split] table valued function  */
/*******************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Split]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION [dbo].[Split]
GO

CREATE FUNCTION [dbo].[Split] (
    @InputString  VARCHAR(MAX),
    @Delimiter    VARCHAR(5)
)
RETURNS @Items TABLE (
    Item          VARCHAR(8000)
)
AS
BEGIN
    IF @Delimiter = ' '
    BEGIN
        SET @Delimiter = ','
        SET @InputString = REPLACE(@InputString, ' ', @Delimiter)
    END

    IF (@Delimiter IS NULL OR @Delimiter = '')
        SET @Delimiter = ','
 
    DECLARE @Item           VARCHAR(8000)
    DECLARE @ItemList       VARCHAR(8000)
    DECLARE @DelimIndex     INT

    SET @ItemList = @InputString
    SET @DelimIndex = CHARINDEX(@Delimiter, @ItemList, 0)

    WHILE (@DelimIndex != 0)
    BEGIN
        SET @Item = SUBSTRING(@ItemList, 0, @DelimIndex)
        INSERT INTO @Items VALUES (LTRIM(RTRIM(@Item)))

        -- Set @ItemList = @ItemList minus one less item
        SET @ItemList = SUBSTRING(@ItemList, @DelimIndex+1, LEN(@ItemList)-@DelimIndex)
        SET @DelimIndex = CHARINDEX(@Delimiter, @ItemList, 0)
    END -- End WHILE

    IF @Item IS NOT NULL -- At least one delimiter was encountered in @InputString
    BEGIN
        SET @Item = @ItemList
        INSERT INTO @Items VALUES (LTRIM(RTRIM(@Item)))
    END
    -- No delimiters were encountered in @InputString, so just return @InputString
    ELSE 
        INSERT INTO @Items VALUES (LTRIM(RTRIM(@InputString)))

    RETURN
END -- End Function
GO

/********************************************************************/
/*  Drop and Create the [GetResourceTypeItemCount] scalar function  */
/********************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Core].[GetResourceTypeItemCount]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
    DROP FUNCTION [Core].[GetResourceTypeItemCount]
GO

CREATE FUNCTION [Core].[GetResourceTypeItemCount] (
    @ResourceTypeId UNIQUEIDENTIFIER
)
RETURNS INT
AS
BEGIN
    -- Declare the return variable here
    DECLARE @Result INT

    -- Query to calculate the count of resources given the resource type id
    SELECT @Result = SUM(ResourceCount.ItemCount) FROM 
        (SELECT Count(Core.Resource.Id) as [ItemCount], DerivedTypes.Id FROM 
         Core.Resource RIGHT OUTER JOIN 
        (SELECT Id FROM [Zentity].[Core].[GetDerivedTypes] (@ResourceTypeId)) as DerivedTypes
         ON Core.Resource.ResourceTypeId = DerivedTypes.Id
         GROUP BY DerivedTypes.Id) as ResourceCount

    -- Return the result of the function
    RETURN @Result
END
GO

/*************************************************************************/
/*  Drop and Create the [GetDataModelResourceItemCount] scalar function  */
/*************************************************************************/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Core].[GetDataModelResourceItemCount]') AND type in (N'P', N'PC'))
    DROP PROCEDURE [Core].[GetDataModelResourceItemCount]
GO

-- =============================================
-- Description: Gets a table of Resource Types and their resource item count 
--              and also the total count of unique resource items in the 
--              Data Model module
-- =============================================
CREATE PROCEDURE [Core].[GetDataModelResourceItemCount]
    @namespaceList VARCHAR(MAX), 
    @totalItemCount INT OUTPUT
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;
    
    SET @namespaceList = LTRIM(RTRIM(@namespaceList))
    IF (@namespaceList <> '')
    BEGIN
        SELECT     Core.DataModelModule.Namespace AS [DataModel], Core.ResourceType.Name AS [ResourceType], Core.GetResourceTypeItemCount(Core.ResourceType.Id) AS [ItemCount]
        FROM         Core.DataModelModule INNER JOIN
                              Core.ResourceType ON Core.DataModelModule.Id = Core.ResourceType.DataModelModuleId LEFT OUTER JOIN
                              Core.Resource ON Core.ResourceType.Id = Core.Resource.ResourceTypeId
        WHERE     (Core.DataModelModule.Namespace IN (SELECT Item FROM dbo.Split(@namespaceList, ',')))
        GROUP BY Core.ResourceType.Id, Core.ResourceType.Name, Core.DataModelModule.Namespace
        
        SELECT @totalItemCount = SUM(TotalCount.ItemCount) FROM 
        (SELECT     COUNT(Core.Resource.Id) AS ItemCount
        FROM         Core.Resource INNER JOIN
                     Core.ResourceType ON Core.Resource.ResourceTypeId = Core.ResourceType.Id INNER JOIN
                     Core.DataModelModule ON Core.DataModelModule.Id = Core.ResourceType.DataModelModuleId
        GROUP BY Core.DataModelModule.Namespace
        HAVING      (Core.DataModelModule.Namespace IN (SELECT Item FROM dbo.Split(@namespaceList, ',')))) AS TotalCount
    END
END

GO

/************************************************************************************/
/*  Zentity Recovery - Tables related to recovery of services from shutdown/crashes */
/*  1) Creation of table [ChangeMessageRecovery]  - Notification Service            */
/*  2) Creation of table [MessageQueueRecovery]   - Notification Service            */
/*  3) Creation of table [PublishRequestRecovery] - Publishing Service              */
/************************************************************************************/

/**************************************************/
/*  Create the [ChangeMessageRecovery] table      */
/**************************************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Administration].[ChangeMessageRecovery]') AND type in (N'U'))
BEGIN
   CREATE TABLE [Administration].[ChangeMessageRecovery]
   (
       [Id] [uniqueidentifier] NOT NULL,
       [ResourceId] [uniqueidentifier] NOT NULL,
       [ResourceTypeId] [uniqueidentifier] NOT NULL,
       [DataModelNamespace] [nvarchar](150) NOT NULL,
       [ResourceTypeName] [nvarchar](100) NOT NULL,
       [ChangeType] [smallint] NOT NULL,
       [DateAdded] [datetime2](7) NULL,
       [DateModified] [datetime2](7) NULL,
       [DateTimeStamp] [datetime2](7) NOT NULL,
       CONSTRAINT [PK_ChangeMessageRecovery] PRIMARY KEY CLUSTERED 
       (
           [Id] ASC
       ) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
   ) ON [PRIMARY]
END
GO

IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_ChangeMessageRecovery_DateTimeStamp]') AND type = 'D')
BEGIN
    ALTER TABLE [Administration].[ChangeMessageRecovery] 
          ADD  CONSTRAINT [DF_ChangeMessageRecovery_DateTimeStamp]  DEFAULT (getdate()) FOR [DateTimeStamp]
END
GO

/*************************************************/
/*  Create the [MessageQueueRecovery] table      */
/*************************************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Administration].[MessageQueueRecovery]') AND type in (N'U'))
BEGIN
    CREATE TABLE [Administration].[MessageQueueRecovery]
    (
        [Id] [uniqueidentifier] NOT NULL,
        [DateTimeStamp] [datetime2](7) NOT NULL,
        [RawMessage] [nvarchar](max) NULL,
        CONSTRAINT [PK_MessageQueueRecovery] PRIMARY KEY CLUSTERED 
        (
            [Id] ASC
        ) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
    ) ON [PRIMARY]
END
GO

IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_MessageQueueRecovery_DateTimeStamp]') AND type = 'D')
BEGIN
    ALTER TABLE [Administration].[MessageQueueRecovery] 
          ADD  CONSTRAINT [DF_MessageQueueRecovery_DateTimeStamp]  DEFAULT (getdate()) FOR [DateTimeStamp]
END
GO

/***************************************************/
/*  Create the [PublishRequestRecovery] table      */
/***************************************************/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Administration].[PublishRequestRecovery]') AND type in (N'U'))
BEGIN
    CREATE TABLE [Administration].[PublishRequestRecovery]
    (
        [InstanceId] [uniqueidentifier] NOT NULL,
        [IsQueuedRequest] [bit] NOT NULL,
        [QueueOrder] [int] NOT NULL,
        [DataModelNamespace] [nvarchar](150) NOT NULL,
        [ResourceTypeName] [nvarchar](100) NOT NULL,
        [ObjectData] [xml] NULL,
        CONSTRAINT [PK_PublishRequestRecovery] PRIMARY KEY CLUSTERED 
        (
            [InstanceId] ASC
        ) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
    ) ON [PRIMARY]
END

IF NOT EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_PublishRequest_IsQueuedRequest]') AND type = 'D')
BEGIN
   ALTER TABLE [Administration].[PublishRequestRecovery] 
         ADD  CONSTRAINT [DF_PublishRequest_IsQueuedRequest]  DEFAULT ((1)) FOR [IsQueuedRequest] 
END
GO

IF  EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[DF_PublishRequest_QueueOrder]') AND type = 'D')
BEGIN
    ALTER TABLE [Administration].[PublishRequestRecovery]
          ADD  CONSTRAINT [DF_PublishRequest_QueueOrder]  DEFAULT ((0)) FOR [QueueOrder]
END
GO


/*********************************************************************/
/*  Zentity Notification - Service Broker relates scripts            */
/*  1) Creation of related Messages, Contract, Queue, Services       */
/*  2) Setup a trigger on Core.Resource table for sending messages   */
/*  3) Releated stored procedures for message transmission to queues */
/*********************************************************************/

/*********************************************************************/
/* This table associates the current connection (@@SPID)             */
/* with a conversation. The association key also contains the        */ 
/* conversation parameteres:                                         */
/* from service, to service, contract used                           */
/*********************************************************************/
IF NOT EXISTS (SELECT TABLE_NAME FROM [INFORMATION_SCHEMA].[TABLES] WHERE (TABLE_NAME = 'SessionConversations'))
BEGIN
    CREATE TABLE [Core].[SessionConversations] 
    (
          SPID INT NOT NULL    
        , FromService SYSNAME NOT NULL
        , ToService SYSNAME NOT NULL
        , OnContract SYSNAME NOT NULL
        , Handle UNIQUEIDENTIFIER NOT NULL
        , PRIMARY KEY (SPID, FromService, ToService, OnContract)
        , UNIQUE (Handle)
    );
END
GO


/****************************************************/
/*  Drop and Create the [SendMessage] procedure     */
/****************************************************/
IF EXISTS (SELECT name FROM [sys].[procedures] WHERE object_id = OBJECT_ID(N'[Core].[SendMessage]'))
BEGIN
    DROP PROCEDURE [Core].[SendMessage]
END 
GO

CREATE PROCEDURE [Core].[SendMessage] 
    @fromService SYSNAME,
    @toService SYSNAME,
    @onContract SYSNAME,
    @messageType SYSNAME,
    @messageBody XML
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @handle UNIQUEIDENTIFIER;
    DECLARE @counter INT;
    DECLARE @error INT;
    SELECT @counter = 1;
    BEGIN TRANSACTION;
    -- Will need a loop to retry in case the conversation is
    -- in a state that does not allow transmission
    --
    WHILE (1=1)
    BEGIN
        -- Seek an eligible conversation in [SessionConversations]
        --
        SELECT @handle = Handle
            FROM Core.[SessionConversations] WITH (UPDLOCK)
            WHERE SPID = @@SPID
            AND FromService = @fromService
            AND ToService = @toService
            AND OnContract = @OnContract;
        IF @handle IS NULL
        BEGIN
            -- Need to start a new conversation for the current @@spid
            --
            BEGIN DIALOG CONVERSATION @handle
                FROM SERVICE @fromService
                TO SERVICE @toService
                ON CONTRACT @onContract
                WITH ENCRYPTION = OFF;
            -- Set an one hour timer on the conversation
            --
            BEGIN CONVERSATION TIMER (@handle) TIMEOUT = 3600;
            INSERT INTO Core.[SessionConversations]
                (SPID, FromService, ToService, OnContract, Handle)
                VALUES
                (@@SPID, @fromService, @toService, @onContract, @handle);
        END;
        -- Attempt to SEND on the associated conversation
        --
        SEND ON CONVERSATION @handle
            MESSAGE TYPE @messageType
            (@messageBody);
        SELECT @error = @@ERROR;
        IF @error = 0
        BEGIN
            -- Successful send, just exit the loop
            --
            BREAK;
        END
        SELECT @counter = @counter+1;
        IF @counter > 10
        BEGIN
            -- We failed 10 times in a row, something must be broken
            --
            RAISERROR (
                N'Failed to SEND on a conversation for more than 10 times. Error %i.'
                , 16, 1, @error) WITH LOG;
            BREAK;
        END
        -- Delete the associated conversation from the table and try again
        --
        DELETE FROM Core.[SessionConversations]
            WHERE Handle = @handle;
        SELECT @handle = NULL;
    END
    COMMIT;
END
GO


/*****************************************************/
/*  Drop and Create the [FetchMessage] procedure     */
/*****************************************************/
IF EXISTS (SELECT name FROM [sys].[procedures] WHERE object_id = OBJECT_ID(N'[Core].[FetchMessage]'))
BEGIN
    DROP PROCEDURE [Core].[FetchMessage]
END 
GO

CREATE PROCEDURE [Core].[FetchMessage] 
    @Msg NVARCHAR(MAX) out, 
    @BatchSize int, 
    @Timeout bigint
    AS
BEGIN
    DECLARE @MsgTable TABLE( ZentityMessages NVARCHAR(MAX))
    WAITFOR
    ( 
      RECEIVE TOP(@BatchSize) CONVERT(NVARCHAR(MAX), message_body) from ZentityReceiveQueue into @MsgTable
    ), TIMEOUT @Timeout;
    SELECT @Msg = COALESCE(@Msg + '', '') + (ZentityMessages) FROM @MsgTable;
END
GO

/*********************************************************/
/*  Drop and Create the [SenderActivation] procedure     */
/*********************************************************/
IF EXISTS (SELECT name FROM [sys].[procedures] WHERE object_id = OBJECT_ID(N'[Core].[SenderActivation]'))
BEGIN
    DROP PROCEDURE [Core].[SenderActivation]
END 
GO

CREATE PROCEDURE [Core].[SenderActivation]
AS
BEGIN
    DECLARE @handle UNIQUEIDENTIFIER;
    DECLARE @messageTypeName SYSNAME;
    DECLARE @messageBody VARBINARY(MAX);
    BEGIN TRANSACTION;
    RECEIVE TOP(1)
        @handle = conversation_handle,
        @messageTypeName = message_type_name,
        @messageBody = message_body
        FROM [sender_queue];
        
    IF @handle IS NOT NULL
    BEGIN
        -- Delete the message from the [SessionConversations] table
        -- before sending the [EndOfStream] message. The order is
        -- important to avoid deadlocks. Strictly speaking, we should
        -- only delete if the message type is timer or error, but is
        -- simpler and safer to just delete always
        --
        DELETE FROM Core.[SessionConversations]
            WHERE [Handle] = @handle;
        IF @messageTypeName = N'http://schemas.microsoft.com/SQL/ServiceBroker/DialogTimer'
        BEGIN
            SEND ON CONVERSATION @handle MESSAGE TYPE [EndOfStream];
        END
        ELSE IF @messageTypeName = N'http://schemas.microsoft.com/SQL/ServiceBroker/EndDialog'
        BEGIN
            END CONVERSATION @handle;
        END
        ELSE IF @messageTypeName = N'http://schemas.microsoft.com/SQL/ServiceBroker/Error'
        BEGIN
            END CONVERSATION @handle;
        END;
    END
    COMMIT;
END
GO


/******************************************************************************/
/*  Drop and Create the [EnqueueMessage] trigger before we create it again    */
/******************************************************************************/
IF EXISTS (SELECT * FROM [sys].[triggers] WHERE object_id = OBJECT_ID(N'[Core].[EnqueueMessage]'))
    DROP TRIGGER [Core].[EnqueueMessage]
GO
CREATE TRIGGER [Core].[EnqueueMessage]
    ON [Core].[Resource]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

DECLARE @DMLType CHAR(1)
DECLARE @msgBody XML
DECLARE @dlgId UNIQUEIDENTIFIER
DECLARE @ID VARCHAR(50)
DECLARE @Count INT
DECLARE @MsgTable TABLE( ZentityMessages NVARCHAR(MAX))
DECLARE @FinalXML XML

-- After delete statement
    IF NOT EXISTS (SELECT * FROM inserted)
    BEGIN    
    
    SELECT    @Count = (select count(*) FROM deleted)    
        IF(@Count != 0)
        BEGIN
            SET @DMLType = 'D'
        END    
        ELSE    
        BEGIN
            RETURN
        END
        
    END 
    -- After update or insert statement
    ELSE
    BEGIN
        -- After update statement
        IF EXISTS (SELECT * FROM deleted)
            SELECT     @DMLType = 'U';
        -- After insert statement
        ELSE
            SELECT    @DMLType = 'I';
    END
    
    -- Create the resource changed xml and add it to a table.
    IF @DMLType <> 'D'
        BEGIN            
        
        Set @msgBody =(
        SELECT(SELECT [Resource].ID as "@ResourceID", [DataModelModule].Namespace as "@Namespace", [ResourceType].Name as "@Name",[Resource].DateAdded as "@DateAdded", [Resource].DateModified as "@DateModified", [Resource].ResourceTypeId as "@ResourceTypeId"
        FROM [inserted] as [Resource] 
        INNER JOIN Core.ResourceType as [ResourceType] ON [Resource].ResourceTypeId = [ResourceType].Id 
        INNER JOIN Core.DataModelModule as DataModelModule ON [ResourceType].DataModelModuleId = [DataModelModule].Id
        WHERE [Resource].ID IN (select ID From [inserted]) FOR XML PAth('Resource')))
        END 
    ELSE
        
        BEGIN
                
        Set @msgBody =(
        SELECT(SELECT [Resource].ID as "@ResourceID", [DataModelModule].Namespace as "@Namespace", [ResourceType].Name as "@Name",[Resource].DateAdded as "@DateAdded", [Resource].DateModified as "@DateModified", [Resource].ResourceTypeId as "@ResourceTypeId"
        FROM [deleted] as [Resource]
        INNER JOIN Core.ResourceType as [ResourceType] ON [Resource].ResourceTypeId = [ResourceType].Id 
        INNER JOIN Core.DataModelModule as DataModelModule ON [ResourceType].DataModelModuleId = [DataModelModule].Id
        WHERE [Resource].ID IN (select ID From [deleted]) FOR XML PAth('Resource')))
        END
    
    SET @FinalXML = (Select @DMLType as 'Operation', @msgBody as 'ChangedData'
    FOR XML PATH('ZentityMsg'))
        
    exec Core.SendMessage ZentitySendService, N'ZentityReceiveService', ZentityContract, ZentityMessage, @FinalXML
END
GO


-- Create Message Type
IF NOT EXISTS (SELECT * FROM [sys].[service_message_types] WHERE name = N'ZentityMessage')
BEGIN
    CREATE MESSAGE TYPE ZentityMessage VALIDATION = NONE
END

-- Create Contract
IF NOT EXISTS (SELECT * FROM [sys].[service_contracts] WHERE name = N'ZentityContract')
BEGIN
    CREATE CONTRACT ZentityContract (ZentityMessage SENT BY INITIATOR)
END

-- Create Send Queue
IF NOT EXISTS (SELECT * FROM [sys].[service_queues] WHERE name = N'ZentitySendQueue')
BEGIN
    CREATE QUEUE ZentitySendQueue WITH ACTIVATION 
    (
        STATUS = ON,
        MAX_QUEUE_READERS = 1,
        PROCEDURE_NAME = [Core].[SenderActivation],
        EXECUTE AS OWNER
    )
END
GO

-- Create Receive Queue
IF NOT EXISTS (SELECT * FROM [sys].[service_queues] WHERE name = N'ZentityReceiveQueue')
BEGIN
    CREATE QUEUE ZentityReceiveQueue
END

-- Create Send Service on Send Queue
IF NOT EXISTS (SELECT * FROM [sys].[services] WHERE name = N'ZentitySendService')
BEGIN
    CREATE SERVICE ZentitySendService ON QUEUE ZentitySendQueue (ZentityContract)
END

-- Create Receive Service on Recieve Queue
IF NOT EXISTS (SELECT * FROM [sys].[services] WHERE name = N'ZentityReceiveService')
BEGIN
    CREATE SERVICE ZentityReceiveService ON QUEUE ZentityReceiveQueue (ZentityContract)
END