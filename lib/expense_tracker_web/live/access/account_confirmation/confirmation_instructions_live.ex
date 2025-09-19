defmodule ExpenseTrackerWeb.Access.ConfirmationInstructionsLive do
  use ExpenseTrackerWeb, :live_view

  alias ExpenseTracker.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">Resend confirmation instructions</.header>

      <.simple_form for={@form} id="confirmation_form" phx-submit="send_instructions">
        <.input field={@form[:email]} type="email" label="Email" required />
        <:actions>
          <.button phx-disable-with="Sending..." class="w-full">
            Send confirmation instructions
          </.button>
        </:actions>
      </.simple_form>

      <p class="text-center mt-4">
        <.link href={~p"/access/register"}>Register</.link>
        | <.link href={~p"/access/login"}>Log in</.link>
      </p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    form = to_form(%{}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: nil]}
  end

  def handle_event("send_instructions", %{"user" => %{"email" => email}}, socket) do
    if user = Accounts.get_user_by_email(email) do
      Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/access/confirm/#{&1}")
      )
    end

    {:noreply,
     socket
     |> put_flash(
       :info,
       "If your email is in our system and it has not been confirmed yet, " <>
         "you will receive an email with instructions shortly."
     )
     |> redirect(to: ~p"/")}
  end
end
