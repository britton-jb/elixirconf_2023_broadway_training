defmodule TransactionService.Transaction do
  use Ecto.Schema

  import Ecto.Changeset

  @required_params [:item, :brand, :amount, :sku]

  schema "transactions" do
    field(:item, :string)
    field(:brand, :string)
    field(:amount, :integer)
    field(:department, :string)
    field(:category, :string)
    field(:sku, :string)
    field(:shipped_at, :naive_datetime)

    timestamps()
  end

  def insert_changeset(params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:item, :brand, :amount, :department, :category, :sku])
    |> validate_required(@required_params)
  end

  def update_changeset(%__MODULE__{} = transaction, params \\ %{}) do
    transaction
    |> cast(params, [:shipped_at])
    |> validate_required(@required_params)
  end
end
