defmodule ExpenseTrackerWeb.SessionController do
  use ExpenseTrackerWeb, :controller

  alias ExpenseTracker.Accounts
  alias ExpenseTrackerWeb.Dashboard.Hooks.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully. Please confirm your email to log in!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/dashboard/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"user" => user_params}, info) do
    case Accounts.get_user_by_email_and_password(user_params["email"], user_params["password"]) do
      nil ->
        conn
        |> put_flash(:error, "Invalid email or password")
        |> put_flash(:email, String.slice(user_params["email"], 0, 160))
        |> redirect(to: ~p"/access/login")

      user ->
        cond do
          user.confirmed_at ->
            conn
            |> put_flash(:info, info)
            |> UserAuth.login_user(user, user_params)

          DateTime.diff(DateTime.utc_now(), user.inserted_at, :second) <= 60 ->
            conn
            |> put_flash(
              :info,
              "Welcome to ExpenseTracker! To get started, please confirm your email."
            )
            |> redirect(to: ~p"/access/login")

          true ->
            conn
            |> put_session(:email_confirmed, false)
            |> put_flash(:email, String.slice(user_params["email"], 0, 160))
            |> put_flash(:error, "You must confirm your email to access the account.")
            |> redirect(to: ~p"/access/confirmation_instructions")
        end
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.logout_user()
  end
end
