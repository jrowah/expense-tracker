defmodule ExpenseTracker.Repo.Migrations.CreateReceipts do
  use Ecto.Migration

  def change do
    create table(:receipts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :filename, :string
      add :original_text, :text
      add :extracted_data, :map
      add :processing_status, :string
      add :confidence_score, :float
      add :ai_category_suggestion, :string
      add :ai_amount_suggestion, :decimal
      add :ai_description_suggestion, :string
      add :needs_review, :boolean, default: false, null: false
      add :processed_at, :utc_datetime
      add :expense_id, references(:expenses, on_delete: :nothing, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create index(:receipts, [:expense_id])
  end
end
