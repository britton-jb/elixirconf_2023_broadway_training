Mimic.copy(TransactionService.Shipper)
Mimic.copy(TransactionService.Transaction)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(TransactionService.Repo, :manual)
BroadwayEctoSandbox.attach(TransactionService.Repo)
