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
end
