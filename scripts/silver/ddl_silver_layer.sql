/*
DDL Silver Layer — Streamify Inc.
Memes noms de colonnes que le Bronze, types corrects + metadata
==================================================
Attention : Ce code va effacer tout et recommencer
*/

-- ====================================================
-- TABLE : silver.crm_customers
-- ====================================================
IF OBJECT_ID('silver.crm_customers', 'U') IS NOT NULL
    DROP TABLE silver.crm_customers;
GO
CREATE TABLE silver.crm_customers (
    customer_id      NVARCHAR(50),
    first_name       NVARCHAR(50),
    last_name        NVARCHAR(50),
    email            NVARCHAR(100),
    birth_date       DATE,             -- converti depuis ISO et DD/MM/YYYY
    age              INT,              -- colonne a ete ajoute et est calcule depuis birth_date
    country          NVARCHAR(5),      -- standardise vers code ISO 2 lettres
    city             NVARCHAR(50),
    gender           NVARCHAR(10),     -- standardise : M / F / Other
    signup_date      DATE,
    plan_name        NVARCHAR(20),     -- standardise : FREE/BASIC/STANDARD/PREMIUM
    plan_start_date  DATE,
    monthly_price    DECIMAL(10,2),    -- valeurs valides : 0/7.99/13.99/17.99
    is_active        BIT,              -- standardise : 0 ou 1
    last_login       DATE,             -- dates futures supprimees
    dwh_create_date  DATETIME DEFAULT GETDATE() -------cette colonne est une metadata--------
);
GO

-- ====================================================
-- TABLE : silver.erp_viewing_logs
-- ====================================================
IF OBJECT_ID('silver.erp_viewing_logs', 'U') IS NOT NULL
    DROP TABLE silver.erp_viewing_logs;
GO
CREATE TABLE silver.erp_viewing_logs (
    log_id            NVARCHAR(20),
    customer_id       NVARCHAR(20),
    content_id        NVARCHAR(20),
    event_type        NVARCHAR(10),
    event_timestamp   DATETIME,         -- converti depuis ISO / EU / Unix
    device_code       NVARCHAR(20),
    [session_id]      NVARCHAR(20),
    duration_seconds  INT,              -- valide : > 0 uniquement
    rating_given      TINYINT,          -- valide : 1-5, NULL si pas de RATE
    quality_stream    NVARCHAR(5),      -- standardise : SD / HD / 4K
    ip_country        NVARCHAR(5),
    app_version       NVARCHAR(10),
    dwh_create_date   DATETIME DEFAULT GETDATE()
);
GO

-- ====================================================
-- TABLE : silver.erp_content_catalog
-- ====================================================
IF OBJECT_ID('silver.erp_content_catalog', 'U') IS NOT NULL
    DROP TABLE silver.erp_content_catalog;
GO
CREATE TABLE silver.erp_content_catalog (
    content_id                NVARCHAR(20),
    title                     NVARCHAR(100),  -- standardise : Title Case
    content_type              NVARCHAR(20),   -- standardise : Series / Movie
    genre                     NVARCHAR(50),   -- standardise : liste fermee
    original_language         NVARCHAR(5),    -- standardise : code ISO (EN/FR/ES...)
    release_year              INT,            -- valide : entre 1920 et 2025
    avg_episode_duration_min  INT,            -- valide : entre 5 et 240
    total_episodes            INT,            -- NULL accepte
    maturity_rating           NVARCHAR(10),   -- standardise : PG/PG-13/TV-14/TV-MA/TV-G
    country_of_origin         NVARCHAR(5),    -- standardise : code ISO
    is_original               BIT,            -- standardise : 0 ou 1
    date_added_platform       DATE,
    dwh_create_date           DATETIME DEFAULT GETDATE()
);
GO

-- ====================================================
-- TABLE : silver.crm_subscription_history
-- ====================================================
IF OBJECT_ID('silver.crm_subscription_history', 'U') IS NOT NULL
    DROP TABLE silver.crm_subscription_history;
GO
CREATE TABLE silver.crm_subscription_history (
    record_id       NVARCHAR(20),
    customer_id     NVARCHAR(20),
    old_plan        NVARCHAR(20),     -- NULL = premiere inscription, c'est normal
    new_plan        NVARCHAR(20),
    change_date     DATE,
    change_reason   NVARCHAR(20),     -- NULL accepte
    payment_status  NVARCHAR(10),
    amount_charged  DECIMAL(10,2),    -- aligne avec les prix officiels des plans
    payment_method  NVARCHAR(20),     -- NULL accepte pour FREE
    dwh_create_date DATETIME DEFAULT GETDATE()
);
GO
