defmodule Dummy.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :rules, :string, null: false
      add :confirmed_at, :utc_datetime
    end
  end
end
