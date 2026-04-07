/*
===================================================================================
    STREAMIFY INC. -- SILVER LAYER CLEANING EXPLORATION
    
    Ce script documente toutes les explorations de nettoyage effectuées
    sur les données Bronze avant implémentation dans la procédure Silver.
    
    Il ne modifie aucune donnée -- lecture seule.
    Il est organisé table par table dans l'ordre d'implémentation.
    
    Ordre :
        1. crm_subscription_history
        2. crm_customers
        3. erp_content_catalog
        4. erp_viewing_logs
===================================================================================
*/


-- ===================================================================================
-- 1. CRM_SUBSCRIPTION_HISTORY
-- ===================================================================================

-- Vue générale de la table brute
SELECT *
FROM bronze.crm_subscription_history;

-- Nettoyage des champs clés
SELECT 
    record_id,
    customer_id,
    -- Règle : old_plan est NULL pour les premières inscriptions (change_reason = 'NEW')
    CASE 
        WHEN UPPER(TRIM(change_reason)) = 'NEW' THEN NULL 
        ELSE UPPER(TRIM(old_plan)) 
    END AS old_plan,
    UPPER(TRIM(new_plan)) AS new_plan,
    TRY_CAST(change_date AS DATE) AS change_date,
    UPPER(TRIM(change_reason)) AS change_reason,
    UPPER(TRIM(payment_status)) AS payment_status,
    -- Recalcul du montant depuis le plan (source plus fiable que le champ brut)
    CASE 
        WHEN UPPER(TRIM(new_plan)) = 'FREE'     THEN 0.0
        WHEN UPPER(TRIM(new_plan)) = 'BASIC'    THEN 7.99
        WHEN UPPER(TRIM(new_plan)) = 'STANDARD' THEN 13.99
        WHEN UPPER(TRIM(new_plan)) = 'PREMIUM'  THEN 17.99
        ELSE 1000.00  -- Sentinelle pour plans inconnus
    END AS amount_charged,
    -- Règle : FREE n'a pas de moyen de paiement
    CASE 
        WHEN UPPER(TRIM(new_plan)) = 'FREE'              THEN 'NONE'
        WHEN payment_method IS NULL OR payment_method = '' THEN 'n/a'
        ELSE UPPER(TRIM(payment_method))
    END AS payment_method
FROM bronze.crm_subscription_history;


-- ===================================================================================
-- 2. CRM_CUSTOMERS
-- ===================================================================================

-- Vue générale de la table brute
SELECT 
    customer_id, first_name, last_name, email, birth_date,
    country, city, gender, signup_date, plan_name,
    plan_start_date, monthly_price, is_active, last_login
FROM bronze.crm_customers;

-- Vérification des doublons sur customer_id
SELECT 
    customer_id,
    COUNT(*) AS nb
FROM (
    SELECT *,
           ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY signup_date DESC) AS rn
    FROM bronze.crm_customers
    WHERE customer_id IS NOT NULL
) AS rsn
WHERE rn = 1
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Nettoyage gender
SELECT DISTINCT
    gender,
    CASE 
        WHEN UPPER(TRIM(gender)) IN ('F', 'FEMALE') THEN 'Female'
        WHEN UPPER(TRIM(gender)) IN ('M', 'MALE')   THEN 'Male'
        ELSE 'n/a'
    END AS gender_cleaned
FROM bronze.crm_customers;

-- Nettoyage plan_name
SELECT DISTINCT
    plan_name,
    CASE 
        WHEN UPPER(TRIM(plan_name)) = 'FREE'     THEN 'FREE'
        WHEN UPPER(TRIM(plan_name)) = 'BASIC'    THEN 'BASIC'
        WHEN UPPER(TRIM(plan_name)) = 'STANDARD' THEN 'STANDARD'
        WHEN UPPER(TRIM(plan_name)) = 'PREMIUM'  THEN 'PREMIUM'
        ELSE 'n/a'
    END AS plan_name_cleaned
FROM bronze.crm_customers;

-- Nettoyage monthly_price (recalculé depuis plan_name)
SELECT DISTINCT
    monthly_price,
    CASE 
        WHEN UPPER(TRIM(plan_name)) = 'FREE'     THEN 0.0
        WHEN UPPER(TRIM(plan_name)) = 'BASIC'    THEN 7.99
        WHEN UPPER(TRIM(plan_name)) = 'STANDARD' THEN 13.99
        WHEN UPPER(TRIM(plan_name)) = 'PREMIUM'  THEN 17.99
        ELSE 1000  -- Sentinelle pour plans inconnus
    END AS monthly_price_cleaned
FROM bronze.crm_customers;

-- Nettoyage is_active (6 formats différents dans la source)
SELECT DISTINCT
    is_active,
    CASE 
        WHEN UPPER(TRIM(CAST(is_active AS VARCHAR))) IN ('TRUE', 'YES', '1')  THEN 1
        WHEN UPPER(TRIM(CAST(is_active AS VARCHAR))) IN ('FALSE', 'NO', '0') THEN 0
        ELSE 1000  -- Sentinelle pour valeurs inattendues
    END AS is_active_cleaned
FROM bronze.crm_customers;

-- Nettoyage last_login (suppression des dates futures)
SELECT DISTINCT
    last_login,
    CASE 
        WHEN last_login IS NULL                      THEN NULL
        WHEN CAST(last_login AS DATE) > GETDATE()    THEN NULL
        ELSE CAST(last_login AS DATE) 
    END AS last_login_cleaned
FROM bronze.crm_customers;

-- Combinaison : signup_date récupérée depuis subscription_history si NULL dans CRM
-- + correction plan_start_date < signup_date
WITH first_registration AS (
    SELECT 
        customer_id, 
        MIN(change_date) AS first_date
    FROM silver.crm_subscription_history
    GROUP BY customer_id
),
cleaned_data AS (
    SELECT 
        c.customer_id,
        c.first_name,
        c.last_name,
        CASE 
            WHEN c.email IS NULL OR c.email = '' OR c.email NOT LIKE '%@%.%' THEN 'n/a'
            ELSE c.email 
        END AS email,
        ISNULL(TRY_CAST(c.signup_date AS DATE), h.first_date) AS fixed_signup_date,
        TRY_CAST(c.plan_start_date AS DATE) AS raw_plan_start_date,
        c.plan_name,
        c.monthly_price,
        c.is_active,
        ROW_NUMBER() OVER(PARTITION BY c.customer_id ORDER BY c.signup_date DESC) AS rn
    FROM bronze.crm_customers c
    LEFT JOIN first_registration h ON c.customer_id = h.customer_id
)
SELECT 
    customer_id,
    fixed_signup_date AS signup_date,
    -- Règle : plan_start_date ne peut pas être avant signup_date
    CASE 
        WHEN raw_plan_start_date < fixed_signup_date THEN fixed_signup_date
        ELSE raw_plan_start_date
    END AS plan_start_date
FROM cleaned_data
WHERE rn = 1;


-- ===================================================================================
-- 3. ERP_CONTENT_CATALOG
-- ===================================================================================

-- Vue générale de la table brute
SELECT *
FROM bronze.erp_content_catalog;

-- Nettoyage complet de toutes les colonnes
SELECT 
    TRIM(content_id) AS content_id,
    UPPER(TRIM(title)) AS title,
    -- Normalisation content_type
    CASE 
        WHEN UPPER(TRIM(content_type)) IN ('SERIE', 'SERIES') THEN 'Series'
        WHEN UPPER(TRIM(content_type)) = 'MOVIE'              THEN 'Movie'
        ELSE 'n/a'
    END AS content_type,
    -- Normalisation genre
    CASE 
        WHEN UPPER(TRIM(genre)) IN ('SCI-FI', 'SCIENCE FICTION')     THEN 'Sci-Fi'
        WHEN UPPER(TRIM(genre)) IN ('COMEDY', 'COMÉDIE')             THEN 'Comedy'
        WHEN UPPER(TRIM(genre)) IN ('THRILLER/ANIME','THRILLER ANIME') THEN 'Thriller/Anime'
        WHEN UPPER(TRIM(genre)) = 'ROMANCE'       THEN 'Romance'
        WHEN UPPER(TRIM(genre)) = 'DRAMA'         THEN 'Drama'
        WHEN UPPER(TRIM(genre)) = 'CRIME'         THEN 'Crime'
        WHEN UPPER(TRIM(genre)) = 'ANIMATION'     THEN 'Animation'
        WHEN UPPER(TRIM(genre)) = 'FANTASY'       THEN 'Fantasy'
        WHEN UPPER(TRIM(genre)) = 'ACTION/ANIME'  THEN 'Action/Anime'
        WHEN UPPER(TRIM(genre)) = 'FANTASY/ANIME' THEN 'Fantasy/Anime'
        WHEN UPPER(TRIM(genre)) = 'DOCUMENTARY'   THEN 'Documentary'
        WHEN UPPER(TRIM(genre)) = 'HORROR'        THEN 'Horror'
        WHEN UPPER(TRIM(genre)) = 'ACTION'        THEN 'Action'
        ELSE 'Other'
    END AS genre,
    -- Standardisation langue vers code ISO
    CASE 
        WHEN UPPER(TRIM(original_language)) IN ('ANGLAIS', 'ENGLISH', 'EN') THEN 'EN'
        WHEN UPPER(TRIM(original_language)) IN ('FRANÇAIS', 'FRENCH', 'FR') THEN 'FR'
        WHEN UPPER(TRIM(original_language)) IN ('ESPAGNOL', 'SPANISH', 'ES') THEN 'ES'
        WHEN UPPER(TRIM(original_language)) IN ('CORÉEN', 'KOREAN', 'KO')   THEN 'KO'
        WHEN UPPER(TRIM(original_language)) IN ('ALLEMAND', 'GERMAN', 'DE') THEN 'DE'
        WHEN UPPER(TRIM(original_language)) IN ('JAPONAIS', 'JAPANESE', 'JA') THEN 'JA'
        ELSE UPPER(TRIM(original_language))
    END AS original_language,
    -- Correction des années invalides
    CASE 
        WHEN release_year > YEAR(GETDATE()) OR release_year < 1920 THEN NULL 
        ELSE release_year 
    END AS release_year,
    -- Correction des durées invalides
    CASE 
        WHEN avg_episode_duration_min <= 0 THEN NULL 
        ELSE avg_episode_duration_min 
    END AS avg_episode_duration_min,
    ISNULL(total_episodes, 1) AS total_episodes,
    UPPER(TRIM(maturity_rating)) AS maturity_rating,
    -- Standardisation pays vers code ISO
    CASE 
        WHEN UPPER(TRIM(country_of_origin)) IN ('US', 'USA', 'UNITED STATES')  THEN 'US'
        WHEN UPPER(TRIM(country_of_origin)) IN ('KR', 'SOUTH KOREA')           THEN 'KR'
        WHEN UPPER(TRIM(country_of_origin)) IN ('JP', 'JAPAN')                 THEN 'JP'
        WHEN UPPER(TRIM(country_of_origin)) IN ('FR', 'FRANCE')                THEN 'FR'
        WHEN UPPER(TRIM(country_of_origin)) IN ('UK', 'UNITED KINGDOM', 'GB')  THEN 'GB'
        ELSE UPPER(TRIM(country_of_origin))
    END AS country_of_origin,
    -- Normalisation is_original vers BIT
    CASE 
        WHEN UPPER(TRIM(CAST(is_original AS VARCHAR))) IN ('TRUE', '1', 'YES') THEN 1
        ELSE 0 
    END AS is_original,
    -- Règle : date_added ne peut pas être avant la sortie du contenu
    CASE 
        WHEN TRY_CAST(date_added_platform AS DATE) < DATEFROMPARTS(release_year, 1, 1) THEN NULL
        ELSE TRY_CAST(date_added_platform AS DATE)
    END AS date_added_platform
FROM bronze.erp_content_catalog
WHERE content_id IS NOT NULL;


-- ===================================================================================
-- 4. ERP_VIEWING_LOGS
-- ===================================================================================

-- Vue générale de la table brute
SELECT *
FROM bronze.erp_viewing_logs;

-- Exploration des valeurs distinctes de device_code
SELECT DISTINCT device_code
FROM bronze.erp_viewing_logs;

-- Vérification des clés étrangères orphelines (logs sans customer ou contenu valide)
SELECT COUNT(*) AS logs_orphelins_customer
FROM bronze.erp_viewing_logs
WHERE customer_id NOT IN (
    SELECT customer_id FROM bronze.crm_customers
    WHERE customer_id IS NOT NULL
);

SELECT COUNT(*) AS logs_orphelins_content
FROM bronze.erp_viewing_logs
WHERE content_id NOT IN (
    SELECT content_id FROM bronze.erp_content_catalog
    WHERE content_id IS NOT NULL
);

-- Nettoyage complet des logs
SELECT 
    log_id,
    customer_id,
    content_id,
    -- Normalisation event_type
    CASE 
        WHEN UPPER(TRIM(event_type)) = 'PLAY'   THEN 'PLAY'
        WHEN UPPER(TRIM(event_type)) = 'PAUSE'  THEN 'PAUSE'
        WHEN UPPER(TRIM(event_type)) = 'RESUME' THEN 'RESUME'
        WHEN UPPER(TRIM(event_type)) = 'STOP'   THEN 'STOP'
        WHEN UPPER(TRIM(event_type)) = 'RATE'   THEN 'RATE'
    END AS event_type,
    -- Conversion des 3 formats de timestamp (ISO, EU, Unix)
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
    -- Suppression des durées négatives
    CASE 
        WHEN TRY_CAST(duration_seconds AS INT) < 0 THEN NULL
        ELSE TRY_CAST(duration_seconds AS INT)
    END AS duration_seconds,
    -- Rating valide uniquement sur les événements RATE (1 à 5)
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
    -- Déduplication : on garde le dernier événement par session et type
    SELECT *,
           ROW_NUMBER() OVER(
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