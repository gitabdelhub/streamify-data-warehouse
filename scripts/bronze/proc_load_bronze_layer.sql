/*
The purpose of this script is to load the bronze layer with the raw data from the source , with no modification or transformation
Just as it is.
It first truncates the table (delete all its content) and then load with the data from the source 
Execute this script if you want to reload the bronze layer  

To execute it , enter: EXEC load_bronze_layer;
*/

CREATE OR ALTER PROCEDURE load_bronze_layer AS
BEGIN

    DECLARE @start_time DATETIME,
            @end_time DATETIME,
            @batch_start_time DATETIME,
            @batch_end_time DATETIME

    BEGIN TRY 

            SET @batch_start_time = GETDATE();
            
            PRINT '==================================================='
            PRINT '              LOADING THE BRONZE LAYER             '
            PRINT '==================================================='

            SET @start_time = GETDATE()
            PRINT '--> TRUNCATING bronze.crm_customers TABLE' 
            TRUNCATE TABLE bronze.crm_customers;
            PRINT '--> LOADING bronze.crm_customers TABLE' 
            BULK INSERT bronze.crm_customers
            FROM 'C:\Users\user\Downloads\DATA dwh\datasets\crm_customers.csv'
            WITH (
                  FIRSTROW = 2,
                  FIELDTERMINATOR = ',',
                  CODEPAGE = '65001',
                  TABLOCK
            );
            SET @end_time = GETDATE()
            PRINT 'DURATION of execution is: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec' ;


            SET @start_time = GETDATE()
            PRINT '--> TRUNCATING bronze.crm_subscription_history'
            TRUNCATE TABLE bronze.crm_subscription_history;
            PRINT '--> LOADING bronze.crm_subscription_history'
            BULK INSERT bronze.crm_subscription_history 
            FROM 'C:\Users\user\Downloads\DATA dwh\datasets\crm_subscription_history.csv'
                WITH(
                    FIRSTROW = 2,
                    FIELDTERMINATOR = ',',
                    CODEPAGE = '65001',
                    TABLOCK
            );
            SET @end_time = GETDATE()
            PRINT 'DURATION of execution is: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec' ;

            SET @start_time = GETDATE()
            PRINT '--> TRUNCATING bronze.erp_content_catalog'
            TRUNCATE TABLE bronze.erp_content_catalog;
            PRINT '--> LOADING bronze.erp_content_catalog'
            BULK INSERT bronze.erp_content_catalog
            FROM 'C:\Users\user\Downloads\DATA dwh\datasets\erp_content_catalog.csv'
                WITH(
                    FIRSTROW = 2,
                    FIELDTERMINATOR = ',',
                    CODEPAGE = '65001',
                    TABLOCK
            );
            SET @end_time = GETDATE()
            PRINT 'DURATION of execution is: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec' ;

            SET @start_time = GETDATE()
            PRINT '--> TRUNCATING bronze.erp_viewing_logs'
            TRUNCATE TABLE bronze.erp_viewing_logs;
            PRINT '--> LOADING bronze.erp_viewing_logs'
            BULK INSERT bronze.erp_viewing_logs
            FROM 'C:\Users\user\Downloads\DATA dwh\datasets\erp_viewing_logs.csv'
                WITH(
                    FIRSTROW = 2,
                    FIELDTERMINATOR = ',',
                    CODEPAGE = '65001',
                    TABLOCK
            );
            SET @end_time = GETDATE()
            PRINT 'DURATION of execution is: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec' ;

            
            PRINT '============================================================================';
            PRINT '                         BRONZE LAYER LOADED SUCCESSFULLY                   ';
            SET @batch_end_time = GETDATE();
            PRINT 'DURATION of the batch is: ' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) +' sec' ;
            PRINT '============================================================================'
        
        END TRY

        BEGIN CATCH
                PRINT '========================================';
                PRINT 'ERROR DURING BRONZE LOAD';
                PRINT ERROR_MESSAGE();
                PRINT '========================================';
        END CATCH


END;
GO
