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

  def update_all(transaction_maps) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)

    transaction_maps =
      Enum.map(transaction_maps, fn transaction_map ->
        Map.put(transaction_map, :updated_at, now)
      end)

    {_rows, transactions} =
      Repo.insert_all(Transaction, transaction_maps,
        returning: true,
        on_conflict: :replace_all,
        conflict_target: [:id]
      )

    {:ok, transactions}
  end
end
