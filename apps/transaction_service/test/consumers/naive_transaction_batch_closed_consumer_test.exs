defmodule TransactionService.NaiveTransactionBatchClosedConsumerTest do
  use TransactionService.DataCase, async: true

  @moduletag capture_log: true

  alias TransactionService.{Repo, Transaction, NaiveTransactionBatchClosedConsumer}

  setup do
    start_supervised!(NaiveTransactionBatchClosedConsumer)
    message = Jason.encode!(%{item: "bananas", brand: "banana brand", amount: 123, department: "produce", category: "fruit", sku: "12345"})
    {:ok, %{message: message}}
  end

  test "inserts transaction", %{message: message} do
    assert Repo.aggregate(Transaction, :count) == 0

    ref =
      Broadway.test_message(NaiveTransactionBatchClosedConsumer, message,
        metadata: %{ecto_sandbox: self()}
      )

    assert_receive {:ack, ^ref, [%{data: ^message}], []}, 1000

    assert Repo.aggregate(Transaction, :count) == 1
  end
end
