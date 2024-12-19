select  
        bEmployeeMasterID,
        FirstName,
        LastName,
        bCompanyLocationsID,
        bEmployeeTypeID,
        Terminated1,
        IsDeliveryDriver,
        IsServiceDriver,
        IsSalesperson,
        REPLACE(UserName, '\\', '\\\\\\\\') AS UserName,
        IsWholesaleDriver,
        IsMeterReader,
        Signature,
        Email,
        bDivisionID,
        Note,
        IsCylinderExchangeDriver,
        IsPOSUser,
        SetupInKnowledgeBase,
        InternalEmployeeID       
        from csv_data1;


-- Step 1: Replace tabs with commas for field separation
SET @DATA = REPLACE('{TASK(PrevTask|StdOut)}', '\t', ',');

SELECT '{TASK(PrevTask|StdOut)}';

-- Step 2: Add parentheses around each row and replace newline with row separators
SET @DATA = REPLACE(@DATA, '\n', '),(');

-- Step 3: Add enclosing parentheses for the entire VALUES clause
SET @DATA = CONCAT('(', @DATA, ')');

SELECT @DATA;

-- Construct the INSERT statement as a full SQL string
SET @sql = CONCAT(
    'INSERT INTO csv_data (
        bEmployeeMasterID,
        FirstName,
        LastName,
        bCompanyLocationsID,
        bEmployeeTypeID,
        Terminated1,
        IsDeliveryDriver,
        IsServiceDriver,
        IsSalesperson,
        UserName,
        IsWholesaleDriver,
        IsMeterReader,
        Signature,
        Email,
        bDivisionID,
        Note,
        IsCylinderExchangeDriver,
        IsPOSUser,
        SetupInKnowledgeBase,
        InternalEmployeeID
    ) VALUES ', @DATA, ';'
);
SELECT @sql;
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

Job Name: {TRIGGER(Active|LastTrigger|VisualCron.Result.Job.Name)}
Message: {TRIGGER(Active|LastTrigger|VisualCron.Result.Message)}
Timestamp: {TRIGGER(Active|LastTrigger|LastRun|MMM d, yyyy HH:mm tt)}


