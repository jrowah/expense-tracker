defmodule ExpenseTracker.Expenses.ExpenseTest do
  use ExpenseTracker.DataCase

  alias ExpenseTracker.Expenses.{Expense, Category}

  describe "changeset/2" do
    setup do
      # Create a category for testing expenses
      {:ok, category} =
        %Category{}
        |> Category.changeset(%{
          name: "Test Category",
          description: "Test category for expenses",
          monthly_budget: Decimal.new("1000.00")
        })
        |> Repo.insert()

      %{category: category}
    end

    test "changeset with valid attributes", %{category: category} do
      valid_attrs = %{
        description: "Lunch at restaurant",
        amount: Decimal.new("25.50"),
        date: Date.utc_today(),
        notes: "Business lunch meeting",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      invalid_attrs = %{
        description: nil,
        amount: nil,
        date: nil,
        notes: nil,
        category_id: nil
      }

      changeset = Expense.changeset(%Expense{}, invalid_attrs)
      refute changeset.valid?

      assert errors_on(changeset) == %{
               description: ["can't be blank"],
               amount: ["can't be blank"],
               date: ["can't be blank"],
               notes: ["can't be blank"],
               category_id: ["can't be blank"]
             }
    end

    test "description is required", %{category: category} do
      attrs = %{
        description: nil,
        amount: Decimal.new("25.50"),
        date: Date.utc_today(),
        notes: "Test notes",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).description
    end

    test "amount is required", %{category: category} do
      attrs = %{
        description: "Test expense",
        amount: nil,
        date: Date.utc_today(),
        notes: "Test notes",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).amount
    end

    test "date is required", %{category: category} do
      attrs = %{
        description: "Test expense",
        amount: Decimal.new("25.50"),
        date: nil,
        notes: "Test notes",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).date
    end

    test "notes is required", %{category: category} do
      attrs = %{
        description: "Test expense",
        amount: Decimal.new("25.50"),
        date: Date.utc_today(),
        notes: nil,
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).notes
    end

    test "category_id is required" do
      attrs = %{
        description: "Test expense",
        amount: Decimal.new("25.50"),
        date: Date.utc_today(),
        notes: "Test notes",
        category_id: nil
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).category_id
    end

    test "amount must be greater than 0", %{category: category} do
      attrs = %{
        description: "Test expense",
        amount: Decimal.new("0"),
        date: Date.utc_today(),
        notes: "Test notes",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).amount
    end

    test "amount can be a positive decimal", %{category: category} do
      attrs = %{
        description: "Test expense",
        amount: Decimal.new("123.45"),
        date: Date.utc_today(),
        notes: "Test notes",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      assert changeset.valid?
    end

    test "description must be at most 255 characters", %{category: category} do
      long_description = String.duplicate("a", 256)

      attrs = %{
        description: long_description,
        amount: Decimal.new("25.50"),
        date: Date.utc_today(),
        notes: "Test notes",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      refute changeset.valid?
      assert "should be at most 255 character(s)" in errors_on(changeset).description
    end

    test "description at 255 characters is valid", %{category: category} do
      description_255_chars = String.duplicate("a", 255)

      attrs = %{
        description: description_255_chars,
        amount: Decimal.new("25.50"),
        date: Date.utc_today(),
        notes: "Test notes",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      assert changeset.valid?
    end

    test "foreign key constraint for category_id" do
      non_existent_category_id = Ecto.UUID.generate()

      attrs = %{
        description: "Test expense",
        amount: Decimal.new("25.50"),
        date: Date.utc_today(),
        notes: "Test notes",
        category_id: non_existent_category_id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      # Changeset is valid, but insert will fail
      assert changeset.valid?

      {:error, changeset} = Repo.insert(changeset)
      refute changeset.valid?
      assert "Category must exist" in errors_on(changeset).category_id
    end

    test "allows valid dates", %{category: category} do
      past_date = Date.add(Date.utc_today(), -30)
      future_date = Date.add(Date.utc_today(), 1)

      past_attrs = %{
        description: "Past expense",
        amount: Decimal.new("25.50"),
        date: past_date,
        notes: "Past expense notes",
        category_id: category.id
      }

      future_attrs = %{
        description: "Future expense",
        amount: Decimal.new("50.00"),
        date: future_date,
        notes: "Future expense notes",
        category_id: category.id
      }

      past_changeset = Expense.changeset(%Expense{}, past_attrs)
      future_changeset = Expense.changeset(%Expense{}, future_attrs)

      assert past_changeset.valid?
      assert future_changeset.valid?
    end
  end

  describe "schema associations" do
    test "expense belongs to category" do
      # Check that it has the category association
      assert %Ecto.Association.BelongsTo{} = Expense.__schema__(:association, :category)
    end

    test "can preload category association" do
      # Create a category
      {:ok, category} =
        %Category{}
        |> Category.changeset(%{
          name: "Test Category",
          description: "Test category",
          monthly_budget: Decimal.new("1000.00")
        })
        |> Repo.insert()

      # Create an expense
      {:ok, expense} =
        %Expense{}
        |> Expense.changeset(%{
          description: "Test expense",
          amount: Decimal.new("25.50"),
          date: Date.utc_today(),
          notes: "Test notes",
          category_id: category.id
        })
        |> Repo.insert()

      # Preload and verify association
      expense_with_category = Repo.preload(expense, :category)
      assert expense_with_category.category.id == category.id
      assert expense_with_category.category.name == "Test Category"
    end
  end

  describe "schema fields" do
    test "has correct primary key type" do
      assert Expense.__schema__(:primary_key) == [:id]
      assert Expense.__schema__(:type, :id) == :binary_id
    end

    test "has correct field types" do
      assert Expense.__schema__(:type, :description) == :string
      assert Expense.__schema__(:type, :amount) == :decimal
      assert Expense.__schema__(:type, :date) == :date
      assert Expense.__schema__(:type, :notes) == :string
      assert Expense.__schema__(:type, :category_id) == :binary_id
      assert Expense.__schema__(:type, :inserted_at) == :utc_datetime
      assert Expense.__schema__(:type, :updated_at) == :utc_datetime
    end

    test "has correct foreign key type" do
      assert Expense.__schema__(:type, :category_id) == :binary_id
    end
  end

  describe "casting and validation edge cases" do
    setup do
      {:ok, category} =
        %Category{}
        |> Category.changeset(%{
          name: "Test Category",
          description: "Test category for expenses",
          monthly_budget: Decimal.new("1000.00")
        })
        |> Repo.insert()

      %{category: category}
    end

    test "handles string amounts", %{category: category} do
      attrs = %{
        description: "Test expense",
        amount: "25.50",
        date: Date.utc_today(),
        notes: "Test notes",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      assert changeset.valid?
      assert Decimal.equal?(changeset.changes.amount, Decimal.new("25.50"))
    end

    test "handles string dates", %{category: category} do
      attrs = %{
        description: "Test expense",
        amount: Decimal.new("25.50"),
        date: "2024-08-03",
        notes: "Test notes",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      assert changeset.valid?
      assert changeset.changes.date == ~D[2024-08-03]
    end

    test "handles empty string values", %{category: category} do
      attrs = %{
        description: "",
        amount: Decimal.new("25.50"),
        date: Date.utc_today(),
        notes: "",
        category_id: category.id
      }

      changeset = Expense.changeset(%Expense{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).description
      assert "can't be blank" in errors_on(changeset).notes
    end
  end
end
