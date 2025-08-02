defmodule ExpenseTracker.Expenses.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  alias ExpenseTracker.Expenses.Category

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
    |> validate_number(:amount, greater_than: 0)
    |> validate_length(:description, max: 255)
    |> foreign_key_constraint(:category_id, message: "Category must exist")
  end
end
