defmodule ExpenseTrackerWeb.HomeLive.Index do
  use ExpenseTrackerWeb, :live_view

  alias ExpenseTracker.Expenses
  import ExpenseTrackerWeb.CommonComponents.CategoriesCard

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ExpenseTracker.PubSub, "expense_updates")
    end

    {:ok, assign(socket, categories: Expenses.list_categories())}
  end

  @impl true
  def handle_info({:expense_created, _expense}, socket) do
    updated_categories = Expenses.list_categories()
    {:noreply, assign(socket, categories: updated_categories)}
  end

  @impl true
  def handle_info({:expense_updated, _expense}, socket) do
    updated_categories = Expenses.list_categories()
    {:noreply, assign(socket, categories: updated_categories)}
  end
end
