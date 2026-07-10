defmodule ExpenseTrackerWeb.Landing.LandingLive do
  use ExpenseTrackerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
