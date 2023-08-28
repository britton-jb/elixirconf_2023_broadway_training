defmodule NotificationService.Notifications.NotificationConsumer do
  use Broadway

  require Logger

  alias Broadway.Message
  alias NotificationService.Notifications

  @retry_queue "retry_notifications"

  def start_link(_opts) do
    producer_module = Application.fetch_env!(:notification_service, :producer_module)

    Notifications.Publisher.declare_queue(@retry_queue)

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: producer_module,
        concurrency: 1,
        rate_limiting: [allowed_messages: 5, interval: 5000]
      ],
      processors: [default: [concurrency: 2]],
      batchers: [default: [batch_size: 1000], duplicate: [batch_size: 100]]
    )
  end

  @impl true
  def prepare_messages(messages, _context) do
    messages =
      Enum.map(messages, fn %Message{metadata: %{key: key_json, ts: ts}} = message ->
        %{"payload" => %{"id" => transaction_id}} = Jason.decode!(key_json)

        Message.update_data(message, fn data_json ->
          %{idempotency_key: "#{ts}-#{transaction_id}", payload: data_json}
        end)
      end)

    notifications =
      messages
      |> Enum.map(& &1.data.idempotency_key)
      |> Notifications.by_idempotency_key()

    Enum.map(messages, fn message ->
      Message.update_data(message, fn %{idempotency_key: idempotency_key} = data ->
        notification = Enum.find(notifications, &(&1.idempotency_key == idempotency_key))
        Map.put(data, :notification, notification)
      end)
    end)
  end

  @impl true
  def handle_message(_processor, %Message{data: message_data} = message, _context) do
    case message_data.notification do
      nil ->
        %{
          "payload" => %{
            "after" =>
              %{
                "item" => item,
              } = transaction_map
          }
        } = Jason.decode!(message_data.payload)

        transaction_map =
          transaction_map
          |> Map.put(:type, :transaction)
          |> Map.put(:idempotency_key, message_data.idempotency_key)

        Message.update_data(message, fn data ->
          data
          |> Map.put(:item, item)
          |> Map.put(:transaction_map, transaction_map)
        end)

      _already_sent_notification ->
        Message.put_batcher(message, :duplicate)
    end
  end

  @impl true
  def handle_batch(:default, messages, _batch_info, _context) do
    Logger.info("Batching messages #{inspect(messages)}")

    messages
    |> Enum.map(& Map.take(&1.data.transaction_map, [:type, :idempotency_key]))
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

  def handle_batch(:duplicate, messages, _batch_info, _context) do
    Logger.info("Handling #{inspect(length(messages))} duplicate messages")
    messages
  end

  @impl true
  def handle_failed(messages, _context) do
    Enum.each(messages, fn message ->
      Logger.error("Error while handling notification: #{inspect(message.status)}")
    end)
    messages
    |> Enum.map(& &1.data.idempotency_key)
    |> Notifications.delete_all_by_idempotency_key()

    Enum.each(messages, fn message ->
      Notifications.Publisher.publish(@retry_queue, message)
    end)

    messages
  end
end
