defmodule ExpenseTrackerWeb.ExpenseLive.FormComponent do
  use ExpenseTrackerWeb, :live_component

  alias ExpenseTracker.Expenses

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage expense records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="expense-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:description]} type="text" label="Description" />
        <.input
          field={@form[:category_id]}
          type="select"
          label="Category"
          options={Enum.map(@categories, &{&1.name, &1.id})}
          prompt="Select a category"
        />
        <.input field={@form[:amount]} type="number" label="Amount" step="any" />
        <.input field={@form[:date]} type="date" label="Date" />
        <.input field={@form[:notes]} type="text" label="Notes" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Expense</.button>
          <.button
            type="button"
            phx-click="upload_receipt"
            phx-target={@myself}
            class="bg-green-600 hover:bg-green-700"
          >
            Upload Receipt
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{expense: expense} = assigns, socket) do
    categories = Expenses.list_categories()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:categories, categories)
     |> assign_new(:form, fn ->
       to_form(Expenses.change_expense(expense))
     end)}
  end

  @impl true
  def handle_event("validate", %{"expense" => expense_params}, socket) do
    changeset = Expenses.change_expense(socket.assigns.expense, expense_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"expense" => expense_params}, socket) do
    save_expense(socket, socket.assigns.action, expense_params)
  end

  def handle_event("upload_receipt", _params, socket) do
    notify_parent(:upload_receipt)
    {:noreply, socket}
  end

  defp save_expense(socket, :edit, expense_params) do
    case Expenses.update_expense(socket.assigns.expense, expense_params) do
      {:ok, expense} ->
        notify_parent({:saved, expense})

        # Broadcast the expense update to update spending totals
        Phoenix.PubSub.broadcast(
          ExpenseTracker.PubSub,
          "expense_updates",
          {:expense_updated, expense}
        )

        {:noreply,
         socket
         |> put_flash(:info, "Expense updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_expense(socket, action, expense_params) when action in [:new, :new_for_category] do
    case Expenses.create_expense(expense_params) do
      {:ok, expense} ->
        notify_parent({:saved, expense})

        # Broadcast the expense creation to update spending totals
        Phoenix.PubSub.broadcast(
          ExpenseTracker.PubSub,
          "expense_updates",
          {:expense_created, expense}
        )

        case action do
          :new_for_category ->
            {:noreply,
             socket
             |> put_flash(:info, "Expense created successfully")
             |> push_navigate(to: ~p"/categories/#{expense.category_id}")}

          :new ->
            {:noreply,
             socket
             |> put_flash(:info, "Expense created successfully")
             |> push_patch(to: socket.assigns.patch)}
        end

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
