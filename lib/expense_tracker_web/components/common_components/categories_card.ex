defmodule ExpenseTrackerWeb.CommonComponents.CategoriesCard do
  use Phoenix.Component

  use ExpenseTrackerWeb, :verified_routes

  @doc """
  Renders a category card with budget information and progress indicator.
  """
  attr :category, :map, required: true

  def category_card(assigns) do
    ~H"""
    <.link navigate={~p"/categories/#{@category.id}"} class="hover:text-blue-600">
      <div class="bg-white rounded-lg border border-gray-200 p-8 shadow-sm hover:shadow-md transition-shadow">
        <div class="flex items-center justify-between">
          <h3 class="text-xl font-semibold text-gray-900">
            {@category.name}
          </h3>
        </div>

        <p class="mt-3 text-base text-gray-600">{@category.description}</p>

        <div class="mt-6">
          <div class="flex justify-between text-base">
            <span class="text-gray-500">Monthly Budget</span>
            <span class="font-semibold text-lg">${@category.monthly_budget}</span>
          </div>

          <% current_total = current_month_total(@category.expenses) %>

          <div class="flex justify-between text-base mt-2">
            <span class="text-gray-500">This Month</span>
            <span class="font-semibold text-lg text-red-600">
              ${current_total}
            </span>
          </div>

          <% percentage = budget_percentage(current_total, @category.monthly_budget) %>
          <% progress_attrs = circle_progress_attributes(percentage) %>

          <div class="mt-6">
            <div class="flex items-center justify-between">
              <span class="text-sm text-gray-500">Budget Used</span>
              <div class="flex items-center space-x-3">
                <div class="relative">
                  <svg class="w-16 h-16 transform -rotate-90" viewBox="0 0 48 48">
                    <!-- Background circle -->
                    <circle cx="24" cy="24" r="20" fill="none" stroke="#e5e7eb" stroke-width="4" />
                    <!-- Progress circle -->
                    <circle
                      cx="24"
                      cy="24"
                      r="20"
                      fill="none"
                      stroke={progress_color(percentage)}
                      stroke-width="4"
                      stroke-linecap="round"
                      stroke-dasharray={progress_attrs.circumference}
                      stroke-dashoffset={progress_attrs.stroke_dashoffset}
                      class="transition-all duration-500 ease-in-out"
                    />
                  </svg>
                  <!-- Percentage text in center -->
                  <div class="absolute inset-0 flex items-center justify-center">
                    <span
                      class={"text-sm font-bold #{budget_status_class(percentage)}"}
                      data-testid="budget-percentage"
                    >
                      {format_budget_percentage(percentage)}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
        
    <!-- Over-budget warning -->
        <div
          :if={percentage > 100}
          class="mt-4 p-3 bg-red-50 border border-red-200 rounded-lg"
          data-testid="over-budget-warning"
        >
          <div class="flex items-center">
            <svg class="w-5 h-5 text-red-500 mr-3" fill="currentColor" viewBox="0 0 20 20">
              <path
                fill-rule="evenodd"
                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                clip-rule="evenodd"
              />
            </svg>
            <span class="text-sm font-medium text-red-700">
              Over budget by $<span data-testid="over-budget-amount"><%= Decimal.sub(current_total, @category.monthly_budget) |> Decimal.to_string() %></span>
            </span>
          </div>
        </div>

        <div class="mt-6 pt-4 border-t border-gray-100">
          <div class="flex justify-between text-base">
            <span class="text-gray-500">Recent Expenses</span>
            <span class="text-gray-500 font-medium">{length(@category.expenses)}</span>
          </div>
          <div :if={not Enum.empty?(@category.expenses)} class="mt-3 space-y-2">
            <div
              :for={expense <- Enum.take(@category.expenses, 3)}
              class="flex justify-between text-sm"
            >
              <span class="text-gray-600 truncate">{expense.description}</span>
              <span class="text-gray-900 font-semibold">${expense.amount}</span>
            </div>
          </div>
          <div :if={Enum.empty?(@category.expenses)} class="mt-3 text-sm text-gray-400 italic">
            No expenses yet
          </div>
        </div>
      </div>
    </.link>
    """
  end

  # Helper functions for budget calculations and UI

  defp current_month_total(expenses) do
    today = Date.utc_today()
    month_start = Date.beginning_of_month(today)
    month_end = Date.end_of_month(today)

    expenses
    |> Enum.filter(&(month_start <= &1.date && &1.date <= month_end))
    |> Enum.map(& &1.amount)
    |> Enum.reduce(Decimal.new("0"), &Decimal.add/2)
  end

  defp budget_percentage(current_total, monthly_budget) do
    if Decimal.positive?(monthly_budget) do
      current_total
      |> Decimal.div(monthly_budget)
      |> Decimal.mult(100)
      |> Decimal.to_float()
    else
      0.0
    end
  end

  defp progress_color(percentage) do
    cond do
      # Bright red for over budget
      percentage >= 100 -> "#dc2626"
      # Red for 90-99%
      percentage >= 90 -> "#ef4444"
      # Orange for 80-89%
      percentage >= 80 -> "#f97316"
      # Yellow for 70-79%
      percentage >= 70 -> "#eab308"
      # Yellow-green for 60-69%
      percentage >= 60 -> "#84cc16"
      # Light green for 50-59%
      percentage >= 50 -> "#22c55e"
      # Medium green for 30-49%
      percentage >= 30 -> "#16a34a"
      # Dark green for 0-29%
      true -> "#15803d"
    end
  end

  defp circle_progress_attributes(percentage) do
    # Updated for radius 20
    circumference = 2 * :math.pi() * 20
    display_percentage = min(percentage, 100)
    stroke_dashoffset = circumference - display_percentage / 100 * circumference

    %{
      circumference: circumference,
      stroke_dashoffset: stroke_dashoffset
    }
  end

  defp format_budget_percentage(percentage) do
    cond do
      percentage > 100 ->
        "+#{:erlang.float_to_binary(percentage, decimals: 0)}%"

      true ->
        "#{:erlang.float_to_binary(percentage, decimals: 0)}%"
    end
  end

  defp budget_status_class(percentage) do
    cond do
      percentage > 100 -> "text-red-700 font-bold"
      percentage >= 90 -> "text-red-600 font-semibold"
      percentage >= 75 -> "text-yellow-600 font-semibold"
      true -> "text-gray-700"
    end
  end
end
