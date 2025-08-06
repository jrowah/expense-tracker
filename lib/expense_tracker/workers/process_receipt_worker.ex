defmodule ExpenseTracker.Workers.ProcessReceiptWorker do
  @moduledoc """
  Oban job for processing receipt images and creating expenses.
  """

  use Oban.Worker, queue: :receipt_processing, max_attempts: 3

  alias ExpenseTracker.{Expenses, OpenAI.ReceiptProcessor}
  # alias ExpenseTracker.Expenses.{Receipt, Category}

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"receipt_id" => receipt_id}}) do
    Logger.info("Processing receipt #{receipt_id}")

    with {:ok, receipt} <- get_receipt(receipt_id),
         {:ok, _updated_receipt} <- update_receipt_status(receipt, "processing"),
         {:ok, ai_data} <- process_receipt_with_ai(receipt),
         {:ok, category} <- find_or_create_category(ai_data.category),
         {:ok, expense} <- create_expense(receipt, ai_data, category),
         {:ok, _final_receipt} <- finalize_receipt(receipt, ai_data, expense) do
      Logger.info("Successfully processed receipt #{receipt_id}, created expense #{expense.id}")
      :ok
    else
      {:error, reason} ->
        Logger.error("Failed to process receipt #{receipt_id}: #{inspect(reason)}")
        mark_receipt_as_failed(receipt_id, reason)
        {:error, reason}
    end
  end

  defp get_receipt(receipt_id) do
    case Expenses.get_receipt(receipt_id) do
      nil -> {:error, "Receipt not found"}
      receipt -> {:ok, receipt}
    end
  end

  defp update_receipt_status(receipt, status) do
    attrs = %{processing_status: status}
    result = Expenses.update_receipt(receipt, attrs)
    result
  end

  defp process_receipt_with_ai(receipt) do
    Logger.info("Processing receipt #{receipt.id} with AI")
    file_path = Path.join(["priv", "static", "uploads", "receipts", receipt.filename])

    case ReceiptProcessor.process_receipt(file_path) do
      {:ok, ai_data} ->
        Logger.info("AI processing successful for receipt #{receipt.id}")
        {:ok, ai_data}

      {:error, reason} ->
        Logger.error("AI processing failed for receipt #{receipt.id}: #{inspect(reason)}")
        {:error, reason}
    end
  end

  defp find_or_create_category(ai_category_name) do
    Logger.info("Finding or creating category: #{inspect(ai_category_name)}")
    # First, try to find an exact match
    case Expenses.get_category_by_name(ai_category_name) do
      nil ->
        # Try fuzzy matching against existing categories
        case find_best_category_match(ai_category_name) do
          {:ok, category} ->
            Logger.info("Found fuzzy match for category '#{ai_category_name}': #{category.name}")
            {:ok, category}

          :no_match ->
            # Create new category
            create_new_category(ai_category_name)
        end

      category ->
        Logger.info("Found exact match for category: #{category.name}")
        {:ok, category}
    end
  end

  defp find_best_category_match(ai_category_name) do
    Logger.info("Finding best match for category: #{ai_category_name}")
    existing_categories = Expenses.list_categories()

    matches =
      Enum.map(existing_categories, fn category ->
        similarity =
          FuzzyCompare.similarity(
            String.downcase(ai_category_name),
            String.downcase(category.name)
          )

        {category, similarity}
      end)

    case Enum.max_by(matches, fn {_category, similarity} -> similarity end, fn -> nil end) do
      {category, similarity} when similarity > 0.7 ->
        {:ok, category}

      _ ->
        :no_match
    end
  end

  defp create_new_category(name) do
    attrs = %{
      name: name,
      description: "Auto-created from receipt processing",
      # Default budget
      monthly_budget: Decimal.new("500.00")
    }

    case Expenses.create_category(attrs) do
      {:ok, category} ->
        Logger.info("Created new category: #{category.name}")
        {:ok, category}

      {:error, changeset} ->
        Logger.error("Failed to create category '#{name}': #{inspect(changeset.errors)}")
        # Fallback to "Other" category or create it
        get_or_create_other_category()
    end
  end

  defp get_or_create_other_category do
    case Expenses.get_category_by_name("Other") do
      nil ->
        attrs = %{
          name: "Other",
          description: "Miscellaneous expenses",
          monthly_budget: Decimal.new("500.00")
        }

        Expenses.create_category(attrs)

      category ->
        {:ok, category}
    end
  end

  defp create_expense(receipt, ai_data, category) do
    Logger.info("Creating expense with data: #{inspect(ai_data)} for category: #{category.name}")

    expense_attrs = %{
      description: ai_data.description,
      amount: ai_data.amount,
      date: ai_data.date,
      notes: "Auto-generated from receipt: #{receipt.filename}",
      category_id: category.id
    }

    case Expenses.create_expense(expense_attrs) do
      {:ok, expense} ->
        Logger.info("Created expense: #{expense.description} - $#{expense.amount}")
        {:ok, expense}

      {:error, changeset} ->
        Logger.error("Failed to create expense: #{inspect(changeset.errors)}")
        {:error, "Failed to create expense"}
    end
  end

  defp finalize_receipt(receipt, ai_data, expense) do
    attrs = %{
      processing_status: "completed",
      confidence_score: ai_data.confidence,
      ai_category_suggestion: ai_data.category,
      ai_amount_suggestion: ai_data.amount,
      ai_description_suggestion: ai_data.description,
      needs_review: ai_data.needs_review,
      processed_at: DateTime.utc_now(),
      expense_id: expense.id
    }

    Expenses.update_receipt(receipt, attrs)
  end

  defp mark_receipt_as_failed(receipt_id, reason) do
    case get_receipt(receipt_id) do
      {:ok, receipt} ->
        attrs = %{
          processing_status: "failed",
          extracted_data: %{"error" => to_string(reason)}
        }

        Expenses.update_receipt(receipt, attrs)

      {:error, _} ->
        Logger.error("Could not mark receipt #{receipt_id} as failed")
    end
  end
end
