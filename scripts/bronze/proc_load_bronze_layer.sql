/*
    Loads the Bronze layer with raw data from CSV sources.
    No transformation applied — data is ingested as-is.
    Full truncate and reload on every run.

    Usage: EXEC load_bronze_layer;
*/

CREATE OR ALTER PROCEDURE load_bronze_layer AS
BEGIN

    DECLARE @start_time      DATETIME,
            @end_time        DATETIME,
            @batch_start     DATETIME,
            @batch_end       DATETIME

    BEGIN TRY

        SET @batch_start = GETDATE();

        PRINT '==================================================='
        PRINT '         LOADING THE BRONZE LAYER                 '
        PRINT '==================================================='

        -- crm_customers
        SET @start_time = GETDATE()
        PRINT '--> TRUNCATING bronze.crm_customers'
        TRUNCATE TABLE bronze.crm_customers;
        PRINT '--> LOADING bronze.crm_customers'
        BULK INSERT bronze.crm_customers
        FROM '/app/datasets/crm_customers.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', CODEPAGE = '65001', TABLOCK);
        SET @end_time = GETDATE()
        PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' sec';

        -- crm_subscription_history
        SET @start_time = GETDATE()
        PRINT '--> TRUNCATING bronze.crm_subscription_history'
        TRUNCATE TABLE bronze.crm_subscription_history;
        PRINT '--> LOADING bronze.crm_subscription_history'
        BULK INSERT bronze.crm_subscription_history
        FROM '/app/datasets/crm_subscription_history.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', CODEPAGE = '65001', TABLOCK);
        SET @end_time = GETDATE()
        PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' sec';

        -- erp_content_catalog
        SET @start_time = GETDATE()
        PRINT '--> TRUNCATING bronze.erp_content_catalog'
        TRUNCATE TABLE bronze.erp_content_catalog;
        PRINT '--> LOADING bronze.erp_content_catalog'
        BULK INSERT bronze.erp_content_catalog
        FROM '/app/datasets/erp_content_catalog.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', CODEPAGE = '65001', TABLOCK);
        SET @end_time = GETDATE()
        PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' sec';

        -- erp_viewing_logs
        SET @start_time = GETDATE()
        PRINT '--> TRUNCATING bronze.erp_viewing_logs'
        TRUNCATE TABLE bronze.erp_viewing_logs;
        PRINT '--> LOADING bronze.erp_viewing_logs'
        BULK INSERT bronze.erp_viewing_logs
        FROM '/app/datasets/erp_viewing_logs.csv'
        WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', CODEPAGE = '65001', TABLOCK);
        SET @end_time = GETDATE()
        PRINT 'Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' sec';

        SET @batch_end = GETDATE();
        PRINT '============================================================'
        PRINT '              BRONZE LAYER LOADED SUCCESSFULLY              '
        PRINT 'Total duration: ' + CAST(DATEDIFF(SECOND, @batch_start, @batch_end) AS NVARCHAR) + ' sec'
        PRINT '============================================================'

    END TRY
    BEGIN CATCH
        PRINT '========================================'
        PRINT 'ERROR DURING BRONZE LOAD'
        PRINT ERROR_MESSAGE()
        PRINT '========================================'
    END CATCH

END;
GO