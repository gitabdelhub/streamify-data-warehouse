/*
Ce script sert a creer le DDL du schema de bronze,
les tables, leur specifications et autres
==================================================
Attention : Ce code va effacer tout et recommencer donc executer
seulement si on veut vraiment
*/

-- ====================================================
-- TABLE : bronze.crm_customers
-- ====================================================
IF OBJECT_ID('bronze.crm_customers', 'U') IS NOT NULL
    DROP TABLE bronze.crm_customers;
GO
CREATE TABLE bronze.crm_customers(
    customer_id      NVARCHAR(50),
    first_name       NVARCHAR(50),
    last_name        NVARCHAR(50),
    email            NVARCHAR(100),
    birth_date       NVARCHAR(50),  -- formats mixtes ISO et DD/MM/YYYY
    country          NVARCHAR(50),
    city             NVARCHAR(50),
    gender           NVARCHAR(20),
    signup_date      NVARCHAR(50),  -- peut être NULL
    plan_name        NVARCHAR(20),  -- casse mélangée
    plan_start_date  NVARCHAR(50),  -- peut être avant signup_date
    monthly_price    NVARCHAR(10),  -- peut avoir des valeurs incorrectes
    is_active        NVARCHAR(10),  -- True/False/1/0/yes/no
    last_login       NVARCHAR(50)   -- quelques dates futures
);
GO

-- ====================================================
-- TABLE : bronze.erp_viewing_logs
-- ====================================================
IF OBJECT_ID('bronze.erp_viewing_logs', 'U') IS NOT NULL
    DROP TABLE bronze.erp_viewing_logs;
GO
CREATE TABLE bronze.erp_viewing_logs(
    log_id            NVARCHAR(20),
    customer_id       NVARCHAR(20),
    content_id        NVARCHAR(20),
    event_type        NVARCHAR(10),
    event_timestamp   NVARCHAR(30),  -- 3 formats : ISO, EU, Unix
    device_code       NVARCHAR(20),
    [session_id]      NVARCHAR(20),
    duration_seconds  NVARCHAR(10),  -- peut être négatif ou vide
    rating_given      NVARCHAR(5),   -- peut être vide ou hors plage
    quality_stream    NVARCHAR(10),
    ip_country        NVARCHAR(5),
    app_version       NVARCHAR(10)
);
GO

-- ====================================================
-- TABLE : bronze.erp_content_catalog
-- ====================================================
IF OBJECT_ID('bronze.erp_content_catalog', 'U') IS NOT NULL
    DROP TABLE bronze.erp_content_catalog;
GO
CREATE TABLE bronze.erp_content_catalog(
    content_id                NVARCHAR(20),
    title                     NVARCHAR(100),
    content_type              NVARCHAR(20),
    genre                     NVARCHAR(50),
    original_language         NVARCHAR(30),  -- code / nom / traduction française
    release_year              NVARCHAR(10),  -- peut être 1800 ou 2099
    avg_episode_duration_min  NVARCHAR(10),  -- peut être 0 ou négatif
    total_episodes            NVARCHAR(10),  -- peut être NULL
    maturity_rating           NVARCHAR(20),
    country_of_origin         NVARCHAR(50),
    is_original               NVARCHAR(10),  -- True/False/1/0/yes
    date_added_platform       NVARCHAR(50)   -- peut être avant release_year
);
GO

-- ====================================================
-- TABLE : bronze.crm_subscription_history
-- ====================================================
IF OBJECT_ID('bronze.crm_subscription_history', 'U') IS NOT NULL
    DROP TABLE bronze.crm_subscription_history;
GO
CREATE TABLE bronze.crm_subscription_history(
    record_id       NVARCHAR(20),
    customer_id     NVARCHAR(20),
    old_plan        NVARCHAR(20),  -- vide pour première inscription
    new_plan        NVARCHAR(20),
    change_date     NVARCHAR(50),
    change_reason   NVARCHAR(20),  -- peut être NULL
    payment_status  NVARCHAR(10),
    amount_charged  NVARCHAR(10),  -- peut être incohérent avec le plan
    payment_method  NVARCHAR(20)   -- vide pour FREE
);
GO