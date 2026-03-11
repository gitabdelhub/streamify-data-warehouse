/*
Ce script sert a creer la database pour le projet de data warehouse 
de STREAMIFY INC. Ce projet vise a creer un DWH selon la medaillon architecture et ensuite realiser le 
power bi et inclure une composante AI.
========================================================================================================
ATTENTION :
    L'exécution de ce script supprimera intégralement la base de données 'streamify_dwh' si elle existe.
    Toutes les données de la base seront définitivement perdues. Procédez avec prudence
    et assurez-vous d'avoir des sauvegardes avant d'exécuter ce script.
*/

USE MASTER 
GO

---------suppression de la database si elle existe deja-------------
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'streamify_dwh')
BEGIN
    ALTER DATABASE streamify_dwh SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE streamify_dwh;
END;
GO

---------Create the streamify data warehouse and medaillon layers---
CREATE DATABASE streamify_dwh;
GO

USE streamify_dwh;
GO

CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO
