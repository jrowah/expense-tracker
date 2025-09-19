defmodule ExpenseTrackerWeb.Router do
  use ExpenseTrackerWeb, :router

  import ExpenseTrackerWeb.Dashboard.Hooks.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ExpenseTrackerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ExpenseTrackerWeb do
    pipe_through :browser

    scope "/", Landing do
      live "/", LandingLive, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExpenseTrackerWeb do
  #   pipe_through :api
  # end

  ## Authentication routes

  scope "/auth", ExpenseTrackerWeb do
    pipe_through :browser

    post "/login", SessionController, :create

    delete "/logout", SessionController, :delete
  end

  scope "/access", ExpenseTrackerWeb.Access do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{ExpenseTrackerWeb.Dashboard.Hooks.UserAuth, :mount_current_user}] do
      live "/confirm/:token", ConfirmationLive, :edit
      live "/confirm", ConfirmationInstructionsLive, :new
    end

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{ExpenseTrackerWeb.Dashboard.Hooks.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/register", RegistrationLive, :new
      live "/login", LoginLive, :new
      live "/confirmation_instructions", ConfirmationInstructionsLive, :new
      live "/reset_password", ForgotPasswordLive, :new
      live "/reset_password/:token", ResetPasswordLive, :edit
    end
  end

  scope "/dashboard", ExpenseTrackerWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/", HomeLive.Index, :index

    live "/categories", CategoryLive.Index, :index
    live "/categories/new", CategoryLive.Index, :new
    live "/categories/:id/edit", CategoryLive.Index, :edit

    live "/categories/:id", CategoryLive.Show, :show
    live "/categories/:id/show/edit", CategoryLive.Show, :edit
    live "/categories/:category_id/expenses/new", ExpenseLive.Index, :new_for_category

    live "/expenses", ExpenseLive.Index, :index
    live "/expenses/new", ExpenseLive.Index, :new
    live "/expenses/:id/edit", ExpenseLive.Index, :edit

    live "/expenses/:id", ExpenseLive.Show, :show
    live "/expenses/:id/show/edit", ExpenseLive.Show, :edit

    live_session :require_authenticated_user,
      on_mount: [{ExpenseTrackerWeb.Dashboard.Hooks.UserAuth, :ensure_authenticated}] do
      live "/settings", UserSettingsLive, :edit
      live "/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:expense_tracker, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ExpenseTrackerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
