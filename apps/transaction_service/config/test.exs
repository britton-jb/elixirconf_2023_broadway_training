import Config

config :transaction_service, TransactionService.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "transaction_service_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  port: "5433"

config :transaction_service, :naive_producer_module, {Broadway.DummyProducer, []}
config :transaction_service, :producer_module, {Broadway.DummyProducer, []}
config :transaction_service, :driving_producer_module, {Broadway.DummyProducer, []}
