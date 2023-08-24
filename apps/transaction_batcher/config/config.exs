import Config

config :transaction_batcher, TransactionBatcher.Scheduler,
  jobs: [
    transaction_batcher: [
      # Every 15 seconds
      schedule: {:extended, "*/15"},
      task: {TransactionBatcher, :read_csv, []}
    ]
  ]
