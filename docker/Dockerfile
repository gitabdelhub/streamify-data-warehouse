FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

RUN apt-get update && apt-get install -y dos2unix

WORKDIR /app

COPY scripts/ ./scripts/
COPY datasets/ ./datasets/
COPY docker/entrypoint.sh ./entrypoint.sh

RUN dos2unix ./entrypoint.sh && chmod +x ./entrypoint.sh

ENV ACCEPT_EULA=Y
ENV MSSQL_PID=Developer

USER mssql

ENTRYPOINT ["/app/entrypoint.sh"]
