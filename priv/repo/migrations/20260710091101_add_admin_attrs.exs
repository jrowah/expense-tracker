defmodule ExpenseTracker.Repo.Migrations.AddAdminAttrs do
  use Ecto.Migration

  def up do
    alter table(:users) do
      add :is_admin, :boolean, default: false, null: false
      add :is_super_admin, :boolean, default: false, null: false
    end
  end

  def down do
    alter table(:users) do
      remove :is_admin
      remove :is_super_admin
    end
  end
end
