import Config

config :transaction_service, ecto_repos: [TransactionService.Repo]

config :transaction_service, TransactionService.Repo,
  database: "transaction_service",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: "5433"

config :transaction_service,
       :naive_producer_module,
       {BroadwayRabbitMQ.Producer, queue: "transaction_batch_closed", on_failure: :reject_and_requeue}

config :transaction_service,
       :producer_module,
       {BroadwayRabbitMQ.Producer, queue: "transaction_batch_closed", on_failure: :ack}

config :transaction_service,
       :driving_producer_module,
       {BroadwayRabbitMQ.Producer, queue: "transaction_saved", on_failure: :ack}

if config_env() == :test do
  import_config "#{config_env()}.exs"
end
