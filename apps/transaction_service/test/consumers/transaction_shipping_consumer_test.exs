defmodule TransactionService.TransactionShippingConsumerTest do
  use TransactionService.DataCase, async: false
  use Mimic

  alias Broadway.Message
  alias Ecto.Changeset
  alias TransactionService.{Shipper, Repo, Transaction, Transactions, TransactionShippingConsumer}

  @moduletag capture_log: true

  setup :set_mimic_global
  setup :verify_on_exit!

  setup do
    now = NaiveDateTime.utc_now()
    {:ok, transaction} = Transactions.insert(%{item: "bananas", brand: "Dole", amount: 123, department: "produce", category: "fruit", sku: "12345", inserted_at: now, updated_at: now})
    bad_message = "123456"
    good_message = "#{transaction.id}"

    {:ok, transaction: transaction, good_message: good_message, bad_message: bad_message}
  end

  test "fails the message if the transaction is not found", %{bad_message: bad_message} do
    assert Repo.aggregate(Transaction, :count) == 1

    ref =
      Broadway.test_message(TransactionShippingConsumer, bad_message, metadata: %{ecto_sandbox: self()})

    assert_receive {:ack, ^ref, [] = _successful_messages,
                    [%Message{batcher: :default}] = _failed_messages},
                   1000

    assert Repo.aggregate(Transaction, :count) == 1
  end

  test "marks the transaction as shipped when shipping is successful", %{
    good_message: good_message,
    transaction: transaction
  } do
    assert Repo.aggregate(Transaction, :count) == 1
    expect(Shipper, :ship, fn _transaction -> {:ok, :shipped} end)

    ref =
      Broadway.test_message(
        TransactionShippingConsumer,
        good_message,
        metadata: %{ecto_sandbox: self()}
      )

    assert_receive {:ack, ^ref, [%Message{batcher: :shipped}], [] = _failed_messages},
                   1000

    updated_transaction = Transactions.get(transaction.id)
    refute is_nil(updated_transaction.shipped_at)
    assert Repo.aggregate(Transaction, :count) == 1
  end

  test "should retry the message when not shipped", %{
    transaction: transaction,
    good_message: good_message
  } do
    expect(Shipper, :ship, fn _transaction -> {:error, :not_shipped} end)

    ref =
      Broadway.test_message(
        TransactionShippingConsumer,
        good_message,
        metadata: %{ecto_sandbox: self()}
      )

    assert_receive {:ack, ^ref, [] = _success_messages, [%Message{status: {:failed, "Shipping failed, retrying"}}]}, 1000
    updated_transaction = Transactions.get(transaction.id)
    assert is_nil(updated_transaction.shipped_at)
  end

  test "should fail the message when the Changeset is invalid",
       %{transaction: transaction, good_message: good_message} do
    expect(Transaction, :update_changeset, fn _transactions, _params -> %Changeset{valid?: false} end)

    ref =
      Broadway.test_message(
        TransactionShippingConsumer,
        good_message,
        metadata: %{ecto_sandbox: self()}
      )

    assert_receive {:ack, ^ref, [] = _success_messages, [%Message{status: {:failed, "Invalid changeset after shipping []"}}]}, 1000
    updated_transaction = Transactions.get(transaction.id)
    assert is_nil(updated_transaction.shipped_at)
  end
end
