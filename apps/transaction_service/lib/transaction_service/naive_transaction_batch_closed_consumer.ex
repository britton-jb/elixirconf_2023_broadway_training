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
    transformed = transform_message(decoded)

    case Transactions.insert(transformed) do
      {:ok, _} -> message
      {:error, _error} -> Message.failed(message, "Ignored error - failed to insert")
    end
  end

  defp transform_message(json) do
    amount =
      case Integer.parse(json["price_current"]) do
        :error -> :error
        {dollars, "." <> string_cents} when byte_size(string_cents) <= 2 ->
          case Integer.parse(string_cents) do
            :error -> :error
            {cents, _} -> dollars * 100 + cents
          end

        _invalid_cents -> :error
      end

    %{
      item: json["product_name"],
      brand: json["brand"],
      amount: amount,
      department: json["department"],
      category: json["category"],
      sku: json["sku"]
    }
  end
end
