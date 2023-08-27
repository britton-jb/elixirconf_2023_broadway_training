curl -i -X POST -H "Accept:application/json" -H  "Content-Type:application/json" http://localhost:8083/connectors/ -d '
{
    "name": "transactions-service-connector",
    "config": {
        "connector.class": "io.debezium.connector.postgresql.PostgresConnector",
        "database.dbname" : "transaction_service",
        "database.hostname": "postgres",
        "database.password": "postgres",
        "database.port": "5432",
        "database.server.name": "postgres",
        "database.user": "postgres",
        "schema.include.list": "public",
        "plugin.name": "pgoutput",
        "tasks.max": "1"
    }
}'