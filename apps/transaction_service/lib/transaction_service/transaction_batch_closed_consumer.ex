defmodule TransactionService.TransactionBatchClosedConsumer do
  use Broadway

  require Logger

  alias AMQP.{Basic, Channel, Connection, Queue}
  alias Broadway.Message
  alias TransactionService.{Transactions, Transaction}

  @queue_name "transaction_batch_closed"
  @failed_queue "transaction_batch_closed.dlq"

  def start_link(_opts) do
    Logger.info("STARTING TRANSACTION BATCH CLOSED CONSUMER")
    producer_module = Application.fetch_env!(:transaction_service, :producer_module)

    {:ok, connection} = Connection.open()
    {:ok, channel} = Channel.open(connection)
    Queue.declare(channel, @queue_name)
    Queue.declare(channel, @failed_queue)
    Connection.close(connection)

    Broadway.start_link(__MODULE__,
      name: TransactionService.TransactionBatchClosedConsumer,
      producer: [module: producer_module, concurrency: 100],
      processors: [default: [concurrency: 500]],
      batchers: [default: [batch_size: 5_000]]
    )
  end

  @doc """
  For handling CPU bound tasks
  """
  @impl true
  def handle_message(_processor, %Message{data: transaction_batch_closed_json} = message, _context) do
    Logger.debug("Handling message #{inspect(transaction_batch_closed_json)}")

    changeset =
      transaction_batch_closed_json
      |> Jason.decode!()
      |> transform_message()
      |> Transaction.insert_changeset()

    if changeset.valid? do
      now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

      transaction_map = Map.merge(%{inserted_at: now, updated_at: now}, changeset.changes)

      Message.put_data(message, transaction_map)
    else
      Message.failed(message, "Invalid changeset")
    end
  end

  @impl true
  def handle_batch(batcher, messages, batch_info, _context) do
    Logger.debug("Batching messages #{inspect(messages)}")
    Logger.debug("Batcher: #{inspect(batcher)}")
    Logger.debug("Batch Info: #{inspect(batch_info)}")

    {:ok, _transactions} =
      messages
      |> Enum.map(& &1.data)
      |> Transactions.bulk_insert()

    messages
  end

  @impl true
  def handle_failed(messages, _context) do
    Logger.error("Failed: #{inspect(messages)}")
    {:ok, connection} = Connection.open()
    {:ok, channel} = Channel.open(connection)
    Enum.each(messages, &Basic.publish(channel, "", @failed_queue, &1.data))
    Connection.close(connection)
    messages
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
