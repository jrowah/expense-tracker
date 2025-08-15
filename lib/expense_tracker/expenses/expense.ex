defmodule ExpenseTracker.Expenses.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  alias ExpenseTracker.Expenses.Category
  alias ExpenseTracker.Expenses.ChangesetHelpers

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "expenses" do
    field :date, :date
    field :description, :string
    field :amount, :decimal
    field :notes, :string

    belongs_to :category, Category

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(expense, attrs) do
    expense
    |> cast(attrs, [:description, :amount, :date, :notes, :category_id])
    |> validate_required([:description, :amount, :date, :notes, :category_id])
    |> validate_amount()
    |> validate_length(:description, max: 255)
    |> validate_length(:notes, max: 1000)
    |> ChangesetHelpers.validate_date()
    |> foreign_key_constraint(:category_id, message: "Category must exist")
  end

  # Comprehensive amount validation for financial precision
  defp validate_amount(changeset) do
    changeset
    |> validate_number(:amount, greater_than: 0, message: "must be greater than 0")
    |> ChangesetHelpers.validate_decimal_precision(:amount)
    |> ChangesetHelpers.validate_reasonable_amount(:amount)
  end
end
