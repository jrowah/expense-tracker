# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ExpenseTracker.Repo.insert!(%ExpenseTracker.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias ExpenseTracker.Expenses
alias ExpenseTracker.Repo

# Clear existing data
Repo.delete_all(ExpenseTracker.Expenses.Expense)
Repo.delete_all(ExpenseTracker.Expenses.Category)

# Create sample categories
{:ok, food_category} =
  Expenses.create_category(%{
    name: "Food & Dining",
    description: "Groceries, restaurants, and food delivery",
    monthly_budget: Decimal.new("500.00")
  })

{:ok, transport_category} =
  Expenses.create_category(%{
    name: "Transportation",
    description: "Gas, public transport, ride shares",
    monthly_budget: Decimal.new("200.00")
  })

{:ok, entertainment_category} =
  Expenses.create_category(%{
    name: "Entertainment",
    description: "Movies, games, subscriptions",
    monthly_budget: Decimal.new("150.00")
  })

# Create sample expenses
Expenses.create_expense(%{
  description: "Grocery shopping",
  amount: Decimal.new("85.50"),
  date: Date.utc_today(),
  notes: "Weekly groceries",
  category_id: food_category.id
})

Expenses.create_expense(%{
  description: "Gas station",
  amount: Decimal.new("45.00"),
  date: Date.add(Date.utc_today(), -1),
  category_id: transport_category.id
})

Expenses.create_expense(%{
  description: "Netflix subscription",
  amount: Decimal.new("15.99"),
  date: Date.add(Date.utc_today(), -2),
  category_id: entertainment_category.id
})
