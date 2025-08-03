defmodule ExpenseTrackerWeb.HomeLive.Index do
  use ExpenseTrackerWeb, :live_view

  alias ExpenseTracker.Expenses

  @impl true
  def mount(_params, _session, socket) do
    categories = Expenses.list_categories()
    {:ok, assign(socket, categories: categories)}
  end
end
