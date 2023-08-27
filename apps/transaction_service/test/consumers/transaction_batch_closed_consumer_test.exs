defmodule TransactionService.TransactionBatchClosedConsumerTest do
  use TransactionService.DataCase, async: true
  @moduletag capture_log: true

  alias TransactionService.{Repo, Transaction, TransactionBatchClosedConsumer}

  setup do
    message = Jason.encode!(%{item: "bananas", brand: "banana brand", amount: "123", department: "produce", category: "fruit", sku: "12345"})
    bad_message = Jason.encode!(%{item: "bananas", amount: 123, department: "produce", category: "fruit", sku: "12345"})
    {:ok, message: message, bad_message: bad_message}
  end

  test "inserts transaction", %{message: message} do
    assert Repo.aggregate(Transaction, :count) == 0

    ref =
      Broadway.test_message(TransactionBatchClosedConsumer, message, metadata: %{ecto_sandbox: self()})

    assert_receive {:ack, ^ref, [%{data: _out_data}], []}, 1000

    assert Repo.aggregate(Transaction, :count) == 1
  end

  test "batches messages, inserting multiple transactions", %{message: message} do
    assert Repo.aggregate(Transaction, :count) == 0

    ref =
      Broadway.test_batch(TransactionBatchClosedConsumer, [message, message],
        metadata: %{ecto_sandbox: self()}
      )

    assert_receive {:ack, ^ref, [_msg1, _msg2], []}, 2000
    assert Repo.aggregate(Transaction, :count) == 2
  end

  test "sends failed messages to the failed batcher", %{bad_message: message} do
    assert Repo.aggregate(Transaction, :count) == 0

    ref =
      Broadway.test_message(TransactionBatchClosedConsumer, message, metadata: %{ecto_sandbox: self()})

    assert_receive {:ack, ^ref, [], [%{data: _out_data, status: {:failed, "Invalid changeset"}}]},
                   1000

    assert Repo.aggregate(Transaction, :count) == 0
  end
end
