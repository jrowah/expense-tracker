defmodule ExpenseTrackerWeb.ExpenseLive.Index do
  use ExpenseTrackerWeb, :live_view

  alias ExpenseTracker.Expenses
  alias ExpenseTracker.Expenses.Expense

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :expenses, Expenses.list_expenses())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Expense")
    |> assign(:expense, Expenses.get_expense!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Expense")
    |> assign(:expense, %Expense{})
  end

  defp apply_action(socket, :new_for_category, %{"category_id" => category_id}) do
    category = Expenses.get_category!(category_id)

    socket
    |> assign(:page_title, "New Expense for #{category.name}")
    |> assign(:expense, %Expense{category_id: category_id})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Expenses")
    |> assign(:expense, nil)
  end

  @impl true
  def handle_info({ExpenseTrackerWeb.ExpenseLive.FormComponent, {:saved, expense}}, socket) do
    {:noreply, stream_insert(socket, :expenses, expense)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    expense = Expenses.get_expense!(id)
    {:ok, _} = Expenses.delete_expense(expense)

    {:noreply, stream_delete(socket, :expenses, expense)}
  end
end
