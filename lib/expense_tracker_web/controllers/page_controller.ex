defmodule ExpenseTrackerWeb.PageController do
  use ExpenseTrackerWeb, :controller
  alias ExpenseTracker.Expenses

  def home(conn, _params) do
    categories = Expenses.list_categories()
    render(conn, :home, categories: categories)
  end
end
