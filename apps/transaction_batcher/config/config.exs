import Config

config :transaction_batcher, TransactionBatcher.Scheduler,
  jobs: [
    # Every minute
    {"* * * * *", {TransactionBatcher, :read_csv, []}}
  ]
