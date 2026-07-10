defmodule ExpenseTrackerWeb.Admin.UserLive.Index do
  use ExpenseTrackerWeb, :live_view

  alias ExpenseTracker.Accounts
  alias ExpenseTracker.Accounts.User
  alias ExpenseTrackerWeb.Admin.UserLive.FormComponent
  alias ExpenseTrackerWeb.Admin.UserLive.ShowComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:users, Accounts.list_users())
     |> assign(:page_title, "Listing Users")}
  end

  @impl true
  # def handle_params(params, _url, socket) do
  #   {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  # end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.table id="users" rows={@users}>
        <:col :let={user} label="ID">{user.id}</:col>
        <:col :let={user} label="Email">{user.email}</:col>
        <%!-- <:col :let={user} label="Actions">
          <.link patch={~p"/admin/users/#{user}/edit"} class="btn btn-primary">
            Edit
          </.link>
        </:col> --%>
      </.table>
    </div>
    """
  end

  # defp apply_action(socket, :edit, %{"id" => id}) do
  #   socket
  #   |> assign(:page_title, "Edit User")
  #   |> assign(:user, Accounts.get_user!(id))
  # end

  # defp apply_action(socket, :new, _params) do
  #   socket
  #   |> assign(:page_title, "New User")
  #   |> assign(:user, %User{})
  # end
end
