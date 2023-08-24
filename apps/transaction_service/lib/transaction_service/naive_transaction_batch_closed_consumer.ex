defmodule TransactionService.NaiveTransactionBatchClosedConsumer do
  use Broadway

  require Logger

  alias Broadway.Message
  alias TransactionService.Transactions

  def start_link(_opts) do
    producer_module = Application.fetch_env!(:transaction_service, :naive_producer_module)

    Broadway.start_link(__MODULE__,
      name: TransactionService.NaiveTransactionBatchClosedConsumer,
      producer: [module: producer_module],
      processors: [default: [concurrency: 2]]
    )
  end

  @impl true
  def handle_message(_processor, %Message{data: transaction_batch_closed_json} = message, _context) do
    Logger.info("Handling message #{transaction_batch_closed_json}")

    decoded = Jason.decode!(transaction_batch_closed_json)

    case Transactions.insert(decoded) do
      {:ok, _} -> message
      {:error, _error} -> Message.failed(message, "Ignored error - failed to insert")
    end
  end
end
