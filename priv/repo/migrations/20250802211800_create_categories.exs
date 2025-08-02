defmodule ExpenseTracker.Repo.Migrations.CreateCategories do
  use Ecto.Migration

  def change do
    create table(:categories) do
      add :name, :string
      add :description, :text
      add :monthly_budget, :decimal, precision: 10, scale: 2, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:categories, [:name])
  end
end
