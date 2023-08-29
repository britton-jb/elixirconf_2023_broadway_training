defmodule NotificationService.Notifications.NotificationConsumer do
  use Broadway

  alias Broadway.Message
  alias NotificationService.Notifications
  alias NotificationService.Notifications.Publisher

  require Logger

  @retry_queue "retry_notifications"

  def start_link(_opts) do
    producer_module = Application.fetch_env!(:notification_service, :producer_module)

    Publisher.declare_queue(@retry_queue)

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: producer_module,
        concurrency: 1,
        rate_limiting: [allowed_messages: 5, interval: 5000]
      ],
      processors: [default: [concurrency: 2]],
      batchers: [default: [batch_size: 100]]
    )
  end

  @impl true
  def prepare_messages(messages, _context) do
    messages
  end

  @impl true
  def handle_message(_processor, %Message{data: message_data} = message, _context) do
    %{
      "payload" => %{
        "after" =>
          %{
            "item" => item,
          } = transaction_map
      }
    } = decoded = Jason.decode!(message_data)

    transaction_map = Map.put(transaction_map, :type, :transaction)

    Message.update_data(message, fn _data ->
      decoded
      |> Map.put(:item, item)
      |> Map.put(:transaction_map, transaction_map)
    end)
  end

  @impl true
  def handle_batch(:default, messages, _batch_info, _context) do
    Logger.info("Batching messages #{inspect(messages)}")

    messages
    |> Enum.map(& Map.take(&1.data.transaction_map, [:type]))
    |> Notifications.insert_all()

    # For guaranteed only once delivery, Oban may be a better approach, depending on scale
    Enum.map(messages, fn message ->
      {message.data.transaction_map["id"], message.data.item}
      |> Notifications.send_notification()
      |> case do
        :ok -> message
        {:error, _reason} -> Broadway.Message.failed(message, "Failed to send notification")
      end
    end)
  end
end
