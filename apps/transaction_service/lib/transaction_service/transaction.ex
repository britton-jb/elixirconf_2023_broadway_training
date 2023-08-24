defmodule TransactionService.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    field(:item, :string)
    field(:brand, :string)
    field(:amount, :integer)
    field(:department, :string)
    field(:category, :string)
    field(:sku, :string)

    timestamps()
  end

  def insert_changeset(params \\ %{}) do
    %__MODULE__{}
    |> cast(params, [:item, :brand, :amount, :department, :category, :sku])
    |> validate_required([:item, :brand, :amount, :sku])
  end
end
