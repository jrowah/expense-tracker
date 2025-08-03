defmodule ExpenseTracker.Expenses.CategoryTest do
  use ExpenseTracker.DataCase

  alias ExpenseTracker.Expenses.Category

  describe "changeset/2" do
    @valid_attrs %{
      name: "Food",
      description: "Food and dining expenses",
      monthly_budget: Decimal.new("500.00")
    }

    @invalid_attrs %{
      name: nil,
      description: nil,
      monthly_budget: nil
    }

    test "changeset with valid attributes" do
      changeset = Category.changeset(%Category{}, @valid_attrs)
      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Category.changeset(%Category{}, @invalid_attrs)
      refute changeset.valid?

      assert errors_on(changeset) == %{
               name: ["can't be blank"],
               description: ["can't be blank"],
               monthly_budget: ["can't be blank"]
             }
    end

    test "name is required" do
      attrs = Map.put(@valid_attrs, :name, nil)
      changeset = Category.changeset(%Category{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "description is required" do
      attrs = Map.put(@valid_attrs, :description, nil)
      changeset = Category.changeset(%Category{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).description
    end

    test "monthly_budget is required" do
      attrs = Map.put(@valid_attrs, :monthly_budget, nil)
      changeset = Category.changeset(%Category{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).monthly_budget
    end

    test "monthly_budget must be greater than 0" do
      attrs = Map.put(@valid_attrs, :monthly_budget, Decimal.new("0"))
      changeset = Category.changeset(%Category{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).monthly_budget
    end

    test "monthly_budget can be a positive decimal" do
      attrs = Map.put(@valid_attrs, :monthly_budget, Decimal.new("1000.50"))
      changeset = Category.changeset(%Category{}, attrs)
      assert changeset.valid?
    end

    test "name must be at least 1 character" do
      attrs = Map.put(@valid_attrs, :name, "")
      changeset = Category.changeset(%Category{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).name
    end

    test "name must be at most 100 characters" do
      long_name = String.duplicate("a", 101)
      attrs = Map.put(@valid_attrs, :name, long_name)
      changeset = Category.changeset(%Category{}, attrs)
      refute changeset.valid?
      assert "should be at most 100 character(s)" in errors_on(changeset).name
    end

    test "name at 100 characters is valid" do
      name_100_chars = String.duplicate("a", 100)
      attrs = Map.put(@valid_attrs, :name, name_100_chars)
      changeset = Category.changeset(%Category{}, attrs)
      assert changeset.valid?
    end

    test "description must be at most 500 characters" do
      long_description = String.duplicate("a", 501)
      attrs = Map.put(@valid_attrs, :description, long_description)
      changeset = Category.changeset(%Category{}, attrs)
      refute changeset.valid?
      assert "should be at most 500 character(s)" in errors_on(changeset).description
    end

    test "description at 500 characters is valid" do
      description_500_chars = String.duplicate("a", 500)
      attrs = Map.put(@valid_attrs, :description, description_500_chars)
      changeset = Category.changeset(%Category{}, attrs)
      assert changeset.valid?
    end

    test "name must be unique" do
      # Insert first category
      category_attrs = @valid_attrs

      {:ok, _category} =
        %Category{}
        |> Category.changeset(category_attrs)
        |> Repo.insert()

      # Try to insert another category with the same name
      changeset = Category.changeset(%Category{}, category_attrs)
      {:error, changeset} = Repo.insert(changeset)
      refute changeset.valid?
      assert "has already been taken" in errors_on(changeset).name
    end

    test "allows different names" do
      # Insert first category
      {:ok, _category1} =
        %Category{}
        |> Category.changeset(@valid_attrs)
        |> Repo.insert()

      # Insert second category with different name
      attrs2 = Map.put(@valid_attrs, :name, "Entertainment")
      changeset2 = Category.changeset(%Category{}, attrs2)
      assert changeset2.valid?
      {:ok, _category2} = Repo.insert(changeset2)
    end
  end

  describe "schema associations" do
    test "category has many expenses" do
      # Create a category
      {:ok, category} =
        %Category{}
        |> Category.changeset(@valid_attrs)
        |> Repo.insert()

      # Check that it has the expenses association
      assert %Ecto.Association.Has{} = Category.__schema__(:association, :expenses)

      # Verify the association can be preloaded
      category_with_expenses = Repo.preload(category, :expenses)
      assert category_with_expenses.expenses == []
    end
  end

  describe "schema fields" do
    test "has correct primary key type" do
      assert Category.__schema__(:primary_key) == [:id]
      assert Category.__schema__(:type, :id) == :binary_id
    end

    test "has correct field types" do
      assert Category.__schema__(:type, :name) == :string
      assert Category.__schema__(:type, :description) == :string
      assert Category.__schema__(:type, :monthly_budget) == :decimal
      assert Category.__schema__(:type, :inserted_at) == :utc_datetime
      assert Category.__schema__(:type, :updated_at) == :utc_datetime
    end
  end
end
