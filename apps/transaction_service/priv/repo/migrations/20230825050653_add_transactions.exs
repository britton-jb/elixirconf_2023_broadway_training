defmodule TransactionService.Repo.Migrations.AddTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :item, :string
      add :brand, :string
      add :amount, :integer
      add :department, :string
      add :category, :string
      add :sku, :string

      timestamps()
    end
  end
end
