defmodule ExpenseTracker.Expenses.Category do
  use Ecto.Schema
  import Ecto.Changeset

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
    |> validate_decimal_precision(:monthly_budget)
    |> validate_reasonable_budget(:monthly_budget)
  end

  # Ensure decimal precision doesn't exceed 2 decimal places for currency
  defp validate_decimal_precision(changeset, field) do
    validate_change(changeset, field, fn field, value ->
      case Decimal.to_string(value) do
        string_value ->
          case String.split(string_value, ".") do
            [_integer_part] ->
              # No decimal places is valid
              []

            [_integer_part, decimal_part] when byte_size(decimal_part) <= 2 ->
              # 2 or fewer decimal places is valid
              []

            [_integer_part, _decimal_part] ->
              [{field, "cannot have more than 2 decimal places"}]

            _ ->
              [{field, "invalid decimal format"}]
          end
      end
    end)
  end

  # Validate reasonable budget limits
  defp validate_reasonable_budget(changeset, field) do
    validate_change(changeset, field, fn field, value ->
      # Reasonable monthly budget limit
      max_budget = Decimal.new("999999.99")

      case Decimal.compare(value, max_budget) do
        :gt -> [{field, "monthly budget cannot exceed $999,999.99"}]
        _ -> []
      end
    end)
  end
end
