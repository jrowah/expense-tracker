defmodule ExpenseTracker.ExpensesTest do
  use ExpenseTracker.DataCase

  alias ExpenseTracker.Expenses

  describe "categories" do
    alias ExpenseTracker.Expenses.Category

    import ExpenseTracker.ExpensesFixtures

    @invalid_attrs %{name: nil, description: nil, monthly_budget: nil}

    test "list_categories/0 returns all categories" do
      category = category_fixture()
      assert Expenses.list_categories() == [category]
    end

    test "get_category!/1 returns the category with given id" do
      category = category_fixture()
      assert Expenses.get_category!(category.id) == category
    end

    test "create_category/1 with valid data creates a category" do
      valid_attrs = %{name: "some name", description: "some description", monthly_budget: "120.5"}

      assert {:ok, %Category{} = category} = Expenses.create_category(valid_attrs)
      assert category.name == "some name"
      assert category.description == "some description"
      assert category.monthly_budget == Decimal.new("120.5")
    end

    test "create_category/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Expenses.create_category(@invalid_attrs)
    end

    test "update_category/2 with valid data updates the category" do
      category = category_fixture()
      update_attrs = %{name: "some updated name", description: "some updated description", monthly_budget: "456.7"}

      assert {:ok, %Category{} = category} = Expenses.update_category(category, update_attrs)
      assert category.name == "some updated name"
      assert category.description == "some updated description"
      assert category.monthly_budget == Decimal.new("456.7")
    end

    test "update_category/2 with invalid data returns error changeset" do
      category = category_fixture()
      assert {:error, %Ecto.Changeset{}} = Expenses.update_category(category, @invalid_attrs)
      assert category == Expenses.get_category!(category.id)
    end

    test "delete_category/1 deletes the category" do
      category = category_fixture()
      assert {:ok, %Category{}} = Expenses.delete_category(category)
      assert_raise Ecto.NoResultsError, fn -> Expenses.get_category!(category.id) end
    end

    test "change_category/1 returns a category changeset" do
      category = category_fixture()
      assert %Ecto.Changeset{} = Expenses.change_category(category)
    end
  end

  describe "expenses" do
    alias ExpenseTracker.Expenses.Expense

    import ExpenseTracker.ExpensesFixtures

    @invalid_attrs %{date: nil, description: nil, amount: nil, notes: nil}

    test "list_expenses/0 returns all expenses" do
      expense = expense_fixture()
      assert Expenses.list_expenses() == [expense]
    end

    test "get_expense!/1 returns the expense with given id" do
      expense = expense_fixture()
      assert Expenses.get_expense!(expense.id) == expense
    end

    test "create_expense/1 with valid data creates a expense" do
      valid_attrs = %{date: ~D[2025-08-01], description: "some description", amount: "120.5", notes: "some notes"}

      assert {:ok, %Expense{} = expense} = Expenses.create_expense(valid_attrs)
      assert expense.date == ~D[2025-08-01]
      assert expense.description == "some description"
      assert expense.amount == Decimal.new("120.5")
      assert expense.notes == "some notes"
    end

    test "create_expense/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Expenses.create_expense(@invalid_attrs)
    end

    test "update_expense/2 with valid data updates the expense" do
      expense = expense_fixture()
      update_attrs = %{date: ~D[2025-08-02], description: "some updated description", amount: "456.7", notes: "some updated notes"}

      assert {:ok, %Expense{} = expense} = Expenses.update_expense(expense, update_attrs)
      assert expense.date == ~D[2025-08-02]
      assert expense.description == "some updated description"
      assert expense.amount == Decimal.new("456.7")
      assert expense.notes == "some updated notes"
    end

    test "update_expense/2 with invalid data returns error changeset" do
      expense = expense_fixture()
      assert {:error, %Ecto.Changeset{}} = Expenses.update_expense(expense, @invalid_attrs)
      assert expense == Expenses.get_expense!(expense.id)
    end

    test "delete_expense/1 deletes the expense" do
      expense = expense_fixture()
      assert {:ok, %Expense{}} = Expenses.delete_expense(expense)
      assert_raise Ecto.NoResultsError, fn -> Expenses.get_expense!(expense.id) end
    end

    test "change_expense/1 returns a expense changeset" do
      expense = expense_fixture()
      assert %Ecto.Changeset{} = Expenses.change_expense(expense)
    end
  end
end
