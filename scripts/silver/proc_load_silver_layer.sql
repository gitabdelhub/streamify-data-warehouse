/*
The purpose of this script is to load the silver layer with cleaned and standardized data from the bronze layer.
It first truncates the table (delete all its content) and then loads with transformed data.
Execute this script if you want to reload the silver layer  

To execute it , enter: EXEC load_silver_layer;
*/

CREATE OR ALTER PROCEDURE load_silver_layer AS
BEGIN

    DECLARE @start_time DATETIME,
            @end_time DATETIME,
            @batch_start_time DATETIME,
            @batch_end_time DATETIME

    BEGIN TRY 

            SET @batch_start_time = GETDATE();
            
            PRINT '==================================================='
            PRINT '              INSERTING data THE silver LAYER             '
            PRINT '==================================================='

            SET @start_time = GETDATE()
            PRINT '--> TRUNCATING silver.crm_subscription_history'
            TRUNCATE TABLE silver.crm_subscription_history;
            PRINT '--> INSERTING data silver.crm_subscription_history'

            INSERT INTO silver.crm_subscription_history (
                record_id, customer_id, old_plan, new_plan, change_date, 
                change_reason, payment_status, amount_charged, payment_method
            )
            SELECT 
                record_id,
                customer_id,
                CASE 
                    WHEN UPPER(TRIM(change_reason)) = 'NEW' THEN NULL 
                    ELSE UPPER(TRIM(old_plan)) 
                END AS old_plan,
                UPPER(TRIM(new_plan)) AS new_plan,
                TRY_CAST(change_date AS DATE) AS change_date,
                UPPER(TRIM(change_reason)) AS change_reason,
                UPPER(TRIM(payment_status)) AS payment_status,
                CASE 
                    WHEN UPPER(TRIM(new_plan)) = 'FREE'     THEN 0.0
                    WHEN UPPER(TRIM(new_plan)) = 'BASIC'    THEN 7.99
                    WHEN UPPER(TRIM(new_plan)) = 'STANDARD' THEN 13.99
                    WHEN UPPER(TRIM(new_plan)) = 'PREMIUM'  THEN 17.99
                    ELSE 1000.00 
                END AS amount_charged,
                CASE 
                    WHEN UPPER(TRIM(new_plan)) = 'FREE' THEN 'NONE'
                    WHEN payment_method IS NULL OR payment_method = '' THEN 'n/a'
                    ELSE UPPER(TRIM(payment_method))
                END AS payment_method
            FROM bronze.crm_subscription_history;

            SET @end_time = GETDATE()
            PRINT 'History Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec' ;

            SET @start_time = GETDATE()
            PRINT '--> TRUNCATING silver.crm_customers TABLE' 
            TRUNCATE TABLE silver.crm_customers;
            PRINT '--> INSERTING data into silver.crm_customers TABLE';

            WITH first_registration AS (
                SELECT customer_id, MIN(change_date) as first_date
                FROM silver.crm_subscription_history
                GROUP BY customer_id
            ),
            cleaned_data AS (
                SELECT 
                    c.customer_id,
                    c.first_name,
                    c.last_name,
                    CASE 
                        WHEN c.email IS NULL OR c.email = '' THEN 'n/a'
                        WHEN c.email NOT LIKE '%@%.%' THEN 'n/a' 
                        ELSE c.email
                    END AS email,
                    CASE 
                        WHEN c.birth_date LIKE '%/%' THEN TRY_CONVERT(DATE, c.birth_date, 103)
                        ELSE TRY_CAST(c.birth_date AS DATE)
                    END AS birth_date,
                    CASE 
                        WHEN UPPER(TRIM(c.country)) IN ('FRANCE', 'FR')                        THEN 'FR'
                        WHEN UPPER(TRIM(c.country)) IN ('MAROC', 'MOROCCO', 'MA')              THEN 'MA'
                        WHEN UPPER(TRIM(c.country)) IN ('ALGERIA', 'ALGERIE', 'DZ')            THEN 'DZ'
                        WHEN UPPER(TRIM(c.country)) IN ('TUNISIA', 'TUNISIE', 'TN')            THEN 'TN'
                        WHEN UPPER(TRIM(c.country)) IN ('UNITED STATES', 'USA', 'US')          THEN 'US'
                        WHEN UPPER(TRIM(c.country)) IN ('GERMANY', 'ALLEMAGNE', 'DE')          THEN 'DE'
                        WHEN UPPER(TRIM(c.country)) IN ('BELGIUM', 'BELGIQUE', 'BE')           THEN 'BE'
                        WHEN UPPER(TRIM(c.country)) IN ('CANADA', 'CA')                        THEN 'CA'
                        WHEN UPPER(TRIM(c.country)) IN ('UNITED KINGDOM', 'UK', 'GB')          THEN 'GB'
                        WHEN UPPER(TRIM(c.country)) IN ('SPAIN', 'ESPAGNE', 'ES')              THEN 'ES'
                        WHEN UPPER(TRIM(c.country)) IN ('ITALY', 'ITALIE', 'IT')               THEN 'IT'
                        WHEN UPPER(TRIM(c.country)) IN ('NETHERLANDS', 'PAYS-BAS', 'NL')       THEN 'NL'
                        WHEN UPPER(TRIM(c.country)) IN ('SENEGAL', 'SN')                       THEN 'SN'
                        WHEN UPPER(TRIM(c.country)) IN ('IVORY COAST', 'COTE D''IVOIRE', 'CI') THEN 'CI'
                        WHEN UPPER(TRIM(c.country)) IN ('BRAZIL', 'BRESIL', 'BR')              THEN 'BR'
                        WHEN UPPER(TRIM(c.country)) IN ('JAPAN', 'JAPON', 'JP')                THEN 'JP'
                        ELSE 'n/a'
                    END AS country,
                    ISNULL(LOWER(TRIM(c.city)), 'n/a') AS city,
                    CASE 
                        WHEN UPPER(TRIM(c.gender)) IN ('F','FEMALE') THEN 'Female'
                        WHEN UPPER(TRIM(c.gender)) IN ('M','MALE')   THEN 'Male'
                        ELSE 'n/a'
                    END AS gender,
                    ISNULL(TRY_CAST(c.signup_date AS DATE), h.first_date) AS signup_date,
                    CASE 
                        WHEN UPPER(TRIM(c.plan_name)) = 'FREE'     THEN 'FREE'
                        WHEN UPPER(TRIM(c.plan_name)) = 'BASIC'    THEN 'BASIC'
                        WHEN UPPER(TRIM(c.plan_name)) = 'STANDARD' THEN 'STANDARD'
                        WHEN UPPER(TRIM(c.plan_name)) = 'PREMIUM'  THEN 'PREMIUM'
                    END AS plan_name,
                    TRY_CAST(c.plan_start_date AS DATE) AS plan_start_date,
                    CASE 
                        WHEN UPPER(TRIM(c.plan_name)) = 'FREE'     THEN 0.0
                        WHEN UPPER(TRIM(c.plan_name)) = 'BASIC'    THEN 7.99
                        WHEN UPPER(TRIM(c.plan_name)) = 'STANDARD' THEN 13.99
                        WHEN UPPER(TRIM(c.plan_name)) = 'PREMIUM'  THEN 17.99
                        ELSE 1000 
                    END AS monthly_price,
                    CASE 
                        WHEN UPPER(TRIM(CAST(c.is_active AS VARCHAR))) IN ('TRUE', 'YES', '1')  THEN 1
                        WHEN UPPER(TRIM(CAST(c.is_active AS VARCHAR))) IN ('FALSE', 'NO', '0') THEN 0
                        ELSE 1000 
                    END AS is_active,
                    CASE 
                        WHEN c.last_login IS NULL THEN NULL
                        WHEN CAST(c.last_login AS DATE) > GETDATE() THEN NULL
                        ELSE CAST(c.last_login AS DATE) 
                    END AS last_login,
                    ROW_NUMBER() OVER(PARTITION BY c.customer_id ORDER BY c.signup_date DESC) AS rn
                FROM bronze.crm_customers c
                LEFT JOIN first_registration h ON c.customer_id = h.customer_id
                WHERE c.customer_id IS NOT NULL 
                      AND c.country != 'XX'
                      AND c.email != 'test@test.com'
            )
            INSERT INTO silver.crm_customers (
                customer_id, first_name, last_name, email, birth_date, age, country, city, 
                gender, signup_date, plan_name, plan_start_date, monthly_price, is_active, last_login
            )
            SELECT 
                customer_id, first_name, last_name, email, birth_date,
                DATEDIFF(YEAR, birth_date, GETDATE()),
                country, city, gender, signup_date, plan_name,
                CASE 
                    WHEN plan_start_date < signup_date THEN signup_date
                    ELSE plan_start_date
                END AS plan_start_date,
                monthly_price, is_active, last_login
            FROM cleaned_data
            WHERE rn = 1;

            SET @end_time = GETDATE()
            PRINT 'Customers Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec' ;

            SET @start_time = GETDATE()
            PRINT '--> TRUNCATING silver.erp_content_catalog'
            TRUNCATE TABLE silver.erp_content_catalog;
            PRINT '--> INSERTING data silver.erp_content_catalog'
            INSERT INTO silver.erp_content_catalog(
                content_id, title, content_type, genre, original_language,
                release_year, avg_episode_duration_min, total_episodes,
                maturity_rating, country_of_origin, is_original, date_added_platform
            )
            SELECT 
                TRIM(content_id) AS content_id,
                UPPER(TRIM(title)) AS title,
                CASE 
                    WHEN UPPER(TRIM(content_type)) IN ('SERIE', 'SERIES') THEN 'Series'
                    WHEN UPPER(TRIM(content_type)) = 'MOVIE' THEN 'Movie'
                    ELSE 'n/a'
                END AS content_type,
                CASE 
                    WHEN UPPER(TRIM(genre)) IN ('SCI-FI', 'SCIENCE FICTION') THEN 'Sci-Fi'
                    WHEN UPPER(TRIM(genre)) IN ('COMEDY', 'COM') THEN 'Comedy'  -- LIKE pour COMÉDIE avec accent
                    WHEN UPPER(TRIM(genre)) LIKE 'COM_DIE'       THEN 'Comedy'
                    WHEN UPPER(TRIM(genre)) IN ('THRILLER/ANIME', 'THRILLER ANIME') THEN 'Thriller/Anime'
                    WHEN UPPER(TRIM(genre)) = 'ROMANCE'      THEN 'Romance'
                    WHEN UPPER(TRIM(genre)) = 'DRAMA'        THEN 'Drama'
                    WHEN UPPER(TRIM(genre)) = 'CRIME'        THEN 'Crime'
                    WHEN UPPER(TRIM(genre)) = 'ANIMATION'    THEN 'Animation'
                    WHEN UPPER(TRIM(genre)) = 'FANTASY'      THEN 'Fantasy'
                    WHEN UPPER(TRIM(genre)) = 'ACTION/ANIME' THEN 'Action/Anime'
                    WHEN UPPER(TRIM(genre)) = 'FANTASY/ANIME' THEN 'Fantasy/Anime'
                    WHEN UPPER(TRIM(genre)) = 'DOCUMENTARY'  THEN 'Documentary'
                    WHEN UPPER(TRIM(genre)) = 'HORROR'       THEN 'Horror'
                    WHEN UPPER(TRIM(genre)) = 'ACTION'       THEN 'Action'
                    ELSE 'Other'
                END AS genre,
                -- Fix principal : LIKE pour capturer les accents mal encodés (CORÉEN, FRANÇAIS, etc.)
                CASE 
                    WHEN UPPER(TRIM(original_language)) IN ('ANGLAIS', 'ENGLISH', 'EN')    THEN 'EN'
                    WHEN UPPER(TRIM(original_language)) LIKE 'ANGL%'                        THEN 'EN'
                    WHEN UPPER(TRIM(original_language)) IN ('FRENCH', 'FR')                 THEN 'FR'
                    WHEN UPPER(TRIM(original_language)) LIKE 'FRAN%'                        THEN 'FR'
                    WHEN UPPER(TRIM(original_language)) IN ('ESPAGNOL', 'SPANISH', 'ES')    THEN 'ES'
                    WHEN UPPER(TRIM(original_language)) LIKE 'ESPAN%'                       THEN 'ES'
                    WHEN UPPER(TRIM(original_language)) IN ('KOREAN', 'KO')                 THEN 'KO'
                    WHEN UPPER(TRIM(original_language)) LIKE 'COR%'                         THEN 'KO'
                    WHEN UPPER(TRIM(original_language)) IN ('ALLEMAND', 'GERMAN', 'DE')     THEN 'DE'
                    WHEN UPPER(TRIM(original_language)) LIKE 'ALLEM%'                       THEN 'DE'
                    WHEN UPPER(TRIM(original_language)) IN ('JAPONAIS', 'JAPANESE', 'JA')   THEN 'JA'
                    WHEN UPPER(TRIM(original_language)) LIKE 'JAPO%'                        THEN 'JA'
                    WHEN UPPER(TRIM(original_language)) IN ('ARABIC', 'ARABE', 'AR')        THEN 'AR'
                    WHEN UPPER(TRIM(original_language)) LIKE 'ARAB%'                        THEN 'AR'
                    WHEN UPPER(TRIM(original_language)) IN ('PORTUGUESE', 'PORTUGAIS', 'PT') THEN 'PT'
                    WHEN UPPER(TRIM(original_language)) LIKE 'PORT%'                        THEN 'PT'
                    WHEN UPPER(TRIM(original_language)) IN ('ITALIAN', 'ITALIEN', 'IT')     THEN 'IT'
                    WHEN UPPER(TRIM(original_language)) LIKE 'ITAL%'                        THEN 'IT'
                    WHEN UPPER(TRIM(original_language)) IN ('HINDI', 'HI')                  THEN 'HI'
                    WHEN UPPER(TRIM(original_language)) IN ('MANDARIN', 'CHINESE', 'ZH')    THEN 'ZH'
                    ELSE 'n/a'
                END AS original_language,
                CASE 
                    WHEN TRY_CAST(release_year AS INT) > YEAR(GETDATE()) 
                      OR TRY_CAST(release_year AS INT) < 1920 THEN NULL 
                    ELSE TRY_CAST(release_year AS INT)
                END AS release_year,
                CASE 
                    WHEN TRY_CAST(avg_episode_duration_min AS INT) <= 0 THEN NULL 
                    ELSE TRY_CAST(avg_episode_duration_min AS INT)
                END AS avg_episode_duration_min,
                ISNULL(TRY_CAST(total_episodes AS INT), 1) AS total_episodes,
                UPPER(TRIM(maturity_rating)) AS maturity_rating,
                -- Fix : ajout de GERMANY et autres pays manquants
                CASE 
                    WHEN UPPER(TRIM(country_of_origin)) IN ('US', 'USA', 'UNITED STATES')  THEN 'US'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('KR', 'SOUTH KOREA', 'KOREA')  THEN 'KR'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('JP', 'JAPAN', 'JAPON')        THEN 'JP'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('FR', 'FRANCE')                THEN 'FR'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('UK', 'UNITED KINGDOM', 'GB')  THEN 'GB'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('DE', 'GERMANY', 'ALLEMAGNE')  THEN 'DE'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('ES', 'SPAIN', 'ESPAGNE')      THEN 'ES'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('IT', 'ITALY', 'ITALIE')       THEN 'IT'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('IN', 'INDIA', 'INDE')         THEN 'IN'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('BR', 'BRAZIL', 'BRESIL')      THEN 'BR'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('CA', 'CANADA')                THEN 'CA'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('AU', 'AUSTRALIA', 'AUSTRALIE') THEN 'AU'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('MX', 'MEXICO', 'MEXIQUE')     THEN 'MX'
                    WHEN UPPER(TRIM(country_of_origin)) IN ('CN', 'CHINA', 'CHINE')        THEN 'CN'
                    ELSE 'n/a'
                END AS country_of_origin,
                CASE 
                    WHEN UPPER(TRIM(CAST(is_original AS VARCHAR))) IN ('TRUE', '1', 'YES') THEN 1
                    ELSE 0 
                END AS is_original,
                CASE 
                    WHEN TRY_CAST(date_added_platform AS DATE) < DATEFROMPARTS(
                        ISNULL(TRY_CAST(release_year AS INT), 1900), 1, 1
                    ) THEN NULL
                    ELSE TRY_CAST(date_added_platform AS DATE)
                END AS date_added_platform
            FROM bronze.erp_content_catalog
            WHERE content_id IS NOT NULL;

            SET @end_time = GETDATE()
            PRINT 'Content Catalog Duration: ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) +' sec' ;

            SET @start_time = GETDATE()
            PRINT '--> TRUNCATING silver.erp_viewing_logs'
            TRUNCATE TABLE silver.erp_viewing_logs;
            PRINT '--> INSERTING data silver.erp_viewing_logs'
            INSERT INTO silver.erp_viewing_logs(
                log_id, customer_id, content_id, event_type, event_timestamp,
                device_code, [session_id], duration_seconds, rating_given,
                quality_stream, ip_country, app_version
            )
            SELECT
                log_id,
                customer_id,
                content_id,
                CASE
                    WHEN UPPER(TRIM(event_type)) = 'PLAY'   THEN 'PLAY'
                    WHEN UPPER(TRIM(event_type)) = 'PAUSE'  THEN 'PAUSE'
                    WHEN UPPER(TRIM(event_type)) = 'RESUME' THEN 'RESUME'
                    WHEN UPPER(TRIM(event_type)) = 'STOP'   THEN 'STOP'
                    WHEN UPPER(TRIM(event_type)) = 'RATE'   THEN 'RATE'
                END AS event_type,
                CASE
                    WHEN event_timestamp NOT LIKE '%-%'
                     AND event_timestamp NOT LIKE '%/%'
                    THEN DATEADD(SECOND, TRY_CAST(event_timestamp AS BIGINT), '1970-01-01')
                    WHEN event_timestamp LIKE '__/__/____'
                    THEN TRY_CONVERT(DATETIME, event_timestamp, 103)
                    ELSE TRY_CAST(event_timestamp AS DATETIME)
                END AS event_timestamp,
                device_code,
                [session_id],
                CASE
                    WHEN TRY_CAST(duration_seconds AS INT) < 0 THEN NULL
                    ELSE TRY_CAST(duration_seconds AS INT)
                END AS duration_seconds,
                CASE
                    WHEN UPPER(TRIM(event_type)) = 'RATE'
                     AND TRY_CAST(rating_given AS INT) BETWEEN 1 AND 5
                    THEN TRY_CAST(rating_given AS INT)
                    ELSE NULL
                END AS rating_given,
                UPPER(TRIM(quality_stream)) AS quality_stream,
                ip_country,
                app_version
            FROM (
                SELECT *,
                       ROW_NUMBER() OVER (
                           PARTITION BY [session_id], event_type
                           ORDER BY event_timestamp DESC
                       ) AS rn
                FROM bronze.erp_viewing_logs
            ) t
            WHERE customer_id IN (
                SELECT customer_id FROM bronze.crm_customers
                WHERE customer_id IS NOT NULL
            )
            AND content_id IN (
                SELECT content_id FROM bronze.erp_content_catalog
                WHERE content_id IS NOT NULL
            )
            AND rn = 1;

            SET @end_time = GETDATE()
            PRINT 'Viewing Logs Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR) + ' sec';
            
            PRINT '============================================================================';
            PRINT '                         SILVER LAYER LOADED SUCCESSFULLY                   ';
            SET @batch_end_time = GETDATE();
            PRINT 'DURATION of the batch is: ' + CAST(DATEDIFF(SECOND,@batch_start_time,@batch_end_time) AS NVARCHAR) +' sec' ;
            PRINT '============================================================================'
        
        END TRY

        BEGIN CATCH
            PRINT '========================================';
            PRINT 'ERROR DURING silver LOAD';
            PRINT ERROR_MESSAGE();
            PRINT '========================================';
        END CATCH

END;
GO