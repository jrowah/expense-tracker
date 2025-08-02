defmodule ExpenseTracker.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string
      add :description, :text
      add :monthly_budget, :decimal

      timestamps(type: :utc_datetime)
    end
  end
end
