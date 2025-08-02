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
    {:ok, expense} =
      attrs
      |> Enum.into(%{
        amount: "120.5",
        date: ~D[2025-08-01],
        description: "some description",
        notes: "some notes"
      })
      |> ExpenseTracker.Expenses.create_expense()

    expense
  end
end
