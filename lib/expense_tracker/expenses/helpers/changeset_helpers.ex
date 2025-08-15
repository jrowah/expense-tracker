defmodule ExpenseTracker.Expenses.ChangesetHelpers do
  @moduledoc """
  Helper functions for working with expenses and categories.
  """
  import Ecto.Changeset

  # Ensure decimal precision doesn't exceed 2 decimal places for currency
  def validate_decimal_precision(changeset, field) do
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
  def validate_reasonable_amount(changeset, field) do
    validate_change(changeset, field, fn field, value ->
      # Reasonable monthly budget limit
      max_budget = Decimal.new("999999.99")

      case Decimal.compare(value, max_budget) do
        :gt -> [{field, "monthly budget cannot exceed $999,999.99"}]
        _ -> []
      end
    end)
  end

  # Validate date constraints
  def validate_date(changeset) do
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
