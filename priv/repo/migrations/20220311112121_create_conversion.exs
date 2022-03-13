defmodule CurrencyConverter.Repo.Migrations.CreateConversion do
  use Ecto.Migration

  def change do
    create table(:conversions) do
      add :user_id, :string, null: false
      add :source_currency, :string, null: false
      add :source_amount, :decimal, null: false
      add :destination_currency, :string, null: false
      add :exchange_rate, :decimal
      add :processed_at, :utc_datetime_usec

      timestamps()
    end

    create index(:conversions, [:user_id])

    create constraint(:conversions, :source_amount_must_be_positive, check: "source_amount >= 0")
    create constraint(:conversions, :exchange_rate_must_be_positive, check: "exchange_rate >= 0")
  end
end
