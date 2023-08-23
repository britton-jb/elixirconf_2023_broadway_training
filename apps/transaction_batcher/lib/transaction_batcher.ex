defmodule TransactionBatcher do
  @queue_name "transaction_batch_closed"

  def read_csv do
    # Implement TransactionBatcher.read_csv/0
    #   Establish a connection to RabbitMQ
    #   Open up, and iterate over, the transactions.csv in the project root
    #   Convert each row to a JSON object
    #   Publish each row, one by one, to a queue called “transaction_batch_closed”
    #   https://hexdocs.pm/amqp/readme.html
  end
end
