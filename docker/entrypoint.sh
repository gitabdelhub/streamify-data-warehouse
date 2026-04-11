#!/bin/bash

/opt/mssql/bin/sqlservr &
SQL_PID=$!

echo "Waiting for SQL Server to start..."
sleep 30

echo "Initializing database..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -No \
    -i /app/scripts/ini_database_streamify.sql

echo "Loading Bronze layer..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -No -d streamify \
    -i /app/scripts/bronze/ddl_bronze.sql
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -No -d streamify \
    -i /app/scripts/bronze/proc_load_bronze_layer.sql
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -No -d streamify \
    -Q "EXEC load_bronze_layer"

echo "Loading Silver layer..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -No -d streamify \
    -i /app/scripts/silver/ddl_silver_layer.sql
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -No -d streamify \
    -i /app/scripts/silver/proc_load_silver_layer.sql
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -No -d streamify \
    -Q "EXEC load_silver_layer"

echo "Loading Gold layer..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$SA_PASSWORD" -No -d streamify \
    -i /app/scripts/gold/ddl_gold_layer.sql

echo "Pipeline complete."

wait $SQL_PID
