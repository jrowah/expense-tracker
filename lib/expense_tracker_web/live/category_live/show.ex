defmodule ExpenseTrackerWeb.CategoryLive.Show do
  use ExpenseTrackerWeb, :live_view

  alias ExpenseTracker.Expenses

  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to expense updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ExpenseTracker.PubSub, "expense_updates")
    end

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:category, Expenses.get_category!(id))}
  end

  @impl true
  def handle_info({:expense_created, expense}, socket) do
    # Only update if the expense belongs to this category
    if expense.category_id == socket.assigns.category.id do
      updated_category = Expenses.get_category!(socket.assigns.category.id)
      {:noreply, assign(socket, category: updated_category)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:expense_updated, expense}, socket) do
    # Update if the expense belongs to this category
    if expense.category_id == socket.assigns.category.id do
      updated_category = Expenses.get_category!(socket.assigns.category.id)
      {:noreply, assign(socket, category: updated_category)}
    else
      {:noreply, socket}
    end
  end

  defp page_title(:show), do: "Show Category"
  defp page_title(:edit), do: "Edit Category"
end
