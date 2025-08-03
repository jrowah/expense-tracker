defmodule ExpenseTrackerWeb.HomeLiveTest do
  use ExpenseTrackerWeb.ConnCase

  import Phoenix.LiveViewTest

  alias ExpenseTracker.Expenses

  alias ExpenseTrackerWeb.CommonComponents.CategoriesCard

  describe "budget display and over-budget handling" do
    setup do
      {:ok, category} =
        Expenses.create_category(%{
          name: "Test Category",
          description: "Test category for budget display",
          monthly_budget: Decimal.new("500.00")
        })

      %{category: category}
    end

    test "displays normal budget percentage correctly", %{conn: conn, category: category} do
      # Add expense within budget
      {:ok, _expense} =
        Expenses.create_expense(%{
          description: "Test expense",
          amount: Decimal.new("200.00"),
          date: Date.utc_today(),
          notes: "Test",
          category_id: category.id
        })

      {:ok, view, _html} = live(conn, "/")

      # Should show 40% (200/500)
      assert has_element?(view, "[data-testid='budget-percentage']", "40%")
      # Should not show over-budget warning
      refute has_element?(view, "[data-testid='over-budget-warning']")
    end

    test "displays over-budget percentage with OVER indicator", %{conn: conn, category: category} do
      # Add expenses that exceed budget
      {:ok, _expense1} =
        Expenses.create_expense(%{
          description: "Expense 1",
          amount: Decimal.new("400.00"),
          date: Date.utc_today(),
          notes: "Test",
          category_id: category.id
        })

      {:ok, _expense2} =
        Expenses.create_expense(%{
          description: "Expense 2",
          amount: Decimal.new("200.00"),
          date: Date.utc_today(),
          notes: "Test",
          category_id: category.id
        })

      {:ok, view, _html} = live(conn, "/")

      # Should show "OVER +20%" (600/500 = 120%, so 20% over)
      assert has_element?(view, "[data-testid='budget-percentage']", "+120%")
      # Should show over-budget warning
      assert has_element?(view, "[data-testid='over-budget-warning']")
      # Should show over-budget amount (without $ since it's already in the text)
      assert has_element?(view, "[data-testid='over-budget-amount']", "100.00")
    end

    test "applies correct CSS classes for different budget levels", %{
      conn: conn,
      category: category
    } do
      test_cases = [
        # {expense_amount, expected_class_pattern}
        # 40% - normal
        {"200.00", "text-gray-700"},
        # 80% - caution
        {"400.00", "text-yellow-600"},
        # 95% - warning
        {"475.00", "text-red-600"},
        # 120% - over budget
        {"600.00", "text-red-700"}
      ]

      for {amount, expected_class} <- test_cases do
        # Clean up previous expenses
        for expense <- Expenses.list_expenses() do
          Expenses.delete_expense(expense)
        end

        {:ok, _expense} =
          Expenses.create_expense(%{
            description: "Test expense",
            amount: Decimal.new(amount),
            date: Date.utc_today(),
            notes: "Test",
            category_id: category.id
          })

        {:ok, view, _html} = live(conn, "/")

        # Check that the budget percentage element has the expected class
        assert has_element?(view, "[data-testid='budget-percentage'].#{expected_class}")
      end
    end

    test "progress circle is capped at 100% visually even when over budget", %{
      conn: conn,
      category: category
    } do
      # Add expenses that exceed budget (120%)
      {:ok, _expense} =
        Expenses.create_expense(%{
          description: "Over budget expense",
          amount: Decimal.new("600.00"),
          date: Date.utc_today(),
          notes: "Test",
          category_id: category.id
        })

      {:ok, view, _html} = live(conn, "/")

      # Get the stroke-dashoffset value - it should correspond to 100% fill, not 120%
      html = render(view)

      # The circumference is 2 * π * 16 ≈ 100.53
      # For 100% fill, stroke-dashoffset should be 0
      assert html =~ "stroke-dashoffset=\"0"
    end
  end

  describe "budget analysis edge cases" do
    test "handles very small budget correctly" do
      {:ok, category} =
        Expenses.create_category(%{
          name: "Small Budget",
          description: "Category with very small budget",
          monthly_budget: Decimal.new("0.01")
        })

      {:ok, _expense} =
        Expenses.create_expense(%{
          description: "Expense on small budget",
          amount: Decimal.new("0.02"),
          date: Date.utc_today(),
          notes: "Test",
          category_id: category.id
        })

      analysis = Expenses.budget_analysis(category)

      # Should calculate percentage correctly for small amounts
      # 0.02 / 0.01 * 100 = 200%
      assert analysis.percentage == 200.0
      assert analysis.status == :over_budget
      assert Decimal.equal?(analysis.over_budget_amount, Decimal.new("0.01"))
    end

    test "handles very small budget amounts" do
      {:ok, category} =
        Expenses.create_category(%{
          name: "Small Budget",
          description: "Category with very small budget",
          monthly_budget: Decimal.new("0.01")
        })

      {:ok, _expense} =
        Expenses.create_expense(%{
          description: "Expense exceeding tiny budget",
          amount: Decimal.new("1.00"),
          date: Date.utc_today(),
          notes: "Test",
          category_id: category.id
        })

      analysis = Expenses.budget_analysis(category)

      # Should calculate percentage correctly for small amounts
      # 1.00 / 0.01 * 100 = 10000%
      assert analysis.percentage == 10000.0
      assert analysis.status == :over_budget
      assert Decimal.equal?(analysis.over_budget_amount, Decimal.new("0.99"))
    end
  end

  describe "categories card component" do
    test "renders category information correctly" do
      category = %{
        id: 1,
        name: "Test Category",
        description: "Test description",
        monthly_budget: Decimal.new("1000.00"),
        expenses: []
      }

      assigns = %{category: category}

      html = render_component(&CategoriesCard.category_card/1, assigns)

      assert html =~ "Test Category"
      assert html =~ "Test description"
      assert html =~ "$1000.00"
    end

    test "shows over-budget warning when expenses exceed budget" do
      today = Date.utc_today()

      category = %{
        id: 1,
        name: "Over Budget Category",
        description: "Test description",
        monthly_budget: Decimal.new("100.00"),
        expenses: [
          %{amount: Decimal.new("150.00"), date: today, description: "Test expense"}
        ]
      }

      assigns = %{category: category}
      html = render_component(&CategoriesCard.category_card/1, assigns)

      assert html =~ "over-budget-warning"
      assert html =~ "Over budget by"
    end

    test "does not show over-budget warning when within budget" do
      today = Date.utc_today()

      category = %{
        id: 1,
        name: "Within Budget Category",
        description: "Test description",
        monthly_budget: Decimal.new("100.00"),
        expenses: [
          %{amount: Decimal.new("50.00"), date: today, description: "Test expense"}
        ]
      }

      assigns = %{category: category}
      html = render_component(&CategoriesCard.category_card/1, assigns)

      refute html =~ "over-budget-warning"
      refute html =~ "Over budget by"
    end

    test "shows normal percentage when within budget" do
      today = Date.utc_today()

      category = %{
        id: 1,
        name: "Normal Category",
        description: "Test description",
        monthly_budget: Decimal.new("100.00"),
        expenses: [
          %{amount: Decimal.new("50.00"), date: today, description: "Test expense"}
        ]
      }

      assigns = %{category: category}
      html = render_component(&CategoriesCard.category_card/1, assigns)

      assert html =~ "50%"
      refute html =~ "OVER"
    end

    test "shows recent expenses" do
      today = Date.utc_today()

      category = %{
        id: 1,
        name: "Category with Expenses",
        description: "Test description",
        monthly_budget: Decimal.new("100.00"),
        expenses: [
          %{amount: Decimal.new("25.00"), date: today, description: "Expense 1"},
          %{amount: Decimal.new("15.00"), date: today, description: "Expense 2"}
        ]
      }

      assigns = %{category: category}
      html = render_component(&CategoriesCard.category_card/1, assigns)

      assert html =~ "Expense 1"
      assert html =~ "Expense 2"
      assert html =~ "$25.00"
      assert html =~ "$15.00"
    end

    test "shows 'No expenses yet' when category has no expenses" do
      category = %{
        id: 1,
        name: "Empty Category",
        description: "Test description",
        monthly_budget: Decimal.new("100.00"),
        expenses: []
      }

      assigns = %{category: category}
      html = render_component(&CategoriesCard.category_card/1, assigns)

      assert html =~ "No expenses yet"
    end

    test "card is clickable and links to category page" do
      category = %{
        id: 123,
        name: "Clickable Category",
        description: "Test description",
        monthly_budget: Decimal.new("100.00"),
        expenses: []
      }

      assigns = %{category: category}
      html = render_component(&CategoriesCard.category_card/1, assigns)

      assert html =~ "href=\"/categories/123\""
    end

    test "only shows current month expenses in calculations" do
      # Use explicit dates to ensure they're in different months
      # Clearly in August
      current_month_date = ~D[2025-08-15]
      # Clearly in June
      different_month_date = ~D[2025-06-15]

      category = %{
        id: 1,
        name: "Mixed Date Category",
        description: "Test description",
        monthly_budget: Decimal.new("100.00"),
        expenses: [
          %{amount: Decimal.new("50.00"), date: current_month_date, description: "This month"},
          %{
            amount: Decimal.new("200.00"),
            date: different_month_date,
            description: "Different month"
          }
        ]
      }

      assigns = %{category: category}
      html = render_component(&CategoriesCard.category_card/1, assigns)

      # Should show 50% (50/100), not 250% (250/100)
      assert html =~ "50%"
    end
  end
end
