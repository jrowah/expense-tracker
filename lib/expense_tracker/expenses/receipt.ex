defmodule ExpenseTracker.Expenses.Receipt do
  use Ecto.Schema
  import Ecto.Changeset

  alias ExpenseTracker.Expenses.Expense

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "receipts" do
    field :filename, :string
    field :original_text, :string
    field :extracted_data, :map
    field :processing_status, :string, default: "pending"
    field :confidence_score, :float
    field :ai_category_suggestion, :string
    field :ai_amount_suggestion, :decimal
    field :ai_description_suggestion, :string
    field :needs_review, :boolean, default: false
    field :processed_at, :utc_datetime

    belongs_to :expense, Expense

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(receipt, attrs) do
    receipt
    |> cast(attrs, [
      :filename,
      :original_text,
      :extracted_data,
      :processing_status,
      :confidence_score,
      :ai_category_suggestion,
      :ai_amount_suggestion,
      :ai_description_suggestion,
      :needs_review,
      :processed_at,
      :expense_id
    ])
    |> validate_required([:filename, :processing_status])
    |> validate_inclusion(:processing_status, ["pending", "processing", "completed", "failed"])
  end
end
