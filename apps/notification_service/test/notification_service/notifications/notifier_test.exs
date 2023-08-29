defmodule NotificationService.Notifications.NotifierTest do
  use ExUnit.Case, async: true
  import Swoosh.TestAssertions

  alias NotificationService.Notifications.Notifier

  test "deliver_transaction_created/1" do
    user = %{name: "Alice", email: "alice@example.com"}

    Notifier.deliver_transaction_created(user)

    assert_email_sent(
      subject: "Welcome to Phoenix, Alice!",
      to: {"Alice", "alice@example.com"},
      text_body: ~r/Hello, Alice/
    )
  end

  test "deliver_transaction_shipped/1" do
    user = %{name: "Alice", email: "alice@example.com"}

    Notifier.deliver_transaction_shipped(user)

    assert_email_sent(
      subject: "Welcome to Phoenix, Alice!",
      to: {"Alice", "alice@example.com"},
      text_body: ~r/Hello, Alice/
    )
  end
end
