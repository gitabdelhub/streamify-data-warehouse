-- =============================================================================
-- GOLD LAYER — STREAMIFY INC.
-- DIMS + FACTS 
-- =============================================================================


IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'gold')
BEGIN
    EXEC('CREATE SCHEMA gold');
END
GO

-- =============================================================================
-- 1. dim_date
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_date AS
WITH all_dates AS (
    SELECT DISTINCT CAST(event_timestamp AS DATE) AS date_value
    FROM silver.erp_viewing_logs
    WHERE event_timestamp IS NOT NULL
    UNION
    SELECT DISTINCT change_date FROM silver.crm_subscription_history WHERE change_date IS NOT NULL
    UNION
    SELECT DISTINCT signup_date FROM silver.crm_customers WHERE signup_date IS NOT NULL
    UNION
    SELECT DISTINCT plan_start_date FROM silver.crm_customers WHERE plan_start_date IS NOT NULL
)
SELECT
    CAST(FORMAT(date_value, 'yyyyMMdd') AS INT) AS date_key,
    date_value AS full_date,
    DAY(date_value) AS day,
    MONTH(date_value) AS month,
    DATENAME(MONTH, date_value) AS month_name,
    DATEPART(QUARTER, date_value) AS quarter,
    YEAR(date_value) AS year,
    DATEPART(WEEKDAY, date_value) AS day_of_week,
    DATENAME(WEEKDAY, date_value) AS day_name,
    CASE WHEN DATEPART(WEEKDAY, date_value) IN (1, 7) THEN 1 ELSE 0 END AS is_weekend
FROM all_dates
WHERE date_value IS NOT NULL;
GO

-- =============================================================================
-- 2. dim_customer
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_customer AS
SELECT
    ROW_NUMBER() OVER (ORDER BY customer_id) AS customer_key,
    customer_id,
    first_name,
    last_name,
    email,
    birth_date,
    age,
    gender,
    country,
    city,
    signup_date,
    is_active,
    last_login
FROM silver.crm_customers;
GO

-- =============================================================================
-- 3. dim_subscription_plan
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_subscription_plan AS
SELECT * FROM (
    VALUES
        (1, 'FREE',     0.00,   1),
        (2, 'BASIC',    7.99,   2),
        (3, 'STANDARD', 13.99,  3),
        (4, 'PREMIUM',  17.99,  4)
) AS t(plan_key, plan_name, monthly_price, plan_tier);
GO

-- =============================================================================
-- 4. dim_content
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_content AS
SELECT
    ROW_NUMBER() OVER (ORDER BY content_id) AS content_key,
    content_id,
    title,
    content_type,
    genre,
    original_language,
    release_year,
    avg_episode_duration_min,
    total_episodes,
    maturity_rating,
    country_of_origin,
    is_original,
    date_added_platform
FROM silver.erp_content_catalog;
GO

-- =============================================================================
-- 5. dim_device
-- =============================================================================
CREATE OR ALTER VIEW gold.dim_device AS
SELECT * FROM (
    VALUES
        (1,  'MOB_IOS',  'Mobile',  'iOS',        'Apple iPhone'),
        (2,  'MOB_AND',  'Mobile',  'Android',    'Samsung, Xiaomi, Huawei'),
        (3,  'PC_WIN',   'Desktop', 'Windows',    'Chrome, Edge, Firefox'),
        (4,  'PC_MAC',   'Desktop', 'macOS',      'Safari, Chrome'),
        (5,  'TV_AND',   'TV',      'Android TV', 'Sony, Philips, TCL'),
        (6,  'TV_SAM',   'TV',      'Tizen',      'Samsung Smart TV'),
        (7,  'TV_LG',    'TV',      'webOS',      'LG Smart TV'),
        (8,  'TV_FIRE',  'TV',      'Fire OS',    'Amazon Fire TV Stick'),
        (9,  'TAB_IOS',  'Tablet',  'iPadOS',     'Apple iPad'),
        (10, 'TAB_AND',  'Tablet',  'Android',    'Samsung Tab, Lenovo'),
        (11, 'UNKNOWN',  'Inconnu', 'Inconnu',    'Appareil non identifié')
) AS t(device_key, device_code, device_category, os, description);
GO

-- =============================================================================
-- 6. fact_viewing_sessions
-- =============================================================================
CREATE OR ALTER VIEW gold.fact_viewing_sessions AS

WITH play_events AS (
    SELECT 
        session_id,
        customer_id,
        content_id,
        device_code,
        event_timestamp AS session_start
    FROM silver.erp_viewing_logs
    WHERE event_type = 'PLAY'
),

stop_events AS (
    SELECT 
        session_id,
        duration_seconds
    FROM silver.erp_viewing_logs
    WHERE event_type = 'STOP'
      AND duration_seconds IS NOT NULL
      AND duration_seconds >= 120
),

rate_events AS (
    SELECT 
        session_id,
        rating_given
    FROM silver.erp_viewing_logs
    WHERE event_type = 'RATE'
      AND rating_given BETWEEN 1 AND 5
),

pause_flags AS (
    SELECT DISTINCT 
        session_id,
        1 AS had_pause
    FROM silver.erp_viewing_logs
    WHERE event_type = 'PAUSE'
),

complete_sessions AS (
    SELECT
        p.session_id,
        p.customer_id,
        p.content_id,
        p.device_code,
        p.session_start,
        s.duration_seconds,
        r.rating_given,
        ISNULL(pa.had_pause, 0) AS had_pause
    FROM play_events p
    INNER JOIN stop_events s ON p.session_id = s.session_id
    LEFT JOIN rate_events r ON p.session_id = r.session_id
    LEFT JOIN pause_flags pa ON p.session_id = pa.session_id
)

SELECT
    -- Clés
    ROW_NUMBER() OVER (ORDER BY cs.session_id) AS viewing_session_key,
    CAST(FORMAT(CAST(cs.session_start AS DATE), 'yyyyMMdd') AS INT) AS date_key,
    dc.customer_key,
    cs.customer_id,
    dco.content_key,
    ISNULL(dd.device_key, 11) AS device_key,
    dp.plan_key,
    cs.session_id,

    -- Métriques
    ROUND(cs.duration_seconds / 60.0, 2) AS watch_time_minutes,
    
    CASE
        WHEN cat.avg_episode_duration_min IS NULL THEN NULL
        WHEN cat.avg_episode_duration_min <= 0 THEN NULL
        WHEN (cs.duration_seconds / 60.0) >= (cat.avg_episode_duration_min * 0.75) THEN 1
        ELSE 0
    END AS is_completed,
    
    cs.rating_given AS rating,
    cs.had_pause,
    cs.session_start,
    DATEPART(HOUR, cs.session_start) AS peak_hour

FROM complete_sessions cs

INNER JOIN gold.dim_customer dc
    ON cs.customer_id = dc.customer_id

INNER JOIN gold.dim_content dco
    ON cs.content_id = dco.content_id

LEFT JOIN gold.dim_device dd
    ON cs.device_code = dd.device_code

INNER JOIN gold.dim_subscription_plan dp
    ON dp.plan_name = (
        SELECT TOP 1 sh.new_plan
        FROM silver.crm_subscription_history sh
        WHERE sh.customer_id = cs.customer_id
          AND sh.change_date <= CAST(cs.session_start AS DATE)
        ORDER BY sh.change_date DESC
    )

INNER JOIN silver.erp_content_catalog cat
    ON cs.content_id = cat.content_id;
GO

-- =============================================================================
-- 7. fact_subscriptions
-- =============================================================================
CREATE OR ALTER VIEW gold.fact_subscriptions AS
SELECT
    -- Clés
    ROW_NUMBER() OVER (ORDER BY sh.record_id) AS subscription_key,
    CAST(FORMAT(sh.change_date, 'yyyyMMdd') AS INT) AS date_key,
    dc.customer_key,
    sh.customer_id,
    dp_new.plan_key AS new_plan_key,
    dp_old.plan_key AS old_plan_key,
    sh.record_id,
    sh.change_date,

    -- Attributs
    sh.change_reason,
    sh.payment_status,
    sh.amount_charged,
    sh.payment_method,

    -- Indicateurs
    CASE WHEN sh.change_reason = 'CANCEL'     THEN 1 ELSE 0 END AS is_churn,
    CASE WHEN sh.change_reason = 'UPGRADE'    THEN 1 ELSE 0 END AS is_upgrade,
    CASE WHEN sh.change_reason = 'DOWNGRADE'  THEN 1 ELSE 0 END AS is_downgrade,
    CASE WHEN sh.change_reason = 'NEW'        THEN 1 ELSE 0 END AS is_new_customer,
    CASE WHEN sh.change_reason = 'REACTIVATE' THEN 1 ELSE 0 END AS is_reactivation,
    CASE WHEN sh.payment_status = 'FAILED'    THEN 1 ELSE 0 END AS is_payment_failed

FROM silver.crm_subscription_history sh

INNER JOIN gold.dim_customer dc
    ON sh.customer_id = dc.customer_id

INNER JOIN gold.dim_subscription_plan dp_new
    ON sh.new_plan = dp_new.plan_name

LEFT JOIN gold.dim_subscription_plan dp_old
    ON sh.old_plan = dp_old.plan_name;
GO

-- =============================================================================
PRINT '============================================================'
PRINT '   GOLD LAYER FINAL — DIMS + FACTS UNIQUEMENT'
PRINT '============================================================'
PRINT ''
PRINT '  DIMENSIONS (5) :'
PRINT '    • gold.dim_date'
PRINT '    • gold.dim_customer'
PRINT '    • gold.dim_subscription_plan'
PRINT '    • gold.dim_content'
PRINT '    • gold.dim_device'
PRINT ''
PRINT '  FACT TABLES (2) :'
PRINT '    • gold.fact_viewing_sessions'
PRINT '    • gold.fact_subscriptions'
PRINT ''
PRINT '============================================================'
GO