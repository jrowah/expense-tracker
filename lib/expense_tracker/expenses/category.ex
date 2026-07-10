defmodule ExpenseTracker.Expenses.Category do
  use Ecto.Schema
  import Ecto.Changeset

  alias ExpenseTracker.Expenses.ChangesetHelpers

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "categories" do
    field :name, :string
    field :description, :string
    field :monthly_budget, :decimal

    has_many :expenses, ExpenseTracker.Expenses.Expense

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description, :monthly_budget])
    |> validate_required([:name, :description, :monthly_budget])
    |> unique_constraint(:name)
    |> validate_budget()
    |> validate_length(:name, min: 1, max: 100)
    |> validate_length(:description, max: 500)
  end

  # Validate budget amount with precision
  defp validate_budget(changeset) do
    changeset
    |> validate_number(:monthly_budget, greater_than: 0, message: "must be greater than 0")
    |> ChangesetHelpers.validate_decimal_precision(:monthly_budget)
    |> ChangesetHelpers.validate_reasonable_amount(:monthly_budget)
  end
end
