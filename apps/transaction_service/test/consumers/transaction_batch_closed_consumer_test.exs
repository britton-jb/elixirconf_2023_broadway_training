defmodule TransactionService.TransactionBatchClosedConsumerTest do
  use TransactionService.DataCase, async: true
  @moduletag capture_log: true

  alias TransactionService.{Repo, Transaction, TransactionBatchClosedConsumer}

  setup do
    message = Jason.encode!(%{
      "brand" => "Bolthouse Farms",
      "breadcrumbs" => "Beverages/Orange Juice & Chilled",
      "category" => "Orange Juice & Chilled",
      "department" => "Beverages",
      "index" => "15646",
      "price_current" => "2.18",
      "price_retail" => "2.18",
      "product_name" => "Bolthouse Farms Perfectly Protein Mocha Cappuccino Coffee Drink, 11 oz",
      "product_size" => "11",
      "product_url" => "https://www.walmart.com/ip/Bolthouse-Farms-Perfectly-Protein-Mocha-Cappuccino-Coffee-Drink-11-oz/49065950?fulfillmentIntent=Pickup",
      "promotion" => "",
      "run_date" => "2022-09-11 21:20:04",
      "shipping_location" => "89108",
      "sku" => "49065950",
      "subcategory" => "",
      "tid" => "16179450"
    })
    bad_message = Jason.encode!(%{
      "brand" => "Bolthouse Farms",
      "breadcrumbs" => "Beverages/Orange Juice & Chilled",
      "category" => "Orange Juice & Chilled",
      "department" => "Beverages",
      "index" => "15646",
      "price_current" => "2.18",
      "price_retail" => "2.18",
      "product_name" => "Bolthouse Farms Perfectly Protein Mocha Cappuccino Coffee Drink, 11 oz",
      "product_size" => "11",
      "product_url" => "https://www.walmart.com/ip/Bolthouse-Farms-Perfectly-Protein-Mocha-Cappuccino-Coffee-Drink-11-oz/49065950?fulfillmentIntent=Pickup",
      "promotion" => "",
      "run_date" => "2022-09-11 21:20:04",
      "shipping_location" => "89108",
      "subcategory" => "",
      "tid" => "16179450"
    })
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
