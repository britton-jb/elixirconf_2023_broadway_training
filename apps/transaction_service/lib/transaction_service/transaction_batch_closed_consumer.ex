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

    Broadway.start_link(__MODULE__,
      name: TransactionService.TransactionBatchClosedConsumer,
      producer: [module: producer_module],
      processors: [default: [concurrency: 2]],
      batchers: [default: [batch_size: 10]]
    )
  end

  @doc """
  For handling CPU bound tasks
  """
  @impl true
  def handle_message(_processor, %Message{data: transaction_batch_closed_json} = message, _context) do
    Logger.debug("Handling message #{inspect(transaction_batch_closed_json)}")

    decoded_transaction_batch = Jason.decode!(transaction_batch_closed_json)
    changeset = Transaction.insert_changeset(decoded_transaction_batch)

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
    Enum.each(messages, &Basic.publish(channel, "", @failed_queue, &1))
    messages
  end
end
