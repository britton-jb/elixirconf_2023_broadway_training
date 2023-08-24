defmodule TransactionService.Transactions do
  alias TransactionService.{Repo, Transaction}

  import Ecto.Query, only: [from: 2]

  def insert(params \\ %{}) do
    params
    |> Transaction.insert_changeset()
    |> Repo.insert()
  end

  def get(id) do
    Repo.get(Transaction, id)
  end

  def get_all(ids) do
    Repo.all(from(t in Transaction, where: t.id in ^ids))
  end

  def all() do
    Repo.all(Transaction)
  end

  def bulk_insert(transaction_maps) do
    {_rows, transactions} = Repo.insert_all(Transaction, transaction_maps, returning: true)
    {:ok, transactions}
  end
end
