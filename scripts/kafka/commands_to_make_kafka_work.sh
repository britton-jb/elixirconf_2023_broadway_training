# One time registration of Kafka Topic
./scripts/kafka/connect_db_to_kafka.sh

# Do the consuming
docker compose -p elixir-conf-2023-broadway-training \
    exec kafka /opt/bitnami/kafka/bin/kafka-console-consumer.sh \
    --bootstrap-server kafka:9092 \
    --from-beginning \
    --property print.key=true \
    --topic postgres.public.transactions

# quickly insert row
psql -U postgres -p postgres --host localhost --port 5433 --dbname transaction_service -c "insert into transactions (item,brand,amount,department,category,sku,inserted_at,updated_at) values ('banana','banana brand',123,'produce','fruit','1234',now(),now());"

# delete a connector
curl -X DELETE http://localhost:8083/connectors/transactions-service-connector
