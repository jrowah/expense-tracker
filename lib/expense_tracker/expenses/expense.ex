defmodule ExpenseTracker.Expenses.Expense do
  use Ecto.Schema
  import Ecto.Changeset

  alias ExpenseTracker.Expenses.{Category, Receipt}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "expenses" do
    field :date, :date
    field :description, :string
    field :amount, :decimal
    field :notes, :string

    belongs_to :category, Category
    has_one :receipt, Receipt

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
    |> validate_date()
    |> foreign_key_constraint(:category_id, message: "Category must exist")
  end

  # Comprehensive amount validation for financial precision
  defp validate_amount(changeset) do
    changeset
    |> validate_number(:amount, greater_than: 0, message: "must be greater than 0")
    |> validate_decimal_precision(:amount)
    |> validate_reasonable_amount(:amount)
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

  # Validate reasonable amount limits (prevent extremely large amounts)
  defp validate_reasonable_amount(changeset, field) do
    validate_change(changeset, field, fn field, value ->
      # 8 digits + 2 decimal places
      max_amount = Decimal.new("99999999.99")

      case Decimal.compare(value, max_amount) do
        :gt -> [{field, "cannot exceed $99,999,999.99"}]
        _ -> []
      end
    end)
  end

  # Validate date constraints
  defp validate_date(changeset) do
    changeset
    |> validate_change(:date, fn :date, date ->
      # Allow up to 1 year in future
      future_limit = Date.add(Date.utc_today(), 365)
      # Allow up to 10 years in past
      past_limit = Date.add(Date.utc_today(), -3650)

      cond do
        Date.compare(date, future_limit) == :gt ->
          [{:date, "cannot be more than 1 year in the future"}]

        Date.compare(date, past_limit) == :lt ->
          [{:date, "cannot be more than 10 years in the past"}]

        true ->
          []
      end
    end)
  end
end
