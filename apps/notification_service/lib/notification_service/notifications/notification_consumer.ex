defmodule NotificationService.Notifications.NotificationConsumer do
  use Broadway

  alias NotificationService.Notifications.Publisher

  @retry_queue "retry_notifications"

  def start_link(_opts) do
    producer_module = Application.fetch_env!(:notification_service, :producer_module)

    Publisher.declare_queue(@retry_queue)

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: producer_module
      ],
      processors: [default: [concurrency: 2]]
    )
  end

  def handle_message(_processor, message, _context) do
    message
  end
end
