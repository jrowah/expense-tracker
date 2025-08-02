defmodule ExpenseTracker.Repo.Migrations.CreateExpenses do
  use Ecto.Migration

  def change do
    create table(:expenses, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :description, :string
      add :amount, :decimal
      add :date, :date
      add :notes, :text
      add :category_id, references(:categories, type: :binary_id, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:expenses, [:category_id])
  end
end
