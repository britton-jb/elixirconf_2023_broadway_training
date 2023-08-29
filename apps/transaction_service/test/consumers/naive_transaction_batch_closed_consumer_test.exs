defmodule TransactionService.NaiveTransactionBatchClosedConsumerTest do
  use TransactionService.DataCase, async: true

  @moduletag capture_log: true

  alias TransactionService.{Repo, Transaction, NaiveTransactionBatchClosedConsumer}

  setup do
    start_supervised(NaiveTransactionBatchClosedConsumer)
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
