defmodule ExpenseTracker.Expenses do
  @moduledoc """
  The Expenses context.
  """

  import Ecto.Query, warn: false
  import Ecto.Changeset, only: [get_change: 2, get_field: 2]
  alias ExpenseTracker.Repo

  alias ExpenseTracker.Expenses.{
    Category,
    Expense,
    Receipt
  }

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories()
      [%Category{}, ...]

  """
  def list_categories do
    Category
    |> Repo.all()
    |> Repo.preload(:expenses)
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(123)
      %Category{}

      iex> get_category!(456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(id) do
    Category
    |> Repo.get!(id)
    |> Repo.preload(expenses: from(e in Expense, order_by: [desc: e.date]))
  end

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%{field: value})
      {:ok, %Category{}}

      iex> create_category(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a category.

  ## Examples

      iex> delete_category(category)
      {:ok, %Category{}}

      iex> delete_category(category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(category)
      %Ecto.Changeset{data: %Category{}}

  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end

  @doc """
  Returns the list of expenses.

  ## Examples

      iex> list_expenses()
      [%Expense{}, ...]

  """
  def list_expenses do
    Expense
    |> Repo.all()
    |> Repo.preload(:category)
  end

  @doc """
  Gets a single expense.

  Raises `Ecto.NoResultsError` if the Expense does not exist.

  ## Examples

      iex> get_expense!(123)
      %Expense{}

      iex> get_expense!(456)
      ** (Ecto.NoResultsError)

  """
  def get_expense!(id) do
    Expense
    |> Repo.get!(id)
    |> Repo.preload(:category)
  end

  @doc """
  Creates a expense with concurrency safety and optional budget validation.

  ## Examples

      iex> create_expense(%{field: value})
      {:ok, %Expense{}}

      iex> create_expense(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_expense(attrs \\ %{}, opts \\ []) do
    validate_budget = Keyword.get(opts, :validate_budget, false)

    # Use a transaction for concurrency safety
    Repo.transaction(fn ->
      with {:ok, changeset} <- validate_expense_creation(attrs, validate_budget),
           {:ok, expense} <- Repo.insert(changeset) do
        # Broadcast the expense creation
        Phoenix.PubSub.broadcast(
          ExpenseTracker.PubSub,
          "expense_updates",
          {:expense_created, expense}
        )

        expense
      else
        {:error, :budget_exceeded, analysis} ->
          Repo.rollback({:budget_exceeded, analysis})

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, expense} -> {:ok, expense}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Updates a expense with concurrency safety.

  ## Examples

      iex> update_expense(expense, %{field: new_value})
      {:ok, %Expense{}}

      iex> update_expense(expense, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_expense(%Expense{} = expense, attrs, opts \\ []) do
    validate_budget = Keyword.get(opts, :validate_budget, false)

    Repo.transaction(fn ->
      with {:ok, changeset} <- validate_expense_update(expense, attrs, validate_budget),
           {:ok, updated_expense} <- Repo.update(changeset) do
        # Broadcast the expense update
        Phoenix.PubSub.broadcast(
          ExpenseTracker.PubSub,
          "expense_updates",
          {:expense_updated, updated_expense}
        )

        updated_expense
      else
        {:error, :budget_exceeded, analysis} ->
          Repo.rollback({:budget_exceeded, analysis})

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
    |> case do
      {:ok, expense} -> {:ok, expense}
      {:error, changeset} -> {:error, changeset}
    end
  end

  # Private helper for expense creation validation
  defp validate_expense_creation(attrs, validate_budget) do
    changeset = Expense.changeset(%Expense{}, attrs)

    if changeset.valid? and validate_budget do
      category_id = get_change(changeset, :category_id) || get_field(changeset, :category_id)

      case validate_budget_impact(attrs, category_id) do
        {:ok, analysis} ->
          if analysis.projected.would_exceed do
            {:error, :budget_exceeded, analysis}
          else
            {:ok, changeset}
          end
      end
    else
      if changeset.valid?, do: {:ok, changeset}, else: {:error, changeset}
    end
  end

  # Private helper for expense update validation
  defp validate_expense_update(expense, attrs, validate_budget) do
    changeset = Expense.changeset(expense, attrs)

    if changeset.valid? and validate_budget do
      # For updates, we need to calculate the net change in amount
      old_amount = expense.amount
      new_amount = get_change(changeset, :amount) || old_amount
      amount_diff = Decimal.sub(new_amount, old_amount)

      if Decimal.compare(amount_diff, Decimal.new("0.00")) != :eq do
        # Only validate if amount actually changed
        category_id = get_change(changeset, :category_id) || expense.category_id

        # Create temporary attrs for validation with the difference
        temp_attrs = %{"amount" => Decimal.to_string(amount_diff)}

        case validate_budget_impact(temp_attrs, category_id) do
          {:ok, analysis} ->
            if analysis.projected.would_exceed do
              {:error, :budget_exceeded, analysis}
            else
              {:ok, changeset}
            end
        end
      else
        {:ok, changeset}
      end
    else
      if changeset.valid?, do: {:ok, changeset}, else: {:error, changeset}
    end
  end

  @doc """
  Deletes a expense.

  ## Examples

      iex> delete_expense(expense)
      {:ok, %Expense{}}

      iex> delete_expense(expense)
      {:error, %Ecto.Changeset{}}

  """
  def delete_expense(%Expense{} = expense) do
    Repo.delete(expense)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking expense changes.

  ## Examples

      iex> change_expense(expense)
      %Ecto.Changeset{data: %Expense{}}

  """
  def change_expense(%Expense{} = expense, attrs \\ %{}) do
    Expense.changeset(expense, attrs)
  end

  @doc """
  Returns the total expenses for a given category.
  """
  def total_expenses_by_category(category_id) do
    from(e in Expense,
      where: e.category_id == ^category_id,
      select: sum(e.amount)
    )
    |> Repo.one()
    |> case do
      nil -> Decimal.new("0.00")
      total -> Decimal.round(total, 2)
    end
  end

  @doc """
  Calculates spending percentage for a category.
  Returns a map with percentage, status, and over-budget amount if applicable.
  """
  def budget_analysis(category) do
    total_expenses = total_expenses_by_category(category.id)
    budget = Decimal.round(category.monthly_budget, 2)

    percentage =
      if Decimal.compare(budget, Decimal.new("0.00")) == :gt do
        total_expenses
        |> Decimal.div(budget)
        |> Decimal.mult(Decimal.new("100"))
        |> Decimal.round(1)
        |> Decimal.to_float()
      else
        0.0
      end

    over_budget_amount =
      case Decimal.compare(total_expenses, budget) do
        :gt -> Decimal.sub(total_expenses, budget) |> Decimal.round(2)
        _ -> Decimal.new("0.00")
      end

    remaining_budget =
      case Decimal.compare(budget, total_expenses) do
        :gt -> Decimal.sub(budget, total_expenses) |> Decimal.round(2)
        _ -> Decimal.new("0.00")
      end

    status =
      cond do
        percentage >= 100.0 -> :over_budget
        percentage >= 90.0 -> :warning
        percentage >= 75.0 -> :caution
        true -> :good
      end

    %{
      total_expenses: total_expenses,
      budget: budget,
      percentage: percentage,
      status: status,
      over_budget_amount: over_budget_amount,
      remaining_budget: remaining_budget
    }
  end

  # Backward compatibility
  def spending_percentage(category) do
    budget_analysis(category).percentage
  end

  @doc """
  Validates if adding an expense would exceed the budget.
  Returns {:ok, expense} or {:error, :budget_exceeded, analysis}.
  """
  def validate_budget_impact(expense_attrs, category_id) do
    category = get_category!(category_id)
    current_analysis = budget_analysis(category)

    # Extract amount and ensure it's a Decimal
    amount =
      case expense_attrs["amount"] || expense_attrs[:amount] do
        %Decimal{} = decimal_amount ->
          decimal_amount

        string_amount when is_binary(string_amount) ->
          case Decimal.parse(string_amount) do
            {parsed_amount, _} -> parsed_amount
            :error -> Decimal.new("0")
          end

        _none ->
          Decimal.new("0")
      end

    projected_total = Decimal.add(current_analysis.total_expenses, amount)

    projected_percentage =
      if Decimal.compare(current_analysis.budget, Decimal.new("0.00")) == :gt do
        projected_total
        |> Decimal.div(current_analysis.budget)
        |> Decimal.mult(Decimal.new("100"))
        |> Decimal.round(1)
        |> Decimal.to_float()
      else
        0.0
      end

    analysis = %{
      current: current_analysis,
      projected: %{
        total_expenses: projected_total,
        percentage: projected_percentage,
        would_exceed: projected_percentage > 100.0
      }
    }

    {:ok, analysis}
  end

  @doc """
  Gets a single category by name.

  ## Examples

      iex> get_category_by_name("Food & Dining")
      %Category{}

      iex> get_category_by_name("Non-existent")
      nil

  """
  def get_category_by_name(name) do
    Repo.get_by(Category, name: name)
  end

  @doc """
  Returns the list of receipts.

  ## Examples

      iex> list_receipts()
      [%Receipt{}, ...]

  """
  def list_receipts do
    Receipt
    |> Repo.all()
    |> Repo.preload(:expense)
  end

  @doc """
  Gets a single receipt.

  Raises `Ecto.NoResultsError` if the Receipt does not exist.

  ## Examples

      iex> get_receipt!(123)
      %Receipt{}

      iex> get_receipt!(456)
      ** (Ecto.NoResultsError)

  """
  def get_receipt!(id) do
    Receipt
    |> Repo.get!(id)
    |> Repo.preload(:expense)
  end

  @doc """
  Gets a single receipt by ID, returning nil if not found.

  ## Examples

      iex> get_receipt(123)
      %Receipt{}

      iex> get_receipt(456)
      nil

  """
  def get_receipt(id) do
    Receipt
    |> Repo.get(id)
    |> case do
      nil -> nil
      receipt -> Repo.preload(receipt, :expense)
    end
  end

  @doc """
  Creates a receipt.

  ## Examples

      iex> create_receipt(%{field: value})
      {:ok, %Receipt{}}

      iex> create_receipt(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_receipt(attrs \\ %{}) do
    %Receipt{}
    |> Receipt.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a receipt.

  ## Examples

      iex> update_receipt(receipt, %{field: new_value})
      {:ok, %Receipt{}}

      iex> update_receipt(receipt, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_receipt(%Receipt{} = receipt, attrs) do
    receipt
    |> Receipt.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a receipt.

  ## Examples

      iex> delete_receipt(receipt)
      {:ok, %Receipt{}}

      iex> delete_receipt(receipt)
      {:error, %Ecto.Changeset{}}

  """
  def delete_receipt(%Receipt{} = receipt) do
    Repo.delete(receipt)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking receipt changes.

  ## Examples

      iex> change_receipt(receipt)
      %Ecto.Changeset{data: %Receipt{}}

  """
  def change_receipt(%Receipt{} = receipt, attrs \\ %{}) do
    Receipt.changeset(receipt, attrs)
  end
end
