defmodule TransactionService.TransactionShippingConsumer do
  use Broadway

  require Logger

  alias AMQP.{Channel, Connection, Queue}

  alias Broadway.Message
  alias TransactionService.{Transactions, Transaction, Shipper}
  alias Ecto.Changeset

  def queue_name, do: "transaction_saved"

  def start_link(_opts) do
    Logger.info("STARTING SHIPPING CONSUMER")
    producer_module = Application.fetch_env!(:transaction_service, :shipping_producer_module)

    {:ok, connection} = Connection.open()
    {:ok, channel} = Channel.open(connection)
    Queue.declare(channel, queue_name())
    Connection.close(connection)

    Broadway.start_link(__MODULE__,
      name: TransactionService.TransactionShippingConsumer,
      producer: [module: producer_module],
      processors: [default: [concurrency: 2, min_demand: 5, max_demand: 20]],
      batchers: [shipped: [batch_size: 100]]
    )
  end

  @impl true
  def prepare_messages(messages, _context) do
    transactions_by_id =
      messages
      |> Enum.map(& &1.data)
      |> Transactions.get_all()
      |> Map.new(fn transaction -> {"#{transaction.id}", transaction} end)

    Enum.map(messages, fn message ->
      case Message.put_data(message, transactions_by_id[message.data]) do
        %Message{data: nil} ->
          message
          |> Message.configure_ack(on_failure: :reject)
          |> Message.failed("Could not find associated transaction")

        message -> message
      end
    end)
  end

  @impl true
  def handle_message(_processor, %Message{status: {:failed, _}} = message, _context), do: message

  @impl true
  def handle_message(_processor, %Message{data: transaction} = message, _context) do
    case Shipper.ship(transaction) do
      {:ok, :shipped} ->
        case Transaction.update_changeset(transaction, %{shipped_at: NaiveDateTime.utc_now()}) do
          %Changeset{valid?: false} = changeset ->
            message
            |> Message.configure_ack(on_failure: :reject)
            |> Message.failed("Invalid changeset after shipping #{inspect(changeset.errors)}")

          changeset ->
            changeset
            |> extract_update_map_from_changeset()
            |> then(&Message.put_data(message, &1))
            |> Message.put_batcher(:shipped)
        end

      {:error, :not_shipped} ->
        Message.failed(message, "Shipping failed, retrying")
    end
  end

  @impl true
  def handle_batch(:shipped, messages, _batch_info, _context) do
    {:ok, _transactions} =
      messages
      |> Enum.map(fn %Message{data: changes_map} -> changes_map end)
      |> Transactions.update_all()

    messages
  end

  @impl true
  def handle_failed(messages, _context) do
    Logger.warn("Failed to ship transactions: #{inspect(messages)}")
    messages
  end

  defp extract_update_map_from_changeset(changeset) do
    changeset
    |> Changeset.apply_changes()
    |> Map.from_struct()
    |> Map.drop([:__meta__])
  end
end
