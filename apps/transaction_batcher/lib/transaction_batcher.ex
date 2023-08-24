defmodule TransactionBatcher do
  alias AMQP.{Basic, Channel, Connection, Queue}

  require Logger

  @queue_name "transaction_batch_closed"

  def read_csv do
    {:ok, connection} = Connection.open()
    {:ok, channel} = Channel.open(connection)
    Queue.declare(channel, @queue_name)

    "../../../transactions.csv"
    |> Path.expand(__DIR__)
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> Enum.each(fn
      {:ok, transaction_row} ->
        Basic.publish(channel, "", @queue_name, Jason.encode!(transaction_row))

      error ->
        Logger.error("Error while trying to read csv row: #{inspect(error)}")
    end)

    AMQP.Connection.close(connection)
  end
end
