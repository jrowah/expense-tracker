defmodule ExpenseTrackerWeb.ExpenseLive.Index do
  use ExpenseTrackerWeb, :live_view

  alias ExpenseTracker.Expenses
  alias ExpenseTracker.Expenses.Expense

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:expenses, Expenses.list_expenses())
     |> assign(:show_upload_modal, false)}
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
    |> assign(:show_upload_modal, false)
  end

  defp apply_action(socket, :upload_receipt, _params) do
    socket
    |> assign(:page_title, "Upload Receipt")
    |> assign(:expense, nil)
    |> assign(:show_upload_modal, true)
  end

  @impl true
  def handle_info({ExpenseTrackerWeb.ExpenseLive.FormComponent, {:saved, expense}}, socket) do
    # Reload the expense with category preloaded
    expense_with_category = Expenses.get_expense!(expense.id)
    {:noreply, stream_insert(socket, :expenses, expense_with_category)}
  end

  def handle_info({ExpenseTrackerWeb.ExpenseLive.FormComponent, :upload_receipt}, socket) do
    {:noreply, assign(socket, show_upload_modal: true)}
  end

  def handle_info({ExpenseTrackerWeb.ExpenseLive.ReceiptUploadComponent, :cancel}, socket) do
    {:noreply, assign(socket, show_upload_modal: false)}
  end

  def handle_info(
        {ExpenseTrackerWeb.ExpenseLive.ReceiptUploadComponent, {:receipt_uploaded, _receipt}},
        socket
      ) do
    {:noreply, assign(socket, show_upload_modal: false)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    expense = Expenses.get_expense!(id)
    {:ok, _} = Expenses.delete_expense(expense)

    {:noreply, stream_delete(socket, :expenses, expense)}
  end

  def handle_event("show_upload_modal", _params, socket) do
    {:noreply, assign(socket, show_upload_modal: true)}
  end

  def handle_event("hide_upload_modal", _params, socket) do
    {:noreply, assign(socket, show_upload_modal: false)}
  end
end
