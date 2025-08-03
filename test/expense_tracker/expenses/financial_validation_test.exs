defmodule ExpenseTracker.Expenses.FinancialValidationTest do
  use ExpenseTracker.DataCase

  alias ExpenseTracker.Expenses
  alias ExpenseTracker.Expenses.{Category, Expense}

  describe "financial precision and validation" do
    setup do
      {:ok, category} =
        Expenses.create_category(%{
          name: "Test Category",
          description: "Test category",
          monthly_budget: Decimal.new("1000.00")
        })

      %{category: category}
    end

    test "validates decimal precision for expense amounts", %{category: category} do
      # Valid: 2 decimal places
      valid_attrs = %{
        description: "Test expense",
        amount: Decimal.new("123.45"),
        date: Date.utc_today(),
        notes: "Test",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, valid_attrs)
      assert changeset.valid?

      # Invalid: 3 decimal places
      invalid_attrs = %{valid_attrs | amount: Decimal.new("123.456")}
      changeset = Expense.changeset(%Expense{}, invalid_attrs)
      refute changeset.valid?
      assert "cannot have more than 2 decimal places" in errors_on(changeset).amount
    end

    test "validates maximum amount limits", %{category: category} do
      # Valid: within limits
      valid_attrs = %{
        description: "Test expense",
        amount: Decimal.new("99999999.99"),
        date: Date.utc_today(),
        notes: "Test",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, valid_attrs)
      assert changeset.valid?

      # Invalid: exceeds limit
      invalid_attrs = %{valid_attrs | amount: Decimal.new("100000000.00")}
      changeset = Expense.changeset(%Expense{}, invalid_attrs)
      refute changeset.valid?
      assert "cannot exceed $99,999,999.99" in errors_on(changeset).amount
    end

    test "validates date constraints", %{category: category} do
      base_attrs = %{
        description: "Test expense",
        amount: Decimal.new("100.00"),
        notes: "Test",
        category_id: category.id
      }

      # Valid: today
      changeset = Expense.changeset(%Expense{}, Map.put(base_attrs, :date, Date.utc_today()))
      assert changeset.valid?

      # Invalid: too far in future
      future_date = Date.add(Date.utc_today(), 400)
      changeset = Expense.changeset(%Expense{}, Map.put(base_attrs, :date, future_date))
      refute changeset.valid?
      assert "cannot be more than 1 year in the future" in errors_on(changeset).date

      # Invalid: too far in past
      past_date = Date.add(Date.utc_today(), -4000)
      changeset = Expense.changeset(%Expense{}, Map.put(base_attrs, :date, past_date))
      refute changeset.valid?
      assert "cannot be more than 10 years in the past" in errors_on(changeset).date
    end

    test "prevents negative amounts", %{category: category} do
      attrs = %{
        description: "Test expense",
        amount: Decimal.new("-100.00"),
        date: Date.utc_today(),
        notes: "Test",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).amount
    end

    test "prevents zero amounts", %{category: category} do
      attrs = %{
        description: "Test expense",
        amount: Decimal.new("0.00"),
        date: Date.utc_today(),
        notes: "Test",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).amount
    end
  end

  describe "budget analysis and over-budget handling" do
    setup do
      {:ok, category} =
        Expenses.create_category(%{
          name: "Budget Test",
          description: "Test category",
          monthly_budget: Decimal.new("500.00")
        })

      %{category: category}
    end

    test "calculates budget analysis correctly", %{category: category} do
      # Add some expenses
      {:ok, _expense1} =
        Expenses.create_expense(%{
          description: "Expense 1",
          amount: Decimal.new("200.00"),
          date: Date.utc_today(),
          notes: "Test",
          category_id: category.id
        })

      {:ok, _expense2} =
        Expenses.create_expense(%{
          description: "Expense 2",
          amount: Decimal.new("150.00"),
          date: Date.utc_today(),
          notes: "Test",
          category_id: category.id
        })

      analysis = Expenses.budget_analysis(category)

      assert Decimal.equal?(analysis.total_expenses, Decimal.new("350.00"))
      assert Decimal.equal?(analysis.budget, Decimal.new("500.00"))
      assert analysis.percentage == 70.0
      assert analysis.status == :good
      assert Decimal.equal?(analysis.remaining_budget, Decimal.new("150.00"))
      assert Decimal.equal?(analysis.over_budget_amount, Decimal.new("0.00"))
    end

    test "detects over-budget scenarios", %{category: category} do
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

      analysis = Expenses.budget_analysis(category)

      assert Decimal.equal?(analysis.total_expenses, Decimal.new("600.00"))
      assert analysis.percentage == 120.0
      assert analysis.status == :over_budget
      assert Decimal.equal?(analysis.over_budget_amount, Decimal.new("100.00"))
      assert Decimal.equal?(analysis.remaining_budget, Decimal.new("0.00"))
    end

    test "handles edge case with very small budget", %{} do
      {:ok, small_budget_category} =
        Expenses.create_category(%{
          name: "Small Budget Category",
          description: "Test category with very small budget",
          monthly_budget: Decimal.new("0.01")
        })

      {:ok, _expense} =
        Expenses.create_expense(%{
          description: "Expense on small budget",
          amount: Decimal.new("0.02"),
          date: Date.utc_today(),
          notes: "Test",
          category_id: small_budget_category.id
        })

      analysis = Expenses.budget_analysis(small_budget_category)

      assert Decimal.equal?(analysis.total_expenses, Decimal.new("0.02"))
      assert Decimal.equal?(analysis.budget, Decimal.new("0.01"))
      # 0.02 / 0.01 * 100 = 200%
      assert analysis.percentage == 200.0
      assert analysis.status == :over_budget
      assert Decimal.equal?(analysis.over_budget_amount, Decimal.new("0.01"))
      assert Decimal.equal?(analysis.remaining_budget, Decimal.new("0.00"))
    end

    test "calculates status thresholds correctly", %{} do
      {:ok, test_category} =
        Expenses.create_category(%{
          name: "Status Test Category",
          description: "Test category for status thresholds",
          monthly_budget: Decimal.new("1000.00")
        })

      test_cases = [
        # {expense_amount, expected_status, expected_percentage}
        {"500.00", :good, 50.0},
        {"750.00", :caution, 75.0},
        {"900.00", :warning, 90.0},
        {"1000.00", :over_budget, 100.0},
        {"1200.00", :over_budget, 120.0}
      ]

      for {amount, expected_status, expected_percentage} <- test_cases do
        # Clear previous expenses
        for expense <- Expenses.list_expenses() do
          if expense.category_id == test_category.id do
            Expenses.delete_expense(expense)
          end
        end

        {:ok, _expense} =
          Expenses.create_expense(%{
            description: "Status test expense",
            amount: Decimal.new(amount),
            date: Date.utc_today(),
            notes: "Test",
            category_id: test_category.id
          })

        analysis = Expenses.budget_analysis(test_category)
        assert analysis.status == expected_status
        assert analysis.percentage == expected_percentage
      end
    end

    test "validates budget impact before creation", %{category: category} do
      expense_attrs = %{
        "description" => "Test expense",
        "amount" => "300.00",
        "date" => Date.to_string(Date.utc_today()),
        "notes" => "Test",
        "category_id" => category.id
      }

      {:ok, analysis} = Expenses.validate_budget_impact(expense_attrs, category.id)

      assert analysis.projected.percentage == 60.0
      refute analysis.projected.would_exceed

      # Test over-budget scenario
      large_expense_attrs = %{expense_attrs | "amount" => "600.00"}
      {:ok, analysis} = Expenses.validate_budget_impact(large_expense_attrs, category.id)

      assert analysis.projected.percentage == 120.0
      assert analysis.projected.would_exceed
    end
  end

  describe "concurrency and transaction safety" do
    setup do
      {:ok, category} =
        Expenses.create_category(%{
          name: "Concurrency Test",
          description: "Test category",
          monthly_budget: Decimal.new("1000.00")
        })

      %{category: category}
    end

    test "creates expense with budget validation", %{category: category} do
      attrs = %{
        description: "Test expense",
        amount: Decimal.new("500.00"),
        date: Date.utc_today(),
        notes: "Test",
        category_id: category.id
      }

      # Should succeed within budget
      assert {:ok, expense} = Expenses.create_expense(attrs, validate_budget: true)
      assert Decimal.equal?(expense.amount, Decimal.new("500.00"))

      # Should fail when exceeding budget
      large_attrs = %{attrs | amount: Decimal.new("600.00")}

      assert {:error, {:budget_exceeded, _analysis}} =
               Expenses.create_expense(large_attrs, validate_budget: true)
    end

    test "updates expense with budget validation", %{category: category} do
      {:ok, expense} =
        Expenses.create_expense(%{
          description: "Test expense",
          amount: Decimal.new("300.00"),
          date: Date.utc_today(),
          notes: "Test",
          category_id: category.id
        })

      # Should succeed when increasing within budget
      assert {:ok, updated_expense} =
               Expenses.update_expense(expense, %{amount: Decimal.new("500.00")},
                 validate_budget: true
               )

      assert Decimal.equal?(updated_expense.amount, Decimal.new("500.00"))

      # Should fail when increasing beyond budget
      assert {:error, {:budget_exceeded, _analysis}} =
               Expenses.update_expense(updated_expense, %{amount: Decimal.new("1200.00")},
                 validate_budget: true
               )
    end

    test "handles concurrent expense creation", %{category: category} do
      # Simulate concurrent operations by creating multiple expenses
      tasks =
        for i <- 1..5 do
          Task.async(fn ->
            Expenses.create_expense(%{
              description: "Concurrent expense #{i}",
              amount: Decimal.new("200.00"),
              date: Date.utc_today(),
              notes: "Test #{i}",
              category_id: category.id
            })
          end)
        end

      results = Task.await_many(tasks, 5000)

      # All should succeed
      assert Enum.all?(results, fn {status, _} -> status == :ok end)

      # Verify total
      total = Expenses.total_expenses_by_category(category.id)
      assert Decimal.equal?(total, Decimal.new("1000.00"))
    end
  end

  describe "category budget validation" do
    test "validates decimal precision for budget amounts" do
      # Valid: 2 decimal places
      valid_attrs = %{
        name: "Test Category",
        description: "Test",
        monthly_budget: Decimal.new("1000.50")
      }

      changeset = Category.changeset(%Category{}, valid_attrs)
      assert changeset.valid?

      # Invalid: 3 decimal places
      invalid_attrs = %{valid_attrs | monthly_budget: Decimal.new("1000.123")}
      changeset = Category.changeset(%Category{}, invalid_attrs)
      refute changeset.valid?
      assert "cannot have more than 2 decimal places" in errors_on(changeset).monthly_budget
    end

    test "validates reasonable budget limits" do
      # Valid: within limits
      valid_attrs = %{
        name: "Test Category",
        description: "Test",
        monthly_budget: Decimal.new("999999.99")
      }

      changeset = Category.changeset(%Category{}, valid_attrs)
      assert changeset.valid?

      # Invalid: exceeds limit
      invalid_attrs = %{valid_attrs | monthly_budget: Decimal.new("1000000.00")}
      changeset = Category.changeset(%Category{}, invalid_attrs)
      refute changeset.valid?
      assert "monthly budget cannot exceed $999,999.99" in errors_on(changeset).monthly_budget
    end
  end
end
