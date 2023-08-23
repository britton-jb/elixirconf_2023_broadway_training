defmodule TransactionService.Shipper do
  @success_rate 0.9

  def ship(_transaction) do
    if @success_rate > :rand.uniform() do
      {:ok, :shipped}
    else
      {:error, :not_shipped}
    end
  end
end
