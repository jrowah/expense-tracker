defmodule ExpenseTracker.ExpensesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `ExpenseTracker.Expenses` context.
  """

  @doc """
  Generate a category.
  """
  def category_fixture(attrs \\ %{}) do
    {:ok, category} =
      attrs
      |> Enum.into(%{
        description: "some description",
        monthly_budget: "120.5",
        name: "some name"
      })
      |> ExpenseTracker.Expenses.create_category()

    category
  end

  @doc """
  Generate a expense.
  """
  def expense_fixture(attrs \\ %{}) do
    # Create a category first if none provided
    category =
      case Map.get(attrs, :category_id) do
        nil -> category_fixture()
        _id -> nil
      end

    category_id = (category && category.id) || Map.get(attrs, :category_id)

    {:ok, expense} =
      attrs
      |> Enum.into(%{
        amount: "120.5",
        date: ~D[2025-08-01],
        description: "some description",
        notes: "some notes",
        category_id: category_id
      })
      |> ExpenseTracker.Expenses.create_expense()

    expense
  end
end
