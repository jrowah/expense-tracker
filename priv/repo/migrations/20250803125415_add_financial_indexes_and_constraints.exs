defmodule ExpenseTracker.Repo.Migrations.AddFinancialIndexesAndConstraints do
  use Ecto.Migration

  def up do
    # Add check constraints for positive amounts
    execute """
    ALTER TABLE expenses
    ADD CONSTRAINT positive_amount
    CHECK (amount > 0);
    """

    execute """
    ALTER TABLE categories
    ADD CONSTRAINT positive_monthly_budget
    CHECK (monthly_budget > 0);
    """

    # Add indexes for better query performance and concurrency
    create index(:expenses, [:category_id, :date],
             comment: "Optimize category expense queries by date"
           )

    create index(:expenses, [:category_id, :amount], comment: "Optimize budget calculations")
    create index(:expenses, [:date], comment: "Optimize date-based queries")

    # Add index for recent expenses (without date predicate to avoid immutability issues)
    create index(:expenses, [:category_id, :date],
             name: :expenses_recent_idx,
             comment: "Optimize recent expense queries"
           )

    # Add index to optimize SUM queries for budget calculations
    create index(:expenses, [:category_id, :amount],
             name: :expenses_amount_sum_idx,
             where: "amount > 0",
             comment: "Optimize budget sum calculations"
           )
  end

  def down do
    # Remove constraints
    execute "ALTER TABLE expenses DROP CONSTRAINT positive_amount;"
    execute "ALTER TABLE categories DROP CONSTRAINT positive_monthly_budget;"

    # Remove indexes
    drop index(:expenses, [:category_id, :date])
    drop index(:expenses, [:category_id, :amount])
    drop index(:expenses, [:date])
    drop index(:expenses, [:category_id, :date], name: :expenses_recent_idx)
    drop index(:expenses, [:category_id, :amount], name: :expenses_amount_sum_idx)
  end
end
